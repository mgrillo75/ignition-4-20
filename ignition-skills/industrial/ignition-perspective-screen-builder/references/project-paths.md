# Project Paths

Use these filesystem locations when editing Ignition Perspective resources.

## Ignition 8.3 Filesystem-Managed Projects

This skill is confirmed against Ignition 8.3 filesystem-managed project layout.

Gateway install/root example on this system:
- `C:\Users\MiguelGrillo\Documents\ignition8_3`

Project root pattern:
- `C:\Users\MiguelGrillo\Documents\ignition8_3\data\projects\<project-name>`

Example project root:
- `C:\Users\MiguelGrillo\Documents\ignition8_3\data\projects\demo-test`

When a script in this skill asks for `-ProjectRoot`, pass the project directory itself, not the gateway root.

## Core Perspective Resources

- Views: `com.inductiveautomation.perspective/views/**/view.json`
- Page config: `com.inductiveautomation.perspective/page-config/config.json`
- Style classes: `com.inductiveautomation.perspective/style-classes/**/style.json`
- Session props: `com.inductiveautomation.perspective/session-props/**`
- Session scripts: `com.inductiveautomation.perspective/session-scripts/**`

## View Path Mapping

Convert an Ignition view path to a file path by appending `/view.json` under the views root.

Examples:
- Ignition view `Screens/LoadBank/Overview`
- File `com.inductiveautomation.perspective/views/Screens/LoadBank/Overview/view.json`

- Ignition view `Templates/Equipment/Faceplate`
- File `com.inductiveautomation.perspective/views/Templates/Equipment/Faceplate/view.json`

## Project Knowledge Sources

Before editing JSON, inspect any project-local architecture or conventions files that actually exist in the repository, such as:
- `.cursor/**`
- `docs/**`
- project readmes
- prior nearby view resources

If those files are absent, continue with the bundled references in this skill and the user's instructions instead of blocking.