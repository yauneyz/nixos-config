{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Clojure runtime
    clojure

    # Build tools
    leiningen # Traditional Clojure build tool
    clojure-lsp # Language Server Protocol

    ###
    # IMPORTANT = npm i -g shadow-cljs
    ###

    # Linters and formatters
    clj-kondo # Linter for Clojure
    cljfmt # Code formatter

    # Fast-starting Clojure scripting environment
    babashka # Fast native Clojure interpreter for scripting

    # Development tools
    electron # Framework for building desktop apps with web technologies
    # Note: Clojure REPL is available via the 'clojure' package (run 'clj' or 'clojure')

    # Testing
    # Note: Most testing is done via Leiningen or deps.edn, so test runners are project-specific

    # Additional utilities
    joker # Small Clojure interpreter, linter, and formatter (alternative/complement to clj-kondo)
    jet # CLI to transform JSON/EDN data
  ];

  # Set up Clojure environment
  home.sessionVariables = {
    # Leiningen will use ~/.lein by default
    LEIN_HOME = "$HOME/.lein";
    # Clojure CLI will use ~/.clojure by default
    CLJ_CONFIG = "$HOME/.clojure";
  };
}
