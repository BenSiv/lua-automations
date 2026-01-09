-- Tests for readdir.lua - directory listing functionality
-- Run with: lua tests/test_readdir.lua

package.path = package.path .. ";./tst/?.lua"

require("utils").using("utils")

local tests = require("test_framework")

print("\n" .. string.rep("=", 60))
print("Testing readdir.lua - Directory Listing")
print(string.rep("=", 60))

--------------------------------------------------------------------------------
-- Test: Basic directory listing
--------------------------------------------------------------------------------
print("\n[SUITE] Basic Directory Listing")

tests.run_test("readdir.lua lists current directory", function()
    local output, _ = exec_command("cd /root/lua-automations && lua src/readdir.lua 2>&1")
    tests.assert_not_nil(output, "Should return output")
    -- Should list src directory
    tests.assert_contains(output, "src", "Should list src directory")
end)

tests.run_test("readdir.lua lists specified directory", function()
    local output, _ = exec_command("cd /root/lua-automations && lua src/readdir.lua tests 2>&1")
    tests.assert_not_nil(output, "Should return output")
    -- Should list test files
    tests.assert_contains(output, "test", "Should list test files")
end)

tests.run_test("readdir.lua handles file argument", function()
    local output, _ = exec_command("cd /root/lua-automations && lua src/readdir.lua repo.lua 2>&1")
    tests.assert_contains(output, "repo.lua", "Should print filename")
end)

--------------------------------------------------------------------------------
-- Test: Edge cases
--------------------------------------------------------------------------------
print("\n[SUITE] Edge Cases")

tests.run_test("readdir.lua handles non-existent path", function()
    local output, _ = exec_command("cd /root/lua-automations && lua src/readdir.lua /nonexistent 2>&1")
    tests.assert_contains(output, "Error", "Should show error for non-existent path")
end)

--------------------------------------------------------------------------------
-- Print Summary
--------------------------------------------------------------------------------
tests.print_summary()
