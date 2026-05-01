# CRITICAL: Builder loop liveness stale, restart blocked

- TempleOS heartbeat age: 46244s (>600s)
- holyc-inference heartbeat age: 45347s (>600s)
- temple-sanhedrin heartbeat age: 0s (fresh)
- Required restart attempts executed and blocked:
  - `ssh ... localhost`: `Could not resolve hostname localhost: -65563`
  - `ssh ... 127.0.0.1`: `Operation not permitted`
- `automation/enforce-laws.sh`: `enforce-laws: 0 violations`
- CI checks (`gh run list`) and VM check (`ssh azureuser@52.157.85.234`) blocked by network restrictions in this sandbox.
