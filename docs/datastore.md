---
sidebar_position: 2
---

# Datastore Pseudocode

---

```lua
local HyperDigits = require("/path/to/HyperDigits")

local currentData = HyperDigits.fromString("1e123")

local dataRaw = currentData:toBase() --convert HyperDigits into raw table
--logic for storing it in your datastore

-------------------------------------------------------------

--initializing raw table back into HyperDigits

local dataRaw --logic for retrieving data from datastore, should be equivalent to the dataRaw above.
local retrievedData = HyperDigits.new(dataRaw)

--continue doing whatever
```

---