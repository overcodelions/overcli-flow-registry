# overcli Flow Registry

This directory is the source of truth for [github.com/overcodelions/overcli-flow-registry](https://github.com/overcodelions/overcli-flow-registry). Push updates to that repo's `main` branch after testing locally.

## Adding a flow

1. Drop a flow YAML file into `flows/` (e.g., `flows/example-flow.yaml`).
2. Compute its sha256:
   ```bash
   shasum -a 256 flows/example-flow.yaml | cut -d ' ' -f1
   ```
3. Add an entry to `index.json` with the sha256 and a relative `yaml_url`:
   ```json
   {
     "id": "example-flow",
     "name": "Example Flow",
     "description": "A sample flow",
     "version": "1.0.0",
     "sha256": "<sha256-hash>",
     "yaml_url": "flows/example-flow.yaml"
   }
   ```

> **Note:** CI must validate flows using `validateFlow` to ensure only valid flows are published (deferred from v1).
