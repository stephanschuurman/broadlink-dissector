#!/usr/bin/env python3
"""Generate cloud-content.md from configguide.json."""

import json
import os

TYPEIDS = {
    "1000168901000000000076accfe44d8e": "Universal Remote",
    "1000168901000000000030a5fc8ab9e1": "Gateway",
    "1000168901000000000030a5fc8ab9e2": "S3 Smart Kit",
    "100016890100000000002dc8a03f3b8c": "Sensor",
    "1000168901000000000099c3a0c31920": "Smart Plug",
    "10001689010000000000fd364e3dfdfa": "Smart Bulb",
    "10001689010000000000a78d070efef4": "General Wifi Device",
}

CONFIG_METHOD_NAMES = {
    0: "Bluetooth AP Mode",
    1: "AP Setup Mode",
    2: "Smart Setup Mode",
    3: "Sub-device (Zigbee/RF)",
    4: "EZ Mode",
    5: "Hotspot Mode",
    6: "AP Mode (generic)",
}

FLASH_MODE_NAMES = {
    0: "intermittent (slow blink) — AP mode indicator",
    1: "quick flash — Smart/EasyLink mode indicator",
}

SUBDEV_PROTOCOLS = {
    0: "Wi-Fi direct",
    16: "Zigbee (0x10)",
}


def pid_list(raw: str) -> list[str]:
    return [p.strip() for p in raw.split(",") if p.strip()]


def format_pid(pid: str) -> str:
    """Extract the meaningful 4-byte device type from a 32-hex devpid string."""
    # devpid is 32 hex chars; bytes 20-24 (0-indexed) hold the device type LE
    if len(pid) == 32:
        dev_type = bytes.fromhex(pid[20:28])
        dev_type_int = int.from_bytes(dev_type, "little")
        return f"`{pid}` (dev type `0x{dev_type_int:04X}`)"
    return f"`{pid}`"


base_dir = os.path.dirname(os.path.abspath(__file__))
json_path = os.path.join(base_dir, "configguide.json")

with open(json_path, encoding="utf-8") as f:
    data = json.load(f)

lines = []
a = lines.append

a("# Cloud Content — Config Guide")
a("")
a("> Data fetched from the BroadLink cloud API by the BroadLink app to display device")
a("> setup instructions, product images, and pairing animations.")
a("")
a("---")
a("")
a("## API Endpoint")
a("")
a("```")
a("POST https://ai-service-eu-001.ibroadlink.com/vtproxy/common")
a("```")
a("")
a("Also served from regional mirrors:")
a("")
a("- `https://ai-service-eu-001.ibroadlink.com/vtproxy/common`")
a("- `https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile` (static files)")
a("")
a("### Request Headers")
a("")
a("| Header | Example Value |")
a("| --- | --- |")
a('| `Content-Type` | `application/json` |')
a('| `messageId` | current epoch timestamp (e.g. `1746000000`) |')
a('| `userid` | MD5 hex string (account user ID) |')
a('| `licenseid` | MD5 hex string |')
a('| `companyid` | MD5 hex string |')
a('| `language` | `en` |')
a('| `User-Agent` | `BroadLink/1.7.67 (iPad; iOS 26.3; Scale/2.00)` |')
a("")
a("### Request Payload — `getconfigguide`")
a("")
a("```json")
a('{')
a('  "ope": "getconfigguide",')
a('  "typedid": "<category type ID>",')
a('  "devpid": "",')
a('  "pid": "00000000000000000000000017890100"')
a('}')
a("```")
a("")
a("### Response Envelope")
a("")
a("```json")
a('{')
a('  "status": 0,')
a('  "msg": "ok",')
a('  "detail": "",')
a('  "data": [ ... ]')
a('}')
a("```")
a("")
a("---")
a("")
a("## Category Type IDs")
a("")
a("| Type ID | Category |")
a("| --- | --- |")
for tid, name in TYPEIDS.items():
    a(f"| `{tid}` | {name} |")
a("")
a("---")
a("")
a("## Field Reference")
a("")
a("### Product fields")
a("")
a("| Field | Type | Description |")
a("| --- | --- | --- |")
a("| `name` | string | Display name shown in the app |")
a("| `producttype` | string | Category label |")
a("| `productmodel` | string | Model string or setup mode hint |")
a("| `productimage` | URL | 88×88 px product list image |")
a("| `devpid` | string | Comma-separated 32-hex device PIDs matched against the LAN discovery broadcast |")
a("| `installdevpid` | string | PID(s) that trigger an install flow |")
a("| `apname` | string | AP SSID prefix used during AP Setup Mode (e.g. `BroadLink_WiFi_Device`, `BroadlinkProv`) |")
a("| `bluetoothname` | string | Bluetooth device name prefix for BLE-assisted pairing |")
a("| `apsamename` | 0/1 | `1` = device AP SSID matches generic name; `0` = unique per device |")
a("| `cluster` | int | Sub-device cluster ID (0 = standalone) |")
a("| `shelfstate` | 0/1 | `1` = visible in app product list |")
a("| `SortNum` | int | Sort order within category |")
a("| `indicator_title` | string | Indicator LED section title (unused / empty in current data) |")
a("| `indicator_switch_desc` | string | Description for indicator switch (unused) |")
a("| `indicator_anothermode_title` | string | Alt mode title (unused) |")
a("")
a("### Config method fields (per `configmethod` entry)")
a("")
a("| Field | Type | Description |")
a("| --- | --- | --- |")
a("| `configmethodname` | int | Setup method (see table below) |")
a("| `subdevprotocol` | int | Sub-device radio protocol: `0` = Wi-Fi direct, `16` (0x10) = Zigbee |")
a("| `flashmode` | 0/1 | LED state the device must be in: `0` = slow blink (AP), `1` = fast blink (Smart) |")
a("| `longpresssecond` | int | Seconds to hold reset button to enter this mode |")
a("| `waitsecond` | int | Seconds the app waits before proceeding |")
a("| `gif1` | URL | Animation shown during pairing (light theme) |")
a("| `gif1_night` | URL | Animation shown during pairing (dark theme) |")
a("| `gif2` | URL | Reset/hardware instruction image |")
a("| `specialdesc` | string | Primary description (often empty; see `specialdesc1`/`specialdesc2`) |")
a("| `specialdesc1` | string | Pairing-mode indicator description |")
a("| `specialdesc2` | string | Reset instruction override |")
a("| `notsupportedgwpid` | array | Gateway PIDs that cannot be used as parent for this device |")
a("| `customizeddesc` | string | Custom description (unused in current data) |")
a("| `customizeddesc2` | string | Custom description 2 (unused) |")
a("")
a("### `configmethodname` values")
a("")
a("| Value | Name | Description |")
a("| --- | --- | --- |")
for k, v in CONFIG_METHOD_NAMES.items():
    a(f"| `{k}` | {v} | |")
a("")
a("---")
a("")
a("## Products by Category")
a("")

for tid, cat_name in TYPEIDS.items():
    cat_data = data.get(tid, {})
    products = cat_data.get("data", [])
    a(f"### {cat_name}")
    a("")
    a(f"> Type ID: `{tid}` — {len(products)} product(s)")
    a("")

    for p in products:
        a(f"#### {p['name']}")
        a("")
        img = p.get("productimage", "")
        if img:
            a(f"![{p['name']}]({img})")
            a("")

        a("| Field | Value |")
        a("| --- | --- |")
        a(f"| **Product type** | {p.get('producttype','')} |")
        a(f"| **Product model** | {p.get('productmodel','')} |")
        a(f"| **Sort #** | {p.get('SortNum','')} |")
        a(f"| **AP name** | `{p.get('apname','')}` |" if p.get('apname') else f"| **AP name** | — |")
        if p.get('bluetoothname'):
            a(f"| **Bluetooth name prefix** | `{p.get('bluetoothname','')}` |")
        a(f"| **AP same name** | {p.get('apsamename','')} |")

        pids = pid_list(p.get("devpid", ""))
        if pids:
            pid_str = ", ".join(f"`{x}`" for x in pids)
            a(f"| **Device PID(s)** | {pid_str} |")
        else:
            a("| **Device PID(s)** | — |")

        install_pids = pid_list(p.get("installdevpid", ""))
        if install_pids:
            a(f"| **Install PID(s)** | {', '.join(f'`{x}`' for x in install_pids)} |")

        a("")

        methods = p.get("configmethod", [])
        for m in methods:
            mn = m.get("configmethodname", "?")
            method_label = CONFIG_METHOD_NAMES.get(mn, f"Method {mn}")
            flash = m.get("flashmode", 0)
            flash_label = "fast blink (Smart mode)" if flash else "slow blink (AP mode)"
            long_press = m.get("longpresssecond", 0)
            wait = m.get("waitsecond", 0)
            proto = m.get("subdevprotocol", 0)
            proto_label = SUBDEV_PROTOCOLS.get(proto, f"0x{proto:02X}")

            a(f"**Config method {mn} — {method_label}**")
            a("")
            a("| Field | Value |")
            a("| --- | --- |")
            a(f"| Long-press to enter | {long_press}s |")
            a(f"| Wait before proceed | {wait}s |")
            a(f"| LED flash mode | {flash} — {flash_label} |")
            a(f"| Sub-device protocol | {proto_label} |")

            for desc_field in ("specialdesc1", "specialdesc2", "specialdesc"):
                val = m.get(desc_field, "").strip()
                if val:
                    label = {"specialdesc1": "Pairing indicator note",
                             "specialdesc2": "Reset instruction",
                             "specialdesc": "Description"}.get(desc_field, desc_field)
                    a(f"| {label} | {val} |")

            gif1 = m.get("gif1", "")
            gif1n = m.get("gif1_night", "")
            gif2 = m.get("gif2", "")
            if gif1:
                a(f"| Pairing GIF (light) | [view]({gif1}) |")
            if gif1n:
                a(f"| Pairing GIF (dark) | [view]({gif1n}) |")
            if gif2:
                a(f"| Reset image | [view]({gif2}) |")

            no_gw = m.get("notsupportedgwpid", [])
            if no_gw:
                a(f"| Not supported gateway PIDs | {', '.join(f'`{x}`' for x in no_gw)} |")

            a("")

        a("---")
        a("")

output = "\n".join(lines)

out_path = os.path.join(base_dir, "cloud-content.md")
with open(out_path, "w", encoding="utf-8") as f:
    f.write(output)

print(f"Written {len(lines)} lines to {out_path}")
