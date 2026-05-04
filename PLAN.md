# Transform AI Text-Morph into a Few-Shot Pattern Learning Engine

## What's changing

AI Text-Morph evolves from a "pick a style and rewrite" tool into a **Pattern Teacher**. You show the AI a few before → after examples, it figures out the rule, tells you how confident it is, and then applies that exact rule to a huge bulk paste — perfect for things like merging duplicate logins, standardizing dates, or reformatting lists.

All existing capabilities (custom modes, batch toggle, Groq → Gemini failover, copy/clear, API keys, toasts) stay fully intact and live alongside the new mode.

## Features

- **New "Pattern Learn" mode** added next to Single and Batch — a third tab in the same screen.
- **Example pairs editor**: add as many "Before" → "After" cards as you want, edit them inline, delete with a swipe, reorder, and duplicate.
- **Quick-start templates**: tap one to prefill the credential-grouping, date-standardization, or list-reformat examples used as inspiration.
- **Analyze button**: AI reads all your pairs and returns a plain-English description of the rule it learned.
- **Confidence meter**: animated 0–100% ring with color (red → amber → green). Below 70% shows a friendly nudge: "Add 1–2 more examples for higher accuracy."
- **Apply to bulk**: once analysis is ready, paste hundreds/thousands of lines into a dedicated bulk box and tap "Apply Pattern" to transform them all using the learned rule, with live progress.
- **Refine pattern**: tweak the AI's interpretation in natural language ("treat the email as the key, not the username") and re-analyze without losing examples.
- **Pattern library**: save a learned pattern (rule + examples) with a name; reload it later from a list. Stored on-device.
- **Result view**: full transformed output with copy-all, plus a small diff preview comparing input vs output line counts.
- All previous Single, Batch, Custom Morph Modes, API Keys, and toasts continue to work unchanged.

## Design

- Premium iOS dashboard look, same indigo/graphite palette as today, full light/dark.
- Three-tab segmented control at the top: **Single · Batch · Pattern Learn**.
- Pattern Learn screen is a vertical scroll of clean cards:
  1. Header card with a sparkles icon and one-line explainer.
  2. **Examples** card containing stacked before/after pairs; each pair is a rounded card with a thin divider, a small "→" between fields, and a delete button. A dashed "+ Add Example" tile sits at the bottom.
  3. **Confidence** card with a circular animated meter, the AI's plain-English rule summary, and a "Refine" text field.
  4. **Apply** card with the bulk text editor, line counter, and a bold "Apply Pattern" button that shows live progress.
  5. **Result** card with monospaced output, copy-all, and stats (lines in / out / changed).
- Smooth spring animations when adding/removing example pairs, when the confidence ring fills, and when the result reveals.
- Empty states: friendly illustrations using SF Symbols and helpful subcopy ("Show me 2–3 examples and I'll learn your pattern").
- Subtle haptics on analyze, apply, and copy.

## Screens

- **AI Text-Morph (existing tab)** — now hosts three modes via the segmented control. Single and Batch behave exactly as today; Pattern Learn is the new flow described above.
- **Pattern Library sheet** — slide-up sheet listing saved patterns with name, example count, learned rule, and last-used date. Tap to load, swipe to delete.
- **Save Pattern sheet** — small sheet to name a pattern before saving.
- **API Keys sheet** — unchanged.
- **Custom Morph Mode sheet** — unchanged.

## Notes

- The AI uses your existing Groq → Gemini failover for both the analysis step and the apply step, so nothing new to configure.
- Bulk apply is chunked behind the scenes so very large pastes (thousands of lines) stay responsive with a live progress bar and a cancel button.
