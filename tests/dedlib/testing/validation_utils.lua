-- Testing the tests
-- Because if these are crap then so are all other tests *shrug*
local Logger = require("__DedLib__/modules/logger").create("Testing")

local Validation_Utils = {}

Validation_Utils._arg_validations = {
    {
        {
            name = "string",
            value = "foo"
        },
        {
            name = "number",
            value = 42
        },
        {
            name = "boolean_false",
            value = false
        },
        {
            name = "boolean_true",
            value = true
        },
        {
            name = "nil",
            value = nil
        },
        {
            name = "table_empty",
            value = {}
        },
        {
            name = "table_list",
            value = {"foo", "bar"}
        },
        {
            name = "table_map",
            value = {f = "foo", b = "bar"}
        }
    },
    {
        {
            name = "string",
            value = {"foo", "bar"}
        },
        {
            name = "number",
            value = {42, 100}
        },
        {
            name = "boolean_false",
            value = {false, false}
        },
        {
            name = "boolean_true",
            value = {true, true}
        },
        {
            name = "nil",
            value = {nil, nil}
        },
        {
            name = "table_empty",
            value = {{}, {}}
        },
        {
            name = "table_list",
            value = {{"foo", "bar"}, {"baz", "qux"}}
        },
        {
            name = "table_map",
            value = {{f = "foo", b = "bar"}, {bz = "baz", q = "qux"}}
        }
    }
}

Validation_Utils.test_validations = {}

function Validation_Utils.add_validation(group, name, func)
    local validations = Validation_Utils.test_validations[group]
    if not validations then
        validations = {}
        Validation_Utils.test_validations[group] = validations
    end
    table.insert(validations, {name = name, func = func})
end

function Validation_Utils.validate(group)
    local count = {succeeded = 0, failed = 0}
    local increment_failed = function() count["failed"] = count["failed"] + 1 end
    local increment_succeeded = function() count["succeeded"] = count["succeeded"] + 1 end

    local validations = Validation_Utils.test_validations[group] or {}
    Logger:info("Running %d " .. group .. " validations", #validations)
    for _, validation in ipairs(validations) do
        local name = group .. "__" .. validation.name
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

    Logger:info(group .. " validation results: %s", count)
    if count["failed"] > 0 then
        error(group .. " validations are failing, cannot accurately run other tests at this time. See debug logs for more details.")
    end
    return count
end

return Validation_Utils