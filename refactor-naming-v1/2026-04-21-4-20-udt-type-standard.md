# 4-20 UDT Type Naming Standard

Prefix rules:
- `Device_` = vendor/device-specific UDTs that preserve raw source field names
- `Base_` = reusable semantic primitives
- `Obj_` = semantic domain objects used by views and higher-level logic

Active UDT names in semantic package:
- Device_Generator_JenbacherJ620
- Device_Relay_SEL700G
- Device_Relay_SEL751
- Device_Relay_SEL751A
- Device_Meter_SEL735
- Device_Relay_SEL787_3E
- Obj_Generator_Genset
- Obj_Relay_ProtectionRelay700G
- Obj_Relay_ProtectionRelay751
- Obj_Relay_ProtectionRelay787
- Obj_Breaker_GeneratorCircuitBreaker
- Obj_Breaker_FeederCircuitBreaker

Object/member naming rules:
- Preserve canonical acronyms in uppercase: TX3, QPAC, IED, GCB, ICB, FCB, FEP, GCS, GMS, AGC, VCS
- Use PascalCase semantic member names: `RealPower`, `ReactivePower`, `AutoManualMode`, `BreakerStatus`
- Keep raw vendor naming only inside device UDTs
