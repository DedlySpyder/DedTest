local Logger = require("__DedLib__/modules/logger").create("Testing")
local Assert = require("__DedLib__/modules/testing/assert")
local Util = require("__DedLib__/modules/util")

local test_counts = {succeeded = 0, failed = 0}

local increment_test_failed = function()
    test_counts["failed"] = test_counts["failed"] + 1
end

local increment_test_succeeded = function()
    test_counts["succeeded"] = test_counts["succeeded"] + 1
end

local test_assert = function(assertFuncName, x, y, wantSuccess)
    local s, e = pcall(Assert[assertFuncName], x, y)
    if type(x) == "function" then x = "FUNCTION" end
    if type(y) == "function" then y = "FUNCTION" end
    if s then
        if wantSuccess then
            Logger:debug("Assert func <" .. assertFuncName .. ">, Expected success, and got success <" .. serpent.line(x) .. "> to <" .. serpent.line(y) .. ">")
            increment_test_succeeded()
        else
            Logger:fatal("Assert func <" .. assertFuncName .. ">, Expected failure, but got success <" .. serpent.line(x) .. "> to <" .. serpent.line(y) .. ">")
            local info = debug.getinfo(2, "Sl")
            Logger:debug("Failed validation at: %s:%s", info.short_src, info.currentline)
            increment_test_failed()
        end
    else
        if wantSuccess then
            Logger:fatal("Assert func <" .. assertFuncName .. ">, Expected success, but got failure <" .. serpent.line(x) .. "> to <" .. serpent.line(y) .. ">")
            local info = debug.getinfo(2, "Sl")
            Logger:debug("Failed validation at: %s:%s", info.short_src, info.currentline)
            Logger:trace(e)
            increment_test_failed()
        else
            Logger:debug("Assert func <" .. assertFuncName .. ">, Expected failure, and got failure <" .. serpent.line(x) .. "> to <" .. serpent.line(y) .. ">")
            Logger:trace(e)
            increment_test_succeeded()
        end
    end
end

local test_assert_3 = function(assertFuncName, x, y, z, wantSuccess)
    local s, e = pcall(Assert[assertFuncName], x, y, z)
    if type(x) == "function" then x = "FUNCTION" end
    if type(y) == "function" then y = "FUNCTION" end
    if type(z) == "function" then z = "FUNCTION" end
    if s then
        if wantSuccess then
            Logger:debug("Assert func <" .. assertFuncName .. ">, Expected success, and got success: <" .. serpent.line(x) .. ">, <" .. serpent.line(y) .. ">, <" .. serpent.line(z) .. ">")
            increment_test_succeeded()
        else
            Logger:fatal("Assert func <" .. assertFuncName .. ">, Expected failure, but got success: <" .. serpent.line(x) .. ">, <" .. serpent.line(y) .. ">, <" .. serpent.line(z) .. ">")
            local info = debug.getinfo(2, "Sl")
            Logger:debug("Failed validation at: %s:%s", info.short_src, info.currentline)
            increment_test_failed()
        end
    else
        if wantSuccess then
            Logger:fatal("Assert func <" .. assertFuncName .. ">, Expected success, but got failure: <" .. serpent.line(x) .. ">, <" .. serpent.line(y) .. ">, <" .. serpent.line(z) .. ">")
            local info = debug.getinfo(2, "Sl")
            Logger:debug("Failed validation at: %s:%s", info.short_src, info.currentline)
            Logger:trace(e)
            increment_test_failed()
        else
            Logger:debug("Assert func <" .. assertFuncName .. ">, Expected failure, and got failure: <" .. serpent.line(x) .. ">, <" .. serpent.line(y) .. ">, <" .. serpent.line(z) .. ">")
            Logger:trace(e)
            increment_test_succeeded()
        end
    end
end

return function()
    local testAssertFailed = function(message, assertType, assertVar1Name, assertVar1Value, assertVar2Name, assertVar2Value, testErrorFunc)
        local s, e = pcall(Assert._fail, message, assertType, assertVar1Name, assertVar1Value, assertVar2Name, assertVar2Value)
        if s then -- This should always fail
            Logger:fatal("Assert._fail test didn't error as expected")
            increment_test_failed()
        elseif e == nil then
            Logger:fatal("Assert._fail missing error")
            increment_test_failed()
        elseif e["message"] == nil then
            Logger:fatal("Assert._fail missing message")
            increment_test_failed()
        elseif e["stacktrace"] == nil then
            Logger:fatal("Assert._fail missing stacktrace")
            increment_test_failed()
        else
            if testErrorFunc and not testErrorFunc(e) then
                Logger:fatal("Failed error check for Assert._fail: %s", e)
                increment_test_failed()
            end
        end
        increment_test_succeeded()
    end
    Logger:debug("Testing Assert._fail()")
    Logger:trace("Testing Assert._fail() with error message")
    testAssertFailed("err_msg", "t_type", "var1", "val1", "var2", "val2", function(e)
        return Util.String.starts_with(e["message"], "err_msg\n")
    end)

    Logger:trace("Testing Assert._fail() without error message")
    testAssertFailed(nil, "t_type", "var1", "val1", "var2", "val2", function(e)
        return Util.String.starts_with(e["message"], "Assertion ")
    end)

    Logger:trace("Testing Assert._fail() with var2 & val2")
    testAssertFailed("err_msg", "t_type", "var1", "val1", "var2", "val2", function(e)
        return string.find(e["message"], "var2")
    end)

    Logger:trace("Testing Assert._fail() without var2 & val2")
    testAssertFailed("err_msg", "t_type", "var1", "val1", nil, nil, function(e)
        return string.find(e["message"], "var2") == nil
    end)



    Logger:debug("Testing assert_nil")
    test_assert("assert_nil", nil, "message", true)
    test_assert("assert_nil", "literally anything else", "message", false)


    Logger:debug("Testing assert_not_nil")
    test_assert("assert_not_nil", nil, "message", false)
    test_assert("assert_not_nil", "literally anything else", "message", true)


    Logger:debug("Testing assert_true")
    test_assert("assert_true", true, "message", true)
    test_assert("assert_true", "value", "message", true)
    test_assert("assert_true", false, "baz", false)
    test_assert("assert_true", nil, "baz", false)


    Logger:debug("Testing assert_false")
    test_assert("assert_false", true, "message", false)
    test_assert("assert_false", "value", "message", false)
    test_assert("assert_false", false, "baz", true)
    test_assert("assert_false", nil, "baz", true)


    Logger:debug("Testing assert_equals - string")
    test_assert("assert_equals", "foobar", "foobar", true)
    test_assert("assert_equals", "foobar", "baz", false)

    Logger:debug("Testing assert_equals - int")
    test_assert("assert_equals", 42, 42, true)
    test_assert("assert_equals", 42, 1, false)

    Logger:debug("Testing assert_equals - float")
    test_assert("assert_equals", 4.2, 4.2, true)
    test_assert("assert_equals", 4.2, 0.5, false)

    Logger:debug("Testing assert_equals - float to int")
    test_assert("assert_equals", 4.0, 4, true)

    Logger:debug("Testing assert_equals - table")
    test_assert("assert_equals", {foo = "bar"}, {foo = "bar"}, true)
    test_assert("assert_equals", {foo = "bar"}, {foo = "quz"}, false)


    Logger:debug("Testing assert_equals_exactly - string")
    test_assert("assert_equals_exactly", "foobar", "foobar", true)
    test_assert("assert_equals_exactly", "foobar", "baz", false)

    Logger:debug("Testing assert_equals_exactly - int")
    test_assert("assert_equals_exactly", 42, 42, true)
    test_assert("assert_equals_exactly", 42, 1, false)

    Logger:debug("Testing assert_equals_exactly - float")
    test_assert("assert_equals_exactly", 4.2, 4.2, true)
    test_assert("assert_equals_exactly", 4.2, 0.5, false)

    Logger:debug("Testing assert_equals_exactly - float to int")
    test_assert("assert_equals_exactly", 4.0, 4, true)

    Logger:debug("Testing assert_equals_exactly - table")
    test_assert("assert_equals_exactly", {foo = "bar"}, {foo = "bar"}, false)
    test_assert("assert_equals_exactly", {foo = "bar"}, {foo = "quz"}, false)

    Logger:debug("Testing assert_equals_exactly - table same reference")
    local assertEqualsExactlyTableRef = {foo = "bar"}
    test_assert("assert_equals_exactly", assertEqualsExactlyTableRef, assertEqualsExactlyTableRef, true)


    Logger:debug("Testing assert_starts_with - string")
    test_assert("assert_starts_with", "foob", "foobar", true)
    test_assert("assert_starts_with", "baz", "foobar", false)

    Logger:debug("Testing assert_starts_with - int")
    test_assert("assert_starts_with", 42, "42foobar", true)

    Logger:debug("Testing assert_starts_with - float")
    test_assert("assert_starts_with", 4.2, "4.2foobar", true)

    Logger:debug("Testing assert_starts_with - table")
    test_assert("assert_starts_with", {foo = "bar"}, "{foo = \"bar\"}", false) -- This is just for strings


    Logger:debug("Testing assert_ends_with - string")
    test_assert("assert_ends_with", "obar", "foobar", true)
    test_assert("assert_ends_with", "baz", "foobar", false)

    Logger:debug("Testing assert_ends_with - int")
    test_assert("assert_ends_with", 42, "foobar42", true)

    Logger:debug("Testing assert_ends_with - float")
    test_assert("assert_ends_with", 4.2, "foobar4.2", true)

    Logger:debug("Testing assert_ends_with - table")
    test_assert("assert_ends_with", {foo = "bar"}, "{foo = \"bar\"}", false) -- This is just for strings


    Logger:debug("Testing assert_contains - string")
    test_assert("assert_contains", "foo", {"foo", "bar", "baz"}, true)
    test_assert("assert_contains", "foo", {a = "foo", b = "bar", c = "baz"}, true)
    test_assert("assert_contains", "qux", {"foo", "bar", "baz"}, false)
    test_assert("assert_contains", "qux", {a = "foo", b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains - int")
    test_assert("assert_contains", 42, {42, "bar", "baz"}, true)
    test_assert("assert_contains", 42, {a = 42, b = "bar", c = "baz"}, true)
    test_assert("assert_contains", 42, {a = 42, b = "bar", c = "baz"}, true)
    test_assert("assert_contains", 1, {42, "bar", "baz"}, false)
    test_assert("assert_contains", 1, {a = 42, b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains - int to string")
    test_assert("assert_contains", 42, {"42", "bar", "baz"}, false)
    test_assert("assert_contains", 42, {a = "42", b = "bar", c = "baz"}, false)
    test_assert("assert_contains", 42, {a = "42", b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains - float")
    test_assert("assert_contains", 4.2, {4.2, "bar", "baz"}, true)
    test_assert("assert_contains", 4.2, {a = 4.2, b = "bar", c = "baz"}, true)
    test_assert("assert_contains", 4.2, {a = 4.2, b = "bar", c = "baz"}, true)
    test_assert("assert_contains", 1, {4.2, "bar", "baz"}, false)
    test_assert("assert_contains", 1, {a = 4.2, b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains - float to string")
    test_assert("assert_contains", 4.2, {"4.2", "bar", "baz"}, false)
    test_assert("assert_contains", 4.2, {a = "4.2", b = "bar", c = "baz"}, false)
    test_assert("assert_contains", 4.2, {a = "4.2", b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains - table")
    test_assert("assert_contains", {"foo"}, {{"foo"}, {"bar"}, {"baz"}}, true)
    test_assert("assert_contains", {a = "foo"}, {{a = "foo"}, {b = "bar"}, {c = "baz"}}, true)
    test_assert("assert_contains", {"qux"}, {{"foo"}, {"bar"}, {"baz"}}, false)
    test_assert("assert_contains", {d = "qux"}, {{a = "foo"}, {b = "bar"}, {c = "baz"}}, false)
    test_assert("assert_contains", {a = "qux"}, {{a = "foo"}, {b = "bar"}, {c = "baz"}}, false)
    test_assert("assert_contains", {d = "foo"}, {{a = "foo"}, {b = "bar"}, {c = "baz"}}, false)


    Logger:debug("Testing assert_contains_exactly - string")
    test_assert("assert_contains_exactly", "foo", {"foo", "bar", "baz"}, true)
    test_assert("assert_contains_exactly", "foo", {a = "foo", b = "bar", c = "baz"}, true)
    test_assert("assert_contains_exactly", "qux", {"foo", "bar", "baz"}, false)
    test_assert("assert_contains_exactly", "qux", {a = "foo", b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains_exactly - int")
    test_assert("assert_contains_exactly", 42, {42, "bar", "baz"}, true)
    test_assert("assert_contains_exactly", 42, {a = 42, b = "bar", c = "baz"}, true)
    test_assert("assert_contains_exactly", 42, {a = 42, b = "bar", c = "baz"}, true)
    test_assert("assert_contains_exactly", 1, {42, "bar", "baz"}, false)
    test_assert("assert_contains_exactly", 1, {a = 42, b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains_exactly - int to string")
    test_assert("assert_contains_exactly", 42, {"42", "bar", "baz"}, false)
    test_assert("assert_contains_exactly", 42, {a = "42", b = "bar", c = "baz"}, false)
    test_assert("assert_contains_exactly", 42, {a = "42", b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains_exactly - float")
    test_assert("assert_contains_exactly", 4.2, {4.2, "bar", "baz"}, true)
    test_assert("assert_contains_exactly", 4.2, {a = 4.2, b = "bar", c = "baz"}, true)
    test_assert("assert_contains_exactly", 4.2, {a = 4.2, b = "bar", c = "baz"}, true)
    test_assert("assert_contains_exactly", 1, {4.2, "bar", "baz"}, false)
    test_assert("assert_contains_exactly", 1, {a = 4.2, b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains_exactly - float to string")
    test_assert("assert_contains_exactly", 4.2, {"4.2", "bar", "baz"}, false)
    test_assert("assert_contains_exactly", 4.2, {a = "4.2", b = "bar", c = "baz"}, false)
    test_assert("assert_contains_exactly", 4.2, {a = "4.2", b = "bar", c = "baz"}, false)

    Logger:debug("Testing assert_contains_exactly - table")
    test_assert("assert_contains_exactly", {"foo"}, {{"foo"}, {"bar"}, {"baz"}}, false)
    test_assert("assert_contains_exactly", {a = "foo"}, {{a = "foo"}, {b = "bar"}, {c = "baz"}}, false)
    test_assert("assert_contains_exactly", {"qux"}, {{"foo"}, {"bar"}, {"baz"}}, false)
    test_assert("assert_contains_exactly", {d = "qux"}, {{a = "foo"}, {b = "bar"}, {c = "baz"}}, false)
    test_assert("assert_contains_exactly", {a = "qux"}, {{a = "foo"}, {b = "bar"}, {c = "baz"}}, false)
    test_assert("assert_contains_exactly", {d = "foo"}, {{a = "foo"}, {b = "bar"}, {c = "baz"}}, false)

    Logger:debug("Testing assert_contains_exactly - table same reference")
    local assertContainsExactlyTableRef = {a = "foo"}
    test_assert("assert_contains_exactly", assertContainsExactlyTableRef, {assertContainsExactlyTableRef, {b = "bar"}, {c = "baz"}}, true)


    Logger:debug("Testing assert_throws_error - no expected error")
    test_assert_3("assert_throws_error", function() end, nil, nil, false)
    test_assert_3("assert_throws_error", function() error("foo") end, nil, nil, true)

    Logger:debug("Testing assert_throws_error - with expected error - string")
    test_assert_3("assert_throws_error", function() error("foo") end, nil, "foo", true)
    test_assert_3("assert_throws_error", function() error("foo") end, nil, "bar", false)

    Logger:debug("Testing assert_throws_error - with expected error - int")
    test_assert_3("assert_throws_error", function() error(42) end, nil, 42, true)
    test_assert_3("assert_throws_error", function() error(42) end, nil, 1, false)

    Logger:debug("Testing assert_throws_error - with expected error - float")
    test_assert_3("assert_throws_error", function() error(4.2) end, nil, 4.2, true)
    test_assert_3("assert_throws_error", function() error(4.2) end, nil, 0.5, false)

    Logger:debug("Testing assert_throws_error - with expected error - table")
    test_assert_3("assert_throws_error", function() error({"foo"}) end, nil, {"foo"}, true)
    test_assert_3("assert_throws_error", function() error({"foo"}) end, nil, {"bar"}, false)
    test_assert_3("assert_throws_error", function() error({a = "foo"}) end, nil, {a = "foo"}, true)
    test_assert_3("assert_throws_error", function() error({a = "foo"}) end, nil, {a = "bar"}, false)

    Logger:debug("Testing assert_throws_error - has args")
    test_assert_3("assert_throws_error", function(arg0)
        if arg0 ~= "foo" then error("failed") end
        error("succeeded")
    end, "foo", "failed", false)
    test_assert_3("assert_throws_error", function(arg0)
        if arg0 ~= 42 then error("failed") end
        error("succeeded")
    end, 42, "failed", false)
    test_assert_3("assert_throws_error", function(arg0)
        if arg0 ~= 4.2 then error("failed") end
        error("succeeded")
    end, 4.2, "failed", false)
    test_assert_3("assert_throws_error", function(arg0)
        if arg0 ~= "foo" then error("failed") end
        error("succeeded")
    end, {"foo"}, "failed", false)
    test_assert_3("assert_throws_error", function(arg0)
        if arg0[1]~= "foo" then error("failed") end
        error("succeeded")
    end, {{ "foo" }}, "failed", false)
    test_assert_3("assert_throws_error", function(arg0, arg1)
        if arg0 ~= "foo" then error("failed") end
        if arg1 ~= "bar" then error("failed") end
        error("succeeded")
    end, {"foo", "bar"}, "failed", false)
    test_assert_3("assert_throws_error", function(arg0, arg1)
        if arg0 ~= nil then error("failed") end
        if arg1 ~= nil then error("failed") end
        error("succeeded")
    end, {f = "foo", b = "bar"}, "failed", false)
    test_assert_3("assert_throws_error", function(arg0, arg1)
        if arg0 ~= "foo" then error("failed") end
        if arg1 ~= nil then error("failed") end
        error("succeeded")
    end, {"foo", b = "bar"}, "failed", false)
    test_assert_3("assert_throws_error", function(arg0, arg1)
        if arg0 ~= "bar" then error("failed") end
        if arg1 ~= nil then error("failed") end
        error("succeeded")
    end, {f = "foo", "bar"}, "failed", false)


    Logger:debug("Testing assert_throws_error_exactly - no expected error")
    test_assert_3("assert_throws_error_exactly", function() end, nil, nil, false)
    test_assert_3("assert_throws_error_exactly", function() error("foo") end, nil, nil, true)

    Logger:debug("Testing assert_throws_error_exactly - with expected error - string")
    test_assert_3("assert_throws_error_exactly", function() error("foo") end, nil, "foo", true)
    test_assert_3("assert_throws_error_exactly", function() error("foo") end, nil, "bar", false)

    Logger:debug("Testing assert_throws_error_exactly - with expected error - int")
    test_assert_3("assert_throws_error_exactly", function() error(42) end, nil, 42, true)
    test_assert_3("assert_throws_error_exactly", function() error(42) end, nil, 1, false)

    Logger:debug("Testing assert_throws_error_exactly - with expected error - float")
    test_assert_3("assert_throws_error_exactly", function() error(4.2) end, nil, 4.2, true)
    test_assert_3("assert_throws_error_exactly", function() error(4.2) end, nil, 0.5, false)

    Logger:debug("Testing assert_throws_error_exactly - with expected error - table")
    test_assert_3("assert_throws_error_exactly", function() error({"foo"}) end, nil, {"foo"}, false)
    test_assert_3("assert_throws_error_exactly", function() error({"foo"}) end, nil, {"bar"}, false)
    test_assert_3("assert_throws_error_exactly", function() error({a = "foo"}) end, nil, {a = "foo"}, false)
    test_assert_3("assert_throws_error_exactly", function() error({a = "foo"}) end, nil, {a = "bar"}, false)

    Logger:debug("Testing assert_throws_error_exactly - with expected error - table same reference")
    local assertThrowsExactlyTableRef = {a = "foo"}
    test_assert_3("assert_throws_error_exactly", function() error(assertThrowsExactlyTableRef) end, nil, assertThrowsExactlyTableRef, true)

    Logger:debug("Testing assert_throws_error_exactly - has args")
    test_assert_3("assert_throws_error_exactly", function(arg0)
        if arg0 ~= "foo" then error("failed") end
        error("succeeded")
    end, "foo", "failed", false)
    test_assert_3("assert_throws_error_exactly", function(arg0)
        if arg0 ~= 42 then error("failed") end
        error("succeeded")
    end, 42, "failed", false)
    test_assert_3("assert_throws_error_exactly", function(arg0)
        if arg0 ~= 4.2 then error("failed") end
        error("succeeded")
    end, 4.2, "failed", false)
    test_assert_3("assert_throws_error_exactly", function(arg0)
        if arg0 ~= "foo" then error("failed") end
        error("succeeded")
    end, {"foo"}, "failed", false)
    test_assert_3("assert_throws_error_exactly", function(arg0)
        if arg0[1]~= "foo" then error("failed") end
        error("succeeded")
    end, {{ "foo" }}, "failed", false)

    test_assert_3("assert_throws_error_exactly", function(arg0, arg1)
        if arg0 ~= "foo" then error("failed") end
        if arg1 ~= "bar" then error("failed") end
        error("succeeded")
    end, {"foo", "bar"}, "failed", false)
    test_assert_3("assert_throws_error_exactly", function(arg0, arg1)
        if arg0 ~= nil then error("failed") end
        if arg1 ~= nil then error("failed") end
        error("succeeded")
    end, {f = "foo", b = "bar"}, "failed", false)
    test_assert_3("assert_throws_error_exactly", function(arg0, arg1)
        if arg0 ~= "foo" then error("failed") end
        if arg1 ~= nil then error("failed") end
        error("succeeded")
    end,{"foo", b = "bar"}, "failed", false)
    test_assert_3("assert_throws_error_exactly", function(arg0, arg1)
        if arg0 ~= "bar" then error("failed") end
        if arg1 ~= nil then error("failed") end
        error("succeeded")
    end, {f = "foo", "bar"}, "failed", false)


    -- Other tests can depend on Assert working properly, so fail early if it is failing
    Logger:info("Assert validation results: %s", test_counts)
    if test_counts["failed"] > 0 then
        error("Assert validations are failing, cannot accurately run other tests at this time. See debug logs for more details.")
    end
    return test_counts
end