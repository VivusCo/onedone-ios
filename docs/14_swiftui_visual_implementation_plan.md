# OneDone SwiftUI Visual Redesign Implementation Plan

Status: Planning document only.
Scope: SwiftUI visual redesign implementation plan for the already approved modern glass direction.
Source-of-truth note: For visual direction conflicts, `docs/13_approved_visual_direction.md` overrides `docs/10_design_system_and_figma_brief.md`.

## 1. Current UI Architecture Summary

Current architecture is product-logic stable and should be preserved:
- App shell: `AppState` + `AppFlow` phase routing.
- Entry/runtime: `OneDoneApp` selects remote runtime by default, mock runtime for development/previews.
- Main nav: `TabView` with `Home`, `Templates`, `My Tasks`, `Settings`.
- Current design system baseline:
  - Theme tokens in `OneDone/Theme/OneDoneColors.swift` and `OneDone/Theme/OneDoneStyle.swift`.
  - Reusable components in `OneDone/Components/*` (`ODCard`, buttons, status badge, info banner, etc.).
  - Screens in `OneDone/Screens/*` already match MVP flows and remote runtime behavior.

Current UI strengths:
- Warm palette and calm layout foundation already exists.
- Componentized button/card/badge primitives are in place.
- Loading and error states exist across key screens.

Current UI gaps vs approved visual direction:
- No dedicated glass-surface token system yet.
- No radial accent background treatment yet.
- Tab shell does not yet provide elevated center `Task` action.
- Home still presents large direct input; approved direction requires Home as overview/launchpad and task creation from center `Task` button.
- Task Result checklist rows are not yet tappable checked/unchecked UI.
- Draft Reply copy action should be compact near text block, not visually dominant full-width CTA.
- My Tasks status labels should be explicitly hardened against wrapping/truncation edge cases.

## 2. Theme/Tokens To Add or Update

Update/extend semantic tokens in `OneDoneColors` + `OneDoneStyle` (without changing behavior logic):

Color tokens (semantic names, no purple/no neon):
- `backgroundWarm`
- `backgroundAccentRadialA`
- `backgroundAccentRadialB`
- `glassFillPrimary`
- `glassFillSecondary`
- `glassBorder`
- `glassShadow`
- `accentPrimaryDeepGreen`
- `accentWarmOrangeSoft` (small/sparse usage only)
- `textPrimary`
- `textSecondary`
- `textTertiary`
- `statusSuccess`
- `statusWarning`
- `statusNeutral`
- `statusLocked`

Style tokens:
- Glass blur/material presets (light and readable).
- Radius scale for cards/chips/buttons.
- Elevation/shadow presets for card layers and floating center tab button.
- Spacing scale normalization for compactness and consistency.
- Compact badge typography + padding values to prevent wrap.

Global surface guidance:
- Warm off-white base canvas.
- Soft radial accents behind major sections (subtle opacity).
- Translucent cards with subtle border and restrained shadow.
- Readability-first contrast checks on all glass layers.

## 3. Base Components To Add/Update

Create or refactor reusable visual components while preserving existing APIs where possible:

1. `GlassCard`
- Translucent material layer + subtle border + soft shadow.
- Variants: default, strong, muted, warning.
- Replace/adapt current `ODCard` internals or wrap `ODCard` for compatibility.

2. `PrimaryButton`
- Deep green primary CTA style.
- Consistent disabled/loading treatment.
- Centered CTA sizing rules for required screens.

3. `SecondaryButton`
- Glass/outlined secondary style.
- Clear hierarchy beneath primary CTA.

4. `Pill/StatusBadge`
- Compact non-wrapping status labels.
- Fixed horizontal padding strategy, min height, single-line text behavior.

5. `ElevatedTaskTabButton`
- Circular elevated center button in tab bar.
- Label fixed to `Task`.
- Entry point to New Task flow.

6. `IllustrationCard`
- Abstract, non-chart/non-robot decorative support card.
- Used on Home and key empty states where helpful.

7. `ChecklistRow`
- Tappable checked/unchecked visual row.
- Clear state icon and accessible touch target.

8. `TaskCard`
- Compact list card with robust truncation behavior.
- Status badge lock-in (no wrap).

9. `ErrorBanner`
- Unified calm error/warning/info banner style.
- Friendly copy; no raw JSON/debug leakage.

10. `ComingSoonBadge`
- Optional disabled badge pattern for attachments/features not available.

## 4. Screen-by-Screen Implementation Plan

### Auth
- Apply glass card hierarchy and radial background accents.
- Keep simple email/password stack, clear loading/error messaging.
- No auth logic changes.

### Onboarding
- Introduce calm glass step cards and refined progress indicators.
- Keep onboarding text/sequence unchanged.

### Starter Access Intro
- Use prominent calm headline + single centered CTA.
- Add subtle visual depth via glass hero card.

### Home
- Convert to overview/shortcut hub.
- Remove large direct input block from Home UI.
- Add greeting, access pill, abstract illustration card, quick shortcuts, optional `Next up` card.
- Keep creation entry through center `Task` button.

### Templates
- Apply consistent glass cards/chips.
- Preserve active vs locked behavior and text-first guidance.

### New Task
- Keep as main creation surface opened from center `Task` button.
- Text-first composition area + centered `Analyze Task` CTA.
- Keep attachments disabled/Coming soon or hidden per current behavior.

### Clarification
- Refine option rows as glass selectable rows.
- Keep one clear question and centered primary CTA.

### Task Result
- Highlight current next step with stronger visual focus.
- Implement tappable `ChecklistRow` checked/unchecked states.
- Keep action hierarchy (`Task Detail`, `Draft Reply`, `Reminder`) clean.

### My Tasks
- Strengthen compact scanability.
- Ensure status badge never wraps or breaks layout.
- Ensure long titles/next-step previews truncate safely.
- Preserve filter behavior and sorting logic.

### Task Detail
- Keep compact, readable sections:
  - Header
  - Status
  - Current next step
  - Checklist
  - Latest output
  - Optional reply draft
  - Reminder block
  - Compact timeline
- Improve section separation and readability, avoid visual overload.

### Draft Reply
- Make draft content block primary.
- Move copy action to compact nearby `Copy` control.
- Keep regenerate/tone/language and post-copy flow behavior unchanged.

### Reminder
- Calm compact scheduling controls.
- Centered key actions where required.
- Permission/error states remain friendly.

### Limited / Access
- Calm locked-state visuals with clear capability explanation.
- Preserve view existing tasks/details behavior.

### SubscriptionGate
- Glass gate card style with centered `Start 14-day trial` and `Restore Purchases`.
- Maintain no `Not now` bypass after Starter expiry.

### Settings
- Apply consistent card/list row styling.
- Keep account/access/runtime rows readable and compact.

## 5. Exact Files Likely To Modify

Theme:
- `OneDone/Theme/OneDoneColors.swift`
- `OneDone/Theme/OneDoneStyle.swift`

App shell/navigation visuals:
- `OneDone/App/AppFlow.swift`
- `OneDone/OneDoneApp.swift` (only if needed for global visual wrapper; no runtime-mode logic changes)

Components (existing + new files in `OneDone/Components/`):
- `ODCard.swift` (or adapter replacement)
- `ODPrimaryButton.swift`
- `ODSecondaryButton.swift`
- `ODStatusBadge.swift`
- `ODComingSoonBadge.swift`
- `ODInfoBanner.swift`
- New: `GlassCard.swift`
- New: `ElevatedTaskTabButton.swift`
- New: `IllustrationCard.swift`
- New: `ChecklistRow.swift`
- New: `TaskCard.swift` (if extracted from My Tasks)
- New: `ErrorBanner.swift` (or evolve `ODInfoBanner` safely)

Screens:
- `OneDone/Screens/AuthView.swift`
- `OneDone/Screens/OnboardingView.swift`
- `OneDone/Screens/StarterAccessIntroView.swift`
- `OneDone/Screens/HomeView.swift`
- `OneDone/Screens/TemplatesView.swift`
- `OneDone/Screens/NewTaskView.swift`
- `OneDone/Screens/ClarificationView.swift`
- `OneDone/Screens/TaskResultView.swift`
- `OneDone/Screens/MyTasksView.swift`
- `OneDone/Screens/TaskDetailView.swift`
- `OneDone/Screens/DraftReplyView.swift`
- `OneDone/Screens/AccessView.swift`
- `OneDone/Screens/SubscriptionGateView.swift`
- `OneDone/Screens/SettingsView.swift`

## 6. Risks and What Not To Touch

Must not touch in redesign:
- No backend/API contract changes.
- No auth/session behavior changes.
- No StoreKit purchase/validation flow changes.
- No remote service logic changes.
- No AppState access-routing decision changes.
- No new product features.

Risk points:
- Home visual change could accidentally alter creation flow. Mitigation: keep New Task entry explicit via center `Task` button and preserve existing gating checks.
- Tab redesign could disrupt navigation semantics. Mitigation: keep existing tab identities and selectedTab state; add only visual/interaction layer.
- Glass styling could reduce legibility. Mitigation: tokenized contrast checks and fallback stronger surfaces.
- Screen-by-screen component replacement could cause style drift. Mitigation: phase-first component rollout before heavy screen edits.

## 7. Recommended Implementation Phases

### UI-01 Theme/Tokens/Components
- Implement glass-aware color/style tokens.
- Add/update shared components (`GlassCard`, buttons, badge, error banner, illustration card).
- Preserve compatibility wrappers for current usage.

### UI-02 Tab Bar and Navigation CTA
- Implement elevated center `Task` tab action.
- Keep existing navigation state and logic unchanged.

### UI-03 Home/New Task
- Refactor Home to overview/shortcut structure.
- Ensure New Task remains primary composition surface from center button.

### UI-04 Task Result/Checklist
- Add interactive checklist row visuals in Task Result.
- Keep task/result data flow untouched.

### UI-05 My Tasks/Task Detail
- Compact task cards, stable status badges, safe truncation.
- Keep Task Detail compact sections and readability focus.

### UI-06 Draft Reply/Reminder
- Compact copy control near draft content.
- Keep reminder interaction UI calm and clear.

### UI-07 Limited/Subscription/Settings
- Align limited and gate visuals to approved glass direction.
- Keep lock/gate rules and CTA behavior unchanged.

### UI-08 Polish/Accessibility
- Tune spacing/contrast/dynamic type behavior.
- Verify no purple/neon, no unsupported feature signaling, no UX regressions.

## 8. Build/Test Checklist Per Phase

Apply this checklist at the end of each phase:
- Build passes on iPhone Simulator.
- No Swift logic changes outside visual scope.
- Existing remote runtime flows still route correctly.
- Mock previews still compile.
- No new secrets/config values committed.
- No unsupported attachment/OCR/autonomous actions surfaced.

Additional phase-specific checks:

UI-01:
- Token usage replaces ad-hoc colors where practical.
- Glass surfaces remain readable on warm background.

UI-02:
- Center `Task` button opens New Task reliably.
- Existing tab destinations remain intact.

UI-03:
- Home no longer depends on large direct input.
- Creation starts from center `Task` button.

UI-04:
- Checklist checked/unchecked visuals are tappable and clear.
- Result-to-detail path still works.

UI-05:
- My Tasks status labels remain single-line/non-breaking.
- Task Detail remains compact and not overloaded.

UI-06:
- Draft Reply `Copy` action is compact and near content.
- Post-copy flow remains coherent.

UI-07:
- Limited mode still allows viewing existing tasks/details.
- Creation actions remain locked in expired/blocked states.
- Gate has no `Not now` bypass.

UI-08:
- Readability and spacing validated across key device sizes.
- Friendly loading/empty/error states remain consistent.

---

Implementation guardrails reaffirmed:
- Documentation plan does not authorize product logic changes.
- Visual redesign must preserve existing MVP behavior and backend-driven access rules.
