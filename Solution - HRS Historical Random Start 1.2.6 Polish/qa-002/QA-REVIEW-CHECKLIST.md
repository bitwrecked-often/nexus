# 1.2.6-qa.002 independent QA checklist

All 41 cases are Pending. This is an index; the frozen contract supplies full evidence and acceptance requirements.

| Case | Review | Handoff status |
| --- | --- | --- |
| HRS-QA-001 | Customer package identity | Pending |
| HRS-QA-002 | Standard-mode control | Pending |
| HRS-QA-003A | Navezgane placed-world landing | Pending |
| HRS-QA-003B | Random Gen placed-world landing | Pending |
| HRS-QA-004 | Placed trader route | Pending |
| HRS-QA-005 | Intro and ordinary work | Pending |
| HRS-QA-006 | One-shot reload | Pending |
| HRS-QA-007 | Arrival protection boundary | Pending |
| HRS-QA-008 | Owned removal | Pending |
| HRS-QA-009 | Owned upgrade | Pending |
| HRS-QA-010 | Manager identity rejection | Pending |
| HRS-QA-011 | Exact Game Name guard | Pending |
| HRS-BIOME-Navezgane-Forest | Chosen Forest in Navezgane | Pending |
| HRS-BIOME-Navezgane-BurntForest | Chosen BurntForest in Navezgane | Pending |
| HRS-BIOME-Navezgane-Desert | Chosen Desert in Navezgane | Pending |
| HRS-BIOME-Navezgane-Snow | Chosen Snow in Navezgane | Pending |
| HRS-BIOME-Navezgane-Wasteland | Chosen Wasteland in Navezgane | Pending |
| HRS-BIOME-Navezgane-Weighted-Mixed | Weighted Mixed in Navezgane | Pending |
| HRS-BIOME-Navezgane-Weighted-ZeroExclusion | Weighted ZeroExclusion in Navezgane | Pending |
| HRS-BIOME-Navezgane-Weighted-SinglePositive | Weighted SinglePositive in Navezgane | Pending |
| HRS-BIOME-Navezgane-Respawn | Respawn and changed preference in Navezgane | Pending |
| HRS-BIOME-RandomGen-Forest | Chosen Forest in RandomGen | Pending |
| HRS-BIOME-RandomGen-BurntForest | Chosen BurntForest in RandomGen | Pending |
| HRS-BIOME-RandomGen-Desert | Chosen Desert in RandomGen | Pending |
| HRS-BIOME-RandomGen-Snow | Chosen Snow in RandomGen | Pending |
| HRS-BIOME-RandomGen-Wasteland | Chosen Wasteland in RandomGen | Pending |
| HRS-BIOME-RandomGen-Weighted-Mixed | Weighted Mixed in RandomGen | Pending |
| HRS-BIOME-RandomGen-Weighted-ZeroExclusion | Weighted ZeroExclusion in RandomGen | Pending |
| HRS-BIOME-RandomGen-Weighted-SinglePositive | Weighted SinglePositive in RandomGen | Pending |
| HRS-BIOME-RandomGen-Respawn | Respawn and changed preference in RandomGen | Pending |
| HRS-BIOME-Weighted-AbsentRenormalized | Weighted absent eligible biome | Pending |
| HRS-BIOME-REQUESTED_BIOME_ABSENT | Safe fallback: REQUESTED_BIOME_ABSENT | Pending |
| HRS-BIOME-WEIGHTED_POOL_EMPTY | Safe fallback: WEIGHTED_POOL_EMPTY | Pending |
| HRS-BIOME-POI_SAFETY_EXHAUSTED | Safe fallback: POI_SAFETY_EXHAUSTED | Pending |
| HRS-BIOME-TRADER_POOL_EMPTY | Safe fallback: TRADER_POOL_EMPTY | Pending |
| HRS-BIOME-Manager | Saved biome selection, native presentation and accessibility | Pending |
| HRS-QA-TRADER-NOTICE | Post-Apply trader-session notice | Pending |
| HRS-QA-TRADER-FIRST-SESSION | Uninterrupted first trader assignment | Pending |
| HRS-QA-TRADER-EARLY-LOGOUT | Known early-logout route limitation | Pending |
| HRS-QA-TRADER-POST-ASSIGNMENT | Trader marker survives return before visit | Pending |
| HRS-QA-TRADER-CROSS-BIOME | Legitimate cross-biome trader fallback | Pending |

## Manager checks

Open the extracted customer START.bat. Check saved selection, cancel/commit weight edits, exact confirmation, rounded outlined actions, the weights dialog, visible focus and disabled states, and Tab/Space/Enter/Escape. At actual 100/150/200/225 percent Windows display scaling, verify narrow and maximized scroll reachability, OS High Contrast, Narrator control names and states, and native confirmation and Settings Applied popup readability.

- [ ] saved-selection-restored
- [ ] weight-cancel-discarded
- [ ] weight-switch-retained
- [ ] all-zero-blocked
- [ ] confirmation-before-mutation
- [ ] keyboard-access
- [ ] scaling-100
- [ ] scaling-150
- [ ] scaling-200
- [ ] scaling-225
- [ ] rounded-actions-readable
- [ ] weights-dialog-readable
- [ ] focus-disabled-readable
- [ ] os-high-contrast
- [ ] narrator-controls
- [ ] scroll-reachability
- [ ] native-popups-readable
