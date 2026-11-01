---
id: T000
title: <short title>
feature: <feature>
role: rtl-designer
model: <filled from the agent file>
difficulty: simple | medium | hard
max_attempts: {{MAX_ATTEMPTS}}
branch: task/T000-<short-name>
---

## Goal
<!-- one paragraph: what to do -->

## Inputs (read only these)
- docs/specs/<feature>.md (sections: ...)
- Requirements: <ID, ID>

## Writable paths
- hw/rtl/<feature>/**
- tracking/tasks/T000.result.md

## Checks (copy the raw *_RESULT lines of build/check/<feature>.txt)
- make check FEATURE=<feature>

## Rules
- Do not modify files outside the writable paths.
- Behaviour not stated in the spec is listed as DERIVED-nnn in the result card.
- Do not claim a gate passed unless its output shows it.
- After max_attempts set status: escalate and stop.
