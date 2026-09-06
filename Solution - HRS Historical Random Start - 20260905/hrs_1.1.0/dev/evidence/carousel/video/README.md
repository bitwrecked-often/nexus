# Local carousel video evidence

Raw Snipping Tool MP4 recordings are stored in this folder locally and synced
by the owner's workspace storage, but are excluded from Git because they may
exceed GitHub's normal 100 MB blob limit. Each recording must have a committed
SHA-256 sidecar manifest in the parent `carousel` folder tying it to the exact
run ID, runtime event log, and terminal result.

Do not treat a missing local MP4 after a fresh Git clone as missing machine
evidence. The committed hash manifest is the integrity/index record; retrieve
the named MP4 from the canonical QA workspace when visual review is required.
