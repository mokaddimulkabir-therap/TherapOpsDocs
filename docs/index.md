# TherapOpsDocs

Welcome to **TherapOpsDocs** — the enterprise operations knowledge base and standard operating procedures (SOP) repository for infrastructure, system administration, and workloads.

---

## 📚 Documentation Sections

```mermaid
flowchart TD
    Ops["TherapOpsDocs Knowledge Base"]
    Ops --> P["Host Provisioning\n(OL8, App, DB, RAC)"]
    Ops --> N["Infrastructure & Networking\n(Future Scope)"]
    Ops --> S["Security & Identity\n(Future Scope)"]
```

### Active Modules

* **[Host Provisioning & Lifecycle](provisioning/index.md)**: Standardized runbook for host re-imaging, Kickstart installation, security hardening, network migration, and Oracle RAC storage setup.

---

## 💡 Repository Principles

1. **Standardized Commands**: Only vetted, standard commands used by the operations team are documented.
2. **Modular Structure**: Topics are grouped logically under domain categories to support future expansion without cluttering top-level navigation.
3. **No Plaintext Secrets**: Sensitive keys, password hashes, and host-specific IPs are parameterized.
