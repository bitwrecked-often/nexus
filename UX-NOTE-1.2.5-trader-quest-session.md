# UX note for the next HRS candidate: wait for the opening trader destination

The frozen `1.2.5-qa.002.zip` remains unchanged. The user chose a visible notice as the current mitigation for the known limitation. A working manager and README prototype is in `prototypes/hrs-1.2.5-trader-session-notice` for the next DEV candidate.

## Manager copy

Place a visible, wrapping note below the Random starting biome controls and above the action buttons. Show it only when **Random** is selected; it applies to Any, Chosen, and Weighted selection and to either protection setting.

> Do not log out until your first trader is assigned. Wait for the Journey to Settlement trader marker. Leaving earlier may point the quest to a trader in another biome when you return.

Repeat a shorter version in the **Apply Settings** confirmation for Random mode:

> Do not log out until your first trader is assigned. Wait for the Journey to Settlement trader marker.

Do not show the warning for Standard mode. Use the existing WinForms layout with wrapping text and scroll support so it remains readable at large display scaling. The notice is informational; it does not block Apply or Launch.

## README copy

Add under Install and start:

> In Random mode, do not log out until your first trader is assigned. Wait for the Journey to Settlement trader marker. Leaving earlier may point the quest to a trader in another biome when you return. Your random landing remains one-shot and is not repeated.

## QA acceptance

- The warning appears for all Random selection methods, including RandomSafe, and is absent in Standard mode.
- It is legible at 100%, 150%, 200%, and 225% display scaling without clipped text.
- Apply and Launch behavior is unchanged. The manager continues to save the exact selected biome policy.
- The customer ZIP, receipt, and transfer manifest for `1.2.5-qa.002` are not edited; shipping this text requires a new candidate identity.

Reason: [QA-FINDING-1.2.5-qa.002-trader-route.md](QA-FINDING-1.2.5-qa.002-trader-route.md).

Public known-issue copy: [KNOWN-ISSUE-1.2.5-trader-route.md](KNOWN-ISSUE-1.2.5-trader-route.md).
