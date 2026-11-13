---
name: slipgate-debug
description: Debug/error template for the slipgate QuakeC mod. Use when the user reports a bug, compiler error, engine console error, or crash. Explain the cause in one sentence, then give complete corrected files and rebuild steps with the smallest possible change. Load slipgate-context first.
---

# DEBUG / ERROR

Load the `slipgate-context` skill first and follow its project facts and answer rules.

BUG REPORT — fix with the smallest possible change.

What I did: [exact steps, e.g. "ran build.bat, then launch.bat, walked to the door"]
Expected: [what should happen]
Actual: [what happens instead]

FULL error text, verbatim (compiler output, engine console, or crash message):
[paste EVERYTHING between the lines]
----
[paste here]
----

Recent changes: [files the LLM last edited, or "none — first run"]
My setup: [Windows or Linux, vkQuake version, LibreQuake version]

First explain the cause in one sentence, then give the complete corrected file(s) and the rebuild steps. If the error mentions a missing model or sound, prefer a fix that does not require new assets.
