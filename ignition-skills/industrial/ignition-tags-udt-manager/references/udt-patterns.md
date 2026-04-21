# UDT Patterns (Ignition 8.3)

Use this file when implementing UDT-centric tag architectures in filesystem resources.

## UDT Parameters

- Define parameters in UDT definitions under `parameters`.
- Reference parameters with `{ParameterName}`.
- Parameters can be used in any configurable field that supports bindings.
- Common predefined parameter: `{TagName}`.
- Example pattern:
  - `sourceTagPath.binding = "{BasePath}/{TagName}"`

## Multi-Instance Pattern

- Multi-instance creation is an instance-row generation task in `tag-definition/**/udts.json`.
- Each row is a `tagType: "UdtInstance"` object with:
  - deterministic `name`
  - `typeId` pointing to an existing UDT definition
  - optional `parameters` overrides
- Keep naming deterministic for scaling:
  - `kq_instance_1`, `kq_instance_2`, ...

## Inheritance Pattern

- Child UDT definitions inherit structure and settings from parent type definitions.
- Child definitions should override existing members, not invent new members unless parent updates are part of the request.
- When patching inherited types in JSON, preserve member names and only touch requested override fields.

## Nesting Pattern

- Nested UDTs are modeled as `tagType: "UdtInstance"` members inside a parent `tagType: "UdtType"` definition.
- Pass parent parameters to child parameters explicitly with parameter bindings.
- Example pass-through:
  - parent parameter: `MotorNumber`
  - nested UDT parameter value binding: `{MotorNumber}`

## Tag Path Pattern

- Absolute provider path: `[provider]Folder/Tag`.
- Relative (same folder): `[.]Tag`.
- Relative (provider root): `[~]Folder/Tag`.
- Perspective bindings usually start from an explicit root instance path and derive child paths from there.

## Expression Pattern for Tag Config

- Use expression syntax for derived values where needed.
- Wrap bound references in braces, for example `{value}`.
- Use `try()` around risky expressions when bad quality or nulls are possible.

## Example Architecture Pattern

A common safe pattern is:
- UDT definitions under `tag-type-definition/<provider>/...`
- Runtime instances under `tag-definition/<provider>/udts.json`
- Instance rows with stable names and explicit `typeId`
- Perspective views using `view.params.tagPath` with indirect bindings to child members
