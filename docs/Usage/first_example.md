---
title: "Example 1"
sidebar_position: 1
---

---

# Using the Constructor `new()` With Simple Operations

---

```lua
local HyperDigits = require("/path/to/HyperDigits")

local myNumber = HyperDigits.new(10)

--Ways to do operations
myNumber += HyperDigits.new(10) --Obviously the best way
myNumber = HyperDigits.add(myNumber, HyperDigits.new(10))
print(myNumber:toNumber()) --should print 30

local myNumber2 = HyperDigits.new(420)

myNumber2 -= HyperDigits.new(353)
myNumber2 = myNumber2 * HyperDigits.new(67) -- or *= like above with the -=

print(myNumber2:toNumber()) --should print 4489
print(myNumber2) --defaults to suffix abbreviation; should print 4.49K
```

# Using Other Constructors

---

```lua
local HyperDigits = require("/path/to/HyperDigits")

local a = HyperDigits.fromString("1e67") --a better version of .new(), takes in numbers, scientific, scientific chain, suffixes
local b = HyperDigits.fromPercent(10)

print(a) --should print 10UVt
print(a + b) --should print 11UVt because 10 + 10% is lowkey 11 :OOOOOO


local c = HyperDigits.fromScientific("1.5K") --practically a wrapper for fromString/you can just use fromString. Just a syntax thing.
print(c * HyperDigits.new(2)) --should print 3K
```
