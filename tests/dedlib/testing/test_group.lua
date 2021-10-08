local Test_Group = require("__DedLib__/modules/testing/test_group")
local Assert = require("__DedLib__/modules/testing/assert")

local Validation_Utils = require("validation_utils")
local GROUP = "Test_Group"

local function after_each(func)
    return function()
        local s, e = pcall(func)
        Test_Group.__UNNAMED_COUNT = 0
        if not s then error(e) end
    end
end

local function add_validation(name, func)
    Validation_Utils.add_validation(GROUP, name, after_each(func))
end

-- These are only really keyed to before/after at the moment, look at Test validations if you need to add something else here
local function add_one_arg_validations(funcName, extraAsserts)
    for _, validArgData in ipairs(Validation_Utils._arg_validations[1]) do
        local name, validArg = validArgData["name"], validArgData["value"]
        add_validation(funcName .. "__func_success_one_arg_" .. name, function()
            local tg = Test_Group.create({
                tests = {},
                [funcName] = function(arg)
                    Assert.assert_equals(validArg, arg)
                end,
                [funcName .. "Args"] = {validArg}
            })

            local result, returnedValue = tg["run_" .. funcName](tg)
            Assert.assert_equals(true, result, "Failed validation for before returned result")
            Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")

            extraAsserts(tg)
        end)
    end
end
local function add_two_arg_validations(funcName, extraAsserts)
    for _, validArgData in ipairs(Validation_Utils._arg_validations[2]) do
        local name, validArgs = validArgData["name"], validArgData["value"]
        add_validation(funcName .. "__func_success_two_arg_" .. name, function()
            local tg = Test_Group.create({
                tests = {},
                [funcName] = function(arg1, arg2)
                    Assert.assert_equals(validArgs[1], arg1)
                    Assert.assert_equals(validArgs[2], arg2)
                end,
                [funcName .. "Args"] = validArgs
            })

            local result, returnedValue = tg["run_" .. funcName](tg)
            Assert.assert_equals(true, result, "Failed validation for " .. funcName .. " returned result")
            Assert.assert_equals(nil, returnedValue, "Failed validation for " .. funcName .. " returned value")

            extraAsserts(tg)
        end)
    end
end
local function add_arg_validations(funcName, extraAsserts)
    add_one_arg_validations(funcName, extraAsserts)
    add_two_arg_validations(funcName, extraAsserts)
end

return function()
    -- Test_Group.create() validations
    for _, validArgData in ipairs(Validation_Utils._arg_validations[1]) do
        local name, args = validArgData["name"], validArgData["value"]
        -- All non-table args should fail
        if string.sub(name, 1, math.min(5, string.len(name))) ~= "table" then
            add_validation("create__failure_arg_" .. name, function()
                Assert.assert_throws_error(
                        Test_Group.create,
                        {args},
                        "Failed to create test group of type " .. type(args) .. " (expected table)",
                        "Create did not fail with bad args, " .. name
                )
            end)
        end
    end

    add_validation("create__success_no_tests", function()
        local tg = Test_Group.create({})
        Assert.assert_equals("Unnamed Test Group #0", tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals({}, tg.tests.incomplete, "Failed validation for create test.incomplete count")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
    end)
    add_validation("create__success_just_name_no_tests", function()
        local name = "this_is_a_Test_Group"
        local tg = Test_Group.create({name = name})
        Assert.assert_starts_with(name, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals({}, tg.tests.incomplete, "Failed validation for create test.incomplete count")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
    end)
    add_validation("create__success_name_and_empty_tests", function()
        local name = "this_is_a_Test_Group"
        local tg = Test_Group.create({name = name, tests = {}})
        Assert.assert_starts_with(name, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals({}, tg.tests.incomplete, "Failed validation for create test.incomplete count")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
    end)
    add_validation("create__success_name_and_one_tests", function()
        local tgName = "this_is_a_Test_Group_for_single_Test"
        local name = "this_is_a_single_Test"
        local tg = Test_Group.create({name = tgName, tests = {{name = name}}})
        Assert.assert_starts_with(tgName, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals(1, table_size(tg.tests.incomplete), "Failed validation for create test.incomplete count")
        Assert.assert_equals(name, tg.tests.incomplete[name].name, "Failed validation for create first test's name")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
    end)
    add_validation("create__success_name_and_two_tests", function()
        local tgName = "this_is_a_Test_Group_for_two_Tests"
        local t1Name = "this_is_the_first_Test"
        local t2Name = "this_is_the_second_Test"
        local tg = Test_Group.create({name = tgName, tests = {{name = t1Name}, {name = t2Name}}})
        Assert.assert_starts_with(tgName, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals(2, table_size(tg.tests.incomplete), "Failed validation for create test.incomplete count")
        Assert.assert_equals(t1Name, tg.tests.incomplete[t1Name].name, "Failed validation for create first test's name")
        Assert.assert_equals(t2Name, tg.tests.incomplete[t2Name].name, "Failed validation for create second test's name")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
    end)

    add_validation("create__success_name_and_empty_tests_root_level_tests_name", function()
        local name = "this_is_a_Test_Group"
        local testName = "this_is_a_Test"
        local tg = Test_Group.create({name = name, tests = {}, [testName] = {}})
        Assert.assert_starts_with(name, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals(1, table_size(tg.tests.incomplete), "Failed validation for create test.incomplete count")
        Assert.assert_equals(testName, tg.tests.incomplete[testName].name, "Failed validation for create test's name")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
    end)
    add_validation("create__success_name_and_empty_tests_root_level_tests_number", function()
        local name = "this_is_a_Test_Group"
        local tg = Test_Group.create({name = name, tests = {}, [1] = {}})
        Assert.assert_starts_with(name, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals(1, table_size(tg.tests.incomplete), "Failed validation for create test.incomplete count")
        Assert.assert_equals("Unnamed Test #1", tg.tests.incomplete["Unnamed Test #1"].name, "Failed validation for create test's name")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
    end)
    add_validation("create__success_name_and_empty_tests_root_level_tests_mixed", function()
        local name = "this_is_a_Test_Group"
        local testName = "this_is_a_Test"
        local tg = Test_Group.create({name = name, tests = {}, [testName] = {}, [1] = {}})
        Assert.assert_starts_with(name, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals(2, table_size(tg.tests.incomplete), "Failed validation for create test.incomplete count")
        Assert.assert_equals("Unnamed Test #1", tg.tests.incomplete["Unnamed Test #1"].name, "Failed validation for create first test's name")
        Assert.assert_equals(testName, tg.tests.incomplete[testName].name, "Failed validation for create second test's name")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
    end)

    add_validation("create__success_multiple_test_groups", function()
        local tg1 = Test_Group.create({})
        Assert.assert_equals("Unnamed Test Group #0", tg1.name, "Failed validation for create name value")
        local tg2 = Test_Group.create({})
        Assert.assert_equals("Unnamed Test Group #1", tg2.name, "Failed validation for create name value")
    end)

    add_validation("create__no_op_with_test_group", function()
        local args = {__which = "Test_Group"}
        local test = Test_Group.create(args)

        Assert.assert_equals_exactly(args, test, "Test as arg did not return test")
        for k, v in pairs(test) do
            if k == "__which" then
                Assert.assert_equals("Test_Group", v, "__which was changed")
            else
                error("Unexpected key exists <" .. k .. "> with value: " .. serpent.line(v))
            end
        end
    end)


    -- Test_Group.add_test() Validation
    add_validation("add_test__existing_tg", function()
        local tg = Test_Group.create({})
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed pre-validation for tests value")
        Assert.assert_equals(0, table_size(tg.tests.incomplete), "Failed pre-validation for test.incomplete count")

        local testName = "this_is_a_Test"
        tg:add_test({name = testName})
        Assert.assert_equals(1, table_size(tg.tests.incomplete), "Failed pre-validation for test.incomplete count")
        Assert.assert_equals(testName, tg.tests.incomplete[testName].name, "Failed validation for create test's name")
    end)


    -- Test_Group.generate_name() validations
    add_validation("generate_name__string", function()
        local name = "foo"
        local actualName = Test_Group.generate_name(name)
        Assert.assert_equals(name, actualName, "Failed validation for generate name value")
    end)
    add_validation("generate_name__nil", function()
        local name = nil
        local actualName = Test_Group.generate_name(name)
        Assert.assert_equals("Unnamed Test Group #0", actualName, "Failed validation for generate name value")
    end)
    add_validation("generate_name__nil_number_two", function()
        Test_Group.__UNNAMED_COUNT = 1
        local name = nil
        local actualName = Test_Group.generate_name(name)
        Assert.assert_equals("Unnamed Test Group #1", actualName, "Failed validation for generate name value")
    end)
    add_validation("generate_name__number", function()
        local name = 42
        local actualName = Test_Group.generate_name(name)
        Assert.assert_equals(tostring(name), actualName, "Failed validation for generate name value")
    end)


    -- Test_Group.validate()
    local makeTestGroupForValidateTests = function(prop, propValue)
        local t = {[prop] = propValue}
        setmetatable(t, Test_Group)
        return t
    end
    local testValidateGood = function(prop, propValue)
        local propType = type(propValue)
        local suffix = "_" .. serpent.line(propValue)
        if propType == "function" then suffix = "" end
        add_validation("validate__" .. prop .. "_good_" .. propType .. suffix, function()
            local tg = makeTestGroupForValidateTests(prop, propValue)
            -- Should succeed
            Test_Group.validate(tg)

            if propType == "table" then -- Validate should change it to a list
                if #propValue == 0 and table_size(propValue) > 0 then
                    Assert.assert_true(#tg[prop] > 0, "Validate did not change " .. prop .. " to a list")
                    Assert.assert_equals({propValue}, rawget(tg, prop), "Value not made into a list")
                else
                    Assert.assert_equals(propValue, rawget(tg, prop), "Value made into a list when not needed")
                end
            end
        end)
    end
    local testValidateBad = function(prop, propValue)
        local propType = type(propValue)
        local suffix = "_" .. serpent.line(propValue)
        if propType == "function" then suffix = "" end
        add_validation("validate__" .. prop .. "_bad_" .. propType .. suffix, function()
            local tg = makeTestGroupForValidateTests(prop, propValue)
            Assert.assert_throws_error(
                    Test_Group.validate,
                    {tg},
                    "failed validation for " .. prop .. ", see logs for more details",
                    "Validate did not fail with " .. prop .. " as " .. propType
            )
        end)
    end

    testValidateGood("before", function() end)
    testValidateGood("before", nil)
    Validation_Utils.add_arg_validations(
            1,
            function(_, args)
                testValidateBad("before", args)
            end,
            {["function"] = true, ["nil"] = true}
    )

    for _, validArgData in ipairs(Validation_Utils._arg_validations[1]) do
        local name, args = validArgData["name"], validArgData["value"]
        if string.sub(name, 1, math.min(5, string.len(name))) == "table" then -- Tables only
            testValidateGood("beforeArgs", args)
        else
            if name ~= "nil" then
                testValidateBad("beforeArgs", args)
            end
        end
    end

    testValidateGood("after", function() end)
    testValidateGood("after", nil)
    Validation_Utils.add_arg_validations(
            1,
            function(_, args)
                testValidateBad("after", args)
            end,
            {["function"] = true, ["nil"] = true}
    )

    for _, validArgData in ipairs(Validation_Utils._arg_validations[1]) do
        local name, args = validArgData["name"], validArgData["value"]
        if string.sub(name, 1, math.min(5, string.len(name))) == "table" then -- Tables only
            testValidateGood("afterArgs", args)
        else
            if name ~= "nil" then
                testValidateBad("afterArgs", args)
            end
        end
    end


    -- Test_Group.before() validations
    add_validation("before__no_func", function()
        local test = Test_Group.create({})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(nil, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_failure", function()
        local errorMessage = "supposed to fail"
        local test = Test_Group.create({tests = {}, before = function() error(errorMessage) end})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(false, result, "Failed validation for before returned result")
        Assert.assert_ends_with(errorMessage, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("skipped", test.state, "Failed validation for before state property")
        Assert.assert_false(test.running, "Failed validation for before running property")
        Assert.assert_true(test.done, "Failed validation for before done property")
    end)
    add_validation("before__func_success_no_args", function()
        local test = Test_Group.create({tests = {}, before = function() end})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_no_args_returned_value", function()
        local expectedReturnedValue = "foo"
        local test = Test_Group.create({tests = {}, before = function() return expectedReturnedValue end})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(expectedReturnedValue, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)

    add_arg_validations("before", function(test)
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)


    -- Test_Group.after() validations
    add_validation("after__no_func", function()
        local test = Test_Group.create({})
        local result, returnedValue = test:run_after()

        Assert.assert_equals(nil, result, "Failed validation for after returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for after returned value")
    end)
    add_validation("after__func_failure", function()
        local errorMessage = "supposed to fail"
        local test = Test_Group.create({tests = {}, after = function() error(errorMessage) end})
        local result, returnedValue = test:run_after()

        Assert.assert_equals(false, result, "Failed validation for after returned result")
        Assert.assert_ends_with(errorMessage, returnedValue, "Failed validation for after returned value")
    end)
    add_validation("after__func_success_no_args", function()
        local test = Test_Group.create({tests = {}, after = function() end})
        local result, returnedValue = test:run_after()

        Assert.assert_equals(true, result, "Failed validation for after returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for after returned value")
    end)
    add_validation("after__func_success_no_args_returned_value", function()
        local expectedReturnedValue = "foo"
        local test = Test_Group.create({tests = {}, after = function() return expectedReturnedValue end})
        local result, returnedValue = test:run_after()

        Assert.assert_equals(true, result, "Failed validation for after returned result")
        Assert.assert_equals(expectedReturnedValue, returnedValue, "Failed validation for after returned value")
    end)

    add_arg_validations("after", function(test)
        Assert.assert_equals("pending", test.state, "Failed validation for after state property") -- unchanged
        Assert.assert_false(test.running, "Failed validation for after running property") -- unchanged
    end)


    -- Test_Group.run() validations
    add_validation("run__already_done", function()
        local tg = Test_Group.create({})
        tg.done = true
        tg:run()

        Assert.assert_nil(rawget(tg, "state"), "Failed validation for run state value")
    end)
    add_validation("run__running_tests_success", function()
        local afterRan = false
        local tg = Test_Group.create({
            tests = {},
            after = function() afterRan = true end
        })
        local stubTestRunFunc = function()
            if afterRan then error("After test group ran before this test") end
        end
        tg.tests.incomplete = {
            test1 = {run = stubTestRunFunc, state = "succeeded", done = true}
        }
        tg.state = "running"
        tg:run()

        Assert.assert_equals("completed", tg.state, "State after run is invalid")
        Assert.assert_true(tg.done, "Done value is invalid after run")
        Assert.assert_true(afterRan, "After function did not run")
        Assert.assert_equals(0, table_size(tg.tests.incomplete), "Failed validation for count of incomplete tests")
        Assert.assert_equals(1, #tg.tests.succeeded, "Failed validation for count of succeeded tests")
        Assert.assert_equals(0, #tg.tests.skipped, "Failed validation for count of skipped tests")
        Assert.assert_equals(0, #tg.tests.failed, "Failed validation for count of failed tests")
    end)
    add_validation("run__running_tests_skipped", function()
        local afterRan = false
        local tg = Test_Group.create({
            tests = {},
            after = function() afterRan = true end
        })
        local stubTestRunFunc = function()
            if afterRan then error("After test group ran before this test") end
        end
        tg.tests.incomplete = {
            test1 = {run = stubTestRunFunc, state = "skipped", done = true}
        }
        tg.state = "running"
        tg:run()

        Assert.assert_equals("completed", tg.state, "State after run is invalid")
        Assert.assert_true(tg.done, "Done value is invalid after run")
        Assert.assert_true(afterRan, "After function did not run")
        Assert.assert_equals(0, table_size(tg.tests.incomplete), "Failed validation for count of incomplete tests")
        Assert.assert_equals(0, #tg.tests.succeeded, "Failed validation for count of succeeded tests")
        Assert.assert_equals(1, #tg.tests.skipped, "Failed validation for count of skipped tests")
        Assert.assert_equals(0, #tg.tests.failed, "Failed validation for count of failed tests")
    end)
    add_validation("run__running_tests_failed", function()
        local afterRan = false
        local tg = Test_Group.create({
            tests = {},
            after = function() afterRan = true end
        })
        local stubTestRunFunc = function()
            if afterRan then error("After test group ran before this test") end
        end
        tg.tests.incomplete = {
            test1 = {run = stubTestRunFunc, state = "failed", done = true}
        }
        tg.state = "running"
        tg:run()

        Assert.assert_equals("completed", tg.state, "State after run is invalid")
        Assert.assert_true(tg.done, "Done value is invalid after run")
        Assert.assert_true(afterRan, "After function did not run")
        Assert.assert_equals(0, table_size(tg.tests.incomplete), "Failed validation for count of incomplete tests")
        Assert.assert_equals(0, #tg.tests.succeeded, "Failed validation for count of succeeded tests")
        Assert.assert_equals(0, #tg.tests.skipped, "Failed validation for count of skipped tests")
        Assert.assert_equals(1, #tg.tests.failed, "Failed validation for count of failed tests")
    end)
    add_validation("run__running_tests_mixed_bag", function()
        local afterRan = false
        local tg = Test_Group.create({
            tests = {},
            after = function() afterRan = true end
        })
        local stubTestRunFunc = function()
            if afterRan then error("After test group ran before this test") end
        end
        tg.tests.incomplete = {
            test1 = {run = stubTestRunFunc, state = "succeeded", done = true},
            test2 = {run = stubTestRunFunc, state = "skipped", done = true},
            test3 = {run = stubTestRunFunc, state = "skipped", done = true},
            test4 = {run = stubTestRunFunc, state = "failed", done = true},
            test5 = {run = stubTestRunFunc, state = "failed", done = true},
            test6 = {run = stubTestRunFunc, state = "failed", done = true}
        }
        tg.state = "running"
        tg:run()

        Assert.assert_equals("completed", tg.state, "State after run is invalid")
        Assert.assert_true(tg.done, "Done value is invalid after run")
        Assert.assert_true(afterRan, "After function did not run")
        Assert.assert_equals(0, table_size(tg.tests.incomplete), "Failed validation for count of incomplete tests")
        Assert.assert_equals(1, #tg.tests.succeeded, "Failed validation for count of succeeded tests")
        Assert.assert_equals(2, #tg.tests.skipped, "Failed validation for count of skipped tests")
        Assert.assert_equals(3, #tg.tests.failed, "Failed validation for count of failed tests")
    end)
    add_validation("run__pending_before_success", function()
        local beforeRan, skipTestsRan, testsRunning = false, false, false
        local tg = Test_Group.create({
            tests = {function() testsRunning = true end},
            before = function() beforeRan = true end,
            skip_tests = function() skipTestsRan = true end,
        })
        tg.state = "pending"
        tg:run()

        Assert.assert_true(beforeRan, "Before func did not run on pending test group")
        Assert.assert_false(skipTestsRan, "Skip tests ran when before succeeded")
        Assert.assert_true(testsRunning, "Tests func did not run on pending test group")
    end)
    add_validation("run__pending_before_failed", function()
        local beforeRan, skipTestsRan, testsRunning = false, false, false
        local tg = Test_Group.create({
            tests = {function() testsRunning = true end},
            before = function()
                beforeRan = true
                error("i failed")
            end,
            skip_tests = function() skipTestsRan = true end
        })
        tg.state = "pending"
        tg:run()

        Assert.assert_true(beforeRan, "Before func did not run on pending test group")
        Assert.assert_true(skipTestsRan, "Skip tests did not run on skipped test group")
        Assert.assert_false(testsRunning, "Tests func ran on skipped test group")
    end)


    -- Test_Group.skip_tests() validations
    add_validation("skip_tests__two_tests", function()
        local tg = Test_Group.create({tests = {{}, {}}})
        Assert.assert_equals(2, table_size(tg.tests.incomplete), "Failed pre-validation of incomplete tests")
        tg:skip_tests()

        Assert.assert_equals(2, #tg.tests.skipped, "Skipped tests not in skipped table")
        Assert.assert_equals(0, table_size(tg.tests.incomplete), "Tests are still in incomplete table")
        for _, t in ipairs(tg.tests.skipped) do
            Assert.assert_starts_with("Test group skipped", t.error, "Failed validation for test error reason")
            Assert.assert_starts_with("skipped", t.state, "Failed validation for test state")
        end
    end)

    return Validation_Utils.validate(GROUP)
end
