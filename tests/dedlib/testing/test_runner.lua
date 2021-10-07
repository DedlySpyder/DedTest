local Test_Runner = require("__DedLib__/modules/testing/test_runner")
local Test_Group = require("__DedLib__/modules/testing/test_group")
local Assert = require("__DedLib__/modules/testing/assert")

local Validation_Utils = require("validation_utils")
local GROUP = "Test_Runner"

local function after_each(func)
    return function()
        local s, e = pcall(func)
        Test_Runner.reset()
        if not s then error(e) end
    end
end

local function add_validation(name, func)
    Validation_Utils.add_validation(GROUP, name, after_each(func))
end

return function()
    -- Test_Runner.reset() validation
    -- Going out of order because reset is used for the after anyways
    add_validation("reset__junk", function()
        local fake = {}
        Test_Runner.ALL_TEST_GROUPS = fake
        Test_Runner.ALL_TEST_GROUPS_COUNTS = fake
        Test_Runner.reset()

        Assert.assert_not_equals(fake, Test_Runner.ALL_TEST_GROUPS, "Groups were not reset")
        Assert.assert_not_equals(fake, Test_Runner.ALL_TEST_GROUPS_COUNTS, "Group count were not reset")
    end)


    -- Test_Runner.add_test() validations
    add_validation("add_test__basic", function()
        local testName = "test"
        local test = {name = testName}
        local name = "test_group"
        Test_Runner.add_test(test, name)

        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.incomplete, "Count of incomplete test groups mismatch")

        local testGroup = Test_Runner.ALL_TEST_GROUPS.incomplete[1]
        Assert.assert_equals("Test_Group", testGroup.__which, "Test group was not created correctly: " .. serpent.line(testGroup))
        Assert.assert_equals(name, testGroup.name, "Test group name mismatch")
        Assert.assert_equals(1, table_size(testGroup.tests.incomplete), "Test group tests count mismatch")
        Assert.assert_equals(testName, testGroup.tests.incomplete[testName].name, "Test group tests[1] name mismatch")
    end)


    -- Test_Runner.add_test_group() validations
    add_validation("add_test_group__basic", function()
        local testName = "test"
        local test = {name = testName}
        local name = "test_group"
        Test_Runner.add_test_group({name = name, tests = {test}})

        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.incomplete, "Count of incomplete test groups mismatch")

        local testGroup = Test_Runner.ALL_TEST_GROUPS.incomplete[1]
        Assert.assert_equals("Test_Group", testGroup.__which, "Test group was not created correctly: " .. serpent.line(testGroup))
        Assert.assert_equals(name, testGroup.name, "Test group name mismatch")
        Assert.assert_equals(1, table_size(testGroup.tests.incomplete), "Test group tests count mismatch")
        Assert.assert_equals(testName, testGroup.tests.incomplete[testName].name, "Test group tests[1] name mismatch")
    end)
    add_validation("add_test_group__test_group_no_op", function()
        local name = "test_group"
        local test_group = Test_Group.create({name = name})
        Test_Runner.add_test_group(test_group)

        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.incomplete, "Count of incomplete test groups mismatch")
        Assert.assert_equals(test_group, Test_Runner.ALL_TEST_GROUPS.incomplete[1], "Test group mismatch (expected no-op)")
    end)


    -- Test_Runner.add_external_results() validations
    add_validation("add_external_results__one_set", function()
        Test_Runner.add_external_results({
            skipped = 1,
            failed = 2,
            succeeded = 3
        })

        Assert.assert_equals(1, Test_Runner.EXTERNAL_RESULT_COUNTS.skipped, "Skipped count mismatch")
        Assert.assert_equals(2, Test_Runner.EXTERNAL_RESULT_COUNTS.failed, "Failed count mismatch")
        Assert.assert_equals(3, Test_Runner.EXTERNAL_RESULT_COUNTS.succeeded, "Succeeded count mismatch")
    end)
    add_validation("add_external_results__two_sets", function()
        Test_Runner.add_external_results({
            skipped = 1,
            failed = 2,
            succeeded = 3
        })
        Test_Runner.add_external_results({
            skipped = 1,
            failed = 2,
            succeeded = 3
        })

        Assert.assert_equals(2, Test_Runner.EXTERNAL_RESULT_COUNTS.skipped, "Skipped count mismatch")
        Assert.assert_equals(4, Test_Runner.EXTERNAL_RESULT_COUNTS.failed, "Failed count mismatch")
        Assert.assert_equals(6, Test_Runner.EXTERNAL_RESULT_COUNTS.succeeded, "Succeeded count mismatch")
    end)
    Validation_Utils.add_arg_validations(
            1,
            function(name, args)
                add_validation("add_external_results__junk_no_op_" .. name, function()
                    Test_Runner.add_external_results(args)
                    Assert.assert_equals(0, Test_Runner.EXTERNAL_RESULT_COUNTS.skipped, "Skipped count mismatch")
                    Assert.assert_equals(0, Test_Runner.EXTERNAL_RESULT_COUNTS.failed, "Failed count mismatch")
                    Assert.assert_equals(0, Test_Runner.EXTERNAL_RESULT_COUNTS.succeeded, "Succeeded count mismatch")
                end)
            end
    )
    Validation_Utils.add_arg_validations(
            2,
            function(name, args)
                add_validation("add_external_results__junk_no_op_" .. name, function()
                    Test_Runner.add_external_results(args)
                    Assert.assert_equals(0, Test_Runner.EXTERNAL_RESULT_COUNTS.skipped, "Skipped count mismatch")
                    Assert.assert_equals(0, Test_Runner.EXTERNAL_RESULT_COUNTS.failed, "Failed count mismatch")
                    Assert.assert_equals(0, Test_Runner.EXTERNAL_RESULT_COUNTS.succeeded, "Succeeded count mismatch")
                end)
            end
    )


    -- Test_Runner.run() validations
    add_validation("run__calls_run_method", function()
        local groupRan = false
        Test_Runner.add_test_group({tests = {}, run = function() groupRan = true end})
        Test_Runner.run()

        Assert.assert_true(groupRan, "Group was not run")
    end)
    add_validation("run__natural_basic_one_good_test", function()
        local testRan = false
        Test_Runner.add_test_group({tests = {function() testRan = true end}})
        Test_Runner.run()

        Assert.assert_true(testRan, "Test was not run by group")
        Assert.assert_equals(0, #Test_Runner.ALL_TEST_GROUPS.incomplete, "Count of incomplete test groups mismatch")
        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.completed, "Count of completed test groups mismatch")
        Assert.assert_equals(0, #Test_Runner.ALL_TEST_GROUPS.skipped, "Count of skipped test groups mismatch")
        Assert.assert_equals(0, Test_Runner.ALL_TEST_GROUPS_COUNTS.failed, "Failed count mismatch")
        Assert.assert_equals(1, Test_Runner.ALL_TEST_GROUPS_COUNTS.succeeded, "Succeeded count mismatch")
        Assert.assert_equals(0, Test_Runner.ALL_TEST_GROUPS_COUNTS.skipped, "Skipped count mismatch")
    end)
    add_validation("run__natural_basic_one_failed_test", function()
        Test_Runner.add_test_group({tests = {function() error("i failed") end}})
        Test_Runner.run()

        Assert.assert_equals(0, #Test_Runner.ALL_TEST_GROUPS.incomplete, "Count of incomplete test groups mismatch")
        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.completed, "Count of completed test groups mismatch")
        Assert.assert_equals(0, #Test_Runner.ALL_TEST_GROUPS.skipped, "Count of skipped test groups mismatch")
        Assert.assert_equals(1, Test_Runner.ALL_TEST_GROUPS_COUNTS.failed, "Failed count mismatch")
        Assert.assert_equals(0, Test_Runner.ALL_TEST_GROUPS_COUNTS.succeeded, "Succeeded count mismatch")
        Assert.assert_equals(0, Test_Runner.ALL_TEST_GROUPS_COUNTS.skipped, "Skipped count mismatch")
    end)
    add_validation("run__natural_basic_one_of_each", function()
        Test_Runner.add_test_group({tests = {function() end}})
        Test_Runner.add_test_group({tests = {function() error("i failed") end}})
        Test_Runner.run()

        Assert.assert_equals(0, #Test_Runner.ALL_TEST_GROUPS.incomplete, "Count of incomplete test groups mismatch")
        Assert.assert_equals(2, #Test_Runner.ALL_TEST_GROUPS.completed, "Count of completed test groups mismatch")
        Assert.assert_equals(0, #Test_Runner.ALL_TEST_GROUPS.skipped, "Count of skipped test groups mismatch")
        Assert.assert_equals(1, Test_Runner.ALL_TEST_GROUPS_COUNTS.failed, "Failed count mismatch")
        Assert.assert_equals(1, Test_Runner.ALL_TEST_GROUPS_COUNTS.succeeded, "Succeeded count mismatch")
        Assert.assert_equals(0, Test_Runner.ALL_TEST_GROUPS_COUNTS.skipped, "Skipped count mismatch")
    end)


    -- Test_Runner.adjust_group() validations
    add_validation("adjust_group__synthetic_completed", function()
        Test_Runner.add_test_group({})
        local tg = Test_Runner.ALL_TEST_GROUPS.incomplete[1]
        tg.state = "completed"
        tg.done = true
        tg.tests.failed = {{}}
        tg.tests.succeeded = {{}, {}}
        tg.tests.skipped = {{}, {}, {}}

        Test_Runner.adjust_group(tg)
        -- Still in incomplete because of current logic
        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.incomplete, "Count of incomplete test groups mismatch")
        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.completed, "Count of completed test groups mismatch")
        Assert.assert_equals(0, #Test_Runner.ALL_TEST_GROUPS.skipped, "Count of skipped test groups mismatch")
        Assert.assert_equals_exactly(tg, Test_Runner.ALL_TEST_GROUPS.completed[1], "Test group not found in completed bucket")
        Assert.assert_equals(1, Test_Runner.ALL_TEST_GROUPS_COUNTS.failed, "Failed count mismatch")
        Assert.assert_equals(2, Test_Runner.ALL_TEST_GROUPS_COUNTS.succeeded, "Succeeded count mismatch")
        Assert.assert_equals(3, Test_Runner.ALL_TEST_GROUPS_COUNTS.skipped, "Skipped count mismatch")
    end)
    add_validation("adjust_group__synthetic_skipped", function()
        Test_Runner.add_test_group({})
        local tg = Test_Runner.ALL_TEST_GROUPS.incomplete[1]
        tg.state = "skipped"
        tg.done = true
        tg.tests.failed = {{}, {}, {}, {}}
        tg.tests.succeeded = {{}, {}, {}, {}, {}}
        tg.tests.skipped = {{}, {}, {}, {}, {}, {}}

        Test_Runner.adjust_group(tg)
        -- Still in incomplete because of current logic
        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.incomplete, "Count of incomplete test groups mismatch")
        Assert.assert_equals(0, #Test_Runner.ALL_TEST_GROUPS.completed, "Count of completed test groups mismatch")
        Assert.assert_equals(1, #Test_Runner.ALL_TEST_GROUPS.skipped, "Count of skipped test groups mismatch")
        Assert.assert_equals_exactly(tg, Test_Runner.ALL_TEST_GROUPS.skipped[1], "Test group not found in skipped bucket")
        Assert.assert_equals(4, Test_Runner.ALL_TEST_GROUPS_COUNTS.failed, "Failed count mismatch")
        Assert.assert_equals(5, Test_Runner.ALL_TEST_GROUPS_COUNTS.succeeded, "Succeeded count mismatch")
        Assert.assert_equals(6, Test_Runner.ALL_TEST_GROUPS_COUNTS.skipped, "Skipped count mismatch")
    end)


    -- Test_Runner.print_pretty_report() validations
    -- Nothing _really_ to validate here, besides that the report print doesn't fail
    add_validation("print_pretty_report__no_tests", function()
        Test_Runner.print_pretty_report()
    end)
    add_validation("print_pretty_report__internal_counts", function()
        Test_Runner.ALL_TEST_GROUPS_COUNTS = {
            skipped = 1,
            failed = 2,
            succeeded = 3
        }
        Test_Runner.print_pretty_report()
    end)
    add_validation("print_pretty_report__external_counts", function()
        Test_Runner.EXTERNAL_RESULT_COUNTS = {
            skipped = 4,
            failed = 5,
            succeeded = 6
        }
        Test_Runner.print_pretty_report()
    end)
    add_validation("print_pretty_report__all_counts", function()
        Test_Runner.ALL_TEST_GROUPS_COUNTS = {
            skipped = 7,
            failed = 8,
            succeeded = 9
        }
        Test_Runner.EXTERNAL_RESULT_COUNTS = {
            skipped = 10,
            failed = 11,
            succeeded = 12
        }
        Test_Runner.print_pretty_report()
    end)


    return Validation_Utils.validate(GROUP)
end
