-- Test framework for lua-automations
-- Simple assertion-based testing

require("utils").using("utils")

local tests = {}
local passed = 0
local failed = 0
local skipped = 0

--------------------------------------------------------------------------------
-- Test Framework
--------------------------------------------------------------------------------

local function assert_equal(actual, expected, message)
    if actual == expected then
        return true
    else
        error(string.format("%s: expected '%s', got '%s'", message or "Assertion failed", tostring(expected), tostring(actual)))
    end
end

local function assert_true(value, message)
    if value then
        return true
    else
        error(message or "Expected true, got false")
    end
end

local function assert_false(value, message)
    if not value then
        return true
    else
        error(message or "Expected false, got true")
    end
end

local function assert_nil(value, message)
    if value == nil then
        return true
    else
        error(message or "Expected nil, got " .. tostring(value))
    end
end

local function assert_not_nil(value, message)
    if value ~= nil then
        return true
    else
        error(message or "Expected non-nil value")
    end
end

local function assert_contains(str, substring, message)
    if string.find(str, substring, 1, true) then
        return true
    else
        error(string.format("%s: '%s' not found in '%s'", message or "Assertion failed", substring, str))
    end
end

local function run_test(name, test_fn)
    io.write(string.format("  [TEST] %s ... ", name))
    local success, err = pcall(test_fn)
    if success then
        print("PASS")
        passed = passed + 1
    else
        print("FAIL")
        print("         " .. tostring(err))
        failed = failed + 1
    end
end

local function skip_test(name, reason)
    io.write(string.format("  [SKIP] %s ... ", name))
    print("SKIPPED" .. (reason and (" - " .. reason) or ""))
    skipped = skipped + 1
end

local function print_summary()
    print("\n" .. string.rep("=", 60))
    print(string.format("Results: %d passed, %d failed, %d skipped", passed, failed, skipped))
    print(string.rep("=", 60))
    if failed > 0 then
        os.exit(1)
    end
end

--------------------------------------------------------------------------------
-- Export test framework
--------------------------------------------------------------------------------

tests.assert_equal = assert_equal
tests.assert_true = assert_true
tests.assert_false = assert_false
tests.assert_nil = assert_nil
tests.assert_not_nil = assert_not_nil
tests.assert_contains = assert_contains
tests.run_test = run_test
tests.skip_test = skip_test
tests.print_summary = print_summary

return tests
