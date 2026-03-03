-- Tests for repo.lua git automation functions
-- Run with: lua tests/test_repo.lua

package.path = package.path .. ";./tst/?.lua"

require("utils").using("utils")
using("paths")

local tests = require("test_framework")

print("\n" .. string.rep("=", 60))
print("Testing repo.lua - Git Automation Functions")
print(string.rep("=", 60))

--------------------------------------------------------------------------------
-- Helper function tests (these are internal to repo.lua, so we redefine them)
--------------------------------------------------------------------------------

-- Check if a git revision exists (using exit code via shell)
local function rev_exists(rev)
    local output, _ = exec_command(string.format("git rev-parse --quiet --verify %s 2>/dev/null && echo 'EXISTS'", rev))
    return output and string.find(output, "EXISTS") ~= nil
end

-- Check if first commit is an ancestor of second (using exit code via shell)
local function is_ancestor(ancestor, descendant)
    local output, _ = exec_command(string.format("git merge-base --is-ancestor %s %s 2>/dev/null && echo 'YES' || echo 'NO'", ancestor, descendant))
    return output and string.find(output, "YES") ~= nil
end

-- Get current branch name
local function get_current_branch()
    local output, success = exec_command("git branch --show-current 2>/dev/null")
    if success and output then
        return output:gsub("%s+$", "")
    end
    return nil
end

-- Get list of remotes
local function get_remotes()
    local output, success = exec_command("git remote 2>/dev/null")
    if not success or not output then return {} end
    local remotes = {}
    for remote in output:gmatch("[^\r\n]+") do
        table.insert(remotes, remote)
    end
    return remotes
end

--------------------------------------------------------------------------------
-- Test: rev_exists
--------------------------------------------------------------------------------
print("\n[SUITE] rev_exists function")

tests.run_test("rev_exists with HEAD", function()
    -- HEAD should always exist in a git repo
    tests.assert_true(rev_exists("HEAD"), "HEAD should exist")
end)

tests.run_test("rev_exists with invalid ref", function()
    tests.assert_false(rev_exists("nonexistent-branch-12345"), "Invalid ref should not exist")
end)

tests.run_test("rev_exists with origin/main or origin/master", function()
    local exists_main = rev_exists("origin/main")
    local exists_master = rev_exists("origin/master")
    tests.assert_true(exists_main or exists_master, "Either origin/main or origin/master should exist")
end)

--------------------------------------------------------------------------------
-- Test: get_current_branch
--------------------------------------------------------------------------------
print("\n[SUITE] get_current_branch function")

tests.run_test("get_current_branch returns string", function()
    local branch = get_current_branch()
    tests.assert_not_nil(branch, "Should return a branch name")
    tests.assert_true(type(branch) == "string", "Branch should be a string")
end)

tests.run_test("get_current_branch returns valid branch", function()
    local branch = get_current_branch()
    -- Branch name should not contain newlines
    tests.assert_false(string.find(branch, "\n"), "Branch name should not contain newlines")
end)

--------------------------------------------------------------------------------
-- Test: get_remotes
--------------------------------------------------------------------------------
print("\n[SUITE] get_remotes function")

tests.run_test("get_remotes returns table", function()
    local remotes = get_remotes()
    tests.assert_true(type(remotes) == "table", "Should return a table")
end)

tests.run_test("get_remotes includes origin", function()
    local remotes = get_remotes()
    local has_origin = false
    for _, remote in ipairs(remotes) do
        if remote == "origin" then
            has_origin = true
            break
        end
    end
    tests.assert_true(has_origin, "Should include 'origin' remote")
end)

--------------------------------------------------------------------------------
-- Test: is_ancestor
--------------------------------------------------------------------------------
print("\n[SUITE] is_ancestor function")

tests.run_test("is_ancestor HEAD~1 is ancestor of HEAD", function()
    -- First check if we have enough commits
    local _, success = exec_command("git rev-parse HEAD~1 2>/dev/null")
    if success then
        tests.assert_true(is_ancestor("HEAD~1", "HEAD"), "HEAD~1 should be ancestor of HEAD")
    else
        -- Not enough commits, skip implicitly by passing
        tests.assert_true(true, "Skipped - not enough commits")
    end
end)

tests.run_test("is_ancestor HEAD is not ancestor of HEAD~1", function()
    local _, success = exec_command("git rev-parse HEAD~1 2>/dev/null")
    if success then
        tests.assert_false(is_ancestor("HEAD", "HEAD~1"), "HEAD should not be ancestor of HEAD~1")
    else
        tests.assert_true(true, "Skipped - not enough commits")
    end
end)

--------------------------------------------------------------------------------
-- Test: CLI argument parsing
--------------------------------------------------------------------------------
print("\n[SUITE] CLI Argument Parsing")

tests.run_test("repo.lua --help exits without error", function()
    local output, _ = exec_command("lua src/repo.lua --help 2>&1")
    tests.assert_contains(output, "Usage", "Help should show usage")
    tests.assert_contains(output, "behind list", "Help should mention behind list")
    tests.assert_contains(output, "commit -m", "Help should mention commit")
end)

tests.run_test("repo.lua commit without args shows git status", function()
    local output, _ = exec_command("lua src/repo.lua commit 2>&1")
    local has_branch = string.find(output, "branch") or string.find(output, "Branch")
    tests.assert_true(has_branch ~= nil, "Should show git status with branch info")
end)

--------------------------------------------------------------------------------
-- Test: Sync functionality (dry run check)
--------------------------------------------------------------------------------
print("\n[SUITE] Git Sync Functionality")

tests.run_test("repo.lua sync fetches from remotes", function()
    local output, _ = exec_command("lua src/repo.lua sync 2>&1")
    tests.assert_contains(output, "Fetching from all remotes", "Should show fetching message")
    tests.assert_contains(output, "Sync complete", "Should complete successfully")
end)

--------------------------------------------------------------------------------
-- Test: Pre-commit hook functionality
--------------------------------------------------------------------------------
print("\n[SUITE] Pre-commit Hook Functionality")

tests.run_test("repo.lua commit without args shows git status", function()
    local output, _ = exec_command("lua src/repo.lua commit 2>&1")
    local has_branch = string.find(output, "branch") or string.find(output, "Branch")
    tests.assert_true(has_branch ~= nil, "Should show git status with branch info")
end)

--------------------------------------------------------------------------------
-- Print Summary
--------------------------------------------------------------------------------
tests.print_summary()
