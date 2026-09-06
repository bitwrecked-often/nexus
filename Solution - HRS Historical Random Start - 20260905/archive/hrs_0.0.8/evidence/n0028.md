# Phase 1 LoadedGame — Pre-Test Baseline

Date: 2026-08-20  
Status: Captured before authorized reload

- Exact target: `Navezgane / HRS_Phase1_Test_001`
- Target file count: 73
- Target aggregate SHA-256:
  `C4D929B682476D9DAB4CEDE5240BD712C5730F923CA4091E5AEA22EA6249A0B1`
- `newGameOptions.sdf` SHA-256:
  `B2BAB832AE44C9612703ED2914BDC89854919D97A16DDDF1102543B331425A6B`
- `serveradmin.xml` SHA-256:
  `19C6F4383DA6093690BDE3482B164BF0F8A8291FD3E0BE3ECCB8BBA41A021774`
- Installed DLL SHA-256:
  `7E235FC8A3F22275B4BBE5B7B511678C4147D4EB4F20CF8E5E4BFF5124977C8A`
- Installed `ModInfo.xml` SHA-256:
  `39CD88B7A0C0D2928B81374399AD77FE28178A67C5B7669FAB3F4FBA5CBCBFC8`

The target aggregate is expected to change during an ordinary load/save. The
test evaluates the probe's lifecycle reason, payload integrity, global metadata
hashes, unrelated-save timestamps, and absence of forbidden/error evidence; it
does not require the active disposable target to remain byte-identical.
