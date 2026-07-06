import asyncio
import inspect
import json
import logging
import time
from typing import Any

from app.agent.state import AgentState
from app.agent.tools import firecrawl_tool, predictive_tool, rag_tool
from app.schemas.knowledge import (
    Citation as KnowledgeCitation,
    CitationMeta,
    WebSearchResult as KWebSearchResult,
)
from app.schemas.prediction import ClassScore, PredictionResult as PR

logger = logging.getLogger(__name__)


async def _emit(state: AgentState, event: dict[str, Any]) -> None:
    callback = getattr(state, "state_update_callback", None)
    if callback:
        try:
            if inspect.iscoroutinefunction(callback):
                await callback(event)
            else:
                callback(event)
        except Exception as e:
            logger.debug("Tools emit failed: %s", e)


async def _handle_rag(args: dict, state: AgentState):
    result = await rag_tool.ainvoke(args)
    raw = result if isinstance(result, list) else (
        result.get("results", []) if isinstance(result, dict) else []
    )
    new_citations = []
    for cit in raw:
        if not isinstance(cit, dict):
            continue
        meta = cit.get("metadata", {})
        citation_obj = KnowledgeCitation(
            source_id=cit.get("source_id", ""),
            snippet=cit.get("snippet", str(cit)[:200]),
            score=cit.get("score", 0.0),
            metadata=CitationMeta(
                title=meta.get("title", meta.get("file_name", "")),
                author=meta.get("author"),
                page=meta.get("page"),
                document_id=meta.get("document_id"),
                file_name=meta.get("file_name"),
            ),
        )
        new_citations.append(citation_obj)
        await _emit(state, {
            "type": "citation",
            "source_id": citation_obj.source_id,
            "snippet": citation_obj.snippet,
            "score": citation_obj.score,
            "metadata": {
                "title": citation_obj.metadata.title,
                "author": citation_obj.metadata.author,
                "page": citation_obj.metadata.page,
                "document_id": citation_obj.metadata.document_id,
                "file_name": citation_obj.metadata.file_name,
            },
        })
    summary = f"{len(raw)} dokumen relevan ditemukan"
    result_str = f"RAG returned {len(raw)} docs. " + " | ".join(
        f"[{c.get('metadata', {}).get('title', 'N/A')}] {str(c.get('snippet', ''))[:200]}"
        for c in raw[:5]
    )
    return new_citations, summary, result_str


async def _handle_firecrawl(args: dict, state: AgentState):
    result = await firecrawl_tool.ainvoke(args)
    raw = result if isinstance(result, list) else (
        result.get("results", []) if isinstance(result, dict) and "results" in result else []
    )
    if isinstance(result, dict) and "url" in result:
        raw = [result]

    new_web = []
    for wsr in raw:
        if not isinstance(wsr, dict):
            continue
        ws_obj = KWebSearchResult(
            result_id=wsr.get("result_id", "ws_" + str(len(new_web)).zfill(3)),
            url=wsr.get("url", ""),
            title=wsr.get("title", ""),
            snippet=wsr.get("snippet", str(wsr)[:200]),
            markdown_excerpt=wsr.get("markdown_excerpt", ""),
            source=wsr.get("source", "firecrawl"),
            relevance_score=wsr.get("relevance_score", 0.0),
        )
        new_web.append(ws_obj)
        await _emit(state, {
            "type": "web_search_result",
            "result_id": ws_obj.result_id,
            "url": ws_obj.url,
            "title": ws_obj.title,
            "snippet": ws_obj.snippet,
            "markdown_excerpt": ws_obj.markdown_excerpt,
            "source": ws_obj.source,
            "relevance_score": ws_obj.relevance_score,
        })
    summary = f"{len(raw)} hasil web ditemukan"
    result_str = f"Web returned {len(raw)} results. " + " | ".join(
        f"[{r.get('title', 'N/A')}] {str(r.get('snippet', ''))[:200]}"
        for r in raw[:5]
    )
    return new_web, summary, result_str


async def _handle_predictive(args: dict, state: AgentState):
    result = await predictive_tool.ainvoke(args)
    rdict = result if isinstance(result, dict) else {}

    class_scores = [
        ClassScore(label=cs.get("label", ""), score=cs.get("score", 0.0))
        for cs in rdict.get("class_scores", [])
    ]
    pred = PR(
        predicted_label=rdict.get("predicted_label", ""),
        confidence=rdict.get("confidence", 0.0),
        confidence_interpretation=rdict.get("confidence_interpretation", ""),
        class_scores=class_scores,
        model_name=rdict.get("model_name", "Deep MLP (TensorFlow)"),
        model_version=rdict.get("model_version", "1.0.0"),
        input_features_used=rdict.get("input_features_used", []),
        recommendations=rdict.get("recommendations", []),
        risk_factors=rdict.get("risk_factors", []),
    )

    synthesis_meta = rdict.get("synthesis_metadata", {})

    await _emit(state, {
        "type": "prediction_result",
        "node": "predictive_tool",
        "data": {
            "predicted_label": pred.predicted_label,
            "confidence": pred.confidence,
            "confidence_interpretation": pred.confidence_interpretation,
            "class_scores": [{"label": cs.label, "score": cs.score} for cs in pred.class_scores],
            "model_name": pred.model_name,
            "model_version": pred.model_version,
            "input_features_used": pred.input_features_used,
            "recommendations": pred.recommendations,
            "risk_factors": pred.risk_factors,
            "generated_at": pred.generated_at.isoformat() if pred.generated_at else None,
            "synthesis_metadata": synthesis_meta,
        },
    })

    summary = f"Prediksi: {pred.predicted_label} (conf: {pred.confidence:.1%})"

    recs_text = "\n".join(f"- {r}" for r in pred.recommendations) if pred.recommendations else "- Tidak ada rekomendasi"
    risks_text = "\n".join(f"- {r}" for r in pred.risk_factors) if pred.risk_factors else "- Tidak ada risk factors"

    inferred_detail = ""
    if synthesis_meta.get("inferred_fields"):
        inferred_detail = "\n\nFIELD SINTESIS:\n"
        for fname, fdata in synthesis_meta["inferred_fields"].items():
            inferred_detail += f"- {fname}: {fdata.get('value')} ({fdata.get('reason')})\n"

    result_str = (
        f"HASIL PREDIKSI:\n"
        f"- Label: {pred.predicted_label}\n"
        f"- Confidence: {pred.confidence:.1%} ({pred.confidence_interpretation})\n"
        f"- Model: {pred.model_name} v{pred.model_version}\n"
        f"- Fitur eksplisit: {synthesis_meta.get('n_explicit_fields', 0)}\n"
        f"- Fitur sintesis: {synthesis_meta.get('n_inferred_fields', 0)}\n"
        f"- Profile confidence: {synthesis_meta.get('profile_confidence', 0):.1%}\n\n"
        f"REKOMENDASI:\n{recs_text}\n\n"
        f"RISK FACTORS:\n{risks_text}{inferred_detail}"
    )
    return pred, summary, result_str


async def _execute_single_tool(
    tc: dict,
    state: AgentState,
    parallel_group: str,
    iteration: int,
) -> dict:
    """Execute 1 tool call. Returns dict dengan hasil terstruktur."""
    func_name = tc.get("name", tc.name if hasattr(tc, "name") else "")
    if not func_name:
        func_name = tc.get("function", {}).get("name", "")
    args = tc.get("args", tc.args if hasattr(tc, "args") else {})
    if isinstance(args, str):
        try:
            args = json.loads(args)
        except json.JSONDecodeError:
            args = {"_raw": args}
    if isinstance(args, list):
        args = args[0] if args else {}
    call_id = tc.get("id", "") or (tc.id if hasattr(tc, "id") else f"call_{func_name}_{id(tc)}")

    await _emit(state, {
        "type": "tool_call",
        "tool_name": func_name,
        "input": args,
        "call_id": call_id,
        "parallel_group": parallel_group,
        "iteration": iteration,
    })

    start = time.perf_counter()
    output: dict = {
        "call_id": call_id,
        "tool_name": func_name,
        "args": args,
        "success": False,
        "result_str": "",
        "summary": "",
        "duration_ms": 0,
        "new_citations": [],
        "new_web": [],
        "prediction": None,
        "error": None,
    }

    try:
        if func_name == "rag_tool":
            cit_list, summary, result_str = await _handle_rag(args, state)
            output["new_citations"] = cit_list
            output["summary"] = summary
            output["result_str"] = result_str
            output["success"] = True

        elif func_name == "firecrawl_tool":
            web_list, summary, result_str = await _handle_firecrawl(args, state)
            output["new_web"] = web_list
            output["summary"] = summary
            output["result_str"] = result_str
            output["success"] = True

        elif func_name == "predictive_tool":
            pred, summary, result_str = await _handle_predictive(args, state)
            output["prediction"] = pred
            output["summary"] = summary
            output["result_str"] = result_str
            output["success"] = True

        else:
            output["summary"] = f"Unknown tool: {func_name}"
            output["result_str"] = f"Tool not recognized: {func_name}"
            output["error"] = "unknown_tool"

    except Exception as e:
        logger.exception("Tool %s failed", func_name)
        await _emit(state, {
            "type": "error",
            "node": func_name,
            "message": f"Error: {e}",
            "fatal": False,
        })
        output["result_str"] = f"Error executing tool: {e}"
        output["summary"] = f"Gagal: {str(e)[:100]}"
        output["error"] = str(e)

    output["duration_ms"] = int((time.perf_counter() - start) * 1000)

    await _emit(state, {
        "type": "tool_result",
        "tool_name": func_name,
        "call_id": call_id,
        "output_summary": output["summary"],
        "duration_ms": output["duration_ms"],
        "success": output["success"],
        "parallel_group": parallel_group,
        "iteration": iteration,
    })

    return output


async def tools_node(state: AgentState) -> dict:
    """Execute all tool_calls dari supervisor dalam PARALEL."""
    last_sr = state.scratchpad[-1] if state.scratchpad else {}
    tcs = last_sr.get("tool_calls", [])

    if not tcs:
        return {
            "scratchpad": state.scratchpad,
            "citations": state.citations,
            "web_search_results": state.web_search_results,
            "prediction": state.prediction,
        }

    parallel_group = f"iter_{state.iteration}_n{len(tcs)}"
    iteration = state.iteration

    logger.info(
        "Tools node: executing %d tool calls in PARALLEL (group=%s, iter=%d)",
        len(tcs), parallel_group, iteration,
    )

    results = await asyncio.gather(
        *[_execute_single_tool(tc, state, parallel_group, iteration) for tc in tcs],
        return_exceptions=False,
    )

    new_citations = list(state.citations)
    new_web = list(state.web_search_results)
    new_pred = state.prediction
    new_scratchpad = list(state.scratchpad)

    for r in results:
        if r["new_citations"]:
            new_citations.extend(r["new_citations"])
        if r["new_web"]:
            new_web.extend(r["new_web"])
        if r["prediction"] is not None:
            new_pred = r["prediction"]

        state.add_tool_call(
            tool_name=r["tool_name"],
            inp=r["args"],
            output_summary=r["summary"],
            success=r["success"],
            duration_ms=r["duration_ms"],
            parallel_group=parallel_group,
        )

        new_scratchpad.append({
            "role": "tool",
            "name": r["tool_name"],
            "tool_call_id": r["call_id"],
            "content": r["result_str"][:4000],
        })

    for r in results:
        if not r["success"]:
            continue
        for step in state.plan:
            if step.status == "pending" and step.tool == r["tool_name"]:
                state.mark_step_done(step.step_id, r["summary"])
                break

    logger.info(
        "Tools node done: %d/%d success, %d citations, %d web, pred=%s",
        sum(1 for r in results if r["success"]),
        len(results),
        sum(len(r["new_citations"]) for r in results),
        sum(len(r["new_web"]) for r in results),
        new_pred.predicted_label if new_pred else "None",
    )

    return {
        "scratchpad": new_scratchpad,
        "citations": new_citations,
        "web_search_results": new_web,
        "prediction": new_pred,
    }