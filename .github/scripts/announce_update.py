import json
import os
import re
from pathlib import Path
from urllib.parse import urlsplit
from urllib.request import Request, urlopen

args = json.loads(os.environ["RELEASE_INPUTS"])
app = args["app"]
target = args["platform"]
build = int(args["build"])
version = args["version"].strip()
message = args["message"].strip()
if app not in {"user_app", "admin_app"} or target not in {"android", "ios", "both"}:
    raise ValueError("Unknown update target")
if build < 1 or not re.fullmatch(r"\d+(?:\.\d+){1,3}", version) or not message:
    raise ValueError("Provide a released version, positive build number and notification message")
manifest = Path("app_version.json")
data = json.loads(manifest.read_text())
section = data[app]
platforms = section.setdefault("platforms", {})
mandatory = args["mandatory"] in (True, "true")
targets = ["android", "ios"] if target == "both" else [target]
for platform in targets:
    url = args[platform + "_url"].strip()
    uri = urlsplit(url)
    name = "Halaa-App-Android.apk" if app == "user_app" else "Halaa-Admin-Android.apk"
    application_id = "com.halla.halaa_user_app" if app == "user_app" else "com.halla.halaa_admin_app"
    if platform == "android":
        allowed = (uri.hostname == "github.com" and re.fullmatch(
            r"/NORALDAYEM/Halla/releases/download/(?!latest/)[\w.-]+/" + re.escape(name), uri.path
        )) or (uri.hostname == "play.google.com" and uri.path == "/store/apps/details" and
               uri.query == "id=" + application_id)
    else:
        allowed = (uri.hostname == "apps.apple.com" and re.search(r"/id\d+/?$", uri.path)) or (
            uri.hostname == "testflight.apple.com" and re.fullmatch(r"/join/[A-Za-z0-9]+", uri.path))
    if uri.scheme != "https" or uri.username or uri.password or not allowed:
        raise ValueError(f"Invalid {platform} release link")
    with urlopen(Request(url, method="HEAD", headers={"User-Agent": "Halla-release-check"}), timeout=30):
        pass
    previous = platforms.get(platform, section)
    if build < previous["latest_build"]:
        raise ValueError("Refusing to announce an older build")
    platforms[platform] = dict(latest_version=version, latest_build=build,
        min_required_build=build if mandatory else previous.get("min_required_build", 0),
        force_update=mandatory, update_type="major" if mandatory else "minor",
        title=section["title"], message=message, download_url=url)

# Older clients read only the shared section. Notify them when both platforms
# have the same published build and a compatible download for each device.
if all(p in platforms for p in ("ios", "android")) and all(
    platforms[p][key] == platforms["android"][key]
    for p in platforms for key in ("latest_build", "latest_version", "force_update", "message")
):
    section.update(platforms["android"])
    section["download_url"] = "https://noraldayem.github.io/Halla/mobile-update.html?app=" + app
manifest.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
