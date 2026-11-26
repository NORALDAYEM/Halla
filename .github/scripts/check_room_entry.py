import re
import subprocess
import time
import xml.etree.ElementTree as ET

import uiautomator2 as u2

DEVICE = u2.connect()
DEVICE.jsonrpc.setConfigurator({"waitForIdleTimeout": 0, "waitForSelectorTimeout": 0})


def adb(*args):
    return subprocess.check_output(["adb", *args], text=True, timeout=20)


def locate(phrase, *, tap=False, scroll=False):
    last_labels = []
    for attempt in range(18):
        try:
            root = ET.fromstring(DEVICE.dump_hierarchy())
        except (subprocess.SubprocessError, ET.ParseError):
            time.sleep(1)
            continue
        last_labels = []
        for node in root.iter("node"):
            label = (node.get("content-desc", "") + " " + node.get("text", "")).strip()
            if label:
                last_labels.append(label)
            if phrase not in label:
                continue
            if tap:
                left, top, right, bottom = map(int, re.findall(r"\d+", node.get("bounds", "")))
                adb("shell", "input", "tap", str((left + right) // 2), str((top + bottom) // 2))
            print("Verified:", phrase, flush=True)
            return
        if scroll and attempt >= 2 and attempt % 2 == 0:
            adb("shell", "input", "swipe", "480", "1600", "480", "850", "350")
        time.sleep(1)
    raise RuntimeError(f"Missing {phrase!r} on guest test device. Visible labels: {last_labels[:45]}")


locate("وضع الضيف", tap=True)
locate("ديوانية نجوم هلا", tap=True, scroll=True)
locate("الدخول للانضمام إلى الغرفة")
