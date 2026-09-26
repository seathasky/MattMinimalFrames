debugstack = debug.traceback
strmatch = string.match

loadfile("../LibStub.lua")()



assert(LibStub.minor)
LibStub.minor = LibStub.minor - 0.0001
LibStub.IterateLibraries = nil

loadfile("../LibStub.lua")()

assert(type(LibStub.IterateLibraries)=="function")



LibStub.IterateLibraries = 123

loadfile("../LibStub.lua")()

assert(LibStub.IterateLibraries == 123)



LibStub.minor = LibStub.minor + 0.0001

loadfile("../LibStub.lua")()

assert(LibStub.IterateLibraries == 123)



LibStub.minor = LibStub.minor + 1234567890

loadfile("../LibStub.lua")()

assert(LibStub.IterateLibraries == 123)


print("OK")