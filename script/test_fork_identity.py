"""Guard fork-specific isolation when integrating upstream updates."""
import pathlib
import plistlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class ForkIdentityTests(unittest.TestCase):
    def test_plist_has_no_upstream_update_feed_or_key(self):
        with (ROOT / "resources/WinMux-Info.plist").open("rb") as stream:
            info = plistlib.load(stream)
        self.assertFalse(info["SUEnableAutomaticChecks"])
        self.assertNotIn("SUFeedURL", info)
        self.assertNotIn("SUPublicEDKey", info)

    def test_project_generates_only_fork_bundle_identifiers(self):
        project = (ROOT / "project.yml").read_text()
        self.assertIn("PRODUCT_BUNDLE_IDENTIFIER: com.gfavaro.winmux\n", project)
        self.assertIn("PRODUCT_BUNDLE_IDENTIFIER: com.gfavaro.winmux.debug\n", project)
        self.assertNotIn("com.zimengxiong", project)
        self.assertNotIn("SUFeedURL", project)
        self.assertNotIn("SUPublicEDKey", project)

    def test_release_does_not_initialize_sparkle(self):
        app = (ROOT / "Sources/WinMuxApp/WinMuxApp.swift").read_text()
        updater = (ROOT / "Sources/SparkleSupport/AutomaticUpdates.swift").read_text()
        self.assertNotIn("AutomaticUpdates.start()", app)
        self.assertNotIn("AutomaticUpdates.checkForUpdates()", app)
        self.assertNotIn("SPUStandardUpdaterController(", updater)

    def test_fork_does_not_delete_upstream_login_items(self):
        login = (ROOT / "Sources/AppBundle/config/startAtLogin.swift").read_text()
        self.assertNotIn("removeItem", login)

    def test_cli_name_cannot_overwrite_app_on_case_insensitive_volumes(self):
        build = (ROOT / "script/fork-build.sh").read_text()
        self.assertIn('"$fork_app/Contents/MacOS/winmux-gf-cli"', build)
        self.assertNotIn('"$fork_app/Contents/MacOS/winmux-gf"', build)
        self.assertNotEqual("WinMux-GF".casefold(), "winmux-gf-cli".casefold())


if __name__ == "__main__":
    unittest.main()
