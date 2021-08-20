-- Testing the tests
-- Because if these are crap then so are all other tests *shrug*
local Logger = require("__DedLib__/modules/logger").create("Testing")
local Test = require("__DedLib__/modules/testing/test")

local Assert = require("__DedLib__/modules/testing/assert")

local test_validations = {succeeded = 0, failed = 0}

function add_validation(name, func)
    table.insert(test_validations, {name = name, func = func})
end

function validate()
    local count = {succeeded = 0, failed = 0}
    local increment_failed = function() count["failed"] = count["failed"] + 1 end
    local increment_succeeded = function() count["succeeded"] = count["succeeded"] + 1 end

    Logger:info("Running %d Test validations", #test_validations)
    for _, validation in ipairs(test_validations) do
        local name = validation.name
        local func = validation.func

        Logger:debug("Running validation for Test: %s", name)
        local s, err = pcall(func)
        if not s then
            Logger:fatal("Failed validation of Test %s with error: %s", name, err)
            increment_failed()
        else
            increment_succeeded()
        end
    end

    Logger:info("Test validation results: %s", count)
    if count["failed"] > 0 then
        error("Test validations are failing, cannot accurately run other tests at this time. See debug logs for more details.")
    end
    return count
end

return function()
    -- Test.create() validations
    add_validation("create__name", function()
        local test = Test.create({}, "test_name")

        Assert.assert_equals("test_name", test.name, "Test name not assigned")
    end)
    add_validation("create__name_args_priority", function()
        local test = Test.create({name = "priority_test_name"}, "test_name")

        Assert.assert_equals("priority_test_name", test.name, "Test name not assigned to priority name")
    end)

    add_validation("create__function_arg", function()
        local args = function() end
        local test = Test.create(args)

        Assert.assert_equals_exactly(args, test.func, "Function as only arg did not create test")
    end)
    add_validation("create__failed_with_number", function()
        Assert.assert_throws_error(
                Test.create,
                "foo",
                "Failed to create test of type string (expected table or function)",
                "Create did not fail with bad args, number"
        )
    end)
    add_validation("create__failed_with_number", function()
        Assert.assert_throws_error(
                Test.create,
                42,
                "Failed to create test of type number (expected table or function)",
                "Create did not fail with bad args, number"
        )
    end)
    add_validation("create__failed_with_boolean", function()
        Assert.assert_throws_error(
                Test.create,
                true,
                "Failed to create test of type boolean (expected table or function)",
                "Create did not fail with bad args, boolean"
        )
    end)
    add_validation("create__failed_with_nil", function()
        Assert.assert_throws_error(
                Test.create,
                nil,
                "Failed to create test of type nil (expected table or function)",
                "Create did not fail with bad args, nil"
        )
    end)

    add_validation("create__no_op_with_test", function()
        local args = Test.create({})
        local test = Test.create(args)

        Assert.assert_equals_exactly(args, test, "Test as arg did not return test")
    end)

    add_validation("create__test_location", function()
        local func = function() end
        local test = Test.create({func = func})

        Assert.assert_starts_with(debug.getinfo(func).short_src, test.test_location, "Test location does not contain this file name")
    end)


    -- Test.create_multiple() validations
    add_validation("create_multiple__function_arg", function()
        local args = function() end
        local tests = Test.create_multiple(args)

        Assert.assert_equals(1, #tests, "Wrong number of tests returned")
        Assert.assert_equals_exactly(args, tests[1].func, "Function as only arg did not create test")
    end)
    add_validation("create_multiple__failed_with_number", function()
        Assert.assert_throws_error(
                Test.create_multiple,
                "foo",
                "Failed to create tests of type string (expected table or function)",
                "Create multiple did not fail with bad args, number"
        )
    end)
    add_validation("create_multiple__failed_with_number", function()
        Assert.assert_throws_error(
                Test.create_multiple,
                42,
                "Failed to create tests of type number (expected table or function)",
                "Create multiple did not fail with bad args, number"
        )
    end)
    add_validation("create_multiple__failed_with_boolean", function()
        Assert.assert_throws_error(
                Test.create_multiple,
                true,
                "Failed to create tests of type boolean (expected table or function)",
                "Create multiple did not fail with bad args, boolean"
        )
    end)
    add_validation("create_multiple__failed_with_nil", function()
        Assert.assert_throws_error(
                Test.create_multiple,
                nil,
                "Failed to create tests of type nil (expected table or function)",
                "Create multiple did not fail with bad args, nil"
        )
    end)

    add_validation("create_multiple__table_empty", function()
        local args = {}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(0, #tests, "Wrong number of tests returned")
    end)
    add_validation("create_multiple__table_list_1", function()
        local args = {{}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(1, #tests, "Wrong number of tests returned")
        Assert.assert_equals_exactly("Test", tests[1].__which, "Test not returned")
    end)
    add_validation("create_multiple__table_list_2", function()
        local args = {{}, {}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(2, #tests, "Wrong number of tests returned")
        Assert.assert_equals_exactly("Test", tests[1].__which, "Test not returned")
    end)
    add_validation("create_multiple__table_map_1", function()
        local args = {test_foo = {}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(1, #tests, "Wrong number of tests returned")
        Assert.assert_equals_exactly("Test", tests[1].__which, "Test not returned")
        Assert.assert_equals_exactly("test_foo", tests[1].name, "Test name wrong")
    end)
    add_validation("create_multiple__table_map_2", function()
        local args = {test_foo = {}, test_bar = {}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(2, #tests, "Wrong number of tests returned")
        Assert.assert_equals_exactly("Test", tests[1].__which, "Test not returned")
        Assert.assert_equals_exactly("test_foo", tests[1].name, "Test name wrong")
        Assert.assert_equals_exactly("test_bar", tests[2].name, "Test name wrong")
    end)
    add_validation("create_multiple__table_map_ignore_non_test", function()
        local args = {test_foo = {}, bar = {}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(1, #tests, "Wrong number of tests returned")
        Assert.assert_equals_exactly("Test", tests[1].__which, "Test not returned")
        Assert.assert_equals_exactly("test_foo", tests[1].name, "Test name wrong")
    end)


    -- Test.valid_name validations
    add_validation("valid_name__string_with_test", function()
        local name = "test_foo"
        local actual = Test.valid_name(name)
        Assert.assert_true(actual, "Failed validation for name: " .. serpent.line(name))
    end)
    add_validation("valid_name__string_with_test_uppercase", function()
        local name = "Test_Foo"
        local actual = Test.valid_name(name)
        Assert.assert_true(actual, "Failed validation for name: " .. serpent.line(name))
    end)
    add_validation("valid_name__string_without_test", function()
        local name = "foo"
        local actual = Test.valid_name(name)
        Assert.assert_false(actual, "Failed validation for name: " .. serpent.line(name))
    end)
    add_validation("valid_name__number", function()
        local name = 42
        local actual = Test.valid_name(name)
        Assert.assert_true(actual, "Failed validation for name: " .. serpent.line(name))
    end)
    add_validation("valid_name__boolean", function()
        local name = true
        local actual = Test.valid_name(name)
        Assert.assert_false(actual, "Failed validation for name: " .. serpent.line(name))
    end)
    add_validation("valid_name__nil", function()
        local name = nil
        local actual = Test.valid_name(name)
        Assert.assert_false(actual, "Failed validation for name: " .. serpent.line(name))
    end)
    add_validation("valid_name__table", function()
        local name = {}
        local actual = Test.valid_name(name)
        Assert.assert_false(actual, "Failed validation for name: " .. serpent.line(name))
    end)
    add_validation("valid_name__function", function()
        local name = function() end
        local actual = Test.valid_name(name)
        Assert.assert_false(actual, "Failed validation for name: " .. serpent.line(name))
    end)


    -- Test.generate_name validations
    add_validation("generate_name__string", function()
        local name = "foo"
        local actual = Test.generate_name(name)
        Assert.assert_equals(name, actual, "Failed validation for generate name: " .. serpent.line(name))
    end)
    add_validation("generate_name__number", function()
        local name = 42
        local actual = Test.generate_name(name)
        Assert.assert_equals("Unnamed Test #" .. name, actual, "Failed validation for generate name: " .. serpent.line(name))
    end)
    add_validation("generate_name__nil", function()
        local name = nil
        local actual = Test.generate_name(name)
        Assert.assert_starts_with("Unnamed Test #", actual, "Failed validation for generate name: " .. serpent.line(name))
    end)
    add_validation("generate_name__boolean", function()
        local name = true
        local actual = Test.generate_name(name)
        Assert.assert_equals("Test: " .. tostring(name), actual, "Failed validation for generate name: " .. serpent.line(name))
    end)
    add_validation("generate_name__table", function()
        local name = {"foo"}
        local actual = Test.generate_name(name)
        Assert.assert_equals("Test: " .. serpent.line(name), actual, "Failed validation for generate name: " .. serpent.line(name))
    end)
    add_validation("generate_name__function", function()
        local name = function() end
        local actual = Test.generate_name(name)
        Assert.assert_equals("Test: <function>", actual, "Failed validation for generate name: " .. serpent.line(name))
    end)


    -- Test.validate() validations
    local makeTestForValidateTests = function(prop, propValue)
        local t = {[prop] = propValue}
        setmetatable(t, Test)
        return t
    end
    local testValidateGood = function(prop, propValue, toList)
        local propType = type(propValue)
        local suffix = "_" .. serpent.line(propValue)
        if propType == "function" then suffix = "" end
        add_validation("validate__" .. prop .. "_good_" .. propType .. suffix, function()
            local test = makeTestForValidateTests(prop, propValue)
            -- Should succeed
            Test.validate(test)

            if propType == "table" then -- Validate should change it to a list
                if #propValue == 0 and table_size(propValue) > 0 then
                    Assert.assert_true(#test[prop] > 0, "Validate did not change " .. prop .. " to a list")
                    Assert.assert_equals({propValue}, rawget(test, prop), "Value not made into a list")
                else
                    Assert.assert_equals(propValue, rawget(test, prop), "Value made into a list when not needed")
                end
            end
        end)
    end
    local testValidateBad = function(prop, propValue)
        local propType = type(propValue)
        add_validation("validate__" .. prop .. "_bad_" .. propType, function()
            local test = makeTestForValidateTests(prop, propValue)
            Assert.assert_throws_error(
                    Test.validate,
                    {test},
                    "failed validation for " .. prop .. ", see logs for more details",
                    "Validate did not fail with " .. prop .. " as " .. propType
            )
        end)
    end
    testValidateGood("args", {})
    testValidateGood("args", {"foo"}) -- Doesn't need to listed
    testValidateGood("args", {f = "foo"}, true)
    testValidateGood("args", nil)
    testValidateBad("args", "foo")
    testValidateBad("args", 42)
    testValidateBad("args", true)
    testValidateBad("args", function() end)

    testValidateGood("generateArgsFunc", function() end)
    testValidateGood("generateArgsFunc", nil)
    testValidateBad("generateArgsFunc", "foo")
    testValidateBad("generateArgsFunc", 42)
    testValidateBad("generateArgsFunc", true)
    testValidateBad("generateArgsFunc", {})

    testValidateGood("generateArgsFuncArgs", {})
    testValidateGood("generateArgsFuncArgs", {"foo"})
    testValidateGood("generateArgsFuncArgs", {f = "foo"}, true)
    testValidateGood("generateArgsFuncArgs", nil)
    testValidateBad("generateArgsFuncArgs", "foo")
    testValidateBad("generateArgsFuncArgs", 42)
    testValidateBad("generateArgsFuncArgs", true)
    testValidateBad("generateArgsFuncArgs", function() end)

    testValidateGood("func", function() end)
    testValidateGood("func", nil)
    testValidateBad("func", "foo")
    testValidateBad("func", 42)
    testValidateBad("func", true)
    testValidateBad("func", {})

    testValidateGood("before", function() end)
    testValidateGood("before", nil)
    testValidateBad("before", "foo")
    testValidateBad("before", 42)
    testValidateBad("before", true)
    testValidateBad("before", {})

    testValidateGood("beforeArgs", {})
    testValidateGood("beforeArgs", {"foo"})
    testValidateGood("beforeArgs", {f = "foo"}, true)
    testValidateGood("beforeArgs", nil)
    testValidateBad("beforeArgs", "foo")
    testValidateBad("beforeArgs", 42)
    testValidateBad("beforeArgs", true)
    testValidateBad("beforeArgs", function() end)

    testValidateGood("after", function() end)
    testValidateGood("after", nil)
    testValidateBad("after", "foo")
    testValidateBad("after", 42)
    testValidateBad("after", true)
    testValidateBad("after", {})

    testValidateGood("afterArgs", {})
    testValidateGood("afterArgs", {"foo"})
    testValidateGood("afterArgs", {f = "foo"}, true)
    testValidateGood("afterArgs", nil)
    testValidateBad("afterArgs", "foo")
    testValidateBad("afterArgs", 42)
    testValidateBad("afterArgs", true)
    testValidateBad("afterArgs", function() end)


    -- Test.run_before()
    -- Assumes that everything is the correct type, because of the validate on test creation
    add_validation("before__no_func", function()
        local test = Test.create({})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(nil, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_failure", function()
        local errorMessage = "supposed to fail"
        local test = Test.create({before = function() error(errorMessage) end})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(false, result, "Failed validation for before returned result")
        Assert.assert_ends_with(errorMessage, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("skipped", test.state, "Failed validation for before state property")
        Assert.assert_false(test.running, "Failed validation for before running property")
        Assert.assert_true(test.done, "Failed validation for before done property")
    end)
    add_validation("before__func_success_no_args", function()
        local test = Test.create({before = function() end})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_no_args_returned_value", function()
        local expectedReturnedValue = "foo"
        local test = Test.create({before = function() return expectedReturnedValue end})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(expectedReturnedValue, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)

    add_validation("before__func_success_one_arg_string", function()
        local beforeArg = "foo"
        local test = Test.create({before = function(arg)
            Assert.assert_equals(beforeArg, arg)
        end, beforeArgs = {beforeArg}})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_one_arg_number", function()
        local beforeArg = 42
        local test = Test.create({before = function(arg)
            Assert.assert_equals(beforeArg, arg)
        end, beforeArgs = {beforeArg}})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_one_arg_boolean", function()
        local beforeArg = true
        local test = Test.create({before = function(arg)
            Assert.assert_equals(beforeArg, arg)
        end, beforeArgs = {beforeArg}})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_one_arg_nil", function()
        local beforeArg = nil
        local test = Test.create({before = function(arg)
            Assert.assert_equals(beforeArg, arg)
        end, beforeArgs = {beforeArg}})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_one_arg_table", function()
        local beforeArg = {f = "foo"}
        local test = Test.create({before = function(arg)
            Assert.assert_equals(beforeArg, arg)
        end, beforeArgs = {beforeArg}})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_one_arg_function", function()
        local beforeArg = function() end
        local test = Test.create({before = function(arg)
            Assert.assert_equals(beforeArg, arg)
        end, beforeArgs = {beforeArg}})
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)

    add_validation("before__func_success_two_args_string", function()
        local beforeArgs = {"foo", "bar"}
        local test = Test.create({before = function(arg1, arg2)
            Assert.assert_equals(beforeArgs[1], arg1)
            Assert.assert_equals(beforeArgs[2], arg2)
        end, beforeArgs = beforeArgs })
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_two_args_number", function()
        local beforeArgs = {42, 200}
        local test = Test.create({before = function(arg1, arg2)
            Assert.assert_equals(beforeArgs[1], arg1)
            Assert.assert_equals(beforeArgs[2], arg2)
        end, beforeArgs = beforeArgs })
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_two_args_boolean", function()
        local beforeArgs = {true, false}
        local test = Test.create({before = function(arg1, arg2)
            Assert.assert_equals(beforeArgs[1], arg1)
            Assert.assert_equals(beforeArgs[2], arg2)
        end, beforeArgs = beforeArgs })
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_two_args_nil", function()
        local beforeArgs = {nil, nil}
        local test = Test.create({before = function(arg1, arg2)
            Assert.assert_equals(beforeArgs[1], arg1)
            Assert.assert_equals(beforeArgs[2], arg2)
        end, beforeArgs = beforeArgs })
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_two_args_table", function()
        local beforeArgs = {{f = "foo"}, {b = "bar"}}
        local test = Test.create({before = function(arg1, arg2)
            Assert.assert_equals(beforeArgs[1], arg1)
            Assert.assert_equals(beforeArgs[2], arg2)
        end, beforeArgs = beforeArgs })
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)
    add_validation("before__func_success_two_args_function", function()
        local beforeArgs = {function() end, function() end}
        local test = Test.create({before = function(arg1, arg2)
            Assert.assert_equals(beforeArgs[1], arg1)
            Assert.assert_equals(beforeArgs[2], arg2)
        end, beforeArgs = beforeArgs })
        local result, returnedValue = test:run_before()

        Assert.assert_equals(true, result, "Failed validation for before returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)

    -- after
    -- generate args (should overwrite base args)
    -- - single returned value
    -- - multiple returned values
    -- run
    -- - success
    -- - fail
    -- - pending test runs before (or tries to if it doesn't have one) & runs generate args func & then runs the main test
    -- parse_reason
    -- set_reason
    -- set_skipped (test for reasonPrefix)
    -- set_failed (test for reasonPrefix)

    validate()
    return test_validations
end
