# 4-20 Naming Conventions Refactor Recommendation

Goal: define a consistent naming convention for tags, UDTs, folders, and Perspective resources that aligns with the VoltaGrid requirements and SEL FDS while preserving the new hierarchical plant path structure:

- TX3
- PowerBlock_1
- Node_1
- QPAC_1
- ...

Source documents analyzed:
- `VoltaGrid Requirements.pdf`
- `VoltaGrid_SEL_FDS.pdf`

---

## 1. Key terminology extracted from the source documents

The documents consistently use a plant-domain vocabulary rather than vendor/register vocabulary.

Primary hierarchy terms appearing in the documents:
- TX-3
- Node 1
- QPac
- Generator / Genset
- Relay / IED
- FEP
- GCS
- GMS
- AGC
- VCS
- GCB
- ICB
- FCB
- Synchronous Condenser / Sync Con
- VG E-house
- feeder
- breaker
- main bus

Important domain statements from the documents:
- `QPac` is explicitly defined in the FDS as a group of four gas turbines.
- The system is structured by plant/site, node, QPac, generator, breaker, relay, feeder, auxiliary systems.
- The documents consistently describe semantic equipment roles such as:
  - generator control system (GCS)
  - generator management system (GMS)
  - generator circuit breaker (GCB)
  - isolation circuit breaker (ICB)
  - feeder circuit breaker (FCB)
  - intelligent electronic device (IED)
- The requirements document emphasizes single-line diagrams as the canonical high-level diagram showing generators, transformers, busbars, breakers, meters, and feeders together with ratings and identifiers.

Conclusion:
The official language is equipment-role-based and plant-structure-based. It is not centered on raw vendor point names.

---

## 2. Naming design principles

### Preserve
Preserve the plant path hierarchy you just created:
- `TX3/PowerBlock_1/Node_1/QPAC_1/...`

This aligns well with the plant-domain structure implied by the documents.

### Prefer semantic names over vendor payload names
Good:
- `PowerGen/Gen_1`
- `IEDs/700G_2`
- `Breakers/GCB_1`

Avoid as primary semantic names:
- `tx3-pb1-n1-qp5-sel700g-002`
- `jenbacher620_1_0_0`
- register-shaped or ad hoc flat identifiers as the visible domain layer

### Separate hierarchy naming from leaf object naming
Use the path to express location/context:
- `TX3/PowerBlock_1/Node_1/QPAC_2/IEDs/700G_2`

Use the object name to express role and local identity:
- `700G_2`
- `Gen_3`
- `GCB_1`
- `FEP_A`

### Preserve document abbreviations when they are canonical
Use these document-backed abbreviations as-is:
- `QPAC`
- `IED`
- `GCB`
- `ICB`
- `FCB`
- `FEP`
- `GCS`
- `GMS`
- `AGC`
- `VCS`

These are formally defined in the source documents and should remain uppercase.

### Use readable object grouping folders
Folder/group names should be plural and semantic.
Recommended examples:
- `PowerGen`
- `IEDs`
- `Breakers`
- `Meters`
- `Transformers`
- `Auxiliaries`
- `Controllers`
- `SyncCondensers`

---

## 3. Recommended naming convention standard

## 3.1 Top-level plant hierarchy

Recommended:
- `TX3`
- `PowerBlock_1`
- `Node_1`
- `QPAC_1`

Convention:
- Facility or site: `TX3`
- Structural groups: `PowerBlock_<n>`, `Node_<n>`, `QPAC_<n>`
- Use underscore-number suffixes for structural containers
- Avoid mixing styles like `PowerBlock1`, `power_block_1`, `PB1`, unless a shorter alias is explicitly required elsewhere

Rationale:
This is readable, deterministic, and consistent with the official plant concepts.

## 3.2 Equipment grouping folders

Recommended folder names:
- `PowerGen`
- `IEDs`
- `Breakers`
- `Meters`
- `Transformers`
- `Auxiliaries`
- `Control`
- `Status`
- `Alarms`

Notes:
- Use plural nouns for collections
- Use singular nouns for leaf objects
- Do not mix vendor names into group folder names unless the folder is explicitly vendor-scoped

## 3.3 Leaf equipment objects

Recommended patterns:
- `Gen_1`, `Gen_2`, `Gen_3`
- `700G_1`, `700G_2`
- `751_1`, `751_2`
- `751A_1`
- `735_1`
- `787_1`
- `GCB_1`
- `ICB_1`
- `FCB_1`
- `FEP_A`, `FEP_B`
- `SyncCon_1`, `SyncCon_2`

Why:
- matches domain language from the documents
- avoids stuffing full location or vendor history into the object name
- location is already handled by the hierarchy

Avoid:
- repeating context already in the path
  - bad: `TX3_PowerBlock_1_Node_1_QPAC_1_Gen_1`
- embedding implementation/version suffixes in live object names
  - bad: `sel700g_1_0_0`
  - bad: `jenbacher620_1_0_0-original`

## 3.4 Attribute/member names inside UDTs and objects

Recommended style:
- use PascalCase or UpperCamelCase for semantic object members
- use full words for major semantic members
- reserve acronyms for document-defined items

Recommended examples:
- `Definition`
- `DisplayName`
- `DeviceType`
- `Vendor`
- `Health`
- `CommStatus`
- `Heartbeat`
- `Electrical`
- `Voltage`
- `Frequency`
- `RealPower`
- `ReactivePower`
- `BreakerStatus`
- `LocalRemoteMode`
- `AutoManualMode`
- `SetpointPower`

Avoid for new semantic layers:
- `spare545_LocalRemote`
- `spare515_BreakerStatus`
- raw register-ish or temporary names

These can remain inside device UDTs, but they should be mapped into clearer semantic members in the object layer.

## 3.5 UDT type names

Recommended three-layer UDT naming:

### Device UDTs
Keep vendor-specific types, but rename them to be explicit and clean when you formalize them:
- `Device_Generator_JenbacherJ620`
- `Device_Relay_SEL700G`
- `Device_Relay_SEL751`
- `Device_Relay_SEL751A`
- `Device_Meter_SEL735`
- `Device_Relay_SEL787`

### Semantic base UDTs
- `Base_Definition_Equipment`
- `Base_Value_Numeric`
- `Base_Value_Boolean`
- `Base_Status_Comm`
- `Base_Status_Health`
- `Base_Control_Command`

### Domain object UDTs
- `Obj_Generator_Genset`
- `Obj_Relay_ProtectionRelay`
- `Obj_Breaker_GeneratorCircuitBreaker`
- `Obj_Breaker_IsolationCircuitBreaker`
- `Obj_Breaker_FeederCircuitBreaker`
- `Obj_Circuit_SingleGeneratorCircuit`
- `Obj_System_GCS`
- `Obj_System_GMS`
- `Obj_System_VCS`
- `Obj_System_AGC`

Why this works:
- deterministic
- easy to group alphabetically
- clearly separates layers
- preserves document terminology

## 3.6 Perspective folder/view naming

Preserve the runtime semantic path model and normalize Perspective similarly.

Recommended view taxonomy:
- `Views/App/Pages/TX3/...`
- `Views/App/Popups/...`
- `Views/Components/Generators/...`
- `Views/Components/Relays/...`
- `Views/Components/Breakers/...`
- `Views/Components/DataDisplays/...`
- `Views/Equipment/TX3/PowerBlock_1/Node_1/...`

Perspective naming rules:
- no spaces
- no parentheses
- no `review`, `future`, or `Development (1)` in runtime resources
- use PascalCase for view folders/files in Perspective
- preserve uppercase for canonical acronyms like `TX3`, `QPAC`, `GCB`, `IED`

Examples:
- `RefactorPilot/Components/GensetSummaryCard`
- `RefactorPilot/Components/RelaySummaryCard`
- `App/Pages/TX3/Node1Overview`
- `Components/Breakers/GeneratorCircuitBreakerCard`

---

## 4. Recommended concrete refactor rules

### Rule 1: Path hierarchy stays plant-structural
Keep:
- `TX3/PowerBlock_1/Node_1/QPAC_1/...`

Do not flatten this back into device names.

### Rule 2: Group folders describe collections
Use:
- `PowerGen`
- `IEDs`
- `Breakers`
- `Meters`

Do not use mixed ad hoc folders like:
- `GenStuff`
- `Protection`
- `SEL700Gs`
unless there is a good domain reason.

### Rule 3: Leaf object names are short, local, and role-based
Use:
- `Gen_1`
- `700G_2`
- `GCB_1`
- `FEP_A`

### Rule 4: Vendor/register naming stays in adapter layer only
Keep raw vendor field names inside device adapter UDTs if needed for compatibility.
But expose clean semantic aliases for the rest of the project.

Example:
- adapter member: `spare545_LocalRemote`
- semantic object member: `LocalRemoteMode`

### Rule 5: Canonical acronyms remain uppercase
Use uppercase for terms formally defined in the documents:
- `QPAC`
- `IED`
- `GCB`
- `ICB`
- `FCB`
- `FEP`
- `GCS`
- `GMS`
- `AGC`
- `VCS`

### Rule 6: Counters use `_N` suffixes
Use:
- `PowerBlock_1`
- `Node_1`
- `QPAC_2`
- `Gen_3`
- `700G_2`

This is clearer and more maintainable than mixed `01`, `002`, `A1`, or vendor-style numbering unless required by an external interface.

### Rule 7: Separate operational name from display label
Tag/view object names should be deterministic.
Friendly display names can be stored separately.

Example:
- runtime object name: `Gen_1`
- display label: `QPAC 1 Generator 1`

---

## 5. Recommended example target naming model

### Example 1: Genset
Current-style concept:
- `[default]TX3/PowerBlock_1/Node_1/QPAC_1/PowerGen/Gen_1`

Recommended internal semantic members:
- `Definition/DisplayName`
- `Definition/Vendor`
- `Definition/Model`
- `Electrical/Voltage`
- `Electrical/Frequency`
- `Electrical/RealPower`
- `Electrical/ReactivePower`
- `Control/AutoManualMode`
- `Control/LocalRemoteMode`
- `Status/BreakerStatus`
- `Status/Heartbeat`
- `Source/Adapter_Generator_JenbacherJ620`

### Example 2: Relay
Current-style concept:
- `[default]TX3/PowerBlock_1/Node_1/QPAC_2/IEDs/700G_2`

Recommended internal semantic members:
- `Definition/DisplayName`
- `Definition/Vendor`
- `Definition/Model`
- `Status/CommStatus`
- `Status/Heartbeat`
- `Protection/BreakerPosition`
- `Protection/SyncFrequency`
- `Protection/TripStatus`
- `Source/Adapter_Relay_SEL700G`

### Example 3: Breaker
Recommended object path:
- `[default]TX3/PowerBlock_1/Node_1/QPAC_2/Breakers/GCB_2`

Recommended naming by breaker class:
- `GCB_1`
- `ICB_1`
- `FCB_1`

This directly aligns with the terminology in the requirements and FDS.

---

## 6. Recommended migration order for naming cleanup

1. Freeze the current plant path hierarchy
   - preserve `TX3/PowerBlock_1/Node_1/QPAC_1/...`
2. Normalize collection folder names
   - `PowerGen`, `IEDs`, `Breakers`, `Meters`, etc.
3. Normalize leaf object names
   - `Gen_1`, `700G_2`, `GCB_1`
4. Introduce semantic member aliases in object UDTs
   - map raw adapter fields to semantic member names
5. Normalize UDT type naming
   - `Adapter_*`, `Base_*`, `Obj_*`
6. Normalize Perspective resource names and folders
7. Remove or quarantine legacy flat names only after compatibility mapping exists

---

## 7. Final recommendation summary

Recommended convention set:
- preserve plant structural hierarchy: `TX3/PowerBlock_1/Node_1/QPAC_1/...`
- use plural semantic folders for collections: `PowerGen`, `IEDs`, `Breakers`, `Meters`
- use short role-based leaf names: `Gen_1`, `700G_2`, `GCB_1`, `FEP_A`
- preserve formal electrical/control acronyms in uppercase: `QPAC`, `IED`, `GCB`, `ICB`, `FCB`, `FEP`, `GCS`, `GMS`, `AGC`, `VCS`
- keep vendor/register naming only in adapter UDTs
- expose semantic names everywhere else
- separate deterministic runtime identifiers from human display labels

This gives you a naming model that is:
- aligned with the VoltaGrid and SEL documents
- easier to understand from an operations perspective
- compatible with your new object hierarchy
- much cleaner than the legacy flat vendor/device naming
