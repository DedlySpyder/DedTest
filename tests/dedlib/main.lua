-- TODO - this can all be a new mod?
-- TODO - should probably still have tests on the functions that wrap other ones, just to make sure they don't break (missing return or something dumb happens)
local Logger = require("__DedLib__/modules/logger").create("DedLib_Testing")
local Tester = require("__DedLib__/modules/testing/tester")

local assert = require("testing/assert")
local mock = require("testing/mock")
local test = require("testing/test")
local tester = require("testing/tester")

local stringify = require("stringify")
local logger = require("logger")

local position = require("position")
local area = require("area")

local entity = require("entity")

local custom_events = require("events/custom_events")

local tester_results = {succeeded = 0, failed = 0}
local add_tester_results = function(results)
    tester_results["succeeded"] = tester_results["succeeded"] + results["succeeded"]
    tester_results["failed"] = tester_results["failed"] + results["failed"]
end

if remote.interfaces["freeplay"] then
    script.on_init(function() -- Stringify tests can't have the freeplay scenario
        remote.call("freeplay", "set_disable_crashsite", true)
        remote.call("freeplay", "set_skip_intro", true)
    end)
end

return function()
    Logger:info("Running tests for DedLib")
    Logger:info("Running Tester module validations")
    -- Test the tester first
    add_tester_results(assert())
    add_tester_results(mock())
    add_tester_results(test())
    --add_tester_results(tester()) --TODO - needs rewrite for the new abstraction

    Logger:info("Tester validation results: %s", tester_results)

    Tester.add_external_results(tester_results)

    -- Run other tests
    -- Modules are tested in dependency order (all depend on logger for example)
    Tester.add_tests(stringify, "Stringify")
    Tester.add_tests(logger, "Logger")

    Tester.add_tests(position, "Position")
    Tester.add_tests(area, "Area")

    Tester.add_tests(entity, "Entity")

    Tester.add_tests(custom_events, "CustomEvents")

    Tester.run()
end
