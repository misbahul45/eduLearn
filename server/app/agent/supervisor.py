import logging

from langchain_core.messages import SystemMessage, HumanMessage, AIMessage

from app.agent.state import AgentState
from app.agent.tools import firecrawl_tool, predictive_tool, rag_tool
from app.llm import get_llm

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = (
    "Kamu adalah asisten akademis EduLearn AI. "
    "Kamu punya 3 tools: rag_tool, predictive_tool, firecrawl_tool. "
    "- rag_tool: cari referensi lokal dari knowledge base (materi kuliah, buku). "
    "- predictive_tool: prediksi lulus/tidak lulus berdasarkan data belajar siswa. "
    "- firecrawl_tool: cari informasi terkini dari web. "
    "\n\n"
    "Panduan memilih tool:\n"
    "- Konsep akademis dasar (mis. 'apa itu neural network') -> rag_tool dulu\n"
    "- Info terkini, berita, topik 2026 -> firecrawl_tool\n"
    "- Topik yang mungkin tidak ada di lokal -> firecrawl_tool\n"
    "- Progress/kelulusan siswa -> predictive_tool\n"
    "- Bisa juga kombinasi: rag_tool + firecrawl_tool untuk jawaban lengkap\n"
    "\n"
    "Gunakan Bahasa Indonesia. "
    "Bila sudah cukup -> susun jawaban."
)


async def supervisor_node(state: AgentState) -> dict:
    logger.info("Supervisor reasoning iteration=%d", state.iteration)
    llm = get_llm()

    bound_llm = llm.bind_tools([rag_tool, predictive_tool, firecrawl_tool])
    messages = [SystemMessage(content=SYSTEM_PROMPT)]

    for m in state.scratchpad:
        role = m.get("role", "")
        content = m.get("content", "")
        if role == "user":
            messages.append(HumanMessage(content=content))
        elif role == "assistant":
            tc_list = m.get("tool_calls", [])
            aim = AIMessage(content=content, tool_calls=tc_list if tc_list else None)
            messages.append(aim)
        elif role == "function":
            messages.append(HumanMessage(content=f"Hasil tool {m.get('name', '')}: {content[:1000]}"))

    if not any(m.type == "human" for m in messages):
        messages.append(HumanMessage(content=state.user_message))

    result = await bound_llm.ainvoke(messages)

    new_scratchpad = state.scratchpad.copy()
    new_scratchpad.append({
        "role": "assistant",
        "content": result.content if isinstance(result.content, str) else str(result.content),
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


async def tools_node(state: AgentState) -> dict:
    last_sr = state.scratchpad[-1] if state.scratchpad else {}
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
            if func_name == "rag_tool":
                result = await rag_tool.ainvoke(args)
            elif func_name == "predictive_tool":
                result = predictive_tool.invoke(args)
            elif func_name == "firecrawl_tool":
                result = await firecrawl_tool.ainvoke(args)
            else:
                result = {}

            result_str = str(result)
            new_scratchpad.append({
                "role": "function",
                "name": func_name,
                "content": result_str[:1000],
            })

            if func_name == "rag_tool":
                raw = result if isinstance(result, list) else (result.get("results", []) if isinstance(result, dict) else [])
                for cit in raw:
                    if isinstance(cit, dict):
                        meta = cit.get("metadata", {})
                        new_citations.append({
                            "source_id": cit.get("source_id", ""),
                            "snippet": cit.get("snippet", str(cit)[:200]),
                            "score": cit.get("score", 0.0),
                            "document": meta.get("title", meta.get("file_name", "")),
                        })
            elif func_name == "firecrawl_tool":
                raw = result if isinstance(result, list) else (result.get("results", []) if isinstance(result, dict) and "results" in result else [])
                if isinstance(result, dict) and "url" in result:
                    raw = [result]
                for wsr in raw:
                    if isinstance(wsr, dict):
                        new_web_search.append({
                            "result_id": wsr.get("result_id", f"ws_{len(new_web_search):03d}"),
                            "url": wsr.get("url", ""),
                            "title": wsr.get("title", ""),
                            "snippet": wsr.get("snippet", str(wsr)[:200]),
                            "markdown_excerpt": wsr.get("markdown_excerpt", ""),
                            "source": wsr.get("source", "firecrawl"),
                            "relevance_score": wsr.get("relevance_score", 0.0),
                        })
            elif func_name == "predictive_tool":
                rdict = result if isinstance(result, dict) else {}
                from app.schemas.prediction import PredictionResult as PR
                new_pred = PR(
                    predicted_label=rdict.get("predicted_label", rdict.get("label", "")),
                    confidence=rdict.get("confidence", rdict.get("probability", 0.0)),
                    class_scores=rdict.get("class_scores", []),
                    model_name=rdict.get("model_name", "Deep MLP (TensorFlow)"),
                    model_version=rdict.get("model_version", "1.0.0"),
                    input_features_used=rdict.get("input_features_used", []),
                    generated_at=rdict.get("generated_at"),
                )
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
