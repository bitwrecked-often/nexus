# UX note for the next HRS candidate: wait for the opening trader destination

The frozen `1.2.5-qa.002.zip` remains unchanged. The user chose a visible notice as the current mitigation for the known limitation. A working manager and README prototype is in `prototypes/hrs-1.2.5-trader-session-notice` for the next DEV candidate.

## Manager copy

Keep the existing pre-write Yes/No confirmation for name and settings. After `Invoke-HrsInstallAndApply` returns with the policy written and read back, show a separate **Settings Applied** popup. For **Random** mode, include this notice; it applies to Any, Chosen, and Weighted selection and to either protection setting.

> Do not log out until your first trader is assigned. Wait for the Journey to Settlement trader marker. Leaving earlier may point the quest to a trader in another biome when you return.

The popup should also restate the applied game name, selection, and protection setting. Keep **Launch Game** disabled after the user approves the pre-write confirmation and until the Settings Applied popup closes. If the write fails, show the existing error popup and do not show Settings Applied. In Standard mode, show the success popup without the trader warning. Dismissing the popup returns to the manager, where Launch Game is available when Steam is running.

## README copy

Add under Install and start:

> In Random mode, do not log out until your first trader is assigned. Wait for the Journey to Settlement trader marker. Leaving earlier may point the quest to a trader in another biome when you return. Your random landing remains one-shot and is not repeated.

## QA acceptance

- The post-write success popup contains the warning for all Random selection methods, including RandomSafe, and omits it in Standard mode.
- The popup is legible at 100%, 150%, 200%, and 225% display scaling without clipped text.
- The popup appears only after a successful policy write and readback. Launch Game stays disabled until it is dismissed; failed writes do not show it.
- The manager continues to save the exact selected biome policy and does not launch the game automatically.
- The customer ZIP, receipt, and transfer manifest for `1.2.5-qa.002` are not edited; shipping this text requires a new candidate identity.

Reason: [QA-FINDING-1.2.5-qa.002-trader-route.md](QA-FINDING-1.2.5-qa.002-trader-route.md).

Public known-issue copy: [KNOWN-ISSUE-1.2.5-trader-route.md](KNOWN-ISSUE-1.2.5-trader-route.md).
