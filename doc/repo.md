# repo.lua - Git Workflow Automation

Automates common git operations including commit/push, branch synchronization, and pre-commit protection.

## Usage

```bash
lua src/repo.lua [options]
```

## Options

| Flag | Short | Description |
|------|-------|-------------|
| `--file <path>` | `-f` | Specific file to add (default: all) |
| `--message <msg>` | `-m` | Commit message |
| `--sync` | `-s` | Sync branches with remote |
| `--precommit` | `-p` | Install pre-commit hook |
| `--checkbranch` | `-c` | Check if on protected branch |
| `--help` | `-h` | Show help |

## Examples

### Show git status
```bash
lua src/repo.lua
```

### Commit and push
```bash
lua src/repo.lua -m "Add new feature"
lua src/repo.lua -f specific_file.lua -m "Update file"
```

### Sync branches
```bash
lua src/repo.lua --sync
```

Synchronizes local branches with remote:
- Fast-forwards branches when upstream has new commits
- Pushes local commits when local is ahead
- Warns about diverged branches
- Suggests cleanup for deleted upstream branches

### Install pre-commit hook
```bash
lua src/repo.lua --precommit
```

Installs a git hook that prevents direct commits to `main` or `master` branches.

### Check current branch
```bash
lua src/repo.lua --checkbranch
```

Returns error if on a protected branch (main/master).

## Pre-commit Hook

The pre-commit hook enforces feature branch workflow:
- Blocks commits directly to `main` or `master`
- Suggests creating a feature branch first

To bypass (use sparingly):
```bash
git commit --no-verify -m "message"
```
