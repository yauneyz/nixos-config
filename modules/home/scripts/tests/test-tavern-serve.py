import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

source = Path(__file__).resolve().parents[1] / "scripts/tavern-serve.py"
if not source.is_file():
    source = Path(__file__).with_name("tavern-serve.py")
spec = importlib.util.spec_from_file_location("tavern", source)
tavern = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tavern)


class TavernTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.template = self.root / "default.json"
        self.template.write_text(json.dumps({"theme": "original", "oai_settings": {"temperature": .8}}))

    def tearDown(self):
        self.temporary.cleanup()

    def test_seed_connection_without_losing_defaults(self):
        path = tavern.configure_frontend(self.root, self.template, "http://127.0.0.1:5000/v1")
        result = json.loads(path.read_text())
        self.assertEqual(result["theme"], "original")
        self.assertEqual(result["oai_settings"]["temperature"], .8)
        self.assertEqual(result["main_api"], "openai")
        self.assertEqual(result["oai_settings"]["custom_url"], "http://127.0.0.1:5000/v1")

    def test_existing_settings_backed_up_once(self):
        path = self.root / "SillyTavern/data/default-user/settings.json"
        path.parent.mkdir(parents=True)
        original = {"theme": "custom", "oai_settings": {"temperature": .3, "custom_model": "my-selected-model"}, "extra": [1, 2]}
        path.write_text(json.dumps(original))
        tavern.configure_frontend(self.root, self.template, "http://127.0.0.1:5000/v1")
        backup = path.with_name("settings.before-tavern-serve.json")
        self.assertEqual(json.loads(backup.read_text()), original)
        tavern.configure_frontend(self.root, self.template, "http://127.0.0.1:5010/v1")
        self.assertEqual(json.loads(backup.read_text()), original)
        self.assertEqual(json.loads(path.read_text())["extra"], [1, 2])
        self.assertEqual(json.loads(path.read_text())["oai_settings"]["custom_model"], "my-selected-model")

    def test_invalid_existing_settings_are_not_overwritten(self):
        path = self.root / "SillyTavern/data/default-user/settings.json"
        path.parent.mkdir(parents=True)
        path.write_text("broken JSON")
        with self.assertRaises(ValueError):
            tavern.configure_frontend(self.root, self.template, "http://127.0.0.1:5000/v1")
        self.assertEqual(path.read_text(), "broken JSON")

    def test_nested_model_preserves_shared_folder(self):
        model = self.root / "models/sub folder/model.gguf"
        model.parent.mkdir(parents=True)
        model.touch()
        name, directory = tavern.model_selection("sub folder/model.gguf", self.root / "models")
        self.assertEqual(name, "sub folder/model.gguf")
        self.assertEqual(directory, self.root / "models")

    def test_external_model_uses_its_parent(self):
        model = self.root / "external.gguf"
        model.touch()
        name, directory = tavern.model_selection(str(model), self.root / "models")
        self.assertEqual(name, "external.gguf")
        self.assertEqual(directory, self.root)

    def test_missing_model_is_reported(self):
        with self.assertRaises(RuntimeError):
            tavern.model_selection("missing.gguf", self.root)

    def test_shutdown_reaps_owned_process(self):
        log = (self.root / "process.log").open("w")
        process = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"], start_new_session=True)
        tavern.stop_children([(process, log)])
        self.assertIsNotNone(process.poll())
        self.assertTrue(log.closed)


if __name__ == "__main__":
    unittest.main()
