-- Git workflow automation CLI
-- Includes: commit/push, sync branches, pre-commit hook

require("utils").using("utils")
using("argparse")
using("paths")

--------------------------------------------------------------------------------
-- Helper functions for git operations
--------------------------------------------------------------------------------

-- Check if a git revision exists
local function rev_exists(rev)
    local _, success = exec_command(string.format("git rev-parse --quiet --verify %s 2>/dev/null", rev))
    return success
end

-- Check if first commit is an ancestor of second
local function is_ancestor(ancestor, descendant)
    local _, success = exec_command(string.format("git merge-base --is-ancestor %s %s 2>/dev/null", ancestor, descendant))
    return success
end

-- Get current branch name
local function get_current_branch()
    local output, success = exec_command("git branch --show-current 2>/dev/null")
    if success and output then
        return output:gsub("%s+$", "")  -- trim trailing whitespace
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

-- Get default branch for a remote (e.g., origin/HEAD -> origin/main)
local function get_remote_head(remote)
    local output, _ = exec_command(string.format("git symbolic-ref refs/remotes/%s/HEAD 2>/dev/null", remote))
    if output and output ~= "" then
        return output:gsub("%s+$", ""):gsub("^refs/remotes/", "")
    end
    return remote .. "/master"  -- fallback
end

-- Parse branch tracking info
local function get_branch_info()
    local output, success = exec_command(
        'git for-each-ref refs/heads --format="%(refname)|%(refname:short)|%(upstream)|%(upstream:short)|%(upstream:remotename)"'
    )
    if not success or not output then return {} end
    
    local branches = {}
    for line in output:gmatch("[^\r\n]+") do
        local localref, branch, upstreamref, upstream, remote = line:match("([^|]*)|([^|]*)|([^|]*)|([^|]*)|([^|]*)")
        if branch and branch ~= "" then
            table.insert(branches, {
                localref = localref,
                branch = branch,
                upstreamref = upstreamref,
                upstream = upstream,
                remote = remote
            })
        end
    end
    return branches
end

--------------------------------------------------------------------------------
-- Git Sync - Synchronize local branches with remote
-- Ported from: https://github.com/pallene-lang/pallene/blob/master/dev/git-sync
--------------------------------------------------------------------------------

local function git_sync()
    print("Fetching from all remotes...")
    local output, success = exec_command("git fetch --all --prune")
    if not success then
        print("Error: Failed to fetch from remotes")
        print(output or "")
        return false
    end
    
    -- Ensure remote HEAD exists for each remote
    local remotes = get_remotes()
    for _, remote in ipairs(remotes) do
        if not rev_exists(remote .. "/HEAD") then
            print(string.format("Setting HEAD for remote '%s'...", remote))
            exec_command(string.format("git remote set-head %s --auto", remote))
        end
    end
    
    -- Save current branch
    local old_branch = get_current_branch()
    
    -- Switch to detached HEAD to allow updating current branch
    exec_command("git switch --detach --quiet 2>/dev/null")
    
    -- Process each local branch
    local branches = get_branch_info()
    for _, info in ipairs(branches) do
        local branch = info.branch
        local upstreamref = info.upstreamref
        local upstream = info.upstream
        local remote = info.remote
        
        -- Only process if tracking an upstream
        if upstreamref and upstreamref ~= "" then
            -- Check if upstream still exists
            if rev_exists(upstreamref) then
                if is_ancestor(info.localref, upstreamref) then
                    -- Fast forward the local branch
                    print(string.format("Fast-forwarding '%s' to '%s'", branch, upstream))
                    exec_command(string.format("git fetch . %s:%s 2>/dev/null", upstreamref, branch))
                elseif is_ancestor(upstreamref, info.localref) then
                    -- Local is ahead, push
                    print(string.format("Pushing local changes from '%s' to '%s'", branch, upstream))
                    exec_command(string.format("git push %s %s 2>/dev/null", remote, info.localref))
                else
                    print(string.format("Warning: '%s' and '%s' have diverged (possible rebase)", branch, upstream))
                end
            else
                -- Upstream was deleted
                local remote_head = get_remote_head(remote)
                if is_ancestor(info.localref, "refs/remotes/" .. remote_head) then
                    print(string.format("Deleting merged branch '%s' (upstream '%s' was deleted)", branch, upstream))
                    exec_command(string.format("git branch -d %s 2>/dev/null", branch))
                else
                    print(string.format("Note: You might want to delete '%s' - upstream '%s' was deleted", branch, upstream))
                end
            end
        end
    end
    
    -- Return to original branch if it still exists
    if old_branch and old_branch ~= "" then
        if rev_exists(old_branch) then
            exec_command(string.format("git switch %s --quiet 2>/dev/null", old_branch))
        else
            print(string.format("Note: Branch '%s' was deleted, switching to default branch", old_branch))
            exec_command("git switch master --quiet 2>/dev/null || git switch main --quiet 2>/dev/null")
        end
    end
    
    print("Sync complete!")
    return true
end

--------------------------------------------------------------------------------
-- Pre-commit check - Prevent commits directly to master/main
-- Ported from: https://github.com/pallene-lang/pallene/blob/master/dev/pre-commit
--------------------------------------------------------------------------------

local function check_branch()
    local branch = get_current_branch()
    if branch == "master" or branch == "main" then
        print(string.format("Error: Please don't create commits directly on the '%s' branch", branch))
        print("Create a feature branch first: git checkout -b feature/your-feature")
        return false
    end
    return true
end

-- Install pre-commit hook
local function install_precommit()
    -- Check if we're in a git repo
    local _, success = exec_command("git rev-parse --git-dir 2>/dev/null")
    if not success then
        print("Error: Not in a git repository")
        return false
    end
    
    local hook_content = [[#!/bin/sh
# Pre-commit hook: Prevent direct commits to master/main
# Installed by lua-automations/repo.lua

branch=$(git branch --show-current)
if [ "$branch" = "master" ] || [ "$branch" = "main" ]; then
    echo "Error: Please don't create commits directly on the '$branch' branch"
    echo "Create a feature branch first: git checkout -b feature/your-feature"
    exit 1
fi

exit 0
]]
    
    local git_dir, _ = exec_command("git rev-parse --git-dir 2>/dev/null")
    git_dir = git_dir:gsub("%s+$", "")
    local hook_path = git_dir .. "/hooks/pre-commit"
    
    -- Write hook file
    local file = io.open(hook_path, "w")
    if not file then
        print("Error: Could not create hook file at " .. hook_path)
        return false
    end
    file:write(hook_content)
    file:close()
    
    -- Make executable
    exec_command(string.format("chmod +x '%s'", hook_path))
    
    print("Pre-commit hook installed at: " .. hook_path)
    return true
end

--------------------------------------------------------------------------------
-- Original commit/push functionality
--------------------------------------------------------------------------------

local function commit_and_push(args)
    if not args["file"] and not args["message"] then
        local status = exec_command("git status")
        print(status)
        return nil
    end
    
    -- Check branch before committing (optional pre-commit check)
    if not check_branch() then
        print("Aborting commit. Use --force to override.")
        return nil
    end
    
    local output, success

    args["file"] = args["file"] or "."
    output, success = exec_command(string.format("git add '%s'", args["file"]))
    if not success then
        print(output or "Failed to add files")
        return output
    end

    output, success = exec_command(string.format("git commit -m '%s'", args["message"]))
    if not success then
        print(output or "Failed to commit")
        return output
    end

    output, success = exec_command("git push")
    if not success then
        print(output or "Failed to push")
        return output
    end
    
    print("Successfully committed and pushed!")
end

--------------------------------------------------------------------------------
-- Main CLI
--------------------------------------------------------------------------------

local function main(args)
    if args["sync"] then
        git_sync()
    elseif args["precommit"] then
        install_precommit()
    elseif args["checkbranch"] then
        if check_branch() then
            print("OK: Not on protected branch")
        end
    else
        commit_and_push(args)
    end
end

local arg_string = [[
    -f --file arg string false
    -m --message arg string false
    -s --sync flag boolean false
    -p --precommit flag boolean false
    -c --checkbranch flag boolean false
]]

local expected_args = def_args(arg_string)
local args = parse_args(arg, expected_args)
    
if get_file_name(arg[0]) == "repo.lua" and args then
    main(args)
end
