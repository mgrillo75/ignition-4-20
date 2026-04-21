# RTAC Redundancy — Initial Deployment (v1)

This drop contains the files needed to make the 86 `TX3` UDT instances follow whichever of the two redundant SEL RTACs (`GCSA_RTAC_MODBUS` or `GCSB_RTAC_MODBUS`) is currently the master, with a one-tag operator override for maintenance.

**Design recap.** Your project already elects the master via the existing expression tag `[default]SEL_Internal_Tags/MasterController` — it returns `"GCSA"` or `"GCSB"` based on device-connection status and a bootup-complete flag. This deployment does three things:

1. Adds `[default]SEL_Internal_Tags/ActiveProvider`, a small expression tag that renders either `"[GCSA_RTAC_MODBUS]"` or `"[GCSB_RTAC_MODBUS]"` (the tag-provider prefix, with brackets). It respects an operator override and falls back to `MasterController`.
2. Rewrites every TX3 UDT instance's `TagProvider` parameter from the current literal `"[MQTT Engine]default"` to an expression binding that reads `ActiveProvider`. Flipping one tag retargets all 86 instances.
3. Adds a small `GCS_RTAC_Control` folder for operator visibility, a forced-mode override, and failover audit counters — plus a matching Perspective view.

No gateway timer script and no SDK module. The failover decision is the expression tag you already wrote; this work just makes the UDT instances consume it.

---

## Files in this folder

| File | Purpose |
|---|---|
| `01_SEL_Internal_Tags_additions.json` | Adds `ActiveProvider` expression tag into the existing `SEL_Internal_Tags` folder. **Use only if merging into an existing folder** — see warning below. |
| `01b_SEL_Internal_Tags_complete.json` | Complete `SEL_Internal_Tags` folder (MasterController, Q1FEP_Master, bootup flags, TotalGenCount, ActiveProvider, plus the Q1FEPB OPC path fix inline). Safe to import whether or not the folder exists; use this when in doubt. |
| `02_GCS_RTAC_Control.json` | New folder with `ActiveRTAC`, `ForcedRTAC`, `A_Healthy`, `B_Healthy`, `BothHealthy`, `NeitherHealthy`, `LastFailoverTime`, `LastFailoverReason`, `FailoverCount`. |
| `03_Q1FEPB_bootup_fix.json` | Fix for the `Q1FEPB_BootupComplete_STAT` OPC path bug — it currently points at `[Q1_FEPA_MODBUS]DI18` instead of `[Q1_FEPB_MODBUS]DI18`. Optional; only import if the copy-paste was unintentional. |
| `04_TX3_patched.json` | All 86 TX3 UDT instances with `TagProvider` rewritten to an expression binding. **Overwrites the TX3 folder — back up first.** |
| `gateway_tag_change_script.py` | **Ignition 8.3 project-scope Gateway Tag Change Script.** Fires on `ActiveRTAC` value changes and updates audit counters. See step 6. |
| `tag_change_script.py` | Older tag-level Value-Changed event script. **Do not use on 8.3** — the tag editor in 8.3 doesn't surface a Value Changed event on individual tags; use the gateway version above. Kept for reference / older gateways. |
| `perspective/RTAC_Redundancy/view.json` | Operator panel showing A/B status, active side, forced-mode dropdown, and audit counters. |
| `perspective/RTAC_Redundancy/resource.json` | Perspective resource metadata for the view. |

---

## Import order

Do these in Designer. All imports go into the `[default]` provider unless noted.

1. **Back up the TX3 folder.** In Designer, right-click `Tags -> [default] -> TX3 -> Export Tags -> JSON`. Save it somewhere outside the project directory. This is your rollback if step 4 goes sideways.

2. **Import the `SEL_Internal_Tags` folder.**

   > **⚠️ If you already imported `01_` and saw `Bad_NotFound("Path '[default]SEL_Internal_Tags/MasterController' not found")` anywhere**, Designer chose Overwrite on the merge prompt and wiped `MasterController`, `Q1FEP_Master`, bootup flags, and `TotalGenCount`. **Import `01b_SEL_Internal_Tags_complete.json` instead** — it reconstitutes the full original folder alongside `ActiveProvider`. Safe to import even if you don't know what state you're in.

   If you're confident you can merge cleanly, `01_SEL_Internal_Tags_additions.json` adds only `ActiveProvider` (choose **Merge**, not Overwrite, when Designer prompts).

   After import, verify the `SEL_Internal_Tags` folder contains: `MasterController`, `GCSA_BootupComplete_STAT`, `GCSB_BootupComplete_STAT`, `Q1FEP_Master`, `Q1FEPA_BootupComplete_STAT`, `Q1FEPB_BootupComplete_STAT`, `TotalGenCount`, and `ActiveProvider`.

3. **Import `02_GCS_RTAC_Control.json`** into `[default]` at the root. This creates the `GCS_RTAC_Control` folder. Verify `ActiveRTAC` shows `"A"` (with `MasterController = "GCSA"` at baseline) and `A_Healthy` / `B_Healthy` reflect reality.

4. *(Optional)* **Import `03_Q1FEPB_bootup_fix.json`** into `[default]`, merging under `SEL_Internal_Tags`. This only changes the one `Q1FEPB_BootupComplete_STAT` tag's OPC path. Skip this if the existing path was intentional for some reason.

5. **Import `04_TX3_patched.json`** into `[default]`, merging the `TX3` folder. Every instance's `TagProvider` parameter is now an expression that reads `ActiveProvider`; member tags are not included in the import (they're inherited from the UDT definition) and will retarget automatically when re-evaluated.

   > **Note on the v1 regeneration:** the initial `04_TX3_patched.json` included full member-tag subtrees inside each instance, which caused Ignition to fail the import with `Bad_Unsupported("Cannot move/rename inherited tag")` on every instance. The current file has those inherited member trees stripped — each instance is just `{name, tagType, typeId, parameters.TagProvider}`. Verified against the source tag export that zero instances had any member-level override, so this is lossless.

6. **Wire up the audit script (Ignition 8.3).** In Designer: **Project Browser -> Project -> Gateway Events -> Tag Change -> New Tag Change Script**.
   - Name: `RTAC_Failover_Audit`
   - Tag paths: `[default]GCS_RTAC_Control/ActiveRTAC` (one path, one line)
   - Event: **Value changed**
   - Script body: paste the contents of `gateway_tag_change_script.py`

   Save the project. In 8.3 the Tag Editor no longer exposes per-tag `Value Changed` scripts directly — Gateway Tag Change Scripts at project scope are the replacement, and they store with the project so they version-control cleanly.

7. **Import the Perspective view.** Copy `perspective/RTAC_Redundancy/` into `com.inductiveautomation.perspective/views/RTAC_Redundancy/` in your project folder, then refresh Designer. Open the view at `/data/perspective/client/<project>/RTAC_Redundancy` or bind it to a nav target.

---

## Test plan — simulator-friendly

You've got the RTACs running as Programmable Device Simulators, so you can exercise the whole failover path without touching hardware.

1. **Baseline.** All imports complete, no forced override. Confirm:
   - `MasterController` = `"GCSA"`
   - `ActiveProvider` = `"[GCSA_RTAC_MODBUS]"`
   - `ActiveRTAC` = `"A"`
   - `A_Healthy` = `B_Healthy` = `true`
   - Pick one TX3 instance (say `tx3-pb1-n1-qp9-br-002`). Browse into its member tags in Designer. `averageVoltage`, `power`, etc. should resolve to good quality reading from the `GCSA_RTAC_MODBUS` provider.

2. **Disable GCSA in the gateway.** `Config -> Connections -> Devices -> GCSA_RTAC_MODBUS -> Disable`. Within a couple of seconds:
   - `[System]Gateway/Devices/GCSA_RTAC_MODBUS/Status` flips away from `"Connected"`
   - `A_Healthy` flips to `false`
   - `MasterController` flips to `"GCSB"`
   - `ActiveProvider` flips to `"[GCSB_RTAC_MODBUS]"`
   - `ActiveRTAC` flips to `"B"`
   - The audit script fires: `LastFailoverTime`, `LastFailoverReason`, and `FailoverCount` update.
   - The same TX3 member tags should now resolve through `GCSB_RTAC_MODBUS` without any other config change.
   - The Perspective view's card borders shift — B becomes green-bordered and active, A becomes red.

3. **Re-enable GCSA.** Within a couple of seconds it should flip back to A and the counter should increment again.

4. **Force override.** Set the `ForcedRTAC` dropdown in the Perspective view (or write directly to `[default]GCS_RTAC_Control/ForcedRTAC`) to `"B"`. Active side should pin to B regardless of MasterController. Set back to `"AUTO"` and verify it returns to following MasterController.

If step 2 works end-to-end for one instance, it'll work for all 86.

---

## Known issues I didn't fix

Two pre-existing issues in the UDT definitions (unrelated to redundancy), flagging for follow-up:

- **`sel751_1_0_0`** member tags reference `{TagString}` in their `sourceTagPath` binding, but `TagString` isn't declared as a parameter on the UDT. Those member paths will resolve to the literal string `{TagString}` and fail. This wasn't caused by the redundancy work, but the 5 `sel751` instances will continue to have broken member tags until someone adds the `TagString` parameter to the UDT definition.
- **`sel787_3e_1_0_0`** references `{AGCAnalogInputPath}` which also isn't declared. Same situation; affects the 1 `sel787_3e` instance.

Both should be addressable by adding the missing parameters to the UDT definition in Designer. I didn't touch them because the fix is independent of the redundancy work and I don't want to silently change behavior you might want to audit separately.

---

## Why no timer script

The previous drafts (`potential-redundancy-v1.st`, `potential-redundancy-v2.st`) ran a gateway timer every second and wrote `ActiveRTAC`. With `MasterController` already doing the election via expression, a timer is redundant and can disagree with the expression during transients. The expression chain `MasterController -> ActiveProvider -> ActiveRTAC` evaluates continuously and atomically; the only thing I kept as a script is the audit hook on `ActiveRTAC`, which records *that* a flip happened — not *whether* to flip.

If you later add debounce requirements, or want to suppress rapid flapping during marginal conditions, the right place is inside the `ActiveProvider` expression (add a timer-smoothed secondary input), not a parallel Jython loop.

---

## What to add once this is proven

- **History** on `ActiveRTAC`, `A_Healthy`, `B_Healthy`, and `FailoverCount` — so you get a historical trend of redundancy events instead of just an in-memory counter.
- **Alarm on `NeitherHealthy`** at critical priority — total RTAC outage is the one state you cannot recover from automatically.
- **Alarm on `!A_Healthy || !B_Healthy`** at high priority, so the control room sees degraded redundancy before it becomes an outage.
- **Consider adding `TagString` / `AGCAnalogInputPath` parameters** to the `sel751` and `sel787_3e` UDT definitions to fix the pre-existing bugs called out above.
