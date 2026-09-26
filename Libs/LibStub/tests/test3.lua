debugstack = debug.traceback
strmatch = string.match

loadfile("../LibStub.lua")()

local proxy = newproxy() 

assert(not pcall(LibStub.NewLibrary, LibStub, proxy, 1)) 
local success, ret = pcall(LibStub.GetLibrary, proxy, true)
assert(not success or not ret) 

assert(not pcall(LibStub.NewLibrary, LibStub, "Something", "No number in here")) 

assert(not LibStub:GetLibrary("Something", true)) 