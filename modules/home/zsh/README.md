Type `r` to run the command configured for the current directory. This replaces
Zsh's `r` history-repeat builtin. Codex remains available as `co` or `codex`.

Run `vrun` to edit `modules/home/zsh/run-commands.nix` in this checkout:

```nix
{ userPaths }:
{
  "${userPaths.development}/jirachi" = "bun run dev";
  "${userPaths.development}/my-project" = "npm run dev";
  "${userPaths.development}/my-rust-project" = "cargo run --";
}
```

Run `rebuild` to apply mapping changes. Home Manager generates the read-only
`~/.config/zsh/run-commands.zsh` from this Nix map. Paths must be absolute;
use `userPaths` for host-specific paths. Matches are exact, with symlinks resolved;
subdirectories need their own entries. An unconfigured directory prints an error.

Commands use Zsh syntax and run in the current directory. Extra arguments are
appended with their quoting preserved: `r --port 3000` runs `bun run dev --port
3000` in Jirachi. For a command with a pipeline or multiple statements, arguments
are appended to the last command. The command's exit status is returned, and
changes to the working directory or shell state stay inside a subshell.
