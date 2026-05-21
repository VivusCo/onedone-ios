# OneDone iOS — Codex Instructions

You are working on the native iOS app only.

Documentation workflow (source of truth is local `/docs` copies):
- Read relevant docs before implementation work.
- For iOS product/UI/flow work, read `docs/01_ios_app_spec_v6.md`.
- For MVP scope and build order, read `docs/03_mvp_implementation_plan_v2.md`.
- For backend integration/API work, read `docs/04_api_contract.md`.
- For QA/review tasks, read `docs/06_test_cases.md`.
- If a prompt conflicts with docs, stop and ask.

Tech stack:
- SwiftUI
- iOS 17+
- StoreKit 2
- Supabase client or URLSession API client
- UserNotifications

Product rules:
- OneDone is guided self-service, not an autonomous agent.
- MVP is text-first.
- Attachments are disabled / coming soon.
- 3-day Starter Access happens after onboarding.
- App Store 14-day trial happens after Starter Access.
- Task is created by backend via analyze-task.
- generate-reply requires task_id.

Do not:
- call OpenAI directly from iOS
- store API keys in the app
- write backend code
- implement autonomous external actions
- add new dependencies without asking
- change API contracts without updating docs

Definition of done:
- project builds in Xcode
- SwiftUI previews work where practical
- UI follows OneDone warm, calm style
- no secrets are committed
