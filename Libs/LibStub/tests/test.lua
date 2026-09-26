debugstack = debug.traceback
strmatch = string.match

loadfile("../LibStub.lua")()

local lib, oldMinor = LibStub:NewLibrary("Pants", 1) 
assert(lib) 
assert(not oldMinor) 


function lib:MyMethod()
end
local MyMethod = lib.MyMethod
lib.MyTable = {}
local MyTable = lib.MyTable

local newLib, newOldMinor = LibStub:NewLibrary("Pants", 1) 
assert(not newLib) 

local newLib, newOldMinor = LibStub:NewLibrary("Pants", 0) 
assert(not newLib) 

local newLib, newOldMinor = LibStub:NewLibrary("Pants", 2) 
assert(newLib) 
assert(rawequal(newLib, lib)) 
assert(newOldMinor == 1) 

assert(rawequal(lib.MyMethod, MyMethod)) 
assert(rawequal(lib.MyTable, MyTable)) 

local newLib, newOldMinor = LibStub:NewLibrary("Pants", "Blah 3 Blah") 
assert(newLib) 
assert(newOldMinor == 2) 

local newLib, newOldMinor = LibStub:NewLibrary("Pants", "Blah 4 and please ignore 15 Blah") 
assert(newLib)
assert(newOldMinor == 3) 

local newLib, newOldMinor = LibStub:NewLibrary("Pants", 5) 
assert(newLib)
assert(newOldMinor == 4) 