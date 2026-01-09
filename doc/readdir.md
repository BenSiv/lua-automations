# readdir.lua - Directory Listing

List directory contents with visual formatting.

## Usage

```bash
lua src/readdir.lua [path]
```

## Arguments

| Argument | Description |
|----------|-------------|
| `path` | Directory or file path (default: current directory) |

## Examples

### List current directory
```bash
lua src/readdir.lua
```

### List specific directory
```bash
lua src/readdir.lua /path/to/directory
```

### Show single file
```bash
lua src/readdir.lua file.lua
```

## Output

- Directories shown in blue
- Hidden files/directories listed first
- Sorted alphabetically within each category
