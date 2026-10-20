{ userPaths }:
{
  # Exact directory -> run command. Edit with vrun, then rebuild to apply.
  "${userPaths.development}/jirachi" = "bun run dev";
  # "${userPaths.development}/my-project" = "npm run dev";
  # "${userPaths.development}/my-rust-project" = "cargo run --";
}
