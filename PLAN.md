# Add AI Text-Morph as a new main tab

**Features**
- [x] Add a new “AI Text-Morph” tab alongside the current app sections.
- [x] Let users transform text in single-item mode or batch mode.
- [x] Split batch input by blank lines and process each item separately.
- [x] Preserve built-in morph styles like professional, summary, grammar fix, simplify, and expand.
- [x] Let users create custom morph styles with a name, emoji, and instruction.
- [x] Save custom morph styles so they remain after closing the app.
- [x] Let users delete custom morph styles from a long-press menu.
- [x] Use a primary AI service with a silent backup service if the first one fails.
- [x] Keep secret access values out of the app screen and show clear placeholders for secure setup.
- [x] Show live batch progress while multiple items are being transformed.
- [x] Show each batch item with its original snippet, transformed result, and success or error status.
- [x] Add character count, word count, and batch item count.
- [x] Add copy result and copy all results actions with animated confirmation.
- [x] Add a clear button that resets input, output, errors, and progress.
- [x] Add a retry button when processing fails.

**Design**
- [x] Use a premium light and dark mode interface with layered cards and soft translucent surfaces.
- [x] Add a polished header that makes the tool feel like a flagship text engine.
- [x] Use strong visual hierarchy for input, style selection, action buttons, and results.
- [x] Add refined empty states so the screen feels intentional before any result exists.
- [x] Add accessible labels, large touch targets, and readable spacing throughout.
- [x] Add smooth animations for copying, progress, results, and error feedback.
- [x] Use the newest visual effects on newer devices while keeping graceful fallbacks for older supported devices.

**Screens**
- [x] Main AI Text-Morph screen with input, mode switch, morph styles, actions, and results.
- [x] Custom style creation sheet for adding personal transformation modes.
- [x] Batch results area showing per-item cards and overall progress.
- [x] Error state with friendly message and retry action.

**Safety and reliability**
- [x] Remove embedded secret keys from the visible implementation.
- [x] Use user-friendly error messages instead of raw technical failures.
- [x] Keep all current capabilities intact while improving structure, resilience, and polish.
- [x] Validate the app after implementation and fix any issues before reporting completion.
