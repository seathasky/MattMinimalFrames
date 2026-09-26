debugstack = debug.traceback
strmatch = string.match

loadfile("../LibStub.lua")()

for major, library in LibStub:IterateLibraries() do
	
	assert(major ~= "MyLib")
end

assert(not LibStub:GetLibrary("MyLib", true)) 
assert(not pcall(LibStub.GetLibrary, LibStub, "MyLib")) 
local lib = LibStub:NewLibrary("MyLib", 1) 
assert(lib) 
assert(rawequal(LibStub:GetLibrary("MyLib"), lib)) 

assert(LibStub:NewLibrary("MyLib", 2))	

local count=0
for major, library in LibStub:IterateLibraries() do
	
	if major == "MyLib" then 
		count = count +1
		assert(rawequal(library, lib)) 
	end
end
assert(count == 1) 
