import json
import os
import runpy
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().with_name("announce_update.py")
BASE = {"latest_build": 6, "min_required_build": 3, "title": "Update"}
ARGS = dict(app="user_app", version="3.1.6", build="7", message="Update available",
            mandatory=False, android_url="https://github.com/NORALDAYEM/Halla/releases/download/v3.1.6/Halaa-App-Android.apk",
            ios_url="https://testflight.apple.com/join/Example1")


class AnnouncementTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.path = Path(self.tmp.name) / "app_version.json"
        self.path.write_text(json.dumps({"user_app": BASE, "admin_app": BASE}))
        self.addCleanup(self.tmp.cleanup)

    def announce(self, platform, **overrides):
        args = dict(ARGS, platform=platform)
        args.update(overrides)
        with patch.dict(os.environ, RELEASE_INPUTS=json.dumps(args)), patch("urllib.request.urlopen"):
            here = Path(os.getcwd())
            try:
                os.chdir(self.tmp.name)
                runpy.run_path(str(SCRIPT.resolve()))
            finally:
                os.chdir(here)
        return json.loads(self.path.read_text())

    def test_optional_single_platform_then_legacy_delivery(self):
        first = self.announce("android")
        self.assertEqual(first["user_app"]["latest_build"], 6)
        self.assertEqual(first["user_app"]["platforms"]["android"]["min_required_build"], 3)
        android = first["user_app"]["platforms"]["android"]
        self.assertEqual(android["fresh_install_url"], ARGS["android_url"])
        self.assertTrue(android["rooms_download_url"].endswith("/Halaa-Rooms-Android.apk"))
        self.assertEqual(android["download_url"], android["rooms_download_url"])
        both = self.announce("ios")
        self.assertEqual(both["user_app"]["latest_build"], 7)
        self.assertIn("mobile-update.html", both["user_app"]["download_url"])
        self.assertEqual(both["admin_app"], BASE)

    def test_mandatory_and_reject_downgrade(self):
        data = self.announce("both", mandatory=True)
        self.assertEqual(data["user_app"]["min_required_build"], 7)
        with self.assertRaises(ValueError):
            self.announce("android", build="6")
        self.assertEqual(json.loads(self.path.read_text()), data)

    def test_reject_wrong_platform_without_partial_write(self):
        original = self.path.read_text()
        with self.assertRaises(ValueError):
            self.announce("both", ios_url=ARGS["android_url"])
        self.assertEqual(self.path.read_text(), original)


if __name__ == "__main__":
    unittest.main()
