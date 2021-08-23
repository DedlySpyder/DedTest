-- Testing the tests
-- Because if these are crap then so are all other tests *shrug*
local Logger = require("__DedLib__/modules/logger").create("Testing")
local Test = require("__DedLib__/modules/testing/test")

local Assert = require("__DedLib__/modules/testing/assert")

local test_validations = {}

local function add_validation(name, func)
    table.insert(test_validations, {name = name, func = func})
end

local function validate()
    local count = {succeeded = 0, failed = 0}
    local increment_failed = function() count["failed"] = count["failed"] + 1 end
    local increment_succeeded = function() count["succeeded"] = count["succeeded"] + 1 end

    Logger:info("Running %d Test validations", #test_validations)
    for _, validation in ipairs(test_validations) do
        local name = "Test__" .. validation.name
        local func = validation.func

        Logger:debug("Running validation for: %s", name)
        local s, err = pcall(func)
        if not s then
            Logger:fatal("Failed validation of %s with error: %s", name, err)
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

local arg_validations = {
    {
        string = "foo",
        number = 42,
        boolean_false = false,
        boolean_true = true,
        ["nil"] = nil,
        table_empty = {},
        table_list = {"foo"},
        table_map = {f = "foo"}
    },
    {
        string = {"foo", "bar"},
        number = {42, 100},
        boolean_false = {false, false},
        boolean_true = {true, true},
        ["nil"] = {nil, nil},
        table_empty = {{}, {}},
        table_list = {{"foo"}, {"bar"}},
        table_map = {{f = "foo"}, {b = "bar"}}
    }
}
local function add_one_arg_validations(funcName, extraAsserts, funcNameInTest, funcArgsInTest, testSetup)
    if not testSetup then testSetup = function() end end
    for name, validArg in pairs(arg_validations[1]) do
        add_validation(funcName .. "__func_success_one_arg_" .. name, function()
            local test = Test.create({[funcNameInTest or funcName] = function(arg)
                Assert.assert_equals(validArg, arg)
            end, [funcArgsInTest or funcName .. "Args"] = {validArg}})
            testSetup(test)

            if funcName == "before" or funcName == "after" then
                local result, returnedValue = test["run_" .. funcName](test)
                Assert.assert_equals(true, result, "Failed validation for before returned result")
                Assert.assert_equals(nil, returnedValue, "Failed validation for before returned value")
            else
                test[funcName](test)
            end

            extraAsserts(test)
        end)
    end
end
local function add_two_arg_validations(funcName, extraAsserts, funcNameInTest, funcArgsInTest, testSetup)
    if not testSetup then testSetup = function() end end
    for name, validArgs in pairs(arg_validations[2]) do
        add_validation(funcName .. "__func_success_two_arg_" .. name, function()
            local test = Test.create({[funcNameInTest or funcName] = function(arg1, arg2)
                Assert.assert_equals(validArgs[1], arg1)
                Assert.assert_equals(validArgs[2], arg2)
            end, [funcArgsInTest or funcName .. "Args"] = validArgs})
            testSetup(test)

            if funcName == "before" or funcName == "after" then
                local result, returnedValue = test["run_" .. funcName](test)
                Assert.assert_equals(true, result, "Failed validation for " .. funcName .. " returned result")
                Assert.assert_equals(nil, returnedValue, "Failed validation for " .. funcName .. " returned value")
            else
                test[funcName](test)
            end

            extraAsserts(test)
        end)
    end
end
local function add_arg_validations(funcName, extraAsserts, funcNameInTest, funcArgsInTest, testSetup)
    add_one_arg_validations(funcName, extraAsserts, funcNameInTest, funcArgsInTest, testSetup)
    add_two_arg_validations(funcName, extraAsserts, funcNameInTest, funcArgsInTest, testSetup)
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

    add_arg_validations("before", function(test)
        Assert.assert_equals("running", test.state, "Failed validation for before state property")
        Assert.assert_true(test.running, "Failed validation for before running property")
    end)


    -- Test.run_after()
    -- Assumes that everything is the correct type, because of the validate on test creation
    add_validation("after__no_func", function()
        local test = Test.create({})
        local result, returnedValue = test:run_after()

        Assert.assert_equals(nil, result, "Failed validation for after returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for after returned value")
    end)
    add_validation("after__func_failure", function()
        local errorMessage = "supposed to fail"
        local test = Test.create({after = function() error(errorMessage) end})
        local result, returnedValue = test:run_after()

        Assert.assert_equals(false, result, "Failed validation for after returned result")
        Assert.assert_ends_with(errorMessage, returnedValue, "Failed validation for after returned value")
    end)
    add_validation("after__func_success_no_args", function()
        local test = Test.create({after = function() end})
        local result, returnedValue = test:run_after()

        Assert.assert_equals(true, result, "Failed validation for after returned result")
        Assert.assert_equals(nil, returnedValue, "Failed validation for after returned value")
    end)
    add_validation("after__func_success_no_args_returned_value", function()
        local expectedReturnedValue = "foo"
        local test = Test.create({after = function() return expectedReturnedValue end})
        local result, returnedValue = test:run_after()

        Assert.assert_equals(true, result, "Failed validation for after returned result")
        Assert.assert_equals(expectedReturnedValue, returnedValue, "Failed validation for after returned value")
    end)

    add_arg_validations("after", function(test)
        Assert.assert_equals("pending", test.state, "Failed validation for after state property") -- unchanged
        Assert.assert_false(test.running, "Failed validation for after running property") -- unchanged
    end)


    -- Test.generate_args() validations
    add_validation("generate_args__unset", function()
        local test = Test.create({})
        test:generate_args()

        Assert.assert_equals({}, test.args, "Failed validation for generate args args value")
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__func_failure", function()
        local errorMessage = "supposed to fail"
        local test = Test.create({generateArgsFunc = function() error(errorMessage) end})
        test:generate_args()

        Assert.assert_equals({}, test.args, "Failed validation for generate args args value")
        Assert.assert_equals("skipped", test.state, "Failed validation for generate args state value")
        Assert.assert_ends_with(errorMessage, test.error, "Failed validation for generate args error reason")
    end)

    add_validation("generate_args__no_args_generated", function()
        local generatedArgs = nil
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals({generatedArgs}, test.args, "Failed validation for generate args args value")
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)

    add_validation("generate_args__generated_string", function()
        local generatedArgs = "foo"
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals({generatedArgs}, test.args, "Failed validation for generate args args value")
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_number", function()
        local generatedArgs = 42
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals({generatedArgs}, test.args, "Failed validation for generate args args value")
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_boolean_true", function()
        local generatedArgs = true
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals({generatedArgs}, test.args, "Failed validation for generate args args value")
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_boolean_false", function()
        local generatedArgs = false
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals({generatedArgs}, test.args, "Failed validation for generate args args value")
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_empty_table", function()
        local generatedArgs = {}
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals_exactly(generatedArgs, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(1, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_list_table", function()
        local generatedArgs = {"foo"}
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals_exactly(generatedArgs, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(1, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_map_table", function()
        local generatedArgs = {f = "foo"}
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals_exactly(generatedArgs, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(1, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_function", function()
        local generatedArgs = function() end
        local test = Test.create({generateArgsFunc = function() return generatedArgs end})
        test:generate_args()

        Assert.assert_equals_exactly(generatedArgs, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(1, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)

    add_validation("generate_args__generated_string_two_args", function()
        local generatedArg1 = "foo"
        local generatedArg2 = "bar"
        local test = Test.create({generateArgsFunc = function() return generatedArg1, generatedArg2 end})
        test:generate_args()

        Assert.assert_equals(generatedArg1, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(generatedArg2, test.args[2], "Failed validation for generate args second args value")
        Assert.assert_equals(2, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_number_two_args", function()
        local generatedArg1 = 42
        local generatedArg2 = 100
        local test = Test.create({generateArgsFunc = function() return generatedArg1, generatedArg2 end})
        test:generate_args()

        Assert.assert_equals(generatedArg1, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(generatedArg2, test.args[2], "Failed validation for generate args second args value")
        Assert.assert_equals(2, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_boolean_true_two_args", function()
        local generatedArg1 = true
        local generatedArg2 = true
        local test = Test.create({generateArgsFunc = function() return generatedArg1, generatedArg2 end})
        test:generate_args()

        Assert.assert_equals(generatedArg1, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(generatedArg2, test.args[2], "Failed validation for generate args second args value")
        Assert.assert_equals(2, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_boolean_false_two_args", function()
        local generatedArg1 = false
        local generatedArg2 = false
        local test = Test.create({generateArgsFunc = function() return generatedArg1, generatedArg2 end})
        test:generate_args()

        Assert.assert_equals(generatedArg1, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(generatedArg2, test.args[2], "Failed validation for generate args second args value")
        Assert.assert_equals(2, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_empty_table_two_args", function()
        local generatedArg1 = {}
        local generatedArg2 = {}
        local test = Test.create({generateArgsFunc = function() return generatedArg1, generatedArg2 end})
        test:generate_args()

        Assert.assert_equals(generatedArg1, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(generatedArg2, test.args[2], "Failed validation for generate args second args value")
        Assert.assert_equals(2, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_list_table_two_args", function()
        local generatedArg1 = {"foo"}
        local generatedArg2 = {"bar"}
        local test = Test.create({generateArgsFunc = function() return generatedArg1, generatedArg2 end})
        test:generate_args()

        Assert.assert_equals(generatedArg1, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(generatedArg2, test.args[2], "Failed validation for generate args second args value")
        Assert.assert_equals(2, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_map_table_two_args", function()
        local generatedArg1 = {f = "foo"}
        local generatedArg2 = {b = "bar"}
        local test = Test.create({generateArgsFunc = function() return generatedArg1, generatedArg2 end})
        test:generate_args()

        Assert.assert_equals(generatedArg1, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(generatedArg2, test.args[2], "Failed validation for generate args second args value")
        Assert.assert_equals(2, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)
    add_validation("generate_args__generated_function_two_args", function()
        local generatedArg1 = function() end
        local generatedArg2 = function() end
        local test = Test.create({generateArgsFunc = function() return generatedArg1, generatedArg2 end})
        test:generate_args()

        Assert.assert_equals(generatedArg1, test.args[1], "Failed validation for generate args first args value")
        Assert.assert_equals(generatedArg2, test.args[2], "Failed validation for generate args second args value")
        Assert.assert_equals(2, #test.args, "Failed validation for generate args args length: " .. serpent.line(test.args))
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end)

    add_arg_validations("generate_args", function(test)
        Assert.assert_equals({}, test.args, "Failed validation for generate args args value")
        Assert.assert_equals(Test.state, test.state, "Failed validation for generate args state value")
    end, "generateArgsFunc", "generateArgsFuncArgs")


    -- Test.run() validations
    add_validation("run__already_done", function()
        local test = Test.create({})
        test.done = true
        test:run()

        Assert.assert_nil(rawget(test, "state"), "Failed validation for run state value")
    end)
    add_validation("run__running_success", function()
        local afterRan = false
        local test = Test.create({func = function() end, after = function() afterRan = true end})
        test.state = "running"
        test.running = true
        test:run()

        Assert.assert_equals("succeeded", test.state, "Failed validation for run state value")
        Assert.assert_false(test.running, "Failed validation for run running value")
        Assert.assert_true(test.done, "Failed validation for run done value")
        Assert.assert_true(afterRan, "After function did not run")
    end)
    add_validation("run__running_failed", function()
        local afterRan = false
        local errorMessage = "i failed"
        local test = Test.create({func = function() error(errorMessage) end, after = function() afterRan = true end})
        test.state = "running"
        test.running = true
        test:run()

        Assert.assert_equals("failed", test.state, "Failed validation for run state value")
        Assert.assert_false(test.running, "Failed validation for run running value")
        Assert.assert_true(test.done, "Failed validation for run done value")
        Assert.assert_ends_with(errorMessage, test.error, "Failed validation for run error value")
        Assert.assert_true(afterRan, "After function did not run")
    end)
    add_validation("run__pending", function()
        local beforeRan = false
        local generatedArgsRan = false
        local mainFuncRan = false
        local test = Test.create({
            before = function() beforeRan = true end,
            generateArgsFunc = function() generatedArgsRan = true end,
            func = function() mainFuncRan = true end
        })
        test.state = "pending"
        test:run()

        Assert.assert_true(beforeRan, "Before func did not run on pending test")
        Assert.assert_true(generatedArgsRan, "Generate args func did not run on pending test")
        Assert.assert_true(mainFuncRan, "Main func did not run on pending test")
    end)

    add_arg_validations(
            "run",
            function(test)
                Assert.assert_equals("succeeded", test.state, "Failed validation for run state value")
                Assert.assert_false(test.running, "Failed validation for run running value")
                Assert.assert_true(test.done, "Failed validation for run done value")
            end,
            "func",
            "args",
            function(test)
                test.state = "running"
            end
    )

    -- parse_reason
    -- set_reason
    -- set_skipped (test for reasonPrefix)
    -- set_failed (test for reasonPrefix)

    return validate()
end
