# 16 — Halaman Chat UI (Realtime Agent Chat)

## Tujuan

Fitur utama EduLearn AI — chat realtime dengan agent ReAct. Siswa bertanya, agent menalar via LangGraph (RAG + prediksi + Firecrawl web search), jawaban di-stream token-per-token. Trace agent ditampilkan live di sheet. Hasil prediksi binary tampil sebagai chart inline di bubble. Sitasi RAG lokal & hasil web search Firecrawl tampil sebagai collapsible list.

## Komponen / Isi Utama

**Route**: `/home/chat` (nama: `chatTab`, tab ke-2 bottom nav).

**Widget tree**:
```
ChatPage (ConsumerStatefulWidget)
└── Scaffold
    ├── appBar: AppBar(
    │     title: Row([StatusBadge(), SizedBox(8), Text("AI Assistant")]),
    │     actions: [IconButton(receipt_long → toggle AgentTraceSheet), IconButton(more_vert → menu)]
    │   )
    ├── body: Column
    │   ├── Expanded
    │   │   └── ListView.builder(reverse, itemCount: messages+1)
    │   │       ├── if index==0: EmptyStateWidget (quick suggestion chips)
    │   │       └── ChatBubble(message)
    │   ├── ConnectionModeBanner (bila REST fallback)
    │   └── ChatInputBar
    └── bottomSheet: AgentTraceSheet (DraggableScrollableSheet 0.15–0.7)
```

**Sub-widgets** (Modular widgets are extracted under `client/lib/features/chat/widgets/`):
- `ConnectionModeBanner` -> [connection_mode_banner.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/connection_mode_banner.dart)
- `StatusBadge` -> [status_badge.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/status_badge.dart)
- `EmptyState` -> [empty_state.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/empty_state.dart)
- `ChatBubble` -> [chat_bubble.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/chat_bubble.dart)
- `PredictionChartCard` -> [prediction_chart_card.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/prediction_chart_card.dart)
- `CitationTile` -> [citation_tile.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/citation_tile.dart)
- `WebSearchTile` -> [web_search_tile.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/web_search_tile.dart)
- `AgentTraceSheet` -> [agent_trace_sheet.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/agent_trace_sheet.dart)
- `ChatInputBar` -> [chat_input_bar.dart](file:///home/misbahul45/code/eduLearn/client/lib/features/chat/widgets/chat_input_bar.dart)

**Events**: stateUpdate, toolCall, toolResult, token, predictionResult, citation, webSearchResult, final_, error.

**WS flow**: connect → sendMessage → stream events → final event → close; REST fallback after 3 failed WS attempts.

**Reconnect**: exponential backoff 1s–30s, check connectivity, reconnect on foreground.

**Quick suggestion chips**: 3 chips only when messages empty — "Jelaskan neural network", "Prediksi kelulusanku", "Berita AI terbaru 2026".
