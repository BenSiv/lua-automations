-- Git workflow automation CLI
-- Focused: sync branches, behind list/update, add+commit+push combo

require("utils").using("utils")
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

local function trim(s)
    if not s then return nil end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function parse_options(argv, start_index, spec)
    local opts = { _unknown = {} }
    local i = start_index
    while i <= #argv do
        local argi = argv[i]
        local def = spec[argi]
        if def then
            if def.has_value then
                if i + 1 > #argv then
                    return nil, "Missing value for " .. argi
                end
                i = i + 1
                opts[def.key] = argv[i]
            else
                opts[def.key] = true
            end
        else
            table.insert(opts._unknown, argi)
        end
        i = i + 1
    end
    return opts, nil
end

-- Check if working tree is clean (no staged or unstaged changes)
local function is_worktree_clean()
    local _, success = exec_command("git diff --quiet 2>/dev/null")
    if not success then return false end
    local _, success2 = exec_command("git diff --cached --quiet 2>/dev/null")
    return success2
end

-- Get current branch name
local function get_current_branch()
    local output, success = exec_command("git branch --show-current 2>/dev/null")
    if success and output then
        return output:gsub("%s+$", "")  -- trim trailing whitespace
    end
    return nil
end

local function get_local_branches()
    local output, success = exec_command('git for-each-ref refs/heads --format="%(refname:short)" 2>/dev/null')
    if not success or not output then return {} end
    local branches = {}
    for line in output:gmatch("[^\r\n]+") do
        if line ~= "" then table.insert(branches, line) end
    end
    return branches
end

local function get_remote_branches(remote)
    if not remote or remote == "" then return {} end
    local output, success = exec_command(string.format(
        'git for-each-ref refs/remotes/%s --format="%%(refname:short)" 2>/dev/null', remote
    ))
    if not success or not output then return {} end
    local branches = {}
    for line in output:gmatch("[^\r\n]+") do
        if line ~= "" and line ~= (remote .. "/HEAD") then
            table.insert(branches, line)
        end
    end
    return branches
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

local function resolve_remote_name(remote_name)
    if remote_name and remote_name ~= "" then return remote_name end
    local remotes = get_remotes()
    for _, remote in ipairs(remotes) do
        if remote == "origin" then
            return "origin"
        end
    end
    return remotes[1]
end

local function resolve_base_ref(base, remote_name)
    if base and base ~= "" then return base end
    if rev_exists("main") then return "main" end
    if rev_exists("master") then return "master" end
    if remote_name and rev_exists(remote_name .. "/HEAD") then return remote_name .. "/HEAD" end
    return "HEAD"
end

local function get_ahead_behind(base, branch)
    local counts, ok = exec_command(
        string.format("git rev-list --left-right --count %s...%s 2>/dev/null", base, branch)
    )
    if not ok or not counts then return nil, nil end
    local behind, ahead = counts:match("(%d+)%s+(%d+)")
    return tonumber(behind), tonumber(ahead)
end

local function get_upstream(branch)
    local output, success = exec_command(
        string.format("git rev-parse --abbrev-ref --symbolic-full-name %s@{upstream} 2>/dev/null", branch)
    )
    if success and output then
        return trim(output)
    end
    return nil
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

local function list_branches_behind(opts)
    local remote_name = nil
    if opts.remote then
        remote_name = resolve_remote_name(opts.remote_name)
        if not remote_name then
            print("Error: No remotes found")
            return false
        end
        exec_command("git fetch --all --prune 2>/dev/null")
    end

    local base = resolve_base_ref(opts.base, remote_name)
    if not rev_exists(base) then
        print(string.format("Error: Base ref '%s' not found", base))
        return false
    end

    local branches = {}
    for _, branch in ipairs(get_local_branches()) do
        table.insert(branches, { name = branch, scope = "local" })
    end
    if opts.remote then
        for _, branch in ipairs(get_remote_branches(remote_name)) do
            table.insert(branches, { name = branch, scope = "remote" })
        end
    end

    local results = {}
    for _, item in ipairs(branches) do
        if item.name ~= base then
            local behind, ahead = get_ahead_behind(base, item.name)
            if behind and ahead and behind > 0 and ahead > 0 then
                table.insert(results, { name = item.name, behind = behind, ahead = ahead, scope = item.scope })
            end
        end
    end

    if #results == 0 then
        print(string.format("No branches behind '%s'.", base))
        return true
    end

    table.sort(results, function(a, b)
        if a.behind == b.behind then
            return a.ahead > b.ahead
        end
        return a.behind > b.behind
    end)

    print(string.format("Branches behind '%s':", base))
    for _, item in ipairs(results) do
        print(string.format("  %s  (behind %d, ahead %d, %s)", item.name, item.behind, item.ahead, item.scope))
    end
    return true
end

local function update_branches_behind(opts)
    local remote_name = nil
    if opts.remote then
        remote_name = resolve_remote_name(opts.remote_name)
        if not remote_name then
            print("Error: No remotes found")
            return false
        end
        exec_command("git fetch --all --prune 2>/dev/null")
    end

    local base = resolve_base_ref(opts.base, remote_name)
    if not rev_exists(base) then
        print(string.format("Error: Base ref '%s' not found", base))
        return false
    end

    if not is_worktree_clean() then
        print("Error: Working tree has uncommitted changes. Please commit or stash before updating branches.")
        return false
    end

    local candidates = {}
    if opts.branch and opts.branch ~= "" then
        if not rev_exists(opts.branch) then
            print(string.format("Error: Branch '%s' not found", opts.branch))
            return false
        end
        if opts.branch == base then
            print("Nothing to do: branch equals base")
            return true
        end
        local behind, ahead = get_ahead_behind(base, opts.branch)
        if behind and behind > 0 then
            table.insert(candidates, { branch = opts.branch, behind = behind, ahead = ahead or 0 })
        else
            print(string.format("Branch '%s' is not behind '%s'.", opts.branch, base))
            return true
        end
    else
        for _, branch in ipairs(get_local_branches()) do
            if branch ~= base then
                local behind, ahead = get_ahead_behind(base, branch)
                if behind and behind > 0 then
                    table.insert(candidates, { branch = branch, behind = behind, ahead = ahead or 0 })
                end
            end
        end
    end

    if #candidates == 0 then
        print(string.format("No local branches behind '%s' to update.", base))
        return true
    end

    table.sort(candidates, function(a, b)
        if a.behind == b.behind then
            return a.ahead > b.ahead
        end
        return a.behind > b.behind
    end)

    local original_branch = get_current_branch()
    exec_command("git switch --detach --quiet 2>/dev/null")

    local updated = 0
    local conflicts = 0
    local pushed = 0
    for _, item in ipairs(candidates) do
        local branch = item.branch
        local _, ok = exec_command(string.format("git switch %s --quiet 2>/dev/null", branch))
        if not ok then
            print(string.format("Error: Failed to switch to '%s'", branch))
        else
            local _, merge_ok = exec_command(string.format("git merge --no-edit %s 2>/dev/null", base))
            if merge_ok then
                updated = updated + 1
                print(string.format("Updated '%s' (behind %d, ahead %d)", branch, item.behind, item.ahead))
                if opts.remote then
                    local upstream = get_upstream(branch)
                    if upstream then
                        local up_remote = upstream:match("^([^/]+)/")
                        if not remote_name or up_remote == remote_name then
                            local _, push_ok = exec_command(string.format("git push %s %s 2>/dev/null", up_remote, branch))
                            if push_ok then
                                pushed = pushed + 1
                            else
                                print(string.format("Warning: Failed to push '%s' to '%s'", branch, up_remote))
                            end
                        else
                            print(string.format("Note: Skipping push for '%s' (upstream on '%s')", branch, up_remote))
                        end
                    else
                        print(string.format("Note: No upstream for '%s'; skipping push", branch))
                    end
                end
            else
                conflicts = conflicts + 1
                exec_command("git merge --abort 2>/dev/null")
                print(string.format("Conflict: Could not merge '%s' into '%s' (merge aborted)", base, branch))
            end
        end
    end

    if original_branch and original_branch ~= "" and rev_exists(original_branch) then
        exec_command(string.format("git switch %s --quiet 2>/dev/null", original_branch))
    else
        exec_command("git switch main --quiet 2>/dev/null || git switch master --quiet 2>/dev/null")
    end

    if opts.remote then
        print(string.format("Done. Updated %d branch(es). Conflicts: %d. Pushed: %d.", updated, conflicts, pushed))
    else
        print(string.format("Done. Updated %d branch(es). Conflicts: %d.", updated, conflicts))
    end
    return true
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
--------------------------------------------------------------------------------
-- Original commit/push functionality
--------------------------------------------------------------------------------

local function commit_and_push(args)
    if not args.file and not args.message then
        local status = exec_command("git status")
        print(status)
        return nil
    end

    if not args.message or args.message == "" then
        print("Error: Commit message required (use -m or --message)")
        return nil
    end
    
    local base_ref = resolve_base_ref(args.base, nil)
    local branch = get_current_branch()
    if branch and base_ref and branch == base_ref then
        print(string.format("Warning: You are on base branch '%s'. Consider using a feature branch.", branch))
    end
    
    local output, success

    args.file = args.file or "."
    output, success = exec_command(string.format("git add '%s'", args.file))
    if not success then
        print(output or "Failed to add files")
        return output
    end

    output, success = exec_command(string.format("git commit -m '%s'", args.message))
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
local function print_usage()
    print([[
Usage:
  repo <command> [subcommand] [flags]

Commands:
  behind list [--remote] [--base <ref>] [--remote-name <name>]
  behind update [branch] [--remote] [--base <ref>] [--remote-name <name>]
  sync
  commit -m <message> [-f <path>] [--base <ref>]

Flags:
  --remote              Include remote branches or push updated branches
  --base <ref>          Base ref to compare/merge against (default: main/master)
  --remote-name <name>  Remote name (default: origin/first remote)
  -h, --help            Show help

Examples:
  repo sync
  repo behind list
  repo behind list --remote
  repo behind list --base origin/main
  repo behind update
  repo behind update feature/growth-rate-reports
  repo behind update benchling-validations-gcp --remote
  repo commit -m "fix: adjust validation flow" -f .
  repo commit -m "chore: bump deps" --base main
]])
end

local function print_behind_usage()
    print([[
Usage:
  repo behind list [--remote] [--base <ref>] [--remote-name <name>]
  repo behind update [branch] [--remote] [--base <ref>] [--remote-name <name>]
]])
end

local function main(argv)
    local cmd = argv[1]
    if not cmd or cmd == "help" or cmd == "-h" or cmd == "--help" then
        print_usage()
        return
    end

    if cmd == "behind" then
        local sub = argv[2]
        local spec = {
            ["--remote"] = { key = "remote", has_value = false },
            ["--base"] = { key = "base", has_value = true },
            ["--remote-name"] = { key = "remote_name", has_value = true },
            ["-h"] = { key = "help", has_value = false },
            ["--help"] = { key = "help", has_value = false },
        }
        local opts, err = parse_options(argv, 3, spec)
        if err then
            print(err)
            return
        end
        if opts.help or not sub then
            print_behind_usage()
            return
        end
        if sub == "list" then
            if #opts._unknown > 0 then
                print("Unknown args: " .. table.concat(opts._unknown, ", "))
                return
            end
            list_branches_behind(opts)
        elseif sub == "update" then
            if #opts._unknown > 1 then
                print("Unknown args: " .. table.concat(opts._unknown, ", "))
                return
            end
            opts.branch = opts._unknown[1]
            update_branches_behind(opts)
        else
            print_behind_usage()
        end
        return
    end

    if cmd == "sync" then
        git_sync()
        return
    end

    if cmd == "commit" then
        local spec = {
            ["-f"] = { key = "file", has_value = true },
            ["--file"] = { key = "file", has_value = true },
            ["-m"] = { key = "message", has_value = true },
            ["--message"] = { key = "message", has_value = true },
            ["--base"] = { key = "base", has_value = true },
            ["-h"] = { key = "help", has_value = false },
            ["--help"] = { key = "help", has_value = false },
        }
        local opts, err = parse_options(argv, 2, spec)
        if err then
            print(err)
            return
        end
        if opts.help then
            print("Usage: repo commit -m <message> [-f <path>]")
            return
        end
        if #opts._unknown > 0 then
            print("Unknown args: " .. table.concat(opts._unknown, ", "))
            return
        end
        commit_and_push(opts)
        return
    end

    print("Unknown command: " .. cmd)
    print_usage()
end

if get_file_name(arg[0]) == "repo.lua" then
    main(arg)
end
