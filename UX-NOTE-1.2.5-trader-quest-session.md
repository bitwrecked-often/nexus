# UX note for the next HRS candidate: finish the opening trader quest in one session

The frozen `1.2.5-qa.002.zip` remains unchanged. This notice is the fallback if the release decision accepts the known limitation; a repair should be assessed first because the tester encountered it during ordinary play.

## Manager copy

Place a visible, wrapping note below the Random starting biome controls and above the action buttons. Show it only when **Random** is selected; it applies to Any, Chosen, and Weighted selection and to either protection setting.

> For this release, finish the starter tasks and Journey to Settlement (talk to the trader) before leaving the world. If you log out first, the trader quest may point to a trader in another biome when you return.

Repeat a shorter version in the **Apply Settings** confirmation for Random mode:

> Stay in the world until you have talked to the opening trader. Logging out earlier may change where the trader quest points when you return.

Do not show the warning for Standard mode. Use the existing WinForms layout with wrapping text and scroll support so it remains readable at large display scaling. The notice is informational; it does not block Apply or Launch.

## README copy

Add under Install and start:

> In Random mode, complete the starter tasks and the opening Journey to Settlement trader visit in the same game session. If you leave the world before finishing that quest, its destination may point to a trader in another biome after you return. Your random landing remains one-shot and is not repeated.

## QA acceptance

- The warning appears for all Random selection methods, including RandomSafe, and is absent in Standard mode.
- It is legible at 100%, 150%, 200%, and 225% display scaling without clipped text.
- Apply and Launch behavior is unchanged. The manager continues to save the exact selected biome policy.
- The customer ZIP, receipt, and transfer manifest for `1.2.5-qa.002` are not edited; shipping this text requires a new candidate identity.

Reason: [QA-FINDING-1.2.5-qa.002-trader-route.md](QA-FINDING-1.2.5-qa.002-trader-route.md).

Public known-issue copy: [KNOWN-ISSUE-1.2.5-trader-route.md](KNOWN-ISSUE-1.2.5-trader-route.md).
