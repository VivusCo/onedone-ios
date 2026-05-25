# OneDone Approved Visual Direction

## 1. Purpose and Status

This document records the visual direction approved by the product owner for OneDone MVP.

Status:
- Approved as the baseline for upcoming SwiftUI visual implementation.
- The `design-prototype/` files are a visual reference only.
- The prototype was created in React/Tailwind style for exploration; it is not production code and must not be ported directly.

How to use this doc:
- Product/design: source of truth for approved UI direction.
- iOS implementation: translate these principles into SwiftUI-native components and tokens.
- QA/review: verify that screen behavior and visual tone match approved direction.

## 2. Approved Visual Direction

Approved style foundation:
- Modern iOS-inspired glass interface.
- Warm off-white base background.
- Soft radial gradient accents.
- Translucent glass cards with blur, subtle borders, and soft shadows.
- Deep green primary accent for key actions.
- Small warm orange accent used sparingly for highlights.

Tone and feel targets:
- Calm.
- Practical.
- Trustworthy.
- Warm but adult.
- Simple and human.

Hard visual constraints:
- No purple.
- No neon.
- No heavy dashboard look.
- No chatbot/robot-heavy AI visuals.

Illustration guidance:
- Use abstract graphic illustration cards where needed to support mood/context.
- Do not use charts/graphs as default visual elements for core task flows.

## 3. Approved Navigation Structure

Core navigation decisions:
- Task creation lives in the elevated circular center button in the bottom tab bar.
- The center button label is `Task` (not `New`).
- Home is an overview/shortcut screen only.
- Home must not include a large direct task input block.
- New Task opens from the center `Task` button.

MVP behavior alignment:
- Guided self-service assistant flow, not a chat-first bot flow.
- Limited mode must still allow viewing existing tasks/details.
- Creation/generation remains locked in expired access states.

## 4. Approved Screen Behaviors

### Home

Required:
- Access pill at top.
- Warm greeting.
- Abstract illustration card.
- Quick shortcut cards.
- Small `Next up` card when available.

Behavior notes:
- Home is overview/launchpad, not full input composition.
- Primary creation entry is the bottom center `Task` button.

### New Task

Required:
- Text-first MVP framing note.
- Large task description area.
- `Analyze Task` CTA centered.

Behavior notes:
- Keep this screen focused on one input and one main action.
- No attachments/OCR as available actions.

### Clarification

Required:
- One clear backend-provided question.
- Option rows styled as glass rows.
- Primary and secondary CTAs centered.

Behavior notes:
- Clarification should reduce ambiguity quickly.
- Avoid dense explanatory text.

### Task Result

Required:
- Clear highlighted next step.
- Tappable checklist with checked/unchecked states.
- `Draft Reply` and `Reminder` actions.

Behavior notes:
- Checklist interaction should feel lightweight and readable.
- Keep action hierarchy explicit.

### My Tasks

Required:
- Compact filters.
- Status badges that must not wrap.
- Long titles and next-step text truncate safely without layout break.

Behavior notes:
- Prioritize scanability over dense metadata.
- Keep list cards visually compact.

### Task Detail

Required:
- Current next-step card.
- Timeline section.
- Checklist/progress section.
- Compact readable sections throughout.

Behavior notes:
- Use clear separation between sections.
- Preserve readable spacing and hierarchy.

### Draft Reply

Required:
- Reply text is the primary content block.
- Compact `Copy` action near the draft text.
- No oversized `Copy reply` CTA.

Behavior notes:
- This screen is content-first.
- Secondary actions should not overpower the draft content.

### Reminder (Create/Edit)

Required:
- Calm scheduling form layout.
- Centered `Save` and `Cancel` actions.

Behavior notes:
- Keep reminder setup minimal and direct.
- Preserve readability for date/time controls.

### Limited Mode

Required:
- Calm locked state treatment.
- Explain what remains available (view existing tasks/details).
- Centered `Start Trial` and `Restore` CTAs.

Behavior notes:
- Must communicate limits clearly without dark patterns.
- Creation/generation actions remain locked.

### Subscription Gate

Required:
- Modern, calm glass gate presentation.
- Centered `Start Trial` and `Restore` CTAs.
- No `Not now` bypass after Starter expiry.

Behavior notes:
- Keep subscription decision flow explicit and respectful.
- Do not imply unsupported subscription states/features.

## 5. Reusable UI Patterns

Approved shared patterns:
- App header with clear title hierarchy.
- Access pill for access-state visibility.
- Glass cards for main surfaces.
- Primary and secondary actions with consistent sizing/radius.
- Status badges with compact, non-wrapping labels.
- Checklist rows with clear checked/unchecked affordances.
- Timeline rows for task history.
- Draft reply content card with nearby compact utility action.
- Calm lock/gate cards for limited/subscription states.

CTA placement rule (explicit):
- Key CTAs are centered on:
  - New Task
  - Clarification
  - My Tasks Empty
  - Reminder
  - Limited Mode
  - Subscription Gate

## 6. Interaction and Copy Guidance

Interaction guidance:
- Keep one primary action visually obvious per screen.
- Use progressive disclosure instead of dense instructional blocks.
- Preserve strong legibility in glass layers through contrast and spacing.

Copy guidance:
- Keep copy simple, non-technical, and user-facing.
- Avoid repeated "AI analyzed..." phrasing.
- Avoid backend/service terminology in user UI.
- Keep lock/gate messaging clear, calm, and specific.

Approved product framing in UX:
- Guided self-service assistant, not a chatbot.
- Not an autonomous executor.

## 7. Implementation Guardrails

Non-negotiable guardrails:
- Do not change backend logic.
- Do not change auth/session logic.
- Do not change StoreKit logic.
- Do not change remote service behavior.
- Do not introduce unsupported product features.
- Do not make attachments/OCR appear available.
- Do not present autonomous cancellation/execution behavior as available.
- Keep mock/previews working as development fallback.
- Keep accessibility/readability as first-class requirements.

Scope reminders:
- Remote runtime is default for real app usage.
- Mock mode remains previews/development fallback only.

## 8. SwiftUI Handoff Notes

Translation guidance for implementation:
- Use the approved React/Tailwind prototype only as visual reference.
- Rebuild UI in SwiftUI-native architecture/components.
- Do not port utility classes or layout code directly.
- Define semantic design tokens in SwiftUI (color/type/spacing/radius) before final screen polishing.
- Implement glass surfaces with platform-appropriate material/blur treatment while preserving readability.
- Keep layout behavior aligned with approved screen interactions and access-state rules.

Out of scope for this visual direction document:
- Backend/API contract changes.
- Auth/session flow changes.
- Subscription business-logic changes.

## 9. Acceptance Checklist

Visual direction acceptance:
- [ ] Modern iOS-inspired glass style is present and consistent.
- [ ] Warm off-white base and soft radial accents are used correctly.
- [ ] Translucent cards use subtle blur, border, and shadow treatment.
- [ ] Deep green is the primary accent; warm orange is sparse.
- [ ] No purple, no neon, no heavy dashboard treatment.
- [ ] No chatbot/robot-heavy AI visual motifs.
- [ ] Abstract illustration cards are used where helpful.
- [ ] Charts/graphs are not default visual elements.

Navigation and behavior acceptance:
- [ ] Elevated center tab button labeled `Task` is the creation entry.
- [ ] Home is overview/shortcuts only (no large direct input block).
- [ ] New Task opens from center `Task` button.
- [ ] Task Result checklist supports checked/unchecked interaction.
- [ ] Draft Reply uses compact `Copy` action near reply text.
- [ ] My Tasks status badges do not wrap or break layout.
- [ ] Long task text truncates safely.
- [ ] Centered key CTAs are present on required screens.
- [ ] Limited mode keeps existing tasks/details viewable.
- [ ] Creation/generation remains locked in expired states.
- [ ] Subscription Gate has no `Not now` bypass after Starter expiry.

Scope and guardrail acceptance:
- [ ] Attachments/OCR are not presented as available.
- [ ] Autonomous external execution is not presented as available.
- [ ] Document is implementation guidance only and does not alter product logic.
