# Override both an old alias and Zsh's history-repeat builtin.
unalias r 2>/dev/null
function r() (
  emulate -L zsh

  local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/run-commands.zsh"
  local -A run_commands
  if [[ ! -r "$config_file" ]]; then
    print -u2 -r -- "r: cannot read $config_file"
    return 1
  fi
  source "$config_file" || return

  local directory run_command
  for directory run_command in "${(@kv)run_commands}"; do
    # Resolve symlinks so ~/development works on both desktop and laptop.
    if [[ "${directory:A}" == "${PWD:A}" ]]; then
      if [[ -z "${run_command//[[:space:]]/}" ]]; then
        print -u2 -r -- "r: empty command for $directory in $config_file"
        return 1
      fi
      # Run in a subshell, preserving the caller's directory and shell options.
      # Append arguments without interpreting their contents as shell code.
      eval "$run_command"' "$@"'
      return $?
    fi
  done

  print -u2 -r -- "r: no run command configured for $PWD"
  print -u2 -r -- "Add a mapping with vrun, then rebuild to apply it"
  return 1
)
