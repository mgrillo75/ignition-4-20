---
name: ignition-custom-module-build
description: Build and stage custom Ignition gateway modules on Miguel's Windows Ignition 8.3 machine, including Java/Maven setup, .modl packaging, and unsigned-module install caveats.
version: 1.1.0
author: Hermes Agent
tags: [ignition, module, modl, maven, java, windows, gateway, opcua]
platforms: [windows]
---

# Ignition Custom Module Build

Use this when working with a Java-based Ignition module repo that produces a `.modl`, especially for Miguel's local Ignition 8.3 environment.

## What this covers

- Inspecting whether a repo is a real Ignition module project
- Installing local build prerequisites on Windows
- Building `.modl` packages from Maven-based Ignition module repos
- Staging unsigned modules into the local Ignition 8.3 install
- Understanding why a built module did or did not appear in the gateway

## Verified environment facts

On Miguel's machine:
- Ignition 8.3 lives under `C:\Users\MiguelGrillo\Documents\Ignition8_3`
- Active gateway service is `Ignition`
- Active HTTP port is `8088`
- SSL port is `8060`
- Java and Maven were not initially installed in PATH
- Working installed tools:
  - JDK: `C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot`
  - Maven: `C:\ProgramData\chocolatey\lib\maven\apache-maven-3.9.14\bin\mvn.cmd`

## How to identify a real Ignition module repo

Strong signs:
- Maven or Gradle multi-module Java project
- uses Ignition SDK dependencies
- packaging step generates `.modl`
- contains a gateway hook, designer hook, or module hook
- contains module metadata like module id, required Ignition version, and scope declarations

For Maven repos, look for:
- `ignition-maven-plugin`
- `moduleId`
- `hookClass`
- `requiredIgnitionVersion`
- gateway dependencies such as `gateway-api`, `driver-api`, or `ignition-common`

## Build prerequisites on Miguel's machine

Install with Chocolatey:

```powershell
choco install temurin17 maven -y --no-progress
```

Do not assume `java` or `mvn` are already in PATH in the current process. For one-off builds, set them explicitly:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot'
$env:Path = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot\bin;C:\ProgramData\chocolatey\lib\maven\apache-maven-3.9.14\bin;' + $env:Path
```

Verify:

```powershell
& 'C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot\bin\java.exe' -version
& 'C:\ProgramData\chocolatey\lib\maven\apache-maven-3.9.14\bin\mvn.cmd' -version
```

## Build pattern for Maven repos

From the repo root:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot'
$env:Path = 'C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot\bin;C:\ProgramData\chocolatey\lib\maven\apache-maven-3.9.14\bin;' + $env:Path
Set-Location 'C:\path\to\repo'
& 'C:\ProgramData\chocolatey\lib\maven\apache-maven-3.9.14\bin\mvn.cmd' -DskipTests package
```

Typical output module path:
- `<repo>\<build-module>\target\*.modl`

## Important packaging caveat discovered

Some repos package `module.xml` with lowercase XML tags such as:
- `<requiredignitionversion>`

Ignition working examples on Miguel's machine use camel-case tags such as:
- `<requiredIgnitionVersion>`
- `<freeModule>true</freeModule>`
- `<requiredFrameworkVersion>8</requiredFrameworkVersion>`

If needed, inspect and patch `module.xml` inside the built `.modl`:

```powershell
Set-Location '<repo>\<build-module>\target'
& 'C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot\bin\jar.exe' tf 'MyModule.modl'
& 'C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot\bin\jar.exe' xf 'MyModule.modl' module.xml
Get-Content module.xml
```

If repacking is necessary, a quick Python zip rewrite works well.

## Staging to the local Ignition install

Copy built module to:

```powershell
Copy-Item '<built modl>' 'C:\Users\MiguelGrillo\Documents\Ignition8_3\user-lib\modules\' -Force
```

Then restart the gateway.

## Critical install lesson learned

On Miguel's current Ignition 8.3 setup, dropping a third-party `.modl` into `user-lib\modules` and restarting is not sufficient to guarantee the module becomes installed and registered.

Symptoms of this failure:
- `.modl` file exists in `user-lib\modules`
- gateway restarts normally
- `wrapper.log` never shows the module id or hook class loading
- module does not appear active in the gateway

By contrast, previously installed unsigned modules on this machine showed gateway log lines like:
- `Moving module ... to quarantine because certificate not yet accepted`
- route path `/v1/modules/install`

This indicates the live gateway expects third-party module installation through the authenticated gateway install flow, not just raw file drop.

## What to do when a built module does not load

1. Check `wrapper.log` for:
   - module id
   - hook class
   - certificate or quarantine messages
   - unsigned/untrusted module messages
2. If there are no references at all, assume the gateway did not ingest the module from file drop.
3. Use the authenticated gateway module install UI or API instead.
4. Expect certificate acceptance/quarantine flow for unsigned modules.

## Verified authenticated install flow on Miguel's 8.3.4 gateway

This was successfully completed against:
- gateway: `http://localhost:8088`
- auth username: standard gateway admin login
- CSRF source: `GET /data/app/session`
- required header for module upload/install API: `X-CSRF-Token`

Important findings:
- `POST /data/api/v1/modules/upload?fileName=...` returns `403` unless `X-CSRF-Token` is supplied.
- Other guessed CSRF header names like `X-Ignition-CSRF-Token` did not work here.
- Upload/install can be done headlessly after completing the IdP login flow.

Successful sequence:
1. Log in through the gateway IdP flow.
   - `GET /data/app/login`
   - follow redirects to `/idp/default/authn/login?...token=...`
   - `POST /idp/default/authn/next-challenge`
   - `POST /idp/default/authn/submit-challenge/basic`
   - `POST /idp/default/authn/next-challenge`
   - finalize with `/idp/default/oidc/auth?...&token=...`
2. Read session info:
   - `GET /data/app/session`
   - extract `csrfToken`
3. Upload module bytes:
   - `POST /data/api/v1/modules/upload?fileName=<modl>`
   - header: `X-CSRF-Token: <csrfToken>`
4. Install uploaded module:
   - `POST /data/api/v1/modules/install?moduleId=<module id>`
   - header: `X-CSRF-Token: <csrfToken>`
5. Check quarantined modules:
   - `GET /data/api/v1/modules/quarantined?limit=20&offset=0`

Observed response pattern for unsigned module upload/install:
- upload returned JSON like:
  - `{"moduleId":"com.kevinherron.modbus-server-driver","licenseAccepted":true,"certAccepted":false,"containsEula":false,"containsCert":false}`
- install returned:
  - `{"success":true,"message":"Module successfully installed."}`
- quarantined entry then showed:
  - `reason: "Certificate has not been accepted."`

## Critical commissioning/trust step for unsigned modules

On this gateway, unsigned module acceptance did not complete via the normal modules API alone.
It moved the gateway into a commissioning-style pending-modules flow.

Useful endpoints discovered from the commissioner app:
- `GET /bootstrap`
- `GET /get-step?step=modules`
- `POST /post-step`
- `GET /StatusPing`

Verified trust/finalize flow:
1. Read pending module state:
   - `GET /get-step?step=modules`
2. Accept pending module certificates/licenses using:
   - `POST /post-step`
   - payload form:
     - `{"id":"modules","step":"modules","data":{"acceptedLicenses":[],"acceptedCertificates":["<module id>"]}}`
3. Start/finish gateway commissioning:
   - `POST /post-step`
   - payload form:
     - `{"id":"finished","step":"finished","data":{"startGateway":true}}`
4. Poll readiness:
   - `GET /StatusPing`

Very important behavior:
- after trust but before the final `finished/startGateway` post, `/StatusPing` may report:
  - `{"state":"RUNNING","details":"COMMISSIONING"}`
- during restart it reports:
  - `{"state":"STARTING"}`
- final healthy state is:
  - `{"state":"RUNNING"}`

Do not mistake `RUNNING + COMMISSIONING` for a complete success.
The extra `finished/startGateway` step is required to exit commissioning and bring the gateway back to normal runtime.

## Verifying real module activation

Do all of the following:
1. `GET /data/api/v1/modules/quarantined?...` should become empty for that module.
2. `GET /data/api/v1/modules/healthy?...` should show the module with:
   - `state: ACTIVE`
3. `wrapper.log` should contain module startup lines, e.g.:
   - `Starting up module 'com.kevinherron.modbus-server-driver'...`
4. For device modules, the extension point should appear in:
   - `GET /data/api/v1/resources/type/com.inductiveautomation.opcua/device`

## Useful log path

```text
C:\Users\MiguelGrillo\Documents\Ignition8_3\logs\wrapper.log
```

## Restart pattern on Miguel's machine

Prefer the local restart helper if available, but use the real active gateway URL and service name:
- service: `Ignition`
- gateway URL: `http://localhost:8088`

Do not trust stale defaults like `Ignition83` or `http://localhost:8188`.

## Good proof-of-concept strategy for Modbus simulation modules

When the target project already has Modbus tags, start with a very small point set:
- one or two input registers
- one discrete input
- one coil

On Miguel's `data-center-hmi` export, useful examples included:
- `IR2943`
- `IR2944`
- `DI1052`
- `C381`

Mapped example tags discovered:
- `SC_S1_BreakerStatus_VAL -> [GCS_RTAC_MODBUS]IR2943`
- `SC_S2_BreakerStatus_VAL -> [GCS_RTAC_MODBUS]IR2944`
- `PMAX_PMAXEnabled_STAT -> [GCS_RTAC_MODBUS]DI1052`
- `SC_SC1_Start_CMD -> [GCS_RTAC_MODBUS]C381`

This is enough to prove:
- module loads
- server device can be created
- built-in Modbus client can connect
- tag values change end-to-end

## Creating a device resource by API

For device-style modules, create the device with the resources API instead of manual UI work when possible.

Verified working endpoint on this gateway:
- `POST /data/api/v1/resources/com.inductiveautomation.opcua/device`

Required headers:
- `Content-Type: application/json`
- `Accept: application/json`
- `X-CSRF-Token: <csrfToken>`

Verified payload shape for the Modbus TCP server module:

```json
[
  {
    "name": "GCS_RTAC_MODBUS",
    "enabled": true,
    "description": "Hermes proof-of-concept Modbus TCP server for data-center-hmi",
    "config": {
      "profile": {
        "type": "com.kevinherron.modbus-server-driver"
      },
      "settings": {
        "connectivity": {
          "bindAddress": "127.0.0.1",
          "port": 1502
        },
        "browsing": {
          "coilBrowseRanges": "381",
          "discreteInputBrowseRanges": "1052",
          "holdingRegisterBrowseRanges": "2943-2944",
          "inputRegisterBrowseRanges": "2943-2944"
        },
        "persistence": {
          "persistData": true
        }
      }
    }
  }
]
```

Verify creation with:
- `GET /data/api/v1/resources/find/com.inductiveautomation.opcua/device/GCS_RTAC_MODBUS`

Healthy proof looked like:
- `healthchecks.status.result.healthy = true`
- `healthchecks.status.result.message = "Listening"`

## Fast proof method: seed the persisted process image directly

For this specific module, the process image persists under:

```text
C:\Users\MiguelGrillo\Documents\Ignition8_3\data\config\com.inductiveautomation.opcua\devices\<deviceName>
```

Files used by the module:
- `coils.bin`
- `discreteInputs.bin`
- `holdingRegisters.bin`
- `inputRegisters.bin`

Observed file layout from source:
- `coils.bin`: 65535 bytes, one byte per coil offset
- `discreteInputs.bin`: 65535 bytes, one byte per DI offset
- `holdingRegisters.bin`: 65535 * 2 bytes, big-endian 2 bytes per register offset
- `inputRegisters.bin`: 65535 * 2 bytes, big-endian 2 bytes per register offset

This is a good proof shortcut when secure OPC UA writes are not yet automated.

Example seeded values used successfully:
- `C381 = true`
- `DI1052 = true`
- `IR2943 = 111`
- `IR2944 = 222`
- mirrored into `holdingRegisters.bin` too for comparison testing

After editing the files, restart the Ignition service and wait for plain `RUNNING` from `/StatusPing`.

## End-to-end verification pattern

After restart:
1. Verify module is still `ACTIVE` in `/data/api/v1/modules/healthy`.
2. Verify device resource health says `Listening`.
3. Verify the Modbus TCP port is open.
4. Read the seeded addresses with a real Modbus client.

Verified working readback with `pymodbus` against `127.0.0.1:1502`:
- coil `381` -> `True`
- discrete input `1052` -> `True`
- input registers `2943,2944` -> `[111, 222]`
- holding registers `2943,2944` -> `[111, 222]`

## Practical live control method discovered

For this specific Modbus server module, a workable live-control path is:
1. update the persisted process image binary files directly
2. disable the device resource by API
3. re-enable the device resource by API
4. verify changed values over Modbus TCP

This avoids a full gateway restart and is good enough for interactive proof-of-concept demos.

Verified device toggle endpoint usage:
- fetch existing resource:
  - `GET /data/api/v1/resources/find/com.inductiveautomation.opcua/device/<deviceName>?collection=core`
- update same resource with `enabled: false`, then `enabled: true`:
  - `PUT /data/api/v1/resources/com.inductiveautomation.opcua/device`
  - header: `X-CSRF-Token: <csrfToken>`

Important payload detail:
- include the current `signature` from the fetched resource on each update
- after each successful `PUT`, replace the cached signature with `changes[0].newSignature`

Verified result:
- changing the device files plus disable/enable caused new values to appear live on port `1502`
- this worked for rapid demos without restarting the whole gateway

## Live control script pattern

A reusable local helper can:
- log into the gateway
- fetch the device resource + signature
- write proof values into:
  - `coils.bin`
  - `discreteInputs.bin`
  - `holdingRegisters.bin`
  - `inputRegisters.bin`
- disable and re-enable the device resource
- verify results by reading from Modbus TCP

Verified useful commands:

```powershell
python C:\Users\MiguelGrillo\.hermes\scripts\modbus_live_control.py status
python C:\Users\MiguelGrillo\.hermes\scripts\modbus_live_control.py set --username <user> --password <pass> --c381 true --di1052 false --ir2943 900 --ir2944 901
python -u C:\Users\MiguelGrillo\.hermes\scripts\modbus_live_control.py demo --username <user> --password <pass> --interval 5
```

Verified live-control demo states used successfully:
- `{C381: true,  DI1052: true,  IR2943: 111, IR2944: 222}`
- `{C381: false, DI1052: true,  IR2943: 333, IR2944: 444}`
- `{C381: true,  DI1052: false, IR2943: 555, IR2944: 666}`
- `{C381: false, DI1052: false, IR2943: 777, IR2944: 888}`

## Pitfalls

- Do not assume `mvn` or `java` are available in PATH even after installation; set explicit paths for the current process.
- Do not assume a successful `.modl` build means Ignition will load it.
- Do not assume `user-lib\modules` file copy equals installation on this machine.
- Always inspect `wrapper.log` after restart to confirm actual module loading.
- If the restart helper claims the gateway never came back, double-check `wrapper.log`; on Miguel's machine the helper has previously waited on stale or misleading readiness assumptions.

## Success criteria

A real success is all of:
1. `.modl` builds successfully
2. module install flow accepts the package
3. `wrapper.log` shows module startup or hook registration
4. the module's device/component type appears in the gateway/designer
5. a small set of real project points can be simulated end-to-end
