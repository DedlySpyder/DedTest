local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"} -- TODO - removeme - for debugging

local Test_Group = require("__DedLib__/modules/testing/test_group")
local Assert = require("__DedLib__/modules/testing/assert")

local Validation_Utils = require("validation_utils")
local GROUP = "Test_Group"

local function after_each(func)
    return function()
        local s, e = pcall(func)
        Test_Group.reset_all_groups()
        if not s then error(e) end
    end
end

local function add_validation(name, func)
    Validation_Utils.add_validation(GROUP, name, after_each(func))
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
        Assert.assert_equals(1, #Test_Group.get_all_groups().incomplete, "Failed validation for create all groups count")
        Assert.assert_equals(tg, Test_Group.get_all_groups().incomplete[1], "Failed validation for create all groups value")
    end)
    add_validation("create__success_single_test_raw", function()
        local name = "this_is_a_Test"
        local tg = Test_Group.create({name = name})
        Assert.assert_equals("Unnamed Test Group #0", tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals(1, #tg.tests.incomplete, "Failed validation for create test.incomplete count")
        Assert.assert_equals(name, tg.tests.incomplete[1].name, "Failed validation for create first test's name")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
        Assert.assert_equals(1, #Test_Group.get_all_groups().incomplete, "Failed validation for create all groups count")
        Assert.assert_equals(tg, Test_Group.get_all_groups().incomplete[1], "Failed validation for create all groups value")
    end)
    add_validation("create__success_name_and_no_tests", function()
        local name = "this_is_a_Test_Group"
        local tg = Test_Group.create({name = name, tests = {}})
        Assert.assert_starts_with(name, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals({}, tg.tests.incomplete, "Failed validation for create test.incomplete count")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
        Assert.assert_equals(1, #Test_Group.get_all_groups().incomplete, "Failed validation for create all groups count")
        Assert.assert_equals(tg, Test_Group.get_all_groups().incomplete[1], "Failed validation for create all groups value")
    end)
    add_validation("create__success_name_and_one_tests", function()
        local tgName = "this_is_a_Test_Group_for_single_Test"
        local name = "this_is_a_single_Test"
        local tg = Test_Group.create({name = tgName, tests = {{name = name}}})
        Assert.assert_starts_with(tgName, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals(1, #tg.tests.incomplete, "Failed validation for create test.incomplete count")
        Assert.assert_equals(name, tg.tests.incomplete[1].name, "Failed validation for create first test's name")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
        Assert.assert_equals(1, #Test_Group.get_all_groups().incomplete, "Failed validation for create all groups count")
        Assert.assert_equals(tg, Test_Group.get_all_groups().incomplete[1], "Failed validation for create all groups value")
    end)
    add_validation("create__success_name_and_two_tests", function()
        local tgName = "this_is_a_Test_Group_for_two_Tests"
        local t1Name = "this_is_the_first_Test"
        local t2Name = "this_is_the_first_Test"
        local tg = Test_Group.create({name = tgName, tests = {{name = t1Name}, {name = t2Name}}})
        Assert.assert_starts_with(tgName, tg.name, "Failed validation for create name value")
        Assert.assert_not_nil(rawget(tg, "tests"), "Failed validation for create tests value")
        Assert.assert_equals(2, #tg.tests.incomplete, "Failed validation for create test.incomplete count")
        Assert.assert_equals(t1Name, tg.tests.incomplete[1].name, "Failed validation for create first test's name")
        Assert.assert_equals(t2Name, tg.tests.incomplete[2].name, "Failed validation for create second test's name")
        Assert.assert_equals({}, tg.tests.skipped, "Failed validation for create test.skipped value")
        Assert.assert_equals({}, tg.tests.failed, "Failed validation for create test.failed value")
        Assert.assert_equals({}, tg.tests.succeeded, "Failed validation for create test.succeeded value")
        Assert.assert_equals(1, #Test_Group.get_all_groups().incomplete, "Failed validation for create all groups count")
        Assert.assert_equals(tg, Test_Group.get_all_groups().incomplete[1], "Failed validation for create all groups value")
    end)

    add_validation("create__success_multiple_test_groups", function()
        local tg1 = Test_Group.create({})
        Assert.assert_equals("Unnamed Test Group #0", tg1.name, "Failed validation for create name value")
        local tg2 = Test_Group.create({})
        Assert.assert_equals("Unnamed Test Group #1", tg2.name, "Failed validation for create name value")
        Assert.assert_equals(2, #Test_Group.get_all_groups().incomplete, "Failed validation for create all groups count")
        Assert.assert_equals(tg1, Test_Group.get_all_groups().incomplete[1], "Failed validation for create all groups value")
        Assert.assert_equals(tg2, Test_Group.get_all_groups().incomplete[2], "Failed validation for create all groups value")
    end)


    -- Test_Group.generate_name() validations
    add_validation("generate_name__string", function()
        local name = "foo"
        local actualName = Test_Group.generate_name(name)
        Assert.assert_equals(name, actualName, "Failed validation for generate name value")
    end)
    add_validation("generate_name__nil", function()
        local name = nil
        local actualName0 = Test_Group.generate_name(name)
        Assert.assert_equals("Unnamed Test Group #0", actualName0, "Failed validation for generate name value")
    end)
    add_validation("generate_name__nil_number_two", function()
        table.insert(Test_Group.get_all_groups().incomplete, {})
        local name = nil
        local actualName0 = Test_Group.generate_name(name)
        Assert.assert_equals("Unnamed Test Group #1", actualName0, "Failed validation for generate name value")
    end)
    add_validation("generate_name__number", function()
        local name = 42
        local actualName = Test_Group.generate_name(name)
        Assert.assert_equals(tostring(name), actualName, "Failed validation for generate name value")
    end)


    --[[
    validate (see how Test does it)

    before
    after
    run_all?
    run
    - all state
    skip_tests
    --]]
    return Validation_Utils.validate(GROUP)
end
