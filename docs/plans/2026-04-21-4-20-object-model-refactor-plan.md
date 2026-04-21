# 4-20 Object-Model Refactor Plan

> For Hermes: use subagent-driven-development for implementation work derived from this plan.

Goal: refactor the 4-20 Ignition project into a better-structured semantic object model while reusing as much of the existing tag, script, widget, popup, and page infrastructure as possible.

Architecture: keep the current device-specific UDTs as adapter/source models, add a reusable semantic base-model layer inspired by object-models, then build 4-20 domain object UDTs and parameterized Perspective contracts on top. Migrate one family at a time instead of rewriting the project in one pass.

Tech Stack: Ignition 8.3 filesystem-managed Perspective project, exported UDT JSON, project script library, gateway tags, PowerShell validation/restart workflow.

---

## Evidence summary

Reference inputs used:
- `C:\Users\MiguelGrillo\Documents\cursor\ignition-4-20\object-models-udts-instances\udts.json`
- `C:\Users\MiguelGrillo\Documents\cursor\ignition-4-20\object-models-udts-instances\tags.json`
- `C:\Users\MiguelGrillo\Documents\cursor\ignition-4-20\object-models-udts-instances\udts-4-20.json`
- `C:\Users\MiguelGrillo\Documents\cursor\ignition-4-20\object-models-udts-instances\tags-4-20.json`
- `C:\Users\MiguelGrillo\Documents\ignition8_3\data\projects\4-20\com.inductiveautomation.perspective\views\**\view.json`

Key findings:
- `object-models` exported model contains 126 UDT types and 2,560 nested UDT instances.
- `4-20` exported model contains 6 UDT types and 86 primary exported UDT instances in `tags-4-20.json`.
- `4-20` Perspective currently contains 109 views:
  - 82 in `Assets`
  - 14 in `MainWindows`
  - 13 in `Test`
- `4-20` already has strong reusable UI assets, but weak semantic modeling.
- Current 4-20 UDTs are device-centric, not domain-centric:
  - `jenbacher620_1_0_0`
  - `sel751a_1_0_0`
  - `sel700g_1_0_0`
  - `sel735_1_0_0`
  - `sel751_1_0_0`
  - `sel787_3e_1_0_0`

---

## Section 1: Proposed target UDT taxonomy for 4-20

### 1. Adapter layer (preserve current device UDTs)

Keep existing vendor/device UDTs as the protocol-facing adapter layer:
- `Adapters/Generator/Jenbacher620`
- `Adapters/Relay/SEL700G`
- `Adapters/Relay/SEL751`
- `Adapters/Relay/SEL751A`
- `Adapters/Relay/SEL787_3E`
- `Adapters/Meter/SEL735`

Purpose:
- preserve current live tags and bindings
- isolate device-specific field names
- avoid a risky full-path rename at the beginning

### 2. Base semantic layer (inspired by object-models)

Create reusable building blocks:
- `Base/Definition/AssetDefinition`
- `Base/Definition/EquipmentDefinition`
- `Base/Definition/DeviceDefinition`
- `Base/Attribute/StringAttribute`
- `Base/Attribute/NumericAttribute`
- `Base/Attribute/BooleanAttribute`
- `Base/Attribute/EnumAttribute`
- `Base/Value/NumericValue`
- `Base/Value/NumericValueExpanded`
- `Base/Value/BooleanValue`
- `Base/Value/StateValue`
- `Base/Parameter/NumericParameter`
- `Base/Parameter/NumericScaledParameter`
- `Base/Parameter/BooleanParameter`
- `Base/Parameter/StateParameter`
- `Base/Parameter/ModeParameter`
- `Base/Status/CommStatus`
- `Base/Status/HealthStatus`
- `Base/Status/AlarmStatus`
- `Base/Status/RuntimeStatus`
- `Base/Control/Command`
- `Base/Control/ModeSelection`

Purpose:
- standardize metadata, values, scaling, engineering context, and status handling
- give the UI consistent paths regardless of underlying device

### 3. Domain object layer for 4-20

Build semantic equipment objects above the adapter layer:
- `Object/Generator/Genset`
- `Object/Breaker/GeneratorBreaker`
- `Object/Relay/ProtectionRelay`
- `Object/Meter/PowerMeter`
- `Object/Synchronizer/SyncController`
- `Object/Circuit/SingleGeneratorCircuit`
- `Object/Circuit/UreaCircuit`
- `Object/System/GDMS`
- `Object/System/UDMS`
- `Object/System/MVPMS`
- `Object/Lineup/TX3`

### 4. Suggested internal object composition

Example: `Object/Generator/Genset`
- `Definition`
- `Electrical`
  - `Voltage`
  - `Frequency`
  - `RealPower`
  - `ReactivePower`
- `Control`
  - `AutoManual`
  - `LocalRemote`
  - `PowerSetpoint`
- `Breaker`
  - `Status`
- `Health`
  - `Heartbeat`
  - `CommStatus`
- `SourceDevice`
  - adapter mapping to Jenbacher/SEL objects

Example: `Object/Circuit/SingleGeneratorCircuit`
- `Definition`
- `Generator`
- `Breaker`
- `Relay`
- `Meter`
- `Synchronizer`
- `Availability`
- `AlarmSummary`
- `Controls`

### 5. Suggested instance hierarchy

Target structure:
- `Site/TX3/Circuits/QP1/...`
- `Site/TX3/Circuits/QP2/...`
- `Site/TX3/Circuits/QP3/...`

Or preserving current naming style with better grouping:
- `TX3/QP1/Genset`
- `TX3/QP1/Relay700G`
- `TX3/QP1/Breaker`
- `TX3/QP1/Meter`
- `TX3/QP1/Synchronizer`

Avoid continuing to expose UI directly against flat device instance names like:
- `TX3/tx3-pb1-n1-qp5-sel700g-002`

---

## Section 2: Mapping table from current 4-20 UDTs/views to proposed semantic object model

### A. UDT mapping table

| Current 4-20 UDT | Current role | Proposed adapter type | Proposed semantic object(s) | Notes |
|---|---|---|---|---|
| `jenbacher620_1_0_0` | generator/controller-ish device payload | `Adapters/Generator/Jenbacher620` | `Object/Generator/Genset` | contains power, reactive power, voltage, frequency, mode-like fields |
| `sel700g_1_0_0` | relay/sync/breaker-adjacent device | `Adapters/Relay/SEL700G` | `Object/Relay/ProtectionRelay`, `Object/Synchronizer/SyncController`, `Object/Breaker/GeneratorBreaker` | current fields are thin; likely needs composition with additional status/control wrappers |
| `sel751_1_0_0` | relay | `Adapters/Relay/SEL751` | `Object/Relay/ProtectionRelay` | likely feeder/breaker relay role |
| `sel751a_1_0_0` | relay with many points | `Adapters/Relay/SEL751A` | `Object/Relay/ProtectionRelay` | high-field-count UDT; likely should be normalized behind a smaller semantic contract |
| `sel735_1_0_0` | metering | `Adapters/Meter/SEL735` | `Object/Meter/PowerMeter` | useful source for voltage/current/power/pf/energy semantics |
| `sel787_3e_1_0_0` | transformer/breaker relay | `Adapters/Relay/SEL787_3E` | `Object/Relay/ProtectionRelay`, maybe `Object/Transformer/Protection` | treat as specialized relay adapter |

### B. Current instance mapping examples

| Current instance pattern | Current type | Proposed target semantic location |
|---|---|---|
| `TX3/tx3-pb1-n1-qp9-br-002` | `jenbacher620_1_0_0` | `TX3/QP9/Genset` |
| `TX3/tx3-pb1-n1-qp5-sel700g-002` | `sel700g_1_0_0` | `TX3/QP5/Relay700G` or `TX3/QP5/SyncController` |
| `TX3/tx3-pb1-n1-fcb3-751-001` | `sel751_1_0_0` in 26-export | `TX3/FCB3/ProtectionRelay` |

### C. Perspective view mapping table

| Current view family | Reuse decision | Proposed target |
|---|---|---|
| `Assets/Pipes/Pipe_Horizontal`, `Pipe_Vertical` | keep | `Views/Components/Pipes/*` |
| `Assets/Widgets/Data Display/SingleValueDisplay` | keep, normalize contract | `Views/Components/DataDisplays/SingleValue` |
| `Assets/Widgets/Data Display/MultiValueDisplay` | keep, normalize contract | `Views/Components/DataDisplays/MultiValue` |
| `Assets/Widgets/Data Display/RelayDigitalIODisplay` | keep, normalize contract | `Views/Components/DataDisplays/RelayDigitalIO` |
| `Assets/Widgets/Valves/Simple Valve` | keep | `Views/Components/Valves/SimpleValve` |
| `Assets/Widgets/Breaker/LV_Breaker` | keep, semanticize bindings | `Views/Components/Breakers/LVBreaker` |
| `Assets/Widgets/Control/ControlButton` | keep, normalize commands | `Views/Components/Controls/CommandButton` |
| `Assets/Widgets/UDMS Circuit/SingleGenUreaCircuit` | keep as pilot content | `Views/Equipment/Circuits/SingleGeneratorUreaCircuit` |
| `Assets/Popups/*` triplets | consolidate | `Views/App/Popups/Shells/*` + `Views/Equipment/*/PopupContent` |
| `MainWindows/TX3/GDMS*` | consolidate | `Views/App/Pages/TX3/GDMS/*` using shared shell |
| `MainWindows/TX3/MV-PMS*` | consolidate | `Views/App/Pages/TX3/MVPMS/*` using shared shell |
| `MainWindows/TX3/UDMS*` | consolidate | `Views/App/Pages/TX3/UDMS/*` using shared shell |
| `Test/*` | quarantine from active runtime structure | `Views/Tools/Testing/*` or external archive repo |

### D. Target view contracts

Standardize parameter contracts for reusable views:
- `params.objectPath`
- `params.assetPath`
- `params.displayName`
- `params.variant`
- `params.popupMode`
- `params.zoomEnabled`
- `params.statePath` where needed
- `params.commandPath` where needed

Then internally bind widgets to semantic object members such as:
- `{objectPath}/Electrical/RealPower/Value`
- `{objectPath}/Health/CommStatus/Value`
- `{objectPath}/Control/AutoManual/Value`

---

## Section 3: Phased refactoring plan

### Phase 0: Inventory and defect stabilization

Objective: create a safe baseline.

Actions:
1. inventory all active routes, views, embedded references, popup references, and scripts
2. inventory all exported 4-20 UDTs and instances
3. classify resources into production vs test/archive/dev
4. fix known broken page/view references before structural migration
5. freeze a baseline export of tags/views/scripts

Outputs:
- dependency matrix
- route map
- active widget catalog
- current UDT instance map
- defect list

### Phase 1: Define target conventions

Objective: lock naming and structural rules before moving files.

Rules to adopt:
- no spaces, parentheses, or `review`/`future` suffixes in active runtime resources
- production views live under `Views/App`, `Views/Components`, or `Views/Equipment`
- test/dev/archive content cannot remain mixed into runtime trees
- all new reusable views expose explicit params
- all new domain object UDTs are semantic, not vendor-register dumps

### Phase 2: Build the semantic base-model library

Objective: create reusable semantic primitives inspired by object-models.

First deliverables:
- `Base/Definition/*`
- `Base/Value/*`
- `Base/Parameter/*`
- `Base/Status/*`
- `Base/Control/*`

Verification:
- export/import cleanly as UDTs
- nested composition works in instance examples
- value/status/metadata contracts are stable

### Phase 3: Create adapter wrappers for current device UDTs

Objective: preserve current device models while preparing migration.

Actions:
- wrap each existing 4-20 device UDT as an explicit adapter type
- document which semantic members each adapter can supply
- identify missing semantics that require helper members or derived tags

Outputs:
- adapter spec for Jenbacher, SEL700G, SEL751, SEL751A, SEL735, SEL787

### Phase 4: Create first semantic object family

Objective: prove the model on one bounded slice.

Recommended pilot:
- `Object/Generator/Genset`
- `Object/Breaker/GeneratorBreaker`
- `Object/Relay/ProtectionRelay`
- `Object/Circuit/SingleGeneratorCircuit`

Why:
- maps well onto existing TX3 and popup families
- already has repeated UI patterns
- enough complexity to validate the approach without a big-bang rewrite

### Phase 5: Refactor the Perspective contract layer

Objective: keep existing assets but normalize how they bind.

Actions:
- keep current high-value widgets
- convert them to semantic parameter contracts
- move repeated inline logic into widget internals or shared scripts
- centralize style logic into a stronger style class hierarchy

Priority assets to preserve and normalize:
- `Assets/Pipes/*`
- `Assets/Widgets/Data Display/*`
- `Assets/Widgets/Breaker/*`
- `Assets/Widgets/Control/*`
- `Assets/Widgets/Valves/*`

### Phase 6: Consolidate popup families

Objective: eliminate repeated popup triplets.

Current repeated families include:
- `C32B`
- `mvGensetFCB`
- `mvGensetGCB`
- `mvGensetICB`
- `Sync Con`
- `MVGenset AUX XFMR CB`

Target pattern:
- shared popup shell
- shared popup layout contract
- family-specific content view
- semantic object path passed in via params

### Phase 7: Consolidate TX3 main-window families

Objective: reduce page duplication.

Current repeated groups:
- `GDMS`, `GDMS-Asset`, `GDMS-ZoomCapable`
- `MV-PMS`, `MV-PMS-Asset`, `MV-PMS-ZoomCapable`
- `UDMS`, `UDMS-Asset`, `UDMS-ZoomCapable`

Target pattern:
- one common page shell
- one common asset/detail shell
- one common zoom wrapper
- embedded family-specific circuit content

### Phase 8: Migrate one family end-to-end

Objective: prove the full stack.

Recommended first pilot:
- one TX3 family, preferably `UDMS`
or
- one `mvGenset` popup family

Pilot deliverables:
- semantic object UDTs
- mapped adapter UDTs
- normalized widget contracts
- one migrated page family
- one migrated popup family
- validation plus gateway restart workflow

### Phase 9: Expand by family, not by technology layer

Objective: preserve runtime confidence.

Migrate in vertical slices:
1. semantic object layer for one family
2. widget contract updates for that family
3. popup/page refactor for that family
4. runtime validation
5. proceed to next family

Avoid doing all tag refactors first and all UI refactors later.

---

## Recommended immediate next actions

1. Build a canonical mapping spreadsheet/document:
   current device UDT -> semantic object -> current screens/popups/widgets
2. Define the first base semantic UDT set
3. Define the first pilot semantic object family around TX3 genset/circuit equipment
4. Build one normalized popup shell and one normalized TX3 page shell
5. Migrate one family only after the above is stable

## Success criteria

The refactor is successful when:
- 4-20 still uses its existing live tag/device infrastructure where practical
- UI binds mostly to semantic object contracts rather than raw vendor payloads
- popup/page families are parameterized instead of copied
- test/archive resources are separated from runtime resources
- naming is normalized
- new equipment can be added by instantiating semantic objects, not by cloning flat views and ad hoc tag bindings
