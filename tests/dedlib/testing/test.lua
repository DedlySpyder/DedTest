-- Testing the tests
-- Because if these are crap then so are all other tests *shrug*
local Test = require("__DedLib__/modules/testing/test")
local Assert = require("__DedLib__/modules/testing/assert")

local Validation_Utils = require("validation_utils")
local GROUP = "Test"

local function add_validation(name, func)
    Validation_Utils.add_validation(GROUP, name, func)
end

local function add_one_arg_validations(funcName, extraAsserts, funcNameInTest, funcArgsInTest, testSetup)
    if not testSetup then testSetup = function() end end
    for _, validArgData in ipairs(Validation_Utils._arg_validations[1]) do
        local name, validArg = validArgData["name"], validArgData["value"]
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
    for _, validArgData in ipairs(Validation_Utils._arg_validations[2]) do
        local name, validArgs = validArgData["name"], validArgData["value"]
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

        Assert.assert_equals(1, table_size(tests), "Wrong number of tests returned")
        for _, test in pairs(tests) do
            Assert.assert_equals_exactly(args, test.func, "Function as only arg did not create test")
        end
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

        Assert.assert_equals(0, table_size(tests), "Wrong number of tests returned")
    end)
    add_validation("create_multiple__table_list_1", function()
        local args = {{}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(1, table_size(tests), "Wrong number of tests returned")
        for _, test in pairs(tests) do
            Assert.assert_equals_exactly("Test", test.__which, "Test not returned")
        end
    end)
    add_validation("create_multiple__table_list_2", function()
        local args = {{}, {}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(2, table_size(tests), "Wrong number of tests returned")
        for _, test in pairs(tests) do
            Assert.assert_equals_exactly("Test", test.__which, "Test not returned")
        end
    end)
    add_validation("create_multiple__table_list_named", function()
        local test1Name = "test_1"
        local test2Name = "test_2"
        local args = {{name = test1Name}, {name = test2Name}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(2, table_size(tests), "Wrong number of tests returned")
        Assert.assert_equals_exactly("Test", tests[test1Name].__which, "Test1 not returned")
        Assert.assert_equals_exactly(test1Name, tests[test1Name].name, "Test1 name wrong")
        Assert.assert_equals_exactly("Test", tests[test2Name].__which, "Test2 not returned")
        Assert.assert_equals_exactly(test2Name, tests[test2Name].name, "Test2 name wrong")
    end)
    add_validation("create_multiple__table_list_named_duplicates", function()
        local test1Name = "test_1"
        local test1Func = function() end
        local test2Func = function() end
        local args = {{name = test1Name, func = test1Func}, {name = test1Name, func = test2Func}}
        local tests = Test.create_multiple(args)

        -- Latest test wins on name collisions
        Assert.assert_equals(1, table_size(tests), "Wrong number of tests returned")
        Assert.assert_equals_exactly("Test", tests[test1Name].__which, "Test1 not returned")
        Assert.assert_equals_exactly(test1Name, tests[test1Name].name, "Test1 name wrong")
        Assert.assert_equals_exactly(test2Func, tests[test1Name].func, "Test1 func wrong")
    end)
    add_validation("create_multiple__table_map_1", function()
        local args = {test_foo = {}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(1, table_size(tests), "Wrong number of tests returned")
        for _, test in pairs(tests) do
            Assert.assert_equals_exactly("Test", test.__which, "Test not returned")
            Assert.assert_equals_exactly("test_foo", test.name, "Test name wrong")
        end
    end)
    add_validation("create_multiple__table_map_2", function()
        local args = {test_foo = {}, test_bar = {}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(2, table_size(tests), "Wrong number of tests returned")
        Assert.assert_equals_exactly("Test", tests["test_foo"].__which, "Test not returned")
        Assert.assert_equals_exactly("test_foo", tests["test_foo"].name, "Test name wrong")
        Assert.assert_equals_exactly("test_bar", tests["test_bar"].name, "Test name wrong")
    end)
    add_validation("create_multiple__table_map_ignore_non_test", function()
        local args = {test_foo = {}, bar = {}}
        local tests = Test.create_multiple(args)

        Assert.assert_equals(1, table_size(tests), "Wrong number of tests returned")
        for _, test in pairs(tests) do
            Assert.assert_equals_exactly("Test", test.__which, "Test not returned")
            Assert.assert_equals_exactly("test_foo", test.name, "Test name wrong")
        end
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
    local testValidateGood = function(prop, propValue)
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
    testValidateGood("args", {f = "foo"})
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
    testValidateGood("generateArgsFuncArgs", {f = "foo"})
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
    testValidateGood("beforeArgs", {f = "foo"})
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
    testValidateGood("afterArgs", {f = "foo"})
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


    -- Test.parse_reason validations
    add_validation("parse_reason__string", function()
        local reason = "foo"
        local parsedMessage, parsedStacktrace = Test.parse_reason(reason)
        Assert.assert_equals(reason, parsedMessage, "Failed validation for parsed message")
        Assert.assert_nil(parsedStacktrace, "Failed validation for parsed stacktrace")
    end)
    add_validation("parse_reason__generic_table", function()
        local reason = {"foo"}
        local parsedMessage, parsedStacktrace = Test.parse_reason(reason)
        Assert.assert_equals(serpent.line(reason), parsedMessage, "Failed validation for parsed message")
        Assert.assert_nil(parsedStacktrace, "Failed validation for parsed stacktrace")
    end)
    add_validation("parse_reason__assert_table", function()
        local reason = {message = "msg", stacktrace = "stk"}
        local parsedMessage, parsedStacktrace = Test.parse_reason(reason)
        Assert.assert_equals(reason.message, parsedMessage, "Failed validation for parsed message")
        Assert.assert_equals(reason.stacktrace, parsedStacktrace, "Failed validation for parsed stacktrace")
    end)
    add_validation("parse_reason__assert_table_message_table", function()
        local reason = {message = {"msg"}, stacktrace = "stk"}
        local parsedMessage, parsedStacktrace = Test.parse_reason(reason)
        Assert.assert_equals(serpent.line(reason.message), parsedMessage, "Failed validation for parsed message")
        Assert.assert_equals(reason.stacktrace, parsedStacktrace, "Failed validation for parsed stacktrace")
    end)


    -- Test.set_reason
    add_validation("set_reason__basic_reason", function()
        local test = Test.create({})
        local reason = "foo"
        test:set_reason(reason)

        Assert.assert_equals(reason, test.error, "Failed validation for set message")
        Assert.assert_nil(test.stacktrace, "Failed validation for set stacktrace")
    end)
    add_validation("set_reason__basic_reason_with_prefix", function()
        local test = Test.create({})
        local reason = "foo"
        test:set_reason(reason, "prefix")

        Assert.assert_equals("prefix" .. reason, test.error, "Failed validation for set message")
        Assert.assert_nil(test.stacktrace, "Failed validation for set stacktrace")
    end)
    add_validation("set_reason__table_message_and_stacktrace", function()
        local test = Test.create({})
        local reason = {message = "msg", stacktrace = "stk"}
        test:set_reason(reason)

        Assert.assert_equals(reason.message, test.error, "Failed validation for set message")
        Assert.assert_equals(reason.stacktrace, test.stacktrace, "Failed validation for set stacktrace")
    end)
    add_validation("set_reason__table_message_only", function()
        local test = Test.create({})
        local reason = {message = "msg"}
        test:set_reason(reason)

        Assert.assert_equals(reason.message, test.error, "Failed validation for set message")
        Assert.assert_nil(test.stacktrace, "Failed validation for set stacktrace")
    end)
    add_validation("set_reason__table_message_only_with_prefix", function()
        local test = Test.create({})
        local reason = {message = "msg"}
        test:set_reason(reason, "prefix")

        Assert.assert_equals("prefix" .. reason.message, test.error, "Failed validation for set message")
        Assert.assert_nil(test.stacktrace, "Failed validation for set stacktrace")
    end)
    add_validation("set_reason__table_stacktrace_only", function()
        local test = Test.create({})
        local reason = {stacktrace = "stk"}
        test:set_reason(reason)

        Assert.assert_nil(rawget(test, "error"), "Failed validation for set message")
        Assert.assert_equals(reason.stacktrace, test.stacktrace, "Failed validation for set stacktrace")
    end)
    add_validation("set_reason__table_stacktrace_only_with_prefix", function()
        local test = Test.create({})
        local reason = {stacktrace = "stk"}
        test:set_reason(reason, "prefix")

        Assert.assert_equals("prefix", test.error, "Failed validation for set message")
        Assert.assert_equals(reason.stacktrace, test.stacktrace, "Failed validation for set stacktrace")
    end)

    return Validation_Utils.validate(GROUP)
end
