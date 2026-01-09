# lua-automations

A collection of Lua scripts for automating common development tasks.

## Structure

```
lua-automations/
├── src/          # Source files
├── tst/          # Test suite
├── doc/          # Documentation
├── LICENSE
└── README.md
```

## Quick Start

```bash
# Run a script
lua src/repo.lua --help

# Run tests
./tst/run_all.sh
```

## Available Commands

| Script | Description |
|--------|-------------|
| `repo.lua` | Git workflow automation (commit, sync, pre-commit) |
| `find.lua` | Search for patterns in files |
| `readdir.lua` | List directory contents |
| `edit.lua` | Open file in editor |
| `open.lua` | Open file with default program |
| `view.lua` | View delimited file as table |
| `dev.lua` | Connect to development container |
| `arch.lua` | Arch Linux package manager wrapper |

See [doc/](doc/) for detailed usage documentation.

## License

MIT License - see [LICENSE](LICENSE)