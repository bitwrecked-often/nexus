# [Mod Name] — Technical File Manifest

## Purpose

Record every distributed file, its role, ownership, and validation rule.

| Path | Category | Purpose | User-editable | Generated | Validation |
|---|---|---|---|---|---|
| `[path]` | Modlet metadata | [purpose] | [yes/no] | [yes/no] | [rule] |
| `[path]` | XML payload | [purpose] | [yes/no] | [yes/no] | [rule] |
| `[path]` | GUI/tool | [purpose] | [yes/no] | [yes/no] | [rule] |
| `[path]` | Documentation | [purpose] | [yes/no] | [yes/no] | [rule] |

## Owned write boundary

The tool may create, replace, or remove only:

* `[owned path]`
* `[owned path]`

The tool must never modify:

* Vanilla `Data/Config` files directly
* Other mod folders
* Saves or generated worlds
* Unrelated server settings

## Payload target record

| Row ID | XML source | XPath/patch target | Baseline | Applied shape | Removal result |
|---|---|---|---|---|---|
| `[row]` | `[file]` | `[target]` | `[baseline]` | `[value]` | `[result]` |
