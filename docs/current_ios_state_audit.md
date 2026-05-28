# OneDone iOS Current State Audit

Date: 2026-05-28
Repository: `onedone-ios`
Scope: current implementation snapshot for documentation sync (no code changes).

## 1. App flow and routing

### Current routing model
- Root flow is driven by `AppState.phase` in `OneDone/App/AppFlow.swift`.
- Supported phases: `auth`, `welcome`, `onboarding`, `starterIntro`, `access`, `accessStateLoading`, `accessStateError`, `main`.
- Remote bootstrap runs once via `bootstrapAppIfNeeded()` from `.task` in `AppFlow`.

### Auth/welcome/onboarding/starter/access/main transitions
- `auth`: email/password sign up and login (`AuthView` + `AppState.signUp/logIn`).
- `welcome`: intro hero screen with CTA to onboarding.
- `onboarding`: 3-step flow, final step calls backend `complete-onboarding` in remote mode.
- `starterIntro`: post-onboarding intro; continues into main app.
- `access`: explicit access-state screen (status + actions).
- `main`: custom tab shell with Home, Templates, My Tasks, Settings.

### Bottom navigation and Task button
- Main shell uses `TabView(selection: $appState.selectedTab)` with native tab bar hidden.
- One custom bottom bar is rendered via `.safeAreaInset(edge: .bottom)`.
- Center Task button opens `NewTaskView` in a sheet (`TaskComposerSheet`) with explicit close control.
- Custom bar is hidden while task composer is shown and while keyboard is visible (`shouldShowCustomBottomBar`).

Files:
- `OneDone/App/AppFlow.swift`
- `OneDone/App/AppState.swift`
- `OneDone/OneDoneApp.swift`

## 2. Visual system (current)

### Theme/colors/background
- Warm off-white base with radial green/orange accents: `ODWarmRadialBackground`.
- Screen background is applied through `.oneDoneScreen()` extension.
- Non-material surface palette is defined in `ODColor` (`surfacePanel`, `surfaceField`, `surfaceBanner`, `surfaceNav`, etc.).

### Surface/card system
- Shared card primitive: `GlassCard` with style variants (`default`, `strong`, `muted`, `warning`, `listRow`).
- Current direction is performance-safe, non-material surfaces (no heavy per-row blur/material).
- `ODCard` wraps `GlassCard` for most screens.

### Typography and spacing tokens
- `OneDoneStyle` defines semantic typography (`screenTitleFont`, `heroTitleFont`, `cardHeadlineFont`, `sectionLabelFont`, etc.).
- Shared spacing/radius/shadow constants are centralized in `OneDoneStyle`.

### Controls
- Buttons: `ODPrimaryButton`, `ODSecondaryButton`.
- Inputs: `ODTextField`; multiline entry uses `TextEditor` with custom warm surface styling in screens.
- Badges: `ODStatusBadge` with `.glass` and `.listRow` styles.
- Loading: `ODLoadingStateCard` reusable centered loading block.
- Banners: `ODInfoBanner`, `ErrorBanner`.

Files:
- `OneDone/Theme/OneDoneColors.swift`
- `OneDone/Theme/OneDoneStyle.swift`
- `OneDone/Components/GlassCard.swift`
- `OneDone/Components/ODCard.swift`
- `OneDone/Components/ODPrimaryButton.swift`
- `OneDone/Components/ODSecondaryButton.swift`
- `OneDone/Components/ODTextField.swift`
- `OneDone/Components/ODStatusBadge.swift`
- `OneDone/Components/ODLoadingStateCard.swift`
- `OneDone/Components/ODInfoBanner.swift`
- `OneDone/Components/ErrorBanner.swift`
- `OneDone/Components/ElevatedTaskTabButton.swift`

## 3. Main screens snapshot

### Auth
- Implemented behavior: sign up, login, error/info messaging, session-aware email prefill.
- UI notes: hero + illustration + strong card form + calm CTA stack.
- Known limitations: email/password only (no Sign in with Apple in current implementation).
- Files: `OneDone/Screens/AuthView.swift`, `OneDone/App/AppState.swift`, `OneDone/Services/Auth/SupabaseAuthService.swift`.

### Welcome
- Implemented behavior: static intro with “Get Started”.
- UI notes: hero intro card and feature pills.
- Known limitations: informational only.
- Files: `OneDone/Screens/WelcomeView.swift`.

### Onboarding
- Implemented behavior: paged onboarding with back/next; final step triggers completion flow.
- UI notes: progress dots, one primary next action, submission state.
- Known limitations: copy is static and text-first.
- Files: `OneDone/Screens/OnboardingView.swift`, `OneDone/App/AppState.swift`.

### Starter Intro
- Implemented behavior: starter-capability intro, continue to main.
- UI notes: checklist-style feature rows and one primary CTA.
- Known limitations: optional DEBUG preview notice.
- Files: `OneDone/Screens/StarterAccessIntroView.swift`.

### Home
- Implemented behavior: overview hub, shortcut cards route into New Task/template prefill; no direct large task input.
- UI notes: greeting, access pill row, illustration card, quick actions, next-up card.
- Known limitations: notification bell is visual only.
- Files: `OneDone/Screens/HomeView.swift`.

### Templates
- Implemented behavior: template catalog list; tap opens New Task if creation allowed, else gate.
- UI notes: repeated lightweight row cards and non-material icon orbs.
- Known limitations: templates are static app-side definitions.
- Files: `OneDone/Screens/TemplatesView.swift`.

### New Task
- Implemented behavior: prompt entry, analyze submit, retry, access gating, routes to clarification/result.
- UI notes: text-first card, large editor, metadata chips, centered Analyze CTA, loading card while submitting.
- Known limitations: attachments/OCR unavailable (text-only flow).
- Files: `OneDone/Screens/NewTaskView.swift`, `OneDone/App/AppState.swift`.

### Clarification
- Implemented behavior: option selection or manual answer, continue, skip-for-now path.
- UI notes: question card + selectable option rows + centered actions.
- Known limitations: split-task preview only informational.
- Files: `OneDone/Screens/ClarificationView.swift`, `OneDone/App/AppState.swift`.

### Task Result
- Implemented behavior: next-step summary, checklist, Draft Reply and Reminder actions, save/open actions.
- UI notes: dominant next-step card, checklist rows, balanced primary actions.
- Known limitations: checklist toggles are local-only (explicit TODO notes persistence API dependency).
- Files: `OneDone/Screens/TaskResultView.swift`, `OneDone/Components/ChecklistRow.swift`.

### My Tasks
- Implemented behavior: remote-aware list loading, filtering, pull-to-refresh, retry, navigation to detail.
- UI notes: compact filter chips, lightweight list rows, compact non-wrapping status badges.
- Known limitations: relies on backend list quality for metadata density.
- Files: `OneDone/Screens/MyTasksView.swift`, `OneDone/Components/TaskCard.swift`.

### Task Detail
- Implemented behavior: remote detail refresh, checklist/timeline/output/reply/reminder sections, reminder actions.
- UI notes: narrative card stack, compact pills, centered reminder action controls.
- Known limitations: checklist toggles are local-only; timeline renders top 3 entries.
- Files: `OneDone/Screens/TaskDetailView.swift`, `OneDone/App/AppState.swift`.

### Draft Reply
- Implemented behavior: copy, regenerate, mark sent sync, follow-up reminder actions.
- UI notes: content-first draft composer, compact “Copy” near text, calm “Did you send it?” flow.
- Known limitations: subject/body are client-side editable only; regenerate depends on backend availability.
- Files: `OneDone/Screens/DraftReplyView.swift`, `OneDone/App/AppState.swift`.

### Reminder surfaces
- Implemented behavior: task-detail reminder scheduling/reschedule/snooze/cancel and draft-reply follow-up reminders.
- UI notes: local-first reminder actions with user-safe sync feedback banners.
- Known limitations: remote reminder sync depends on deployed edge functions and schema alignment.
- Files: `OneDone/Screens/TaskDetailView.swift`, `OneDone/Screens/DraftReplyView.swift`, `OneDone/App/AppState.swift`.

### Access
- Implemented behavior: access status and capability display, trial/restore entry points when locked.
- UI notes: calm locked-state messaging and centered access actions.
- Known limitations: DEBUG-only mock access switcher appears in debug runtime.
- Files: `OneDone/Screens/AccessView.swift`, `OneDone/App/AppState.swift`.

### Subscription Gate
- Implemented behavior: start trial, restore purchases, terms/privacy placeholder actions, feedback state.
- UI notes: gate status card + benefits + centered CTAs.
- Known limitations: terms/privacy currently display in-app informational feedback instead of opening full policy pages.
- Files: `OneDone/Screens/SubscriptionGateView.swift`, `OneDone/Services/API/Remote/RemoteSubscriptionService.swift`.

### Settings
- Implemented behavior: account info, logout (remote mode), preferences, access summary, privacy/legal rows, non-active data/account guidance.
- UI notes: row-card rhythm with calm static rows for non-implemented destructive operations.
- Known limitations: terms/privacy links point users to subscription screen; delete actions are informational only.
- Files: `OneDone/Screens/SettingsView.swift`.

## 4. Task flow (end-to-end)

### Flow chain
- Entry: `NewTaskView` from center Task button (sheet), Home shortcuts, or Templates.
- Analyze call: `AppState.analyzeNewTask(...)` sends `AnalyzeTaskRequest` with `Idempotency-Key` in remote mode.
- Outcomes:
  - clarification -> `ClarificationView`
  - task analysis -> `TaskResultView`
  - split preview -> informational banner only
- Clarification resolution: `AppState.resolveClarification(...)`.
- Task creation model: backend returns `task_id`; no pre-creation local backend-id task before response.

### Checklist and reply/reminder entry
- Task Result checklist: local toggle only.
- Task Detail checklist: local toggle only.
- Draft Reply action path remains linked to saved task.
- Reminder action path remains linked via `taskID` and local-notification-first sync.

Files:
- `OneDone/Screens/NewTaskView.swift`
- `OneDone/Screens/ClarificationView.swift`
- `OneDone/Screens/TaskResultView.swift`
- `OneDone/Screens/TaskDetailView.swift`
- `OneDone/App/AppState.swift`
- `OneDone/Services/API/Remote/RemoteTaskService.swift`

## 5. My Tasks and Task Detail details

### List loading and filters
- My Tasks loads remotely once per entry (`hasTriggeredInitialRemoteLoad`) and supports pull-to-refresh.
- Filter semantics are unchanged from enum `MyTasksFilter`.
- Sorting prioritizes status priority, then reminder/due date, then recency.

### Status badge and row rendering
- Repeated rows use `TaskCard(style: .listRow, badgeStyle: .listRow)` to keep rows compact and performant.
- Badges are fixed-size capsule labels and designed to stay single-line.

### Performance-related list/detail implementation
- `LazyVStack` is used for populated task rows.
- Static date formatters in My Tasks and Task Detail avoid per-render allocations.
- Task Detail timeline compact view is computed once per section render (`compactTimeline`).

### Checklist behavior in detail
- Task Detail checklist row toggles are local in `@State checkedChecklistIndexes`; no backend persistence.

Files:
- `OneDone/Screens/MyTasksView.swift`
- `OneDone/Screens/TaskDetailView.swift`
- `OneDone/Components/TaskCard.swift`
- `OneDone/Components/ODStatusBadge.swift`
- `OneDone/Models/MockTaskModels.swift`

## 6. Reminder flow snapshot

### Local-notification-first sequence
- Schedule path:
  - `LocalNotificationScheduler.scheduleReminder(...)` first.
  - If local schedule succeeds, app updates task reminder state and then attempts backend sync.
- Cancel/snooze paths also preserve local-first behavior.

### Backend sync
- Sync endpoints used: `reminder-create`, `reminder-update`, `reminder-cancel`, `reminder-snooze`, and read `get-reminders`.
- `ios_notification_id` is passed in create/update/snooze request payloads.
- Fetch reminders failure falls back to empty reminder list during detail refresh (non-blocking).

### User-facing copy and diagnostics
- User-visible reminder warnings are sanitized to non-technical wording.
- DEBUG logs include safe endpoint/status/backend-code diagnostics (no token logging).

### Schema/contract dependency notes
- Remote reminder read/write assumes backend reminder records with `reminder_id`, `task_id`, `remind_at`, `ios_notification_id`, `status`.
- If schema/function payload shape drifts, UI remains operational locally but remote sync/read may degrade.

Files:
- `OneDone/App/AppState.swift`
- `OneDone/Services/API/Remote/RemoteReminderService.swift`
- `OneDone/Services/API/ReminderServiceProtocol.swift`
- `OneDone/Services/LocalNotificationScheduler.swift`
- `OneDone/Models/API/APIContractModels.swift`

## 7. Subscription and access snapshot

### Access model in app state
- App uses backend-driven `APIAccessState` and routes according to snapshot state.
- Locked states can still enter main app in limited mode with creation disabled and gate prompts.

### Subscription UI vs real logic
- UI surfaces: `SubscriptionGateView`, `AccessView`, Home/MyTasks/NewTask gate entry points.
- Real purchase/restore logic: `RemoteSubscriptionService` via StoreKit 2 product purchase + backend `validate-subscription` and `restore-purchases` sync.
- In mock/dev runtime, fallback mock transitions still exist for preview/development paths.

### What is UI-only
- Terms/Privacy actions currently show informational in-app messages (not full legal page navigation).
- Some access explanatory rows are descriptive only.

Files:
- `OneDone/Screens/SubscriptionGateView.swift`
- `OneDone/Screens/AccessView.swift`
- `OneDone/App/AppState.swift`
- `OneDone/Services/API/Remote/RemoteSubscriptionService.swift`
- `OneDone/Services/API/SubscriptionServiceProtocol.swift`

## 8. Performance-related changes currently present

- My Tasks rendering changed to `LazyVStack` for populated lists.
- Filtered/sorted task list is computed once per render (`let visibleTasks = filteredAndSortedTasks`) and reused.
- Shared static `DateFormatter` instances used in My Tasks and Task Detail.
- Task Detail timeline sorting reused via helper instead of repeated inline sorts.
- Lightweight non-material row style (`GlassCardStyle.listRow`, `ODStatusBadge.Style.listRow`) used for repeated rows.
- Root duplicate full-screen background overdraw was reduced by relying on per-screen `.oneDoneScreen()`.

Files:
- `OneDone/Screens/MyTasksView.swift`
- `OneDone/Screens/TaskDetailView.swift`
- `OneDone/Components/GlassCard.swift`
- `OneDone/Components/TaskCard.swift`
- `OneDone/Components/ODStatusBadge.swift`
- `OneDone/App/AppFlow.swift`
- `OneDone/Theme/OneDoneColors.swift`

### Remaining performance risks (known)
- Some screens still use multiple layered overlays/shadows per card, which can add cost on older devices.
- Large `TextEditor` and multiple rich cards in one scroll can still be memory-sensitive on constrained devices.
- Remote detail refresh performs multiple concurrent fetches; error-tolerant but potentially bursty over weak networks.

## 9. Known limitations and deferred scope

- Attachments/OCR are not implemented (text-first flow only).
- Checklist completion persistence is not implemented (local-only toggles in Result/Detail).
- Multi-task split confirmation flow is not implemented; split response is informational only.
- Pending-questions advanced flow (beyond current clarification loop) is not implemented as a separate feature.
- Split review workflow is not implemented as a dedicated screen/flow.
- Terms of Use / Privacy Policy full in-app document surfaces are not implemented.
- Sign in with Apple is not implemented in current auth flow.

Files reflecting current limitations:
- `OneDone/Screens/NewTaskView.swift`
- `OneDone/Screens/TaskResultView.swift`
- `OneDone/Screens/TaskDetailView.swift`
- `OneDone/Screens/SubscriptionGateView.swift`
- `OneDone/Screens/SettingsView.swift`
- `OneDone/App/AppState.swift`

---
Notes:
- This audit reflects current source code behavior and UI wiring in this repository branch.
- No backend or StoreKit server behavior is asserted beyond what the iOS client currently calls and handles.
