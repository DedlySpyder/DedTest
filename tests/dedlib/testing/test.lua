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
                42,
                "Failed to create test of type number (expected table or function)",
                "Create did not fail with bad args"
        )
    end)
    add_validation("create__failed_with_boolean", function()
        Assert.assert_throws_error(
                Test.create,
                true,
                "Failed to create test of type boolean (expected table or function)",
                "Create did not fail with bad args"
        )
    end)
    add_validation("create__failed_with_nil", function()
        Assert.assert_throws_error(
                Test.create,
                nil,
                "Failed to create test of type nil (expected table or function)",
                "Create did not fail with bad args"
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
    -- create_multiple
    -- - function arg
    -- - non-table/non-function should fail
    -- - list table of tests
    -- - map table of tests
    -- valid_name
    -- generate name
    -- validate_property (or validate?) (or I could do this through create) for each one, a good and a bad, and force
    -- before
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
