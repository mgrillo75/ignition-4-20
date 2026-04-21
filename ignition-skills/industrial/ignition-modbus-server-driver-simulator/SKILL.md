---
name: ignition-modbus-server-driver-simulator
description: Install, trust, configure, and drive Kevin Herron's Modbus Server Driver module on a local Ignition 8.3 gateway, including live simulator value updates via device files and resource toggling.
version: 1.0.0
author: Hermes Agent
tags: [ignition, modbus, simulator, module, opcua, windows]
platforms: [windows]
---

# Ignition Modbus Server Driver Simulator

Use this skill when working with the custom module repo `modbus-server-driver` on Miguel's Windows Ignition 8.3 machine, especially to:
- build/install the custom `.modl`
- complete unsigned/trust flows on the gateway
- create a Modbus TCP server device in Ignition
- seed or live-update simulated Modbus values for `data-center-hmi`

This skill captures the machine-specific workflow that actually worked.

## When to use

- User wants to simulate Modbus TCP values inside the same Ignition runtime
- Repo is `C:\Users\MiguelGrillo\Documents\github-repos\modbus-server-driver`
- Gateway is local Ignition 8.3 on `http://localhost:8088`
- You need a quick proof-of-concept or demo for `data-center-hmi`

## Key findings

1. Raw file-drop into `user-lib\modules` is not sufficient here for reliable third-party install.
2. The correct install path is the authenticated gateway web/API flow.
3. Ignition 8.3 web auth is OIDC-based; you must:
   - hit `/data/app/login`
   - follow redirects to `/idp/default/authn/login?...token=...`
   - POST `/idp/default/authn/next-challenge`
   - POST `/idp/default/authn/submit-challenge/basic`
   - POST `/idp/default/authn/next-challenge` again
   - finish with `/idp/default/oidc/auth?...&token=...`
4. For module upload/install, `X-CSRF-Token` is required. Other guessed CSRF headers failed.
5. Unsigned/trust flow after upload/install is split:
   - upload: `/data/api/v1/modules/upload?fileName=...`
   - install: `/data/api/v1/modules/install?moduleId=...`
   - commissioning/trust acceptance: `POST /post-step`
6. After module trust, gateway remains in `COMMISSIONING` until the `finished` step is posted with `startGateway: true`.
7. The local Modbus server device stores its live process image in binary files under:
   - `C:\Users\MiguelGrillo\Documents\Ignition8_3\data\config\com.inductiveautomation.opcua\devices\<device-name>`
8. Fast live updates can be forced by editing those device files, then toggling the device resource disabled/enabled through the resource API. Full gateway restart is not required for every simulator value change.
9. Toggling the same device from multiple demo processes causes signature races and intermittent 500 errors. Use a single-instance lock for any demo loop.

## Prerequisites

- Gateway URL: `http://localhost:8088`
- Admin creds available
- Built module file, usually:
  - `C:\Users\MiguelGrillo\Documents\github-repos\modbus-server-driver\msd-build\target\Modbus-Server-Driver-Module-dev2.modl`

## Install/trust workflow

### 1. Log in programmatically

Use a cookie jar and follow this sequence:

1. `GET /data/app/login`
2. follow redirect to `/idp/default/oidc/auth?...`
3. follow redirect to `/idp/default/authn/login?...token=...`
4. `POST /idp/default/authn/next-challenge` with `{token}`
5. `POST /idp/default/authn/submit-challenge/basic` with:
   - `token`
   - `rememberMe: false`
   - `challenge.username`
   - `challenge.password`
6. `POST /idp/default/authn/next-challenge` again
7. final `GET /idp/default/oidc/auth?...&token=...`
8. `GET /data/app/session` and capture `csrfToken`

Important: the header name that worked for protected module APIs was exactly:
- `X-CSRF-Token`

### 2. Upload/install the module

- `POST /data/api/v1/modules/upload?fileName=<modl-name>`
  - body = raw `.modl` bytes
  - header = `X-CSRF-Token`
- `POST /data/api/v1/modules/install?moduleId=com.kevinherron.modbus-server-driver`
  - header = `X-CSRF-Token`

Expected install response:
- `{"success":true,"message":"Module successfully installed."}`

### 3. Complete certificate/trust step

Commissioning endpoint that worked:
- `POST /post-step`

Accept module cert with payload like:
```json
{
  "id": "modules",
  "step": "modules",
  "data": {
    "acceptedLicenses": [],
    "acceptedCertificates": ["com.kevinherron.modbus-server-driver"]
  }
}
```

### 4. Exit commissioning and start gateway

Post:
```json
{
  "id": "finished",
  "step": "finished",
  "data": {
    "startGateway": true
  }
}
```

Then poll `/StatusPing` until it returns plain running state, not commissioning.

## Verify module activation

Use either:
- `GET /data/api/v1/modules/healthy?limit=500&offset=0`
- wrapper log

Expected healthy module entry:
- `id = com.kevinherron.modbus-server-driver`
- `state = ACTIVE`

Expected wrapper log line:
- `Starting up module 'com.kevinherron.modbus-server-driver'...`

## Create the simulator device

Use the resource API for OPC UA devices:
- `POST /data/api/v1/resources/com.inductiveautomation.opcua/device`

Working example payload for device `GCS_RTAC_MODBUS`:
```json
[
  {
    "name": "GCS_RTAC_MODBUS",
    "enabled": true,
    "description": "Hermes proof-of-concept Modbus TCP server for data-center-hmi",
    "config": {
      "profile": {"type": "com.kevinherron.modbus-server-driver"},
      "settings": {
        "connectivity": {"bindAddress": "127.0.0.1", "port": 1502},
        "browsing": {
          "coilBrowseRanges": "381-384",
          "discreteInputBrowseRanges": "1052-1056",
          "holdingRegisterBrowseRanges": "2943-2959",
          "inputRegisterBrowseRanges": "2943-2959"
        },
        "persistence": {"persistData": true}
      }
    }
  }
]
```

Verify with:
- `GET /data/api/v1/resources/find/com.inductiveautomation.opcua/device/GCS_RTAC_MODBUS?collection=core`

Health should show:
- `healthy: true`
- `message: "Listening"`

## Live simulator value updates

### Where the live values are stored

Device folder:
- `C:\Users\MiguelGrillo\Documents\Ignition8_3\data\config\com.inductiveautomation.opcua\devices\GCS_RTAC_MODBUS`

Files:
- `coils.bin`
- `discreteInputs.bin`
- `holdingRegisters.bin`
- `inputRegisters.bin`

### File layout

- `coils.bin[address] = 0|1`
- `discreteInputs.bin[address] = 0|1`
- register files use 2 bytes per register, big-endian signed int16 for the simple test values used here
  - byte offset = `address * 2`

Important addressing finding from live debugging:
- for this custom driver, a tag like `[GCS_RTAC_MODBUS]IR2943` maps to file byte offset `2943 * 2 = 5886`
- do not subtract 1 when manually inspecting or resetting persisted register values for this driver
- example: if `IR2943` appears stuck, inspect `inputRegisters.bin` at offset `5886`

Persistence finding:
- with `persistData=true`, the simulator reloads values from these `.bin` files on gateway/device startup
- if no active writer/demo loop is feeding a register, the last persisted value simply comes back after restart
- this means a value can look "stuck" even when the UI is fine; the real source of truth is the device file plus any active writer process

### Fast refresh method that worked

1. Edit the relevant device files
2. Fetch the current device resource and current signature
3. `PUT /data/api/v1/resources/com.inductiveautomation.opcua/device` with `enabled=false`
4. Refetch resource/signature
5. `PUT ...` again with `enabled=true`
6. Wait briefly and verify via Modbus TCP readback

This reliably reloads the updated process image without restarting the whole gateway.

### Warning

Do not run multiple background demo loops at once. They race on the device resource signature and cause intermittent 500s on PUT.

## Verification via Modbus TCP

Use localhost device endpoint:
- host: `127.0.0.1`
- port: `1502`

Example proof values that worked:
- coil 381 -> `True`
- discrete input 1052 -> `True`
- input registers 2943,2944 -> `[111, 222]`
- holding registers 2943,2944 -> `[111, 222]`

Useful debugging rule:
- always verify suspected stuck values with direct Modbus TCP readback before blaming Perspective or tags
- if Modbus readback shows the same stale value, inspect the persisted device file first
- example live issue: `IR2943` was stuck at `555`; direct Modbus readback confirmed the server itself was serving `555`, and resetting `inputRegisters.bin` plus restart changed live readback to `0`

## `data-center-hmi` tag mappings confirmed

Examples from exported tags:
- `SC_S1_BreakerStatus_VAL -> [GCS_RTAC_MODBUS]IR2943`
- `SC_S2_BreakerStatus_VAL -> [GCS_RTAC_MODBUS]IR2944`
- `PMAX_PMAXEnabled_STAT -> [GCS_RTAC_MODBUS]DI1052`
- `SC_SC1_Start_CMD -> [GCS_RTAC_MODBUS]C381`
- additional AUX breaker values were also extended through `IR2945-2959`

## Perspective simulator page

A live simulator page was added successfully at:
- route: `/Simulator`
- view path: `Test/Simulator/ModbusControl`

Use this when the user wants to see/edit the simulated values directly in Perspective.

## Suggested reusable script pattern

If scripting this again, build a helper that supports:
- `status`
- `set`
- `demo`

Core responsibilities:
- log in and capture `X-CSRF-Token`
- fetch current resource/signature before each PUT
- single-instance lock for demo mode
- write device files
- disable/enable device resource to reload values
- verify through Modbus TCP readback

## Pitfalls

1. `X-CSRF-Token` matters; other guessed names failed.
2. Upload/install success does not mean module is active yet; commissioner trust step is still required.
3. After trust, gateway can remain in `COMMISSIONING` until `finished/startGateway` is posted.
4. `find ... ?collection=` may 404 for this device while `?collection=core` works.
5. Full gateway restart scripts may report false timeout even when `/StatusPing` already says running.
6. Multiple simulator demo processes will collide and break device toggles.
7. A stuck IR/HR value is often not a UI problem at all — it may just be the persisted `.bin` image being reloaded on startup with no active writer updating it.
8. On this gateway's OPC UA endpoint, anonymous user tokens were not available during live debugging; endpoint enumeration showed username/password token only. If you need OPC UA writes to drive live movement, plan on valid gateway credentials or another writer path.
9. The gateway may keep previously rejected Hermes OPC UA client certs under `data/config/local/com.inductiveautomation.opcua/server/security/pki/rejected/certs`; if trying a secure OPC UA client again, inspect trusted/rejected cert stores before assuming the certificate itself is new or accepted.

## Minimal success checklist

- module shows ACTIVE in healthy modules API
- wrapper log shows module startup
- OPC UA device resource exists for `GCS_RTAC_MODBUS`
- device health says `Listening`
- Modbus TCP readback on `127.0.0.1:1502` matches seeded values
- Perspective `/Simulator` page shows editable values bound to live project tags
