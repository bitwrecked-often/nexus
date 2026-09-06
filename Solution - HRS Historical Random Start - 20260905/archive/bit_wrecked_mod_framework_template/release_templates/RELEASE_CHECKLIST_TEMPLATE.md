# [Mod Name] — Release Checklist

## Identity and source

* [ ] Internal name, display name, version, and author match across files.
* [ ] GPL license text, copyright notice, and source location are included.
* [ ] Third-party materials and attribution are recorded.

## Payload and safety

* [ ] Every included row has an evidence-backed line-item-map entry.
* [ ] XML parses successfully.
* [ ] XPath/target checks pass against the supported game version.
* [ ] Install, reinstall, selective removal, and full removal pass.
* [ ] Shared dependencies remain while required and disappear only after the
      last dependent row is removed.
* [ ] Tool write boundary is documented and enforced.

## Player documentation

* [ ] README explains promise, exclusions, install, removal, and compatibility.
* [ ] Release notes and changelog match actual behavior.
* [ ] SEO/publishing copy makes no unsupported promises.
* [ ] Multiplayer/server and anti-cheat notes are evidence-based.

## Archives

* [ ] No-scripts modlet archive is present and usable by itself.
* [ ] Optional GUI/full archive includes source scripts and documentation.
* [ ] Archive shape checks pass.
* [ ] SHA-256 hashes are recorded.
* [ ] A dated known-good source/archive backup is retained.

## Authorization

* [ ] Gameplay owner approved the target behavior.
* [ ] Release owner approved publication.
* [ ] External upload has not occurred before approval.
