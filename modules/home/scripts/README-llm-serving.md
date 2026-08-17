# Local LLM serving

`llm-serve` is the front door for local model serving. It selects a named target
from a TOML registry, applies machine-specific hardware settings, and then
executes the appropriate backend.

The registry is [`llm-serve.toml`](./llm-serve.toml). Home Manager installs it
as `$XDG_CONFIG_HOME/llm-serve/config.toml`. The launcher is
[`scripts/llm-serve.py`](./scripts/llm-serve.py).

## Everyday commands

```console
llm-serve                         # launch the configured default
llm-serve oss                     # launch a registry nickname
llm-serve --list                  # list nicknames and GPU expectations
llm-serve --show euryale          # show the resolved command and environment
llm-serve oss --dry-run           # equivalent launch inspection
llm-serve --validate              # check every model path and backend command
llm-serve oss --ctx-size 16384    # override a common setting
llm-serve oss -- --metrics        # pass an option directly to the backend
```

Launcher options may appear before or after the target. Backend-specific
arguments must follow `--`, which preserves every argument boundary safely.

The main aliases (`llmserve`, `oss-serve`, `w-serve`, `c-serve`,
`euryale-serve`, `vllmserve`, and `vllmembedserve`) now resolve through this
registry. The older `llama-serve-*` executables remain as compatibility wrappers.

## text-generation-webui

The upstream project commonly called text-generation-webui is installed and
launched by `textgen-serve`. It manages model selection and serving inside its
own UI, so it remains a useful standalone command:

```console
textgen-serve
```

It is also registered for discoverability and consistent overrides:

```console
llm-serve textgen
llm-serve textgen --model some-model-directory
llm-serve textgen --port 7861
llm-serve textgen -- --listen
```

Both launchers use the same `LLAMA_MODELS_DIR` / `TEXTGEN_MODELS_DIR` root.
Keep a split GGUF in one subdirectory and point a llama target at its first
`-00001-of-NNNNN.gguf` shard. Textgen scans those subdirectories recursively,
lists only the first shard, and loads the remaining shards automatically. This
keeps one shared model copy usable from both `llm-serve` and the web UI.

The first run can take a long time because `textgen-serve` installs the upstream
application and its Python/CUDA dependencies. Its checkout, user data, caches,
and model roots are kept on the configured data/model volumes rather than the
small NixOS root filesystem.

## How configuration is combined

Settings are layered in this order, with later values winning:

1. `[defaults]`
2. `[backends.BACKEND]`
3. `[targets.NAME]`
4. `[hosts.HOST.defaults]`
5. `[hosts.HOST.backends.BACKEND]`
6. `[hosts.HOST.targets.NAME]`
7. supported legacy environment overrides
8. `llm-serve` command-line overrides

The host defaults to the short system hostname. Override it for inspection with
`--host-profile desktop` or `LLM_SERVE_HOST_PROFILE=desktop`.

Relative llama.cpp model paths and `local_model` paths resolve beneath
`LLAMA_MODELS_DIR`, falling back to `~/Games/Models`. Hugging Face repository
IDs remain unchanged. `LLM_SERVE_CONFIG` or `--config` can select a different
registry without rebuilding.

## GPU offloading on the RTX 4090

The desktop profile describes the actual 24 GiB RTX 4090 policy:

```toml
[hosts.desktop.backends.llama]
gpu_layers = "auto"
fit = true
fit_target_mib = 2048
```

This becomes `--n-gpu-layers auto --fit on --fit-target 2048`. llama.cpp chooses
the maximum useful offload that fits while attempting to retain a 2 GiB startup
margin. Context length, KV cache types, other CUDA users, and backend overhead
all affect the final number of offloaded layers, so a fixed layer count would be
less reliable across these models.

Each target also has an informational `gpu_expectation` shown by `--list` and at
launch:

- `full`: weights and the configured context are expected to fit on the 4090.
- `mostly-full`: near the VRAM limit; automatic fitting may leave some work in RAM.
- `partial`: the model cannot fit and is expected to use substantial system RAM.
- `cpu`: intentionally CPU-served.
- `dynamic`: selected later by a UI or delegated launcher.

These labels do not change backend behavior; `gpu_layers`, `fit`,
`fit_target_mib`, `fit_ctx`, cache types, and vLLM memory settings do. If measured
behavior differs, update both the operational settings and the expectation.

For vLLM, the existing wrapper still computes safe defaults from visible GPUs
and free memory. Registry entries should set model-specific values such as
`max_model_len`, `max_num_seqs`, `reasoning_parser`, and
`expert_parallel`. Expert parallelism must be enabled intentionally for a
suitable mixture-of-experts deployment; it is not inferred merely from having
multiple GPUs.

## Adding or changing a target

Future agents should follow this sequence:

1. Add one `[targets.NICKNAME]` table to `llm-serve.toml`.
2. Choose one of the supported backends: `llama`, `vllm`, `embeddings-cpu`, or
   `command`.
3. Use a path relative to `LLAMA_MODELS_DIR` for a local GGUF. For vLLM or
   embeddings, set `model` to the remote repository ID and optionally set
   `local_model` to the preferred local directory.
4. Set a stable `served_name`; this is the model name exposed by the compatible
   API and is distinct from the command-line nickname.
5. Add model-specific context, reasoning, cache, sampling, and parallelism
   settings. Do not add a generic metadata override or reasoning parser unless
   the model needs it.
6. Set an honest `gpu_expectation` for the desktop 4090.
7. Put uncommon backend arguments in a TOML string array, never a shell string:

   ```toml
   args = ["--some-flag", "value with spaces"]
   ```

8. Run the checks below, rebuild, and repeat `llm-serve --validate` against the
   installed configuration.

Minimal llama.cpp example:

```toml
[targets.example]
backend = "llama"
description = "What this target is for"
model = "example-model.Q5_K_M.gguf"
served_name = "example"
gpu_expectation = "full"
ctx_size = 16384
flash_attn = "on"
```

Minimal vLLM example:

```toml
[targets.example-vllm]
backend = "vllm"
description = "Example through vLLM"
model = "org/example-model"
local_model = "example-model"
served_name = "example"
gpu_expectation = "full"
max_model_len = 16384
expert_parallel = false
```

A `command` target delegates to an application that owns its serving lifecycle:

```toml
[targets.some-ui]
backend = "command"
description = "A self-contained model UI/server"
command = ["some-ui-serve"]
gpu_expectation = "dynamic"
model_env = "SOME_UI_MODEL" # optional support for llm-serve --model
host_env = "SOME_UI_HOST"   # optional support for --bind-host
port_env = "SOME_UI_PORT"   # optional support for --port
```

## Verification

Before rebuilding, exercise the source registry directly:

```console
python modules/home/scripts/scripts/llm-serve.py \
  --config modules/home/scripts/llm-serve.toml --list

python modules/home/scripts/scripts/llm-serve.py \
  --config modules/home/scripts/llm-serve.toml \
  --host-profile desktop --show textgen
```

`--show` and `--dry-run` resolve model paths, so they fail early when a required
GGUF is absent. `--validate` additionally checks all registered targets and
backend commands. Finally evaluate or rebuild the Nix configuration so the
launcher and registry are installed together.

## Design boundaries

- The launcher starts one target and uses `exec`, preserving signals and exit
  status. `vllm-serve-both` remains the supervisor for the two-service stack.
- The CPU embeddings target uses the local OpenAI-compatible Python server even
  though its legacy executable is named `vllm-serve-embeddings`.
- TabbyAPI and text-generation-webui keep their own configuration/install logic;
  registry entries delegate to them rather than duplicating it.
- llama.cpp router mode is a separate option for API-time model switching. The
  registry selects a launch target at command time and works across backends.
