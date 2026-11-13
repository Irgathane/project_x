---
name: slipgate-feature
description: Feature task template for the slipgate QuakeC mod. Use when the user requests a new gameplay feature, behavior change, or enhancement to the mod. Fill in {{FEATURE}}, context, and acceptance test, then write complete file contents plus build/test steps. Load slipgate-context first.
---

# FEATURE TASK

Load the `slipgate-context` skill first and follow its project facts and answer rules.

TASK: {{FEATURE}}

CONTEXT:
- Current behavior: [describe what happens in-game now]
- Desired behavior: [describe exactly what should happen instead]
- Files you will probably touch: [guess, or write "you decide"]

CONSTRAINTS:
- Vanilla QuakeC only; values go in tuning.qc; numeric frames only.
- Do not break: shotgun firing, stalker AI, the exit door, respawn, the exit trigger.

ACCEPTANCE TEST (write code so this passes):
1. [what I should see/do in-game]
2. [expected result]
3. [expected result]

Reply with complete file contents + build/test steps, per the system prompt.
