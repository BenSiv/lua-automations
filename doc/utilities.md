# Additional Scripts

## edit.lua - Open in Editor

Opens a file in the micro editor.

```bash
lua src/edit.lua <file>
```

---

## open.lua - Open with Default Program

Opens a file with the system default program.

```bash
lua src/open.lua <file>
```

---

## view.lua - View Delimited Files

Displays TSV/CSV files as formatted tables.

```bash
lua src/view.lua -i <file.tsv>
lua src/view.lua -i <file.csv>
```

---

## dev.lua - Development Container

Connects to a Podman development container.

```bash
lua src/dev.lua              # Connect to "celleste-dev"
lua src/dev.lua <name>       # Connect to named container
```

---

## arch.lua - Arch Package Manager

Wrapper for yay package manager (Arch Linux).

```bash
lua src/arch.lua install <package>
lua src/arch.lua remove <package>
lua src/arch.lua update
lua src/arch.lua list
```
