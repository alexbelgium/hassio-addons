## 0.64.5-8 (2026-07-06)
- Fix NetBird management startup by adding glibc compatibility for the upstream binary.
- Assign separate metrics ports for management, signal, and relay to avoid startup port conflicts.
- Quote dashboard OIDC scopes so the generated env file can be sourced correctly.
