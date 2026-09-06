# Payload Template Placeholder

This directory intentionally contains no active `ModInfo.xml` or XML patch.

When a new mod has completed its line-item map, create its owned modlet payload
here or in the new mod's active version lane:

```text
[NewModletName]/
├── ModInfo.xml
└── Config/
    └── [target].xml
```

Every file and XPath must come from the new mod's verified line-item map. Do not
copy an inherited animal, weapon, loot, or other payload into a new product.
