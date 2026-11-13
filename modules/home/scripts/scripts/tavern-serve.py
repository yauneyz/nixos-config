#!/usr/bin/env python3
"""Run SillyTavern plus textgen's model UI/API as one local session."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, indent=2)
            stream.write("\n")
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def configure_frontend(data_home, template, api_url):
    """Change only connection settings; retain an original backup on first change."""
    settings = data_home / "SillyTavern/data/default-user/settings.json"
    existing = settings.exists()
    value = json.loads((settings if existing else template).read_text())
    original = json.dumps(value, sort_keys=True)
    value["main_api"] = "openai"
    connection = value.setdefault("oai_settings", {})
    connection["chat_completion_source"] = "custom"
    connection["custom_url"] = api_url
    # textgen serves whichever model is selected in its Model tab.
    connection.setdefault("custom_model", "")
    if json.dumps(value, sort_keys=True) != original:
        backup = settings.with_name("settings.before-tavern-serve.json")
        if existing and not backup.exists():
            shutil.copy2(settings, backup)
        atomic_json(settings, value)
    elif not existing:
        atomic_json(settings, value)
    return settings


def probe(url, kind):
    try:
        with urllib.request.urlopen(url, timeout=2) as response:
            body = response.read(1024 * 1024)
        if kind == "api":
            result = json.loads(body)
            return isinstance(result, dict) and isinstance(result.get("data"), list)
        if kind == "frontend":
            result = json.loads(body)
            return isinstance(result, dict) and isinstance(result.get("token"), str)
        return b"gradio" in body.lower() or b"textgen" in body.lower()
    except (OSError, ValueError, urllib.error.URLError):
        return False


def port_busy(port):
    with socket.socket() as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(("127.0.0.1", port))
        except OSError:
            return True
    return False


def service_state(port, url, kind):
    if not port_busy(port):
        return False
    if probe(url, kind):
        return True
    raise RuntimeError(f"Port {port} is already occupied by an incompatible or unready service. Stop it or choose another port.")


def model_selection(value, models_dir):
    if not value:
        return None, models_dir
    path = Path(value).expanduser()
    if not path.is_absolute():
        candidate = Path.cwd() / path
        path = candidate if candidate.is_file() else models_dir / path
    if not path.exists():
        raise RuntimeError(f"Model does not exist: {path}")
    path = path.resolve()
    try:
        return str(path.relative_to(models_dir.resolve())), models_dir
    except ValueError:
        return path.name, path.parent


def stop_children(children):
    for process, _ in reversed(children):
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
    deadline = time.monotonic() + 12
    for process, stream in reversed(children):
        try:
            process.wait(timeout=max(.1, deadline - time.monotonic()))
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            process.wait()
        stream.close()


def run(args):
    for port in [args.port, args.model_ui_port, args.api_port]:
        if not 1 <= port <= 65535:
            raise RuntimeError("Ports must be between 1 and 65535.")
    if len({args.port, args.model_ui_port, args.api_port}) != 3:
        raise RuntimeError("Chat, model UI and API ports must be different.")
    state_home = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "tavern-serve"
    state_home.mkdir(parents=True, exist_ok=True)
    lock = (state_home / "session.lock").open("w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        raise RuntimeError("tavern-serve is already running. Use its browser tabs or stop that session first.")
    # Keep lock alive for the lifetime of this process.
    children = []
    chat_url = f"http://127.0.0.1:{args.port}"
    ui_url = f"http://127.0.0.1:{args.model_ui_port}"
    api_url = f"http://127.0.0.1:{args.api_port}/v1"
    frontend_running = service_state(args.port, chat_url + "/csrf-token", "frontend")
    api_running = service_state(args.api_port, api_url + "/models", "api")
    ui_running = service_state(args.model_ui_port, ui_url, "ui")
    if api_running != ui_running:
        raise RuntimeError("Only one textgen endpoint is running. Start/stop textgen as a pair, or choose free API and model UI ports.")
    if api_running and args.model:
        raise RuntimeError("Textgen is already running: choose the model in its Model tab instead of passing a startup model.")

    def start(name, command, environment):
        logfile = state_home / (name + ".log")
        stream = logfile.open("a", buffering=1)
        print(f"Starting {name}; log: {logfile}", flush=True)
        try:
            process = subprocess.Popen(command, env=environment, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
        except BaseException:
            stream.close()
            raise
        children.append((process, stream))

    def check_children():
        for process, stream in children:
            if process.poll() is not None:
                raise RuntimeError(f"A managed service exited ({process.returncode}). Check {stream.name}")

    try:
        env = os.environ.copy()
        models_dir = Path(env.get("TEXTGEN_MODELS_DIR", env.get("LLAMA_MODELS_DIR", str(Path.home() / "Games/Models")))).expanduser()
        model, models_dir = model_selection(args.model, models_dir)
        if not api_running:
            env.update(TEXTGEN_HOST="127.0.0.1", TEXTGEN_PORT=str(args.model_ui_port), TEXTGEN_API_PORT=str(args.api_port),
                       TEXTGEN_MODELS_DIR=str(models_dir), TEXTGEN_AUTO_LAUNCH="0", TEXTGEN_LISTEN="0")
            if model:
                env["TEXTGEN_MODEL"] = model
            start("textgen", ["textgen-serve"], env)
        else:
            print("Reusing textgen; it will remain running when this session ends.", flush=True)
        if not frontend_running:
            data_home = Path(env.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))).expanduser()
            template = Path(env["TAVERN_DEFAULT_SETTINGS"])
            settings = configure_frontend(data_home, template, api_url)
            print(f"SillyTavern connection configured in {settings}", flush=True)
            command = [env["TAVERN_NODE"], env["TAVERN_FRONTEND_ENTRY"], "--port", str(args.port),
                       "--listen=false", "--browserLaunchEnabled=false"]
            start("sillytavern", command, env)
        else:
            print(f"Reusing SillyTavern. If needed, select Custom OpenAI-compatible and {api_url} in API Connections.", flush=True)

        print("Waiting for browser UIs and API (first-run backend installation can take several minutes)...", flush=True)
        deadline = time.monotonic() + args.startup_timeout
        while not (probe(chat_url + "/csrf-token", "frontend") and probe(ui_url, "ui") and probe(api_url + "/models", "api")):
            check_children()
            if time.monotonic() >= deadline:
                raise RuntimeError(f"Startup timed out. Check logs in {state_home}")
            time.sleep(1)
        print(f"\nChat:             {chat_url}\nModels/settings:  {ui_url}\nModel folder:     {models_dir}\nBackend API:      {api_url}\n", flush=True)
        print("Choose a model in textgen's Model tab, set its loader options, and Load. Use Save settings for this model to keep loader configurations.", flush=True)
        print("Chat in SillyTavern; its API Connections panel can refresh the loaded model. Ctrl+C stops services started by this command.", flush=True)
        if not args.no_browser:
            opener = shutil.which("xdg-open")
            if opener:
                for url in [ui_url, chat_url]:
                    subprocess.Popen([opener, url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        while True:
            check_children()
            time.sleep(1)
    finally:
        stop_children(children)
        lock.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", nargs="?", help="Optional model file/directory beneath the shared model folder, or an absolute path. Otherwise choose in the UI.")
    parser.add_argument("--no-browser", action="store_true")
    parser.add_argument("--port", type=int, default=int(os.environ.get("TAVERN_PORT", 8000)), help="SillyTavern chat port")
    parser.add_argument("--model-ui-port", type=int, default=int(os.environ.get("TEXTGEN_PORT", 7860)))
    parser.add_argument("--api-port", type=int, default=int(os.environ.get("TEXTGEN_API_PORT", 5000)))
    parser.add_argument("--startup-timeout", type=int, default=1800)
    args = parser.parse_args()
    def interrupted(_signal, _frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    try:
        run(args)
    except KeyboardInterrupt:
        print("\nTavern session stopped.")
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(f"tavern-serve: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
