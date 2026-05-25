# OneDone iOS MVP / TestFlight Release Checklist

Purpose: this checklist documents the exact setup and manual validation steps before sharing OneDone as a working MVP/TestFlight prototype.

Scope assumptions (current implementation):
- Supabase Auth is used for user authentication.
- Remote backend runtime is the default for normal app usage.
- Mock mode is for SwiftUI previews and development fallback only.
- Backend access-state drives routing.
- iOS never calls OpenAI directly.
- StoreKit subscription access flow exists.
- Local StoreKit configuration exists for development testing.

## 1. Required App Configuration

Set these runtime values in a local unshared Xcode scheme (for example `OneDone Local`):
- `ONEDONE_SUPABASE_URL`
- `ONEDONE_SUPABASE_ANON_KEY`
- `ONEDONE_FUNCTIONS_BASE_URL`
- `ONEDONE_SUBSCRIPTION_PRODUCT_ID`

Rules:
- Supabase anon/public key is allowed in iOS client configuration.
- Supabase `service_role` key must never be used in iOS.
- OpenAI key must never be used in iOS.
- Shared Xcode scheme must remain value-free (no concrete env values committed).
- Concrete env values must live only in local unshared scheme(s).

## 2. Xcode / Scheme Setup

- Use shared `OneDone` scheme for team-safe project config.
- Use local unshared scheme for runtime env values (`OneDone Local` recommended).
- Confirm StoreKit config file exists and is linked:
  - `OneDone.storekit`
- Confirm StoreKit product ID in local config matches `ONEDONE_SUBSCRIPTION_PRODUCT_ID`.
- Transaction reset notes:
  - Clear local StoreKit transactions in Xcode test environment when repeating purchase tests.
  - If subscription linkage conflicts appear, reset both local StoreKit test state and backend test subscription records.
- Real device vs simulator:
  - Simulator is acceptable for most UI and API flow checks.
  - Real device is required before external sharing to validate signing, notifications, and production-like behavior.

## 3. Supabase Backend Deployment Checklist

Confirm these Edge Functions are deployed and reachable:
- [ ] `complete-onboarding`
- [ ] `get-access-state`
- [ ] `analyze-task`
- [ ] `answer-clarification`
- [ ] `generate-reply`
- [ ] `update-task-status`
- [ ] `message-marked-sent`
- [ ] `reminder-create`
- [ ] `reminder-update`
- [ ] `reminder-cancel`
- [ ] `reminder-snooze`
- [ ] `notification-triggered`
- [ ] `list-tasks`
- [ ] `get-task-detail`
- [ ] `get-task-outputs`
- [ ] `get-task-events`
- [ ] `get-checklist-items`
- [ ] `get-reminders`
- [ ] `validate-subscription`
- [ ] `restore-purchases`
- [ ] `feedback`
- [ ] `delete-task`
- [ ] `delete-all-data`
- [ ] `delete-account`

## 4. Supabase Database / Secrets Checklist

Database and auth:
- [ ] Hosted Supabase migrations applied.
- [ ] Supabase Auth configured and enabled.
- [ ] Email confirmation policy is intentionally selected for MVP testing (enabled or disabled by decision).
- [ ] RLS enabled on required tables.
- [ ] Authenticated user flow works end-to-end with RLS.

Required backend secrets (server-side only):
- [ ] `OPENAI_API_KEY`
- [ ] `OPENAI_MODEL`

Required tables exist and function:
- [ ] `profiles`
- [ ] `subscriptions`
- [ ] `subscription_events`
- [ ] `tasks`
- [ ] related task output/events/checklist/reminders tables

Security rules:
- Never place backend secrets in iOS app config.
- Never place `service_role` in iOS.
- Never place OpenAI key in iOS.

## 5. Auth Manual Test

- [ ] Sign up with email/password.
- [ ] Log in with valid credentials.
- [ ] Invalid login shows friendly error.
- [ ] Log out works and routes to auth.
- [ ] Relaunch app restores valid session.
- [ ] Expired session refreshes, or fails gracefully with login-required message.
- [ ] If email confirmation is enabled, confirmation behavior is correct and messaging is clear.

## 6. Access / Onboarding Manual Test

- [ ] New authenticated user receives `onboarding_required` from backend.
- [ ] Onboarding completion calls `complete-onboarding`.
- [ ] Starter Access becomes active from backend state.
- [ ] Starter Access intro appears after onboarding completion.
- [ ] `starter_active` routes to Home.
- [ ] `starter_expired` / `trial_expired` / `subscription_expired` route to gate/limited mode.
- [ ] No classic "Not now" bypass after Starter expiry.
- [ ] Existing tasks/details remain viewable in limited mode.
- [ ] Creation actions are locked in expired/blocked states.

## 7. AI Task Flow Manual Test

Core analyze flow:
- [ ] Submit New Task text.
- [ ] `analyze-task` is called with Authorization and Idempotency-Key.
- [ ] App does not create local task before backend `task_id`.
- [ ] Clarification response routes to Clarification UI.
- [ ] `answer-clarification` returns result and flow continues.
- [ ] `task_analysis` routes to result/detail flow.
- [ ] Retryable AI errors show retry-friendly message.
- [ ] Rate-limited errors show friendly rate-limit message.
- [ ] Access/paywall errors show Subscription Gate.

Task list/detail checks in remote runtime:
- [ ] Logged-in remote users do not see seeded mock tasks by default.
- [ ] My Tasks loads backend list data.
- [ ] Filters work or degrade safely without breaking flow.
- [ ] Empty state is clear.
- [ ] Error/retry state is friendly.
- [ ] Task Detail loads detail/outputs/events/checklist/reminders.
- [ ] If refresh fails with existing data, fallback is labeled softly (not hard-fail only).

## 8. Draft Reply / Sent Manual Test

- [ ] `generate-reply` is called with backend `task_id`.
- [ ] No orphan reply generation without task id.
- [ ] Draft reply content appears.
- [ ] Copy action works.
- [ ] "Did you send it?" prompt appears.
- [ ] "Yes, I sent it" calls `message-marked-sent`.
- [ ] Task status moves toward `waiting_for_reply`.
- [ ] My Tasks and Task Detail refresh after sent-state sync.

## 9. Reminder Manual Test

- [ ] Reminder can be created from task flow.
- [ ] Notification permission request/denied flow is user-friendly.
- [ ] Local notification scheduling happens first.
- [ ] Backend reminder sync occurs only after local scheduling succeeds.
- [ ] `ios_notification_id` is included in backend sync payload.
- [ ] Cancel reminder sync works.
- [ ] Snooze reminder sync works (if endpoint available).
- [ ] Friendly error appears if notifications are denied/scheduling fails.

## 10. StoreKit / Subscription Manual Test

Preconditions:
- [ ] Test user is in `starter_expired` (or another locked state) on backend.
- [ ] `ONEDONE_SUBSCRIPTION_PRODUCT_ID` is configured in local unshared scheme.

Purchase/restore flow:
- [ ] Access gate opens in locked state.
- [ ] "Start 14-day trial" opens StoreKit purchase flow.
- [ ] Verified transaction triggers `validate-subscription`.
- [ ] `validate-subscription` success (`HTTP 200` and `ok=true`) is handled correctly.
- [ ] Access state refreshes from `get-access-state` after validation.
- [ ] Restore Purchases calls `restore-purchases` and refreshes access state.
- [ ] Cancelled/pending/unverified purchase states show friendly messages.

Data validation checks:
- [ ] `subscriptions` and `subscription_events` records are created/updated as expected.

StoreKit test reset/conflict note:
- The same StoreKit test transaction cannot be reliably linked to a different OneDone user without reset.
- If conflict happens, reset local StoreKit test state and clear related backend test subscription records.

## 11. Safety / Security Checks

- [ ] No `service_role` key in iOS code/config.
- [ ] No OpenAI key in iOS code/config.
- [ ] No raw tokens/passwords/transaction IDs/raw transaction payloads in logs.
- [ ] No raw backend/debug JSON shown to users.
- [ ] `usage_events` (or equivalent telemetry) does not store raw user private content.
- [ ] Shared Xcode scheme contains no concrete env values.

## 12. Known Limitations / Deferred Items

- Attachments/OCR:
  - Attachments are disabled/Coming soon.
  - OCR/PDF upload is not included in MVP.
- Auth roadmap:
  - Sign in with Apple may still be required before broader/public release.
- Subscription backend roadmap:
  - App Store Server Notifications integration is deferred.
  - Full Apple Server API validation path is deferred to backend roadmap.
- Platform setup:
  - Production deep links and email confirmation production setup may still be needed.
- Product boundaries:
  - No autonomous external actions.
- StoreKit scope:
  - `OneDone.storekit` is for local development/testing.
  - Real TestFlight/App Store validation still requires proper App Store Connect product setup.

## 13. Final Go / No-Go Checklist

Ship only when all are true:
- [ ] iOS app builds successfully.
- [ ] Real device run succeeds with proper signing.
- [ ] Required backend functions are deployed.
- [ ] Hosted database migrations are applied.
- [ ] Required backend secrets are configured server-side.
- [ ] StoreKit config/product setup is correct for test path.
- [ ] Auth flow works (signup/login/logout/session restore).
- [ ] Access/onboarding routing works from backend states.
- [ ] Core AI task flow works end-to-end.
- [ ] Task list/detail remote loading works.
- [ ] Subscription gate + purchase/restore flow works.
- [ ] No secrets are committed to iOS repo.
