# find.lua - File Search

Search for patterns within files using grep.

## Usage

```bash
lua src/find.lua -s <pattern> -l <location> [options]
```

## Options

| Flag | Short | Description |
|------|-------|-------------|
| `--what <pattern>` | `-s` | Pattern to search for (required) |
| `--where <path>` | `-l` | Location to search (required) |
| `--unique` | `-u` | Show only file names (not matches) |

## Examples

### Search for function definitions
```bash
lua src/find.lua -s "function" -l .
```

### Search in specific file
```bash
lua src/find.lua -s "local" -l src/repo.lua
```

### List files containing pattern
```bash
lua src/find.lua -s "require" -l src/ -u
```

## Output

Results include:
- Line numbers
- Matching line content
- Color-highlighted matches
