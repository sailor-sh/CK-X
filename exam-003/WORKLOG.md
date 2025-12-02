# CKAD Exam 3 (ckad-003) — Work Log

Start: 2025-11-30
Owner: Orchestrator

Context
- Goal: Maintain a third CKAD exam under `facilitator/assets/exams/ckad/003` using adapted questions.
- Constraint: Single Kubernetes instance; use per-question namespace isolation.

Milestones
- [x] Scaffold ckad-003 assets (config, assessment, setup, validation, README)
- [x] Register lab in labs.json
- [ ] Author per-question setups for complex items (Q7, Q8, Q11, Q12, Q13, Q18)
- [ ] Dry-run a subset (Q1, Q2, Q3, Q7, Q18, Q19)
- [ ] Full pass and refine

Next Actions
- Implement Q1–Q3 validators and example setups
- Add Q7/Q8/Q18 setup seeds and validators
- Iterate assessment.json to point to added checks

Changelog
- 2025-12-01: Standardized compose/env usage; added tests; consolidated kubelingo samples.

