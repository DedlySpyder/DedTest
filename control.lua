local Logger = require("__DedLib__/modules/logger").create()
local Test_Runner = require("__DedLib__/modules/testing/test_runner")

local DedLib = require("tests/dedlib/main")
local Avatars = require("tests/avatars/main")

local controlTestChoice = settings.global["DedTest_control_test_what"].value

local testRunner = function() end
if controlTestChoice == "dedlib" then
    -- DedLib Testings cannot use the normal rigging, since it needs to test it as well
    Logger:trace("Running DedLib tests")
    testRunner = function()
        DedLib()
        script.on_event(defines.events.on_tick, nil)
    end
else
    -- These will just load the tests, then the on_tick will run and print when done
    if controlTestChoice == "avatars" then
        Logger:trace("Running Avatars tests")
        Avatars()
    end
    testRunner = function()
        Test_Runner.on_tick()
    end
end


script.on_event(defines.events.on_tick, testRunner)
