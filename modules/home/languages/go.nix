{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Language Server Protocol + IDE helpers
    gopls

    # Debugger
    delve

    # Linters and code quality
    golangci-lint
    gotools # includes goimports, godoc, etc.

    # REPL
    gore

    # Note: Install additional tools via `go install`:
    # - staticcheck: go install honnef.co/go/tools/cmd/staticcheck@latest
    # - gomodifytags: go install github.com/fatih/gomodifytags@latest
    # - impl: go install github.com/josharian/impl@latest
    # - gotests: go install github.com/cweill/gotests/gotests@latest
  ];

  # Set up Go environment variables
  home.sessionVariables = {
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
  };

  # Add GOBIN to PATH
  home.sessionPath = [
    "$HOME/go/bin"
  ];
}
