# 03 — Agent Orchestration (LangGraph ReAct)

## Tujuan

Mendefinisikan graph LangGraph baru: node, edge kondisional, isi `AgentState`, dan kriteria berhenti loop. Halaman ini adalah blueprint refactor `app/agent/` files.

## Graph Baru

```
        START
          │
          ▼
   ┌──────────────┐
   │  supervisor  │ ◄──────────────┐
   │ (reasoning)  │                │
   └──────┬───────┘                │
          │                        │
   ┌──────┴───────┐                │
   │ decision:    │                │
   │ - call_tool  │                │
   │ - respond    │                │
   └──┬────────┬──┘                │
      │        │                   │
   call_tool  respond              │
      │        │                   │
      ▼        ▼                   │
   ┌──────────────────────┐  ┌──────────────┐
   │ tools (router)       │  │ response_node│
   │  ├─ rag_tool         │  │ (LLM stream) │
   │  ├─ predictive_tool  │  └──────┬───────┘
   │  └─ firecrawl_tool   │         │
   └──────────┬───────────┘         │
              │                     │
              └─────────────────────┘───┐
                  (loop back)           │
                                        ▼
                                      END
```

## Node

### 1. `supervisor`

Reasoning node. Menerima `AgentState`, memanggil LLM dengan 3 tools ter-bind (`llm.bind_tools([rag_tool, predictive_tool, firecrawl_tool])`). LLM mengembalikan:
- **tool call** → pilih tool + argumen
- **final answer ready** → lanjut ke `response_node`

### 2. `tools`

Tool executor router. Dispatch dari supervisor `tool_calls` ke tool yang sesuai. Hasil ditulis ke `scratchpad` + field state yang relevan.

### 3. `response_node`

LLM final. Stream token via `astream`. Memasukkan seluruh state (citations, web_search_results, prediction) ke prompt.

## Tools

| Tool | Method | Output WS event |
|---|---|---|
| `rag_tool` | `rag_search(query)` | `citation` × N |
| `predictive_tool` | `predictive_predict(features)` | `prediction_result` |
| `firecrawl_tool` | `firecrawl_search(query)` | `web_search_result` × N |

Tools adalah wrapper di `app/agent/tools/` yang memanggil fungsi di `app/rag/` / `app/machine_learning/` (layers tidak tahu soal LangGraph).

## AgentState

```python
class AgentState(BaseModel):
    conversation_id: str
    user_id: str
    user_message: str

    scratchpad: list[dict] = Field(default_factory=list)
    tool_calls: list[ToolCallRecord] = Field(default_factory=list)

    iteration: int = 0
    max_iterations: int = 5

    citations: list[Citation] = Field(default_factory=list)
    web_search_results: list[WebSearchResult] = Field(default_factory=list)
    prediction: PredictionResult | None = None

    final_answer: str | None = None
    error: str | None = None
```

## Loop Conditions

1. LLM says "final_ready" → `respond` (response_node)
2. `iteration >= max_iterations` → `respond`
        Add system message to scratchpad: "max iterations reached, answer with available info"
3. Fatal error → `respond` with apology

## Edge Conditional

```python
def route_after_supervisor(state: AgentState) -> str:
    if state.iteration >= state.max_iterations:
        return "respond"
    if state.error:
        return "respond"
    last = state.scratchpad[-1] if state.scratchpad else {}
    if last.get("tool_calls"):
        return "tools"
    return "respond"
```

## Notes

- System prompt: Indonesian, 3 tools described, guidance to choose tool per question type
- supervisor NOT hardcode tool names – use `bind_tools([...])`
- response_node use `astream` for per-token streaming
- Iteration counter increments before supervisor runs
- Tool executor catches exceptions per tool, logs stack trace, return ToolException to scratchpad
- Tools and LLM layers remain independent from LangGraph
