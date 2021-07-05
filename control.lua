local Logger = require("__DedLib__/modules/logger").create()
local testRunner = require("tests/main")

local DedLib = require("tests/dedlib/main")

local controlTestChoice = settings.global["DedTest_control_test_what"].value

local testRunner = function() end
if controlTestChoice == "dedlib" then
    Logger:trace("Running DedLib tests")
    testRunner = DedLib
end


script.on_event(defines.events.on_tick, function(e)
    testRunner()
    script.on_event(defines.events.on_tick, nil)
end)
