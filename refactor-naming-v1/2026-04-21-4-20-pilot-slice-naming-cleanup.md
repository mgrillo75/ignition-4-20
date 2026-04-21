# Pilot Slice Naming Cleanup Applied

Pilot slice aligned to the recommended naming model:
- Genset semantic path: `TX3/PowerBlock_1/Node_1/QPAC_1/PowerGen/Gen_1`
- Relay semantic path: `TX3/PowerBlock_1/Node_1/QPAC_2/IEDs/700G_2`

Notes:
- The runtime Perspective cards currently point at these semantic object paths only when those tags exist in the gateway.
- The generated semantic tag package in `refactor-naming-v1/tags-semantic-v1.json` is the import-ready buildout for these paths and the rest of the currently exported TX3 equipment.
- Existing live cards were left operational; no additional card edits were required for the naming-only package output.
