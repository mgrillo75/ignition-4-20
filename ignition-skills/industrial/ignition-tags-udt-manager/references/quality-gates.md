# Quality Gates

Run these checks before returning tag/UDT edits.

## Safety

1. Confirm target provider and path before editing.
2. Confirm a backup/export strategy exists for rollback.
3. Avoid unrelated provider or project edits.

## JSON Integrity

1. All edited JSON must parse.
2. No trailing commas.
3. Preserve existing structure style where possible.
4. Keep arrays in `udts.json`; do not convert payload files into objects.

## Tag/UDT Integrity

1. Every tag row has at least `name` and `tagType`.
2. Every `tagType: "UdtInstance"` row includes a `typeId`.
3. Every `tagType: "UdtType"` row keeps stable `parameters` and `tags` shape.
4. Parameter token bindings (`{ParamName}`) only reference valid UDT parameters or predefined parameters (for example `{TagName}`).
5. Nested UDT pass-through parameters remain mapped after edits.
6. Inherited UDT changes only override existing members unless parent edits are explicitly requested.
7. Relative tag paths (`[.]`, `[~]`) are preserved where used.

## Operational Readiness

1. Validation script passes for edited provider path.
2. Validation includes type roots so instance `typeId` references resolve.
3. Apply changes through Ignition Manager **Apply + Restart**.
