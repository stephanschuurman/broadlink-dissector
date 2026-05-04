# Cloud Content — Config Guide

> Data fetched from the BroadLink cloud API by the BroadLink app to display device
> setup instructions, product images, and pairing animations.

---

## API Endpoint

- `https://ai-service-eu-001.ibroadlink.com/vtproxy/common`
- `https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile` (static files)

### Request Headers

| Header | Example Value |
| --- | --- |
| `Content-Type` | `application/json` |
| `messageId` | current epoch timestamp (e.g. `1746000000`) |
| `userid` | MD5 hex string (account user ID) |
| `licenseid` | MD5 hex string |
| `companyid` | MD5 hex string |
| `language` | `en` |
| `User-Agent` | `BroadLink/1.7.67 (iPad; iOS 26.3; Scale/2.00)` |

### Request Payload — `getconfigguide`

```json
{
  "ope": "getconfigguide",
  "typedid": "<category type ID>",
  "devpid": "",
  "pid": "00000000000000000000000017890100"
}
```

### Response Envelope

```json
{
  "status": 0,
  "msg": "ok",
  "detail": "",
  "data": [ ... ]
}
```

---

## Category Type IDs

| Type ID | Category |
| --- | --- |
| `1000168901000000000076accfe44d8e` | Universal Remote |
| `1000168901000000000030a5fc8ab9e1` | Gateway |
| `1000168901000000000030a5fc8ab9e2` | S3 Smart Kit |
| `100016890100000000002dc8a03f3b8c` | Sensor |
| `1000168901000000000099c3a0c31920` | Smart Plug |
| `10001689010000000000fd364e3dfdfa` | Smart Bulb |
| `10001689010000000000a78d070efef4` | General Wifi Device |

---

## Field Reference

### Product fields

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | Display name shown in the app |
| `producttype` | string | Category label |
| `productmodel` | string | Model string or setup mode hint |
| `productimage` | URL | 88×88 px product list image |
| `devpid` | string | Comma-separated 32-hex device PIDs matched against the LAN discovery broadcast |
| `installdevpid` | string | PID(s) that trigger an install flow |
| `apname` | string | AP SSID prefix used during AP Setup Mode (e.g. `BroadLink_WiFi_Device`, `BroadlinkProv`) |
| `bluetoothname` | string | Bluetooth device name prefix for BLE-assisted pairing |
| `apsamename` | 0/1 | `1` = device AP SSID matches generic name; `0` = unique per device |
| `cluster` | int | Sub-device cluster ID (0 = standalone) |
| `shelfstate` | 0/1 | `1` = visible in app product list |
| `SortNum` | int | Sort order within category |
| `indicator_title` | string | Indicator LED section title (unused / empty in current data) |
| `indicator_switch_desc` | string | Description for indicator switch (unused) |
| `indicator_anothermode_title` | string | Alt mode title (unused) |

### Config method fields (per `configmethod` entry)

| Field | Type | Description |
| --- | --- | --- |
| `configmethodname` | int | Setup method (see table below) |
| `subdevprotocol` | int | Sub-device radio protocol: `0` = Wi-Fi direct, `16` (0x10) = Zigbee |
| `flashmode` | 0/1 | LED state the device must be in: `0` = slow blink (AP), `1` = fast blink (Smart) |
| `longpresssecond` | int | Seconds to hold reset button to enter this mode |
| `waitsecond` | int | Seconds the app waits before proceeding |
| `gif1` | URL | Animation shown during pairing (light theme) |
| `gif1_night` | URL | Animation shown during pairing (dark theme) |
| `gif2` | URL | Reset/hardware instruction image |
| `specialdesc` | string | Primary description (often empty; see `specialdesc1`/`specialdesc2`) |
| `specialdesc1` | string | Pairing-mode indicator description |
| `specialdesc2` | string | Reset instruction override |
| `notsupportedgwpid` | array | Gateway PIDs that cannot be used as parent for this device |
| `customizeddesc` | string | Custom description (unused in current data) |
| `customizeddesc2` | string | Custom description 2 (unused) |

### `configmethodname` values

| Value | Name | Description |
| --- | --- | --- |
| `0` | Bluetooth AP Mode | |
| `1` | AP Setup Mode | |
| `2` | Smart Setup Mode | |
| `3` | Sub-device (Zigbee/RF) | |
| `4` | EZ Mode | |
| `5` | Hotspot Mode | |
| `6` | AP Mode (generic) | |

---

## Products by Category

### Universal Remote

> Type ID: `1000168901000000000076accfe44d8e` — 13 product(s)

#### RM5 Plus

![RM5 Plus](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=80b75c30b6494c27939877bb530b18f3&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | RM5 Plus |
| **Sort #** | 4 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000024520000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=47db3bcfe97849439b6bf1e172e29aad&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=367e23fc5e9f48db8b51ea36d1b59bb1&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=9a24b01650fe4b38a3995ae546e47d49&mimetype=image/png&name=reset_750x560.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=7e763467ba384b3c88357aa26edd5836&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=219d30b8079c463c8e595f2f7f3c36c4&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3bd316d7c021451ea3ec6d316ae84c92&mimetype=image/png&name=reset_750x560.png) |

---

#### RM4 pro

![RM4 pro](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=9a3e520cd3254f60942961f7a3c9edf6&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | default AP setup mode |
| **Sort #** | 13 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000009b640000`, `0000000000000000000000003c650000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=842446478b74472a8fee4d4b690f0b9a&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=19501d2adf6742d7b49e11f0ce785ff0&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=93e84d7a4ab849f5a917d16979bb15a6&mimetype=image/png&name=reset_750x560.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=de68ce57079c4145aeb5993d2006de17&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f84a956d0c1e46b581f1fa31ca46f892&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2d14404639a342a6896878c71b436143&mimetype=image/png&name=reset_750x560.png) |

---

#### RM4 pro - 2019 version

![RM4 pro - 2019 version](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e746309fac334722b25e7c04eff6517c&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | default smart setup mode |
| **Sort #** | 16 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000026600000`, `000000000000000000000000a2610000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d1836721e14649088ae7494af1ef613e&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=705b4f6b42474a6983620b102cc86148&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=0471c8e75c114a4a936e9decd0439f58&mimetype=image/png&name=reset_750x560.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=7138a2371d78494eb2f30d6285de7c65&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=fb7e583c76f1428b905295f656493a94&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f371f9928c354280bdd2bb7f13b85165&mimetype=image/png&name=reset_750x560.png) |

---

#### RM4 mini

![RM4 mini](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5758d131fe1249479b6662bc661d550b&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | default AP setup mode |
| **Sort #** | 23 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000008d640000`, `0000000000000000000000003a650000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | For some models with reset hole not button, please use a needle to press and hold to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d4966b8ed7174894965251d0e9406bd5&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=73fb59f59c0a442097265db729737b2e&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=7db4781efd5e46fd9ccd01b51084d603&mimetype=image/png&name=reset_750x560.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | For some models with reset hole not button, please use a needle to press and hold to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=6a283afd9847437daf9505b60dcf7667&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=001bf4172e114e8ebd3abfcf4e95736e&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=1fde6b609ef745b1a72a77fc55bdd764&mimetype=image/png&name=reset_750x560.png) |

---

#### RM4 mini - 2019 version

![RM4 mini - 2019 version](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=efc0902897be409f820d4e5f01f83ee7&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | default smart setup mode |
| **Sort #** | 26 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `000000000000000000000000bc620000`, `0000000000000000000000000e610000`, `000000000000000000000000da510000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | For some models with reset hole not button, please use a needle to press and hold to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f18f5ed2ea424c9291ac18ffe3d3e1d4&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=deb0b701f1004ae5b984f58c09bf410f&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=a4358cd2f4594c469a33cb4e71295602&mimetype=image/png&name=reset_750x560.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | For some models with reset hole not button, please use a needle to press and hold to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=0f0b3c5ee4ba4e12b076156b31373764&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=dc3f488726284c80ac00fb1f8f3f5d89&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b0555732c43944f790c4ef3d6e11c594&mimetype=image/png&name=reset_750x560.png) |

---

#### RM4 mate

![RM4 mate](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=25273df1c9b848f4a0906eb2ba734662&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | RM4 mate / RM4 TV mate / RM4 AC mate |
| **Sort #** | 31 |
| **AP name** | `BroadLink_WiFi_Device` |
| **Bluetooth name prefix** | `BL-RM-` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000009520000`, `0000000000000000000000000e520000`, `00000000000000000000000010520000` |
| **Install PID(s)** | `00000000000000000000000009520000` |

**Config method 0 — Bluetooth AP Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f77c1798d2f5464196fa9310d459b119&mimetype=image/gif&name=AP_mode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=62126b5938564d9e9d5b46f69c22c701&mimetype=image/gif&name=AP_mode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4f670e15b54e40b891804fd919f82fd8&mimetype=image/png&name=reset_750x560.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d460af04c1c143b68fe42fe852f378e6&mimetype=image/gif&name=AP_mode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=452def96472a4aff87dcd733ce7d8978&mimetype=image/gif&name=AP_mode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=7bf2fbabc72a4248ac65dcd989fc5256&mimetype=image/png&name=reset_750x560.png) |

---

#### RM4C mate

![RM4C mate](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5a5eeda88d0845a9b54a94d9f16752ac&mimetype=image/png&name=产品列表_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | RM4C mate / RM4C mate S |
| **Sort #** | 32 |
| **AP name** | `BroadLink_WiFi_Device` |
| **Bluetooth name prefix** | `BL-RM-` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000011520000` |

**Config method 0 — Bluetooth AP Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f82dfbbda2f74df3a2b4b186b62a4eee&mimetype=image/gif&name=AP配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c76a4cd7ed2a4367b6fc06fff2323967&mimetype=image/gif&name=AP配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=1e82656dd72a457faaa9e4b1503293ba&mimetype=image/png&name=设备重置_750x560.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4a9752d37e594c51a2e48901c430bc5b&mimetype=image/gif&name=AP配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3d2397915d5b40718ca39aa9cf25f2a8&mimetype=image/gif&name=AP配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4cf217488ab5462383135f113db5b5ef&mimetype=image/png&name=设备重置_750x560.png) |

---

#### RM4C mini

![RM4C mini](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=852a3b5e65e34e85b2ff7d1c95cba327&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | default AP setup mode |
| **Sort #** | 43 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000039650000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | For some models with reset hole not button, please use a needle to press and hold to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c91297a408084adf98219fe70191b46c&mimetype=image/gif&name=AP_mode_360x360-White.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=1c4e4e88030c46bcb602e5418e8b8733&mimetype=image/gif&name=APmode_360x360-black.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3ece3c179ac14a1a83352266f3ccdef0&mimetype=image/png&name=reset_750x560.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | For some models with reset hole not button, please use a needle to press and hold to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=49b88c3cfa6644a1a26288c510e53e44&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=229552d3fddd459696a8dc76b14102cb&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3419de59fe524e08b33353f4f878bcce&mimetype=image/png&name=reset_750x560.png) |

---

#### RM4C mini - 2019 version

![RM4C mini - 2019 version](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=958d8c26cb594645a0841036a2eeaca9&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | default smart setup mode |
| **Sort #** | 45 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `000000000000000000000000be620000`, `0000000000000000000000000f610000`, `00000000000000000000000070600000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | For some models with reset hole not button, please use a needle to press and hold to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ee4da0f554564e90b918d3fd964398a1&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4e145e2cc0854a53bacbdc7b4f9dbf40&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f3bfec87c6c74e5db4b738b650b8e680&mimetype=image/png&name=reset_750x560.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | For some models with reset hole not button, please use a needle to press and hold to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=acae4b8092d2495e876cf4c415e9a4d1&mimetype=image/gif&name=AP_mode_360x360-White.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=280e50791fa845cab9c0433bbcccaaca&mimetype=image/gif&name=APmode_360x360-black.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5e19882d81764e73ba57a8a6ff7028ab&mimetype=image/png&name=reset_750x560.png) |

---

#### RM4C pro

![RM4C pro](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4be2fac3dec54e7aa8554d8bf8791ef6&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | RM4C pro |
| **Sort #** | 53 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000084610000`, `000000000000000000000000ca610000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5ab5f513cc834e4dad463c3e76ac5284&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ce2072a633ef428a87c0f2f1b93f8c54&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3f98dbbee27246f58a001c27efe86b7a&mimetype=image/png&name=list_750x560.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ca4b749719064b2495d04d9f54d56040&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=fa3077f17bfb4a2bbde288b9d687343b&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=dc1a1d0369d04050b7da55e6d8c35c8b&mimetype=image/png&name=list_750x560.png) |

---

#### RM mini 3

![RM mini 3](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=1f2cf8eab5a74f2f8469374ed47d8d4c&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | RM mini 3 |
| **Sort #** | 60 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000037270000`, `000000000000000000000000c7270000`, `000000000000000000000000de270000`, `000000000000000000000000365f0000`, `00000000000000000000000007650000`, `00000000000000000000000008650000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=87bb373bfecb43f8a6dbb08f2019b1f2&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=289d04f3ddd5428387c9c6aa4b723968&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=33a38972a7de499bb33030c47baaff30&mimetype=image/png&name=reset_750x560.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | Long press the reset button until blue LED indicator flashes quickly. Then release and long press the reset button again until it flashes intermittently to AP Setup mode. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=8fb6684bcb5247ed92b6d19083a0d7a2&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=35285473cefd4b028760b528fd912371&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5b2f483253be4de59cc4462376bb896e&mimetype=image/png&name=reset_750x560.png) |

---

#### RM MAX

![RM MAX](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=52e771e72f0e43b79081ae63e5827bf7&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | RM MAX |
| **Sort #** | 5 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000008baf0000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=7b89386270a542089dd5be7cb8ab3309&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c63511cce990489fa7049cfe2e17b699&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5a0a001e06284845962f3f06263a0dcf&mimetype=image/png&name=reset_750x560.png) |

---

#### RM pro

![RM pro](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=52e771e72f0e43b79081ae63e5827bf7&mimetype=image/png&name=list_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Universal Remote |
| **Product model** | RM pro / RM pro+ / RM home / RM2 |
| **Sort #** | 63 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000012270000`, `00000000000000000000000083270000`, `0000000000000000000000002a270000`, `00000000000000000000000087270000`, `0000000000000000000000009d270000`, `000000000000000000000000a9270000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=7b89386270a542089dd5be7cb8ab3309&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c63511cce990489fa7049cfe2e17b699&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5a0a001e06284845962f3f06263a0dcf&mimetype=image/png&name=reset_750x560.png) |

---

### Gateway

> Type ID: `1000168901000000000030a5fc8ab9e1` — 2 product(s)

#### Smart Hub

![Smart Hub](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3b2c682a9f9e414288def060f3152514&mimetype=image/png&name=产品列表_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | Gateway |
| **Product model** | S3 |
| **Sort #** | 1 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000009ca50000`, `0000000000000000000000004da60000` |
| **Install PID(s)** | `0000000000000000000000009ca50000`, `0000000000000000000000004da60000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ad9a5cb444b642a99b4786d138f6b17d&mimetype=image/gif&name=AP配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=6d3442a10d4d45c2abc51c884254c5d4&mimetype=image/gif&name=AP配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f210bec600f8402eaf6a75b8a015f5e9&mimetype=image/png&name=设备重置_750x560.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f95edbdea5d34826bb83338f457750cb&mimetype=image/gif&name=配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b4961279d20d499db4b40b226c4cf5a7&mimetype=image/gif&name=配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=be1ebddb2fc54c77be6273b01352f4dc&mimetype=image/png&name=设备重置_750x560.png) |

---

#### Wi-Fi Alarm Kit

![Wi-Fi Alarm Kit](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=422e827a164a4128812d1851b46c654a&mimetype=image/png&name=产品列表_88x88_s2.png)

| Field | Value |
| --- | --- |
| **Product type** | Gateway |
| **Product model** | S1/S2 |
| **Sort #** | 2 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `000000000000000000000000a5270000` |
| **Install PID(s)** | `000000000000000000000000a5270000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5731d44e9b5d4f04ac11d7943fb83072&mimetype=image/gif&name=配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=6f884a506cd24b9194a2c3633dc0c3c8&mimetype=image/gif&name=配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=40eca118934f471da83a823fb1d6c4b7&mimetype=image/png&name=设备重置_750x560.png) |

---

### S3 Smart Kit

> Type ID: `1000168901000000000030a5fc8ab9e2` — 6 product(s)

#### Smart Light Switch

![Smart Light Switch](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=39881daf98554cdcb8ec96cb4474f527&mimetype=image/png&name=Product+List_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | S3 Smart Kit |
| **Product model** | TC3-3 / TC3-2 / TC3-1 |
| **Sort #** | 3 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `00000000000000000000000024610000`, `00000000000000000000000023610000`, `00000000000000000000000022610000` |

**Config method 3 — Sub-device (Zigbee/RF)**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 180s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Zigbee (0x10) |
| Pairing indicator note | The device is in pairing mode if the LED indicator flashes every 1 second. |
| Reset instruction | f the device is not in pairing mode, press and hold any button for more than 5 seconds until the LED indicator flashes every 1 second to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4024f4ca46c545d39ad58827327e017a&mimetype=image/gif&name=Configuration+status_360x360-b.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=caaf9599fbe44d54a62502ba2bda0053&mimetype=image/gif&name=Configuration+status_360x360-h.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b8e38785076644b3b6a8f18bfab74456&mimetype=image/png&name=Device+reset__750x560.png) |

---

#### Motion Sensor

![Motion Sensor](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c60fb21f647e44e08f21448c4203f891&mimetype=image/png&name=产品列表_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | S3 Smart Kit |
| **Product model** |  PIR3-FC |
| **Sort #** | 1 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `000000000000000000000000e2610000` |
| **Install PID(s)** | `000000000000000000000000e2610000` |

**Config method 3 — Sub-device (Zigbee/RF)**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 2s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Zigbee (0x10) |
| Reset instruction | Press and holds the LED indicator foe 5s and loose |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=db6889a5799c4675b430e0dec8973ff2&mimetype=image/gif&name=配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e7d588479c3e4fa2adf80e18c8717738&mimetype=image/gif&name=配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=a5c7b03e79c34a08971bf366d389578d&mimetype=image/png&name=设备重置_750x560.png) |

---

#### Smart Light Switch

![Smart Light Switch](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=14550092062045029c2d83ccc37d58b5&mimetype=image/png&name=Product+List_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | S3 Smart Kit |
| **Product model** | LC1-1 / LC1-2 / LC1-3 |
| **Sort #** | 4 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `00000000000000000000000020650000`, `0000000000000000000000001f650000`, `0000000000000000000000001e650000` |

**Config method 3 — Sub-device (Zigbee/RF)**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 180s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Zigbee (0x10) |
| Pairing indicator note | The device is in pairing mode if the LED indicator flashes every 1 second. |
| Reset instruction | f the device is not in pairing mode, press and hold any button for more than 5 seconds until the LED indicator flashes every 1 second to reset device. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f2a48372b2924cdfb29ebb63ff62f5ba&mimetype=image/gif&name=Configuration+status_360x360-b.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ae62a6e4392f481d8bac50fe13ee51cc&mimetype=image/gif&name=Configuration+status_360x360-h.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=7458ce2bca7b459fb3ddc8522130dda1&mimetype=image/png&name=Device+reset__750x560.png) |

---

#### Smart Button

![Smart Button](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=939cea43a2104ed1a003a11f5518c6b3&mimetype=image/png&name=产品列表_88x88.png)

| Field | Value |
| --- | --- |
| **Product type** | S3 Smart Kit |
| **Product model** | SR3-4KEY |
| **Sort #** | 3 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `00000000000000000000000048650000` |
| **Install PID(s)** | `00000000000000000000000048650000` |

**Config method 3 — Sub-device (Zigbee/RF)**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 2s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Zigbee (0x10) |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=bbb7f440ab714c70be0d4176d3629609&mimetype=image/gif&name=配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b1b77fd99918494e9c5e8c35257404ef&mimetype=image/gif&name=配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=dd60cd97463544dba8b432d18b778808&mimetype=image/png&name=设备重置_750x560.png) |

---

#### Door Sensor

![Door Sensor](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c6f88a12ef93489d8f1d2dc261b6bde0&mimetype=image/png&name=产品图_360x360.png)

| Field | Value |
| --- | --- |
| **Product type** | S3 Smart Kit |
| **Product model** | DS4-FC |
| **Sort #** | 5 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `000000000000000000000000ffa70000` |

**Config method 3 — Sub-device (Zigbee/RF)**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 2s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Zigbee (0x10) |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=abaed5c4ac4c40fea1b358edbfb331fd&mimetype=image/gif&name=配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=186f03441e294ca194414e4510352489&mimetype=image/gif&name=配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=92e3cb73db5142998d7053e5523b0042&mimetype=image/png&name=设备重置_750x560.png) |

---

#### Motion Sensor

![Motion Sensor](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f4bab9ffdb5d4c89a20eb5f3a78232d2&mimetype=image/png&name=产品图_360x360.png)

| Field | Value |
| --- | --- |
| **Product type** | S3 Smart Kit |
| **Product model** | RS4-FC |
| **Sort #** | 9 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `00000000000000000000000035a90000` |

**Config method 3 — Sub-device (Zigbee/RF)**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 1s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Zigbee (0x10) |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=16ef5b162ad449c29e2826bac723c6ee&mimetype=image/gif&name=配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4b0025721dc94aeaa52b7ffc9055e956&mimetype=image/gif&name=配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2d917a0659874a4ba69ecb1c81ccbb9b&mimetype=image/png&name=设备重置_750x560.png) |

---

### Sensor

> Type ID: `100016890100000000002dc8a03f3b8c` — 1 product(s)

#### Motion Sensor

![Motion Sensor](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f4bab9ffdb5d4c89a20eb5f3a78232d2&mimetype=image/png&name=产品图_360x360.png)

| Field | Value |
| --- | --- |
| **Product type** | Sensor |
| **Product model** | SR4M |
| **Sort #** | 9 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `000000000000000000000000fca90000` |

**Config method 3 — Sub-device (Zigbee/RF)**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 1s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Zigbee (0x10) |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=16ef5b162ad449c29e2826bac723c6ee&mimetype=image/gif&name=配置状态_360x360-白.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4b0025721dc94aeaa52b7ffc9055e956&mimetype=image/gif&name=配置状态_360x360-黑.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2d917a0659874a4ba69ecb1c81ccbb9b&mimetype=image/png&name=设备重置_750x560.png) |

---

### Smart Plug

> Type ID: `1000168901000000000099c3a0c31920` — 16 product(s)

#### 5G Smart Plug

![5G Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2d878c85b55e47b19c99a532ff4d8977&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP4D-US |
| **Sort #** | 1 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `000000000000000000000000f4a60000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing indicator note | For first use or after reset, the LED indicator will flash quickly (5 times/sec). Please wait for max 2 min until it flashes intermittently to enter AP Setup mode. |
| Reset instruction | After reset, wait for 120 seconds until the LED indicator flashes intermittently. Then tap "Next" to proceed with setup. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d898aa7295fd45b0870bf4d0c807d303&mimetype=image/gif&name=AP_360x360-.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=0a75956578c8480391c8b5ed18eb592c&mimetype=image/gif&name=AP.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f65b98d893da4631aa647173836b8a80&mimetype=image/png&name=reset.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e6526b5bee134c5d8dcbc38165c659a8&mimetype=image/png&name=product.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP4M-US |
| **Sort #** | 2 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000008b640000`, `0000000000000000000000007aa50000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ebee326caf1745c7a1538c797631512d&mimetype=image/gif&name=AP_360x360-.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4cab7a20e4b74a9cafa09f0f66b82d78&mimetype=image/gif&name=AP.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=eea1e2c3b01e456b9009ff1db252ac59&mimetype=image/png&name=reset.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=105990dfdbcf401cbf0afad6e09ea22b&mimetype=image/gif&name=smart_360x360-.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=0c28426fc324460c886511994dd0c459&mimetype=image/gif&name=smart.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=460c53b9981648edb7cb41082d82c31f&mimetype=image/png&name=reset.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3bdac9cc85754ecd9844cc6cf5185b45&mimetype=image/png&name=product.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP4L-EU |
| **Sort #** | 3 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000008b610000`, `0000000000000000000000006ca50000` |
| **Install PID(s)** | `0000000000000000000000008b610000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=17543bf1bca340dfa077a21664ed55a9&mimetype=image/gif&name=AP_360x360-.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5aa82d0656ae4ae5a0ff899490ef531d&mimetype=image/gif&name=AP.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=02b06e0e4b244a70a06a0fe16df25c81&mimetype=image/png&name=reset.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=9fd82a6164db48de841eccc780de4e3d&mimetype=image/gif&name=_360x360-.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b6f7c7afb70f4c288a3d758d58a37854&mimetype=image/gif&name=smart.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=8a545e3c24ad489d856999c7e8aa5208&mimetype=image/png&name=reset.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=a1d2f61f0b9945e98846d47ae081d4ed&mimetype=image/png&name=product.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP4L-US |
| **Sort #** | 4 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000008c640000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=a807821f16e64b429a8ae471febe266e&mimetype=image/gif&name=AP.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=666c4d0f9173434882f34ee5e27a1d84&mimetype=image/gif&name=AP_360x360-.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f42e15ba23b846c19ec97b97640517c8&mimetype=image/png&name=reset.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ecbd3dae2cae4a34936bf699799620f7&mimetype=image/gif&name=smart_360x360-.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=589e5f5b288d4e93bd802ee01b278ae7&mimetype=image/gif&name=samrt.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=eeed0e3ccb834c498577d2578623f1de&mimetype=image/png&name=reset.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=193d2c4cb693422bb30fe10a23c2d996&mimetype=image/png&name=p.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP4L-IN |
| **Sort #** | 5 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000085750000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d1d3f3c4b71a4907898c93934a1c370c&mimetype=image/gif&name=smart.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=8e9d056946924202b32d88ae73af2957&mimetype=image/gif&name=smart1.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4ea0263702584d8c8cede04024083ce6&mimetype=image/png&name=re.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5646192a11e84ce9b87bdea607da8a0b&mimetype=image/gif&name=AP.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=a9deb469b84040c8849cdd3f5a155f7b&mimetype=image/gif&name=ap1.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b7278d1da33042bb8526b151375611fb&mimetype=image/png&name=re.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=517befca264042289e0ef49691fca0e1&mimetype=image/png&name=p.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP4L-UK |
| **Sort #** | 6 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000089a50000`, `00000000000000000000000069a50000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=cad2c67a9ffd4393b9909525af400f96&mimetype=image/gif&name=apw.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=56ce0c15369a49af8cc78e8406145cf8&mimetype=image/gif&name=apb.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3f3160b3d3364d9c9a8e9f5b40b19fb9&mimetype=image/png&name=re.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ab0403a5fd774c5e9296fd999495788a&mimetype=image/gif&name=smart.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=50bef33ffce24cafbad1de483837f765&mimetype=image/gif&name=smartb.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=29bf044126e34278bc7785915ecceea1&mimetype=image/png&name=re.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=0f64efa14c864fa1b0f2c83bf0092ea4&mimetype=image/png&name=p.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP4L-AU |
| **Sort #** | 7 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000089640000`, `00000000000000000000000076a50000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=6e3ffac1ace6495e81f4909b2420d538&mimetype=image/gif&name=apw.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ea435c546d434f789849b76c38af3f2c&mimetype=image/gif&name=apb.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3ce710b0b5aa4cbaa805cabdbef43846&mimetype=image/png&name=re.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=fa7b5b31e89340ceb521e179e2d74914&mimetype=image/gif&name=smartw.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=cce11ae59e37484bab7667865fe4e652&mimetype=image/gif&name=smartb.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=02387cb9bc6e4710989b191752076b03&mimetype=image/png&name=re.png) |

---

#### ControL Box with monitor

![ControL Box with monitor](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d19f41aad2b44c4c8badcb9329343a97&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SCB1E |
| **Sort #** | 8 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000013610000`, `00000000000000000000000015510000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=9705174d4137438f89e5a35650ed52d5&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=733ad744166a48d7aa6137137e7bc6c9&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4a097114df5743f98d2c5b8b7f100505&mimetype=image/png&name=RE.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c29e7f8cf5b14317b7f07d99dbe832fc&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=db8a549090cb47159514544525f88ebc&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ae21c9b888554624ad9e2ce8cb240d47&mimetype=image/png&name=RE.png) |

---

#### Control Box

![Control Box](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=803563ece50c4a6c8808d6c02d004b30&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | MCB1 / SCB2 |
| **Sort #** | 12 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000006aa50000`, `00000000000000000000000094640000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=12a167c2f41742edac17288cfeda237e&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b09243c39c6745c8a2b521959ca28559&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=965c4c4603854d38b774ffb5ec3a44d1&mimetype=image/png&name=RE.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=4bf5980404114f2fade24960635ae1f1&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=10e0ab69488a461a89f6e9834ed1ecca&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e9f3fa5b4bbb4ed595452595aa2a5a0b&mimetype=image/png&name=RE.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ad4a165120484eb58f84d82da538c78f&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP3-US |
| **Sort #** | 14 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000033270000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 3s |
| Wait before proceed | 0s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=496fd8e8f8064b62b7fb24050186cb80&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=bec0822ffbc9423ea206a8832c2c96a3&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2eae4ea247f445d1a17d0ae77c40f622&mimetype=image/png&name=RE.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | In the case of LED flash, long press the reset button for more than 5 seconds until the LED flash intermittently |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c948684206e0431c93561bac48807f21&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=21c930866443486cba7621b3f7a98768&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=5d0dd01b2fe942a7853ef12881576c3b&mimetype=image/png&name=RE.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=6bbcd0a40afa4517bbe648e21c8a8e7f&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP3S-EU / SP3-EU |
| **Sort #** | 15 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000007a940000`, `00000000000000000000000033270000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b15884a6f77644bbb7329770fb1a6602&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=c5d97e78b6ce48d5b6fb98a9d4faa76a&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f9f3a37aec174b799843c78ac804d5b4&mimetype=image/png&name=RE.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | In the case of LED flash, long press the reset button for more than 5 seconds until the LED flash intermittently |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=9e38bb25f1fb457e9cf06f5a1e4baeec&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=9472e3669447451f8eed8e77ae592296&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=aa7c5e1508aa414d93599d20b250f181&mimetype=image/png&name=RE.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d03145b5ce3d41b6a4dad74cc35c594a&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP3-IN |
| **Sort #** | 16 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000042750000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ddd332d556a1409e9666885b534243a1&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e622c05e3f18466d93be73e6a7c3ec26&mimetype=image/gif&name=SMAERTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=fa25ba60d9a2447da2bafaebb727c6e1&mimetype=image/png&name=RE.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | In the case of LED flash, long press the reset button for more than 5 seconds until the LED flash intermittently |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ccbffc97fc614b7fb4417bd8d2816a1f&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e267dc0b60764fe88a721dfe94450bed&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=96fd15a32e7f4354b8b5be900132eb8a&mimetype=image/png&name=RE.png) |

---

#### SCB1E

![SCB1E](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=6866b250819f4cf48c48e0d5af3e73eb&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | default AP setup mode |
| **Sort #** | 16 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000006ba50000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d730a26e5b2a4d1a8eb70c2fe181badf&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=6ebd3fa424424e368375ba1061b461e2&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e48e03e9d914459091e5001a5fa850ef&mimetype=image/png&name=RE.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=1c21943507234920a972ef0ac873f718&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=85ed4486268243818c05028210b4dc6d&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=430ae3deeec140b884267c57297635df&mimetype=image/png&name=RE.png) |

---

#### Power Strip

![Power Strip](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2d4678bc963f4b03af1ede805ab4ac53&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | MP1-1K4S |
| **Sort #** | 17 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `000000000000000000000000b54e0000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=a1e78f3d6f264fc98245a5fb88ee816e&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=ac6f38e1dbe44fd2a65866fe9e069adf&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=410bc8db643140c083ccc9040314b13c&mimetype=image/png&name=RE.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | In the case of LED flash, long press the reset button for more than 5 seconds until the LED flash intermittently |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=dfb12a8ba0c24cc3ba2d34a9d431e4a1&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d8320f47cc4c45af9ddb3c70dea3b030&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=fd6704b30d594b059c4957dc74094b18&mimetype=image/png&name=RE.png) |

---

#### Smart Plug

![Smart Plug](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=fa2aae1eeba14f849514dafec1611e39&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | SP2-CL |
| **Sort #** | 17 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000044750000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d996efa2b59f43e4a9d849cc818c3e37&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=425d0484f5a84eaeae500bb3f3b49f42&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e1b0dbf24e2841fd8a7ab6ad0d7e0477&mimetype=image/png&name=RE.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | In the case of LED flash, long press the reset button for more than 5 seconds until the LED flash intermittently |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=07ef543a90b04b3985853aaaf537a334&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=08079a762cec4565abb127e8a9e79be4&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f1a30f3804514a0784b3be40eed281cc&mimetype=image/png&name=RE.png) |

---

#### Power Strip

![Power Strip](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=add023c586e74b37aa89cd96d285983c&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Plug |
| **Product model** | MP1-1K3S2U |
| **Sort #** | 19 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `000000000000000000000000654f0000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2b63c4a79e4b4b9c9e6c487cc8b84bad&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=f7bff2f973d444528486d92e4b00b018&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=e658db42524042b9b3d4fa5a565f7556&mimetype=image/png&name=RE.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | In the case of LED flash, long press the reset button for more than 5 seconds until the LED flash intermittently |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=cf8de9e0ebba4dbc88d0bff1e15f4bb3&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=1b70f6370adf46629c6e98600da1ca0c&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2c20ca072d744188bf2f992fb2ad4240&mimetype=image/png&name=RE.png) |

---

### Smart Bulb

> Type ID: `10001689010000000000fd364e3dfdfa` — 1 product(s)

#### Smart Blub

![Smart Blub](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=a47b6b7edff54a4cbc1425cd6935f532&mimetype=image/png&name=P.png)

| Field | Value |
| --- | --- |
| **Product type** | Smart Bulb |
| **Product model** | LB26 R1 / LB27 R1 / LB1 / LB27 C1 |
| **Sort #** | 1 |
| **AP name** | `BroadLink_WiFi_Device` |
| **AP same name** | 1 |
| **Device PID(s)** | `0000000000000000000000004c640000`, `0000000000000000000000004e640000`, `0000000000000000000000004b640000`, `000000000000000000000000f7a50000`, `000000000000000000000000f4a40000`, `00000000000000000000000017a50000`, `00000000000000000000000088640000` |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 0s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | When the bulb is an any conditions(except AP Setup mode),quickly switch it off and on for five times until the bulb flashes intermittently. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=cb18e00325dd4128ab370c22de9f3102&mimetype=image/gif&name=APW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=951c7f130bde47429b601593c0359d15&mimetype=image/gif&name=APB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=278df7f5597f4dada04597b32707665e&mimetype=image/png&name=RE.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 0s |
| Wait before proceed | 0s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | When the blub is in AP Setup mode ,quickly switch it off and on for five times until the bulb flashes quickly. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=fed94eb7a8144fd7a7cdd79c48ff367c&mimetype=image/gif&name=SMARTW.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=b78ed51ec22e4f01b0f67a8e075c6d54&mimetype=image/gif&name=SMARTB.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2e2d0b1c2e124aa3946bc7eaee0bc185&mimetype=image/png&name=RE.png) |

---

### General Wifi Device

> Type ID: `10001689010000000000a78d070efef4` — 2 product(s)

#### AP Setup Mode

![AP Setup Mode](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=46d11f57e7c340febb05e1fd70936adb&mimetype=image/png&name=general+WiFi+device.png)

| Field | Value |
| --- | --- |
| **Product type** | General Wi-Fi Device |
| **Product model** | LED indicator intermittent flash |
| **Sort #** | 90 |
| **AP name** | — |
| **AP same name** | 0 |
| **Device PID(s)** | `00000000000000000000000022270000` |

**Config method 6 — AP Mode (generic)**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | Please refer to setup guide for more detailed instructions. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=41840c7836b047ee82c21d36ec96d89d&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=72660c18892642589863f7697d9570e2&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d47deb4f308f4f2b92d089d124a96efe&mimetype=image/png&name=reset_750x560.png) |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 10s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Reset instruction | Please refer to setup guide for more detailed instructions. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=0e9a7ae0766542f1a87db9ebde7c2a03&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=dfc9e1ae7b054c8db7344451897f6741&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=3240c973e63649f8a2bcca9cd9b9c38e&mimetype=image/png&name=reset_750x560.png) |

---

#### Smart setup Mode

![Smart setup Mode](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=1d394dc4c44a4398a7621c6ca1fa9e4e&mimetype=image/png&name=general+WiFi+device.png)

| Field | Value |
| --- | --- |
| **Product type** | General Wi-Fi Device |
| **Product model** | LED indicator quick flash |
| **Sort #** | 90 |
| **AP name** | `BroadlinkProv` |
| **AP same name** | 1 |
| **Device PID(s)** | `00000000000000000000000022270000` |

**Config method 2 — Smart Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 1 — fast blink (Smart mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing indicator note | Please refer to the equipment manual for details |
| Reset instruction | Please refer to setup guide for more detailed instructions. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=0da306a7e8d2445985c2c8c92f518d4a&mimetype=image/gif&name=smart_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=38200fcdae1d4f83a28fb0bd07a765b2&mimetype=image/gif&name=smart_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=2b9db1778b0c4d6995ba04f4d6450308&mimetype=image/png&name=reset_750x560.png) |

**Config method 1 — AP Setup Mode**

| Field | Value |
| --- | --- |
| Long-press to enter | 5s |
| Wait before proceed | 3s |
| LED flash mode | 0 — slow blink (AP mode) |
| Sub-device protocol | Wi-Fi direct |
| Pairing indicator note | Please refer to the equipment manual for details |
| Reset instruction | Please refer to setup guide for more detailed instructions. |
| Pairing GIF (light) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=dffb4fa49d0442f3b29cb2f642acd67d&mimetype=image/gif&name=APmode_360x360-white.gif) |
| Pairing GIF (dark) | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=d97caa64036a4f81ba5348b75ace989a&mimetype=image/gif&name=APmode_360x360-dark.gif) |
| Reset image | [view](https://app-service-usa-21b17cc3.ibroadlink.com/appfront/blappproxy/v2/vtstaticfile?fileid=908520aaa4af4778be27e2419111b918&mimetype=image/png&name=reset_750x560.png) |

---
