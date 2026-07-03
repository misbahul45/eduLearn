import logging

from langchain_core.messages import SystemMessage, HumanMessage, AIMessage

from app.agent.state import AgentState
from app.agent.tools import rag_tool as rag_t
from app.agent.tools import predictive_tool as pred_t
from app.agent.tools import firecrawl_tool as fire_t
from app.llm import get_llm

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = (
    "Kamu adalah asisten akademis EduLearn AI. "
    "Kamu punya 3 tools: rag_tool, predictive_tool, firecrawl_tool. "
    "rag_tool: referensi lokal, predictive_tool: prediksi lulus/tidak lulus, firecrawl_tool: web search. "
    "Bila pertanyaan konsep -> rag_tool. Info terkini -> firecrawl_tool. Progress/kelulusan -> predictive_tool. "
    "Bila sudah cukup -> susun jawaban."
)


async def supervisor_node(state: AgentState) -> dict:
    logger.info("Supervisor reasoning iteration=%d", state.iteration)
    llm = get_llm()

    llm_binding = llm.bind_tools([rag_t.bound_tool, pred_t.bound_tool, fire_t.bound_tool])
    messages = [SystemMessage(content=SYSTEM_PROMPT)]
    for m in state.scratchpad:
        r = m.get("role", "")
        content = m.get("content", "")
        if r == "user":
            messages.append(HumanMessage(content=content))
        elif r == "assistant":
            tc_list = m.get("tool_calls", [])
            airesult = AIMessage(content=content, tool_calls=tc_list if tc_list else None)
            messages.append(airesult)
        elif r == "function":
            name = m.get("name", "")
            messages.append(AIMessage(content="", tool_call_id="placeholder"))
            messages.append(HumanMessage(content=f"Tool {name} result: {content[:1000]}"))

    if not any(m.type == "human" for m in messages):
        messages.append(HumanMessage(content=state.user_message))

    result = await llm_binding.ainvoke(messages)

    sc_list = []
    if isinstance(result.content, list):
        sc_list = result.content
    elif isinstance(result.content, str):
        sc_list = [{"type": "text", "text": result.content}]

    tc_list = result.tool_calls if result.tool_calls else sc_list

    new_scratchpad = state.scratchpad.copy()
    new_scratchpad.append({
        "role": "assistant",
        "content": str(sc_list),
        "tool_calls": result.tool_calls if result.tool_calls else [],
    })

    return {
        "scratchpad": new_scratchpad,
        "iteration": state.iteration + 1,
    }


def route_after_supervisor(state: AgentState) -> str:
    if state.iteration >= state.max_iterations:
        return "respond"
    if state.error:
        return "respond"
    last_sr = state.scratchpad[-1] if state.scratchpad else {}
    tcs = last_sr.get("tool_calls", [])
    if tcs:
        return "tools"
    return "respond"


async def _get_tool_response(tool_name: str, func_args: dict) -> dict | list:
    if tool_name == "rag_tool":
        q = func_args.get("query", "")
        res = await rag_t.rag_search(q)
        return res
    elif tool_name == "predictive_tool":
        res = await pred_t.predictive_predict()
        return res
    elif tool_name == "firecrawl_tool":
        q = func_args.get("query", "")
        res = await fire_t.firecrawl_search(q)
        return res
    return {}


async def tools_node(state: AgentState) -> dict:
    last_sr = state.scratchpad[-1]
    tcs = last_sr.get("tool_calls", [])

    new_citations = list(state.citations)
    new_web_search = list(state.web_search_results)
    new_pred = state.prediction
    new_scratchpad = list(state.scratchpad)

    for tc in tcs:
        func_name = tc.get("name", tc.name if hasattr(tc, "name") else "")
        if not func_name:
            func_name = tc.get("function", {}).get("name", "")
        args = tc.get("args", tc.args if hasattr(tc, "args") else {})
        if isinstance(args, str):
            import json
            args = json.loads(args)
        if isinstance(args, list):
            args = args[0] if args else args
        try:
            result = await _get_tool_response(func_name, args)
            result_str = str(result)

            new_scratchpad.append({
                "role": "function",
                "name": func_name,
                "content": result_str[:1000],
            })

            if func_name == "rag_tool" or func_name == "rag_tool":
                raw = result if isinstance(result, list) else (result.get("results", []) if isinstance(result, dict) else [])
                for cit in raw:
                    if isinstance(cit, dict):
                        new_citations.append({
                            "document": cit.get("document", cit.get("title", "")),
                            "snippet": cit.get("snippet", str(cit)[:200]),
                            "relevance": cit.get("relevance", cit.get("score", 0.0)),
                        })
            elif func_name == "firecrawl_tool":
                raw = result if isinstance(result, list) else (result.get("results", []) if isinstance(result, dict) and "results" in result else [])
                if isinstance(result, dict) and "url" in result:
                    raw = [result]
                for wsr in raw:
                    if isinstance(wsr, dict):
                        new_web_search.append({
                            "url": wsr.get("url", ""),
                            "title": wsr.get("title", ""),
                            "snippet": wsr.get("snippet", str(wsr)[:200]),
                        })
            elif func_name == "predictive_tool":
                rdict = result if isinstance(result, dict) else {}
                new_pred = {
                    "label": rdict.get("label", ""),
                    "probability": rdict.get("probability", 0.0),
                    "class_scores": rdict.get("class_scores", {}),
                }
        except Exception as e:
            logger.exception("Tool %s failed", func_name)
            new_scratchpad.append({
                "role": "function",
                "name": func_name,
                "content": f"Error: {e}",
                "error": True,
            })

    return {
        "scratchpad": new_scratchpad,
        "citations": new_citations,
        "web_search_results": new_web_search,
        "prediction": new_pred,
    }
