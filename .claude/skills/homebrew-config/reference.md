# Homebrew Brewfile Reference

## Directives

### `tap` - Third-party repositories
```ruby
tap "user/repo"
tap "user/repo", "https://custom-git-url.git"
```

### `brew` - CLI formulae
```ruby
brew "package"
brew "package", args: ["with-openssl"]
brew "postgresql@16", restart_service: true
brew "ollama", restart_service: :changed
brew "mysql@5.6", link: true, conflicts_with: ["mysql"]
brew "package", start_service: true
brew "package", postinstall: "echo done"
```
Options: `args`, `restart_service` (true / :changed), `start_service`, `link` (true / :overwrite), `conflicts_with` (array), `postinstall`

### `cask` - GUI applications
```ruby
cask "firefox"
cask "firefox", args: { appdir: "~/Applications" }
cask "opera", greedy: true
```
Options: `args` (hash), `greedy`

Global defaults: `cask_args appdir: "~/Applications", require_sha: true`

### `mas` - Mac App Store (requires `mas` CLI)
```ruby
mas "Xcode", id: 497799835
```

### `vscode` - VS Code / Cursor extensions
```ruby
vscode "ms-python.python"
```

### Other package managers
```ruby
go "github.com/user/package"
cargo "ripgrep"
uv "ruff"
flatpak "org.app.Name", remote: "flathub-beta"
```

## Conditional Logic
```ruby
brew "gnupg" if OS.mac?
brew "glibc" if OS.linux?
cask "java" unless system "/usr/libexec/java_home", "--failfast"
```
