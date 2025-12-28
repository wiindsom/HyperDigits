---
title: "Simple Use"
sidebar_position: 1
---

# Basic Usage

---

```lua
local HyperDigits = require("/path/to/HyperDigits")

local myNumber = HyperDigits.new(10)

--Ways to do operations
myNumber += HyperDigits.new(10) --Obviously the best way
myNumber = HyperDigits.add(myNumber, HyperDigits.new(10))
print(myNumber) --should print 30

local myNumber2 = HyperDigits.new(420)

myNumber2 -= HyperDigits.new(353)
myNumber2 = myNumber * HyperDigits.new(2) -- or *= like above with the -=
```

---

# Basic Usage 2

---

```lua
local HyperDigits = require("/path/to/HyperDigits")

local myNumber = HyperDigits.fromString("1e3") --same as .new(), just obviously easier to use imo.



```

---