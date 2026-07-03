# Graph Report - eduLearn  (2026-07-03)

## Corpus Check
- 81 files · ~28,583 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 536 nodes · 603 edges · 53 communities (42 shown, 11 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1c8cbc51`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Win32Window|Win32Window]]
- [[_COMMUNITY_ML Prak — Infra & Setup Requirements|ML Prak — Infra & Setup Requirements]]
- [[_COMMUNITY_app_text_field.dart|app_text_field.dart]]
- [[_COMMUNITY_GeneratedPluginRegistrant|GeneratedPluginRegistrant]]
- [[_COMMUNITY_my_application.cc|my_application.cc]]
- [[_COMMUNITY_Internationalizing Flutter Applications|Internationalizing Flutter Applications]]
- [[_COMMUNITY_Implementing Routing and Deep Linking|Implementing Routing and Deep Linking]]
- [[_COMMUNITY_app_colors.dart|app_colors.dart]]
- [[_COMMUNITY_AppDelegate|AppDelegate]]
- [[_COMMUNITY_Architecting Flutter Applications|Architecting Flutter Applications]]
- [[_COMMUNITY_register_page.dart|register_page.dart]]
- [[_COMMUNITY_Implementing Flutter Integration Tests|Implementing Flutter Integration Tests]]
- [[_COMMUNITY_Previewing Flutter Widgets|Previewing Flutter Widgets]]
- [[_COMMUNITY_login_page.dart|login_page.dart]]
- [[_COMMUNITY_wWinMain|wWinMain]]
- [[_COMMUNITY_Summary|Summary]]
- [[_COMMUNITY_Implementing Adaptive Layouts|Implementing Adaptive Layouts]]
- [[_COMMUNITY_app_routes.dart|app_routes.dart]]
- [[_COMMUNITY_app_spacing.dart|app_spacing.dart]]
- [[_COMMUNITY_app_text_styles.dart|app_text_styles.dart]]
- [[_COMMUNITY_manifest.json|manifest.json]]
- [[_COMMUNITY_Writing Flutter Widget Tests|Writing Flutter Widget Tests]]
- [[_COMMUNITY_Resolving Flutter Layout Errors|Resolving Flutter Layout Errors]]
- [[_COMMUNITY_Serializing JSON Manually in Flutter|Serializing JSON Manually in Flutter]]
- [[_COMMUNITY_Implementing Flutter Networking|Implementing Flutter Networking]]
- [[_COMMUNITY_splash_page.dart|splash_page.dart]]
- [[_COMMUNITY_app_router.dart|app_router.dart]]
- [[_COMMUNITY_LoginPage|LoginPage]]
- [[_COMMUNITY_GeneratedPluginRegistrant|GeneratedPluginRegistrant]]
- [[_COMMUNITY_packagefluttermaterial.dart|package:flutter/material.dart]]
- [[_COMMUNITY_handle_new_rx_page|handle_new_rx_page]]
- [[_COMMUNITY_widget_test.dart|widget_test.dart]]
- [[_COMMUNITY_MainActivity|MainActivity]]
- [[_COMMUNITY_PackageDescription|PackageDescription]]
- [[_COMMUNITY__onLogin|_onLogin]]
- [[_COMMUNITY_app|app]]
- [[_COMMUNITY_opencode.json|opencode.json]]
- [[_COMMUNITY_dependencies|dependencies]]
- [[_COMMUNITY_AGENTS|AGENTS.md]]
- [[_COMMUNITY_flutter_export_environment.sh|flutter_export_environment.sh]]
- [[_COMMUNITY_README|README.md]]
- [[_COMMUNITY_flutter_export_environment.sh|flutter_export_environment.sh]]
- [[_COMMUNITY_String|String?]]
- [[_COMMUNITY_server|server]]

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 22 edges
2. `ML Prak — Infra & Setup Requirements` - 14 edges
3. `MessageHandler` - 12 edges
4. `FlutterWindow` - 10 edges
5. `Create` - 10 edges
6. `WndProc` - 10 edges
7. `MessageHandler` - 9 edges
8. `Implementing Flutter Integration Tests` - 8 edges
9. `Implementing Adaptive Layouts` - 8 edges
10. `_MyApplication` - 7 edges

## Surprising Connections (you probably didn't know these)
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  app/windows/runner/main.cpp → app/windows/runner/utils.cpp
- `Win32Window::Win32Window()` --calls--> `Destroy`  [INFERRED]
  app/windows/runner/win32_window.cpp → app/windows/runner/win32_window.h
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  app/linux/runner/my_application.cc → app/linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  app/linux/runner/main.cc → app/linux/runner/my_application.cc
- `OnCreate` --calls--> `RegisterPlugins()`  [INFERRED]
  app/windows/runner/flutter_window.h → app/windows/flutter/generated_plugin_registrant.cc

## Import Cycles
- None detected.

## Communities (53 total, 11 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.06
Nodes (53): RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT, UINT, WPARAM, FlutterWindow (+45 more)

### Community 1 - "ML Prak — Infra & Setup Requirements"
Cohesion: 0.04
Nodes (46): 10. Useful Commands, 11.1 SSE Streaming Configuration, 11.2 Vector Database (pgvector), 11.3 Python Version Mismatch, 11.4 App Structure Requirement, 11.5 Inter-Container Communication, 11.6 Flutter App Connectivity, 11. Important Notes (+38 more)

### Community 2 - "app_text_field.dart"
Cohesion: 0.07
Nodes (29): AppButton, build, isLoading, onPressed, text, AppTextField, build, controller (+21 more)

### Community 3 - "GeneratedPluginRegistrant"
Cohesion: 0.08
Nodes (19): GeneratedPluginRegistrant, +registerWithRegistry, SceneDelegate, RunnerTests, RegisterGeneratedPlugins(), MainFlutterWindow, RunnerTests, Cocoa (+11 more)

### Community 4 - "my_application.cc"
Cohesion: 0.09
Nodes (22): fl_register_plugins(), main(), first_frame_cb(), my_application_activate(), my_application_class_init(), my_application_dispose(), my_application_init(), my_application_local_command_line() (+14 more)

### Community 5 - "Internationalizing Flutter Applications"
Cohesion: 0.10
Nodes (19): 1. Add Dependencies, 1. Define ARB Files, 2. Enable Code Generation, 2. Generate Localization Classes, 3. Consume Localized Strings, 3. Create Configuration File, 4. Configure the App Entry Point, Advanced Formatting (+11 more)

### Community 6 - "Implementing Routing and Deep Linking"
Cohesion: 0.11
Nodes (17): 1. Scaffold the Application, 2. Configure the Router, Contents, Core Concepts, Examples, High-Fidelity Shell Widget Implementation, If configuring for Android:, If configuring for iOS: (+9 more)

### Community 7 - "app_colors.dart"
Cohesion: 0.12
Nodes (16): accentBlue, AppColors, background, border, error, primary, primaryDark, primaryLight (+8 more)

### Community 8 - "AppDelegate"
Cohesion: 0.16
Nodes (10): Any, AppDelegate, Bool, AppDelegate, Bool, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate (+2 more)

### Community 9 - "Architecting Flutter Applications"
Cohesion: 0.15
Nodes (12): Architecting Flutter Applications, Architectural Layers, Contents, Data Layer, Data Layer: Service and Repository, Examples, Logic Layer (Domain - Optional), Project Structure (+4 more)

### Community 10 - "register_page.dart"
Cohesion: 0.15
Nodes (12): build, _confirmPasswordController, createState, dispose, _emailController, _formKey, _isLoading, _nameController (+4 more)

### Community 11 - "Implementing Flutter Integration Tests"
Cohesion: 0.17
Nodes (11): Contents, Examples, Execution and Profiling, Host Driver Script (`test_driver/integration_test.dart`), Implementing Flutter Integration Tests, Interactive Exploration via MCP, Performance Profiling Driver Script (`test_driver/perf_driver.dart`), Project Setup and Dependencies (+3 more)

### Community 12 - "Previewing Flutter Widgets"
Cohesion: 0.17
Nodes (11): Basic Preview, Contents, Creating a Widget Preview, Custom Preview with Runtime Transformation, Examples, Handling Limitations, Interacting with Previews, MultiPreview Implementation (+3 more)

### Community 13 - "login_page.dart"
Cohesion: 0.17
Nodes (11): build, createState, dispose, _emailController, _formKey, _isLoading, _passwordController, ../../core/widgets/app_text_field.dart (+3 more)

### Community 14 - "wWinMain"
Cohesion: 0.24
Nodes (9): wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), _In_, _In_opt_ (+1 more)

### Community 15 - "Summary"
Cohesion: 0.17
Nodes (11): 1. Design Token System (`lib/core/theme/`), 2. Routing Config (`lib/core/routing/`), 3. Shared Widgets (`lib/core/widgets/`), 4. Stub Pages (`lib/features/`), 5. Entry Point (`lib/main.dart`), 6. Dependency, Notes, Progress 2: Flutter App Bootstrap — Design System & Routing (+3 more)

### Community 16 - "Implementing Adaptive Layouts"
Cohesion: 0.18
Nodes (10): Adaptive Layout using LayoutBuilder, Constraining Width on Large Screens, Contents, Device and Orientation Behaviors, Examples, Implementing Adaptive Layouts, Space Measurement Guidelines, Widget Sizing and Constraints (+2 more)

### Community 17 - "app_routes.dart"
Cohesion: 0.18
Nodes (10): AppRoutes, home, homePath, login, loginPath, register, registerPath, splash (+2 more)

### Community 18 - "app_spacing.dart"
Cohesion: 0.18
Nodes (10): AppRadius, AppSpacing, full, lg, md, sm, xl, xs (+2 more)

### Community 19 - "app_text_styles.dart"
Cohesion: 0.18
Nodes (10): AppTextStyles, body, button, caption, h1, h2, label, link (+2 more)

### Community 20 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 21 - "Writing Flutter Widget Tests"
Cohesion: 0.20
Nodes (9): Contents, Core Components, Examples, High-Fidelity Widget Test Implementation, Interaction & State Management, Setup & Configuration, Task Progress, Workflow: Implementing a Widget Test (+1 more)

### Community 22 - "Resolving Flutter Layout Errors"
Cohesion: 0.20
Nodes (9): Constraint Violation Diagnostics, Contents, Examples, Fixing RenderFlex Overflow, Fixing Unbounded Height (ListView in Column), Fixing Unbounded Width (TextField in Row), Layout Error Resolution Workflow, Resolving Flutter Layout Errors (+1 more)

### Community 23 - "Serializing JSON Manually in Flutter"
Cohesion: 0.20
Nodes (9): Background Parsing (Large Payload), Contents, Core Guidelines, Examples, High-Fidelity Model Implementation, Serializing JSON Manually in Flutter, Synchronous Parsing (Small Payload), Workflow: Fetching and Parsing JSON (+1 more)

### Community 24 - "Implementing Flutter Networking"
Cohesion: 0.22
Nodes (8): Background Parsing, Configuration & Permissions, Contents, Examples, High-Fidelity Implementation: Fetching and Parsing in the Background, Implementing Flutter Networking, Request Execution & Response Handling, Workflow: Executing Network Operations

### Community 25 - "splash_page.dart"
Cohesion: 0.28
Nodes (7): build, build, createState, ../../core/routing/app_routes.dart, ../../core/theme/app_colors.dart, ../../core/theme/app_spacing.dart, ../../core/theme/app_text_styles.dart

### Community 26 - "app_router.dart"
Cohesion: 0.25
Nodes (7): appRouter, app_routes.dart, ../../features/auth/login_page.dart, ../../features/auth/register_page.dart, ../../features/home/home_page.dart, ../../features/splash/splash_page.dart, package:go_router/go_router.dart

### Community 27 - "LoginPage"
Cohesion: 0.32
Nodes (8): LoginPage, _LoginPageState, RegisterPage, _RegisterPageState, SplashPage, _SplashPageState, State, StatefulWidget

### Community 28 - "GeneratedPluginRegistrant"
Cohesion: 0.47
Nodes (4): GeneratedPluginRegistrant, String, FlutterEngine, Keep

### Community 29 - "package:flutter/material.dart"
Cohesion: 0.33
Nodes (5): app_colors.dart, AppTheme, app_spacing.dart, app_text_styles.dart, package:flutter/material.dart

### Community 30 - "handle_new_rx_page"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 31 - "widget_test.dart"
Cohesion: 0.50
Nodes (3): main, package:app/main.dart, package:flutter_test/flutter_test.dart

### Community 34 - "_onLogin"
Cohesion: 0.67
Nodes (3): _onLogin, _onRegister, AppRoutes.home

## Knowledge Gaps
- **237 isolated node(s):** `$schema`, `plugin`, `@opencode-ai/plugin`, `flutter_export_environment.sh script`, `+registerWithRegistry` (+232 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FlutterWindow` connect `Win32Window` to `GeneratedPluginRegistrant`?**
  _High betweenness centrality (0.027) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `MessageHandler` (e.g. with `Destroy` and `GetClientArea`) actually correct?**
  _`MessageHandler` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `$schema`, `plugin`, `@opencode-ai/plugin` to the rest of the system?**
  _238 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.0597567424643046 - nodes in this community are weakly interconnected._
- **Should `ML Prak — Infra & Setup Requirements` be split into smaller, more focused modules?**
  _Cohesion score 0.0425531914893617 - nodes in this community are weakly interconnected._
- **Should `app_text_field.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06628787878787878 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant` be split into smaller, more focused modules?**
  _Cohesion score 0.07661290322580645 - nodes in this community are weakly interconnected._