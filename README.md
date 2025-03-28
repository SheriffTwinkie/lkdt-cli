# lkdt – Kong Docker Tag Lister

A CLI tool to list Docker Hub tags for Kong Gateway (Enterprise).

---

## 📆 Install from source

```bash
git clone https://github.com/SheriffTwinkie/lkdt-cli.git
cd lkdt-cli
dpkg-deb --build deb
sudo dpkg -i deb.deb
```

---

## 🚀 Usage

```bash
lkdt --help
```

### Examples

```bash
# List all stable 3.X.X.X versions, newest first
lkdt -f "^3\.[0-9]+\.[0-9]+\.[0-9]+$" -s --sort desc

# Only show the latest 5
lkdt -f "^3\.[0-9]+\.[0-9]+\.[0-9]+$" -s -n 5

# Save results to a file
lkdt -f "^3\.[0-9]+\.[0-9]+\.[0-9]+$" --output tags.txt

# Output results as JSON
lkdt -f "^3\.[0-9]+\.[0-9]+\.[0-9]+$" --json
```

---

## 🛠️ Features

- ✅ Filter tags using regex (`--filter`)
- 📦 Output as JSON (`--json`)
- 📎 Save results to file (`--output`)
- 🔢 Show only the latest N results (`--latest`)
- 🔁 Sort ascending or descending (`--sort asc|desc`)
- 🚫 Exclude unstable tags like `-rc`, `-beta`, `-alpha` (`--stable`)
- 🆎 Verbose mode (`--verbose`)
- 🔍 View version info (`--version`)

