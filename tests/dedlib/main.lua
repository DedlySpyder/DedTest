-- TODO - this can all be a new mod?
-- TODO - should probably still have tests on the functions that wrap other ones, just to make sure they don't break (missing return or something dumb happens)
local Logger = require("__DedLib__/modules/logger").create("DedLib_Testing")
local Test_Runner = require("__DedLib__/modules/testing/test_runner")

local assert = require("testing/assert")
local mock = require("testing/mock")
local test = require("testing/test")
local test_group = require("testing/test_group")
local test_runner = require("testing/test_runner")

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
    add_tester_results(test_group())
    add_tester_results(test_runner())

    Logger:info("Tester validation results: %s", tester_results)

    -- This needs to be after test_runner validations, as it resets the Test_Runner
    Test_Runner.add_external_results(tester_results)

    -- Run other tests
    -- Modules are tested in dependency order (all depend on logger for example)
    Test_Runner.add_test_group(stringify)
    Test_Runner.add_test_group(logger)

    Test_Runner.add_test_group(position)
    Test_Runner.add_test_group(area)

    Test_Runner.add_test_group(entity)

    Test_Runner.add_test_group(custom_events)

    Test_Runner.run()
    Test_Runner.print_pretty_report()
end
