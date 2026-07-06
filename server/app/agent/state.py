"""
Enhanced AgentState dengan struktur untuk:
- Multi-step planning (PlanStep[])
- Parallel tool execution tracking
- Reflection loop
- Token budget tracking

Perubahan dari versi lama:
- Tambah `plan` dan `plan_step_idx` untuk orchestration eksplisit
- Tambah `reflection` untuk self-critique sebelum respond
- Tambah `tool_call_log` untuk audit parallel calls
- Tambah `token_budget` untuk mencegah infinite loop
- `scratchpad` tetap kompatibel dengan format lama (role/content/tool_calls)
"""
from collections.abc import Callable
from typing import Any, Optional

from pydantic import BaseModel, Field

from app.schemas.agent import Citation, PredictionResult, ToolCallRecord, WebSearchResult


# ---------- Planning primitives ----------

class PlanStep(BaseModel):
    """Satu langkah dalam execution plan."""
    step_id: int
    description: str = ""
    tool: str = ""                  # rag_tool | predictive_tool | firecrawl_tool | respond
    args_hint: dict[str, Any] = Field(default_factory=dict)
    depends_on: list[int] = Field(default_factory=list)
    status: str = "pending"         # pending | running | done | skipped | failed
    result_summary: str = ""


class ReflectionResult(BaseModel):
    """Hasil self-critique setelah eksekusi tool."""
    info_sufficient: bool = False
    plan_completed: bool = False
    missing_aspects: list[str] = Field(default_factory=list)
    next_action: str = "respond"    # iterate | respond
    reason: str = ""
    quality_score: float = 0.0      # 0.0 - 1.0


# ---------- Enhanced State ----------

class AgentState(BaseModel):
    # Identity
    conversation_id: str = ""
    user_id: str = ""
    user_message: str = ""

    # Planning (BARU)
    plan: list[PlanStep] = Field(default_factory=list)
    plan_step_idx: int = 0
    needs_planning: bool = True

    # Execution
    scratchpad: list[dict] = Field(default_factory=list)
    tool_calls: list[ToolCallRecord] = Field(default_factory=list)
    tool_call_log: list[dict] = Field(default_factory=list)

    # Reflection (BARU)
    reflection: Optional[ReflectionResult] = None
    reflection_count: int = 0
    max_reflections: int = 2

    # Iteration control
    iteration: int = 0
    max_iterations: int = 6         # naikkan dari 5 → 6 karena ada planner+reflector

    # Results
    citations: list[Citation] = Field(default_factory=list)
    web_search_results: list[WebSearchResult] = Field(default_factory=list)
    prediction: Optional[PredictionResult] = None
    final_answer: Optional[str] = None
    error: Optional[str] = None

    # Callback
    state_update_callback: Optional[Callable] = None

    model_config = {"arbitrary_types_allowed": True}

    # ---------- Helpers ----------

    def add_tool_call(
        self,
        tool_name: str,
        inp: dict,
        output_summary: str = "",
        success: bool = True,
        duration_ms: int = 0,
        parallel_group: Optional[str] = None,
    ) -> None:
        """Log tool call untuk audit trail."""
        self.tool_calls.append(ToolCallRecord(
            tool_name=tool_name,
            input_snapshot=str(inp)[:300],
            output_summary=output_summary[:300],
            success=success,
        ))
        self.tool_call_log.append({
            "tool": tool_name,
            "input_keys": list(inp.keys()) if isinstance(inp, dict) else [],
            "success": success,
            "duration_ms": duration_ms,
            "parallel_group": parallel_group,
            "iteration": self.iteration,
        })

    def mark_step_done(self, step_id: int, result_summary: str = "") -> None:
        for step in self.plan:
            if step.step_id == step_id:
                step.status = "done"
                step.result_summary = result_summary[:200]
                break

    def pending_steps(self) -> list[PlanStep]:
        """Steps yang siap dieksekusi (deps terpenuhi, status pending)."""
        done_ids = {s.step_id for s in self.plan if s.status == "done"}
        ready = []
        for step in self.plan:
            if step.status != "pending":
                continue
            if all(dep in done_ids for dep in step.depends_on):
                ready.append(step)
        return ready

    def is_plan_complete(self) -> bool:
        if not self.plan:
            return True
        return all(s.status in ("done", "skipped", "failed") for s in self.plan)
