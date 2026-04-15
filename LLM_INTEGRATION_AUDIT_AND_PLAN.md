# LLM Integration Audit and Plan

## Executive Summary

PawSense already had a strong base architecture where computer vision (CV) is the primary evidence source and LLM output is intended to be assistive. The audit confirmed this direction is mostly intact, but several implementation gaps were reducing reliability and traceability:

- Step 2 could overwrite an already-good pre-scan symptom prior.
- Fallback triage condition labels were not always constrained to camera-detectable classes.
- Raw intake/prior payloads were not persisted for later audit/replay.
- There were no dedicated unit tests validating deterministic LLM fallback behavior.

This iteration implements the highest-priority corrections for those gaps and documents remaining risks and next actions.

## Current Status

### 1) Verified Current Assessment Flow

- Step 1 collects owner-observed behavior signals.
- Pre-scan chat step ("Skin Check Chat") performs dynamic questioning, free-text capture, readiness gating, and symptom prior refresh.
- Step 2 handles imaging and detection, and now respects existing pre-scan priors.
- Step 3 performs CV + prior + rule fusion, generates guidance, and persists assessment telemetry.

### 2) Verified LLM Roles in Current Code

- Dynamic next-question generation (chat sequencing).
- Structured symptom prior generation (symptom-informed ranking only).
- Recommendation narrative generation (grounded and safety-constrained).
- Deterministic fallback and retry chain logic when LLM is unavailable.

### 3) Requested Status Artifact Check

- `PAWSENSE_CURRENT_STATUS.md` was requested in the architecture directive, but it does not exist in the repository at the time of this audit.

## Audit Classification (Correct / Partial / Incorrect / Needed)

### Correct

- CV remains the primary evidence stream in final ranking.
- LLM has schema checks and deterministic fallback behavior.
- Safety language constraints are present (no diagnosis claims in prompts/fallbacks).
- Red-flag escalation signal is incorporated downstream.

### Partial

- Symptom intake is structured and improving, but still misses some richer owner-history dimensions (e.g., full environmental/lifestyle granularity).
- Fusion is explicit and weighted, but calibration is still heuristic rather than validated against a benchmark set.
- Telemetry exists, but long-term governance/reporting conventions are not yet standardized.

### Incorrect (fixed in this pass)

- Step 2 could regenerate and overwrite symptom priors from pre-scan chat.
- Fallback triage labels could drift from camera-detectable classes.
- Persisted assessment records did not include enough raw payload traceability.

### Needed

- Add benchmark-based fusion calibration and threshold tuning.
- Add end-to-end scenario tests for disagreement and escalation paths.
- Improve README/developer docs for LLM architecture and environment setup.

## P0 Changes Implemented In This Iteration

### A) Prior Source Reconciliation

- Step 2 now reuses existing prior when available instead of overwriting it.
- Added explicit telemetry source tags to distinguish pre-scan prior reuse vs step-two generation.

Files:
- `lib/core/widgets/user/assessment/assessment_step_two.dart`
- `lib/core/widgets/user/assessment/assessment_step_pretriage.dart`

### B) Condition-Class Constraint Hardening

- Added camera-detectable condition constraints through triage generation and fallback.
- Added normalization/alias handling so fallback/LLM conditions map cleanly to detectable labels.
- Added post-processing constraint guard to ensure `top_conditions` remain within allowed classes.

Files:
- `lib/core/services/ai/groq_orchestration_service.dart`
- `lib/core/services/ai/rule_based_fallback_service.dart`

### C) Traceability Persistence

- Extended assessment result model with optional payload snapshots:
  - clinical intake snapshot
  - triage prior payload
  - triage telemetry payload
  - recommendation payload
  - recommendation telemetry payload
- Populated these fields when creating assessment records.

Files:
- `lib/core/models/user/assessment_result_model.dart`
- `lib/core/widgets/user/assessment/assessment_step_three.dart`

### D) Test Coverage Added

- Added deterministic-path tests for:
  - guided chat fallback schema
  - structured symptom prior fallback using camera labels only
  - triage fallback constrained to allowed labels

Files:
- `test/groq_orchestration_service_test.dart`

Validation:
- New test file passes (`runTests`: 5 passed, 0 failed).

## Risks (Current Residual)

1. Fusion coefficients are still heuristic.
- Risk: ranking sensitivity may vary across pet subgroups and image quality levels.
- Mitigation: introduce validation dataset and tune weights/thresholds by measured metrics.

2. Intake breadth is still moderate.
- Risk: some clinically important owner-history variables are not captured yet.
- Mitigation: expand question catalog with targeted fields and keep dynamic sequencing.

3. Client-only orchestration.
- Risk: policy/telemetry controls can vary by app version and are harder to centrally enforce.
- Mitigation: move critical guardrails and logging schema checks server-side over time.

## Plan by Priority

### P0 (done now)

- Reconcile prior generation ownership between pre-scan chat and step two.
- Constrain triage outputs to camera-detectable classes.
- Persist raw LLM-related payloads for auditability.
- Add deterministic LLM integration unit tests.

### P1 (next)

- Expand structured intake dimensions (environment, contagion context, behavior/systemic signals).
- Add end-to-end tests for disagreement-flag and red-flag escalation behavior.
- Add explicit README section for LLM architecture, prompts, safety contract, and failover behavior.

### P2 (later)

- Introduce benchmark-guided calibration framework for fusion and confidence thresholds.
- Add lightweight quality scoring loop (image quality and confidence reliability) for adaptive questioning depth.
- Add server-side telemetry aggregation and governance dashboard.

## Files Likely To Change Next

- `lib/core/widgets/user/assessment/assessment_step_pretriage.dart`
- `lib/core/widgets/user/assessment/assessment_step_three.dart`
- `lib/core/services/ai/groq_orchestration_service.dart`
- `lib/core/services/ai/rule_based_fallback_service.dart`
- `test/groq_orchestration_service_test.dart`
- `README.md`

## Open Questions / Assumptions

1. Should step-two triage generation be completely disabled once pre-scan structured prior exists, or retained as a fallback-only path (current implementation = fallback-only behavior)?
2. Is the target thesis evaluation focused on top-1 condition accuracy, top-k recall, safety sensitivity, or a weighted composite?
3. Should all LLM prompts/schemas be frozen as versioned artifacts for reproducibility in thesis defense?
4. Should traceability payloads be mirrored to a separate analytics collection for offline evaluation, or remain embedded in assessment records only?

## Notes

- Existing analyzer infos unrelated to this P0 scope remain in some files (e.g., deprecation infos in `assessment_step_two.dart`, unused helper sections in step three).
- These are non-blocking for the implemented LLM integration corrections and can be cleaned in a separate maintenance pass.
