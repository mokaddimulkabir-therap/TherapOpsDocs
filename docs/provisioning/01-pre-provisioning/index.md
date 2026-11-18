# 1. Pre-Provisioning Phase

Before any operating system re-installation or hardware provisioning begins, two critical requirements must be met:

1. **Backup Existing Configuration**: Ensuring all networking, routing, mount points, and application files from the existing server are archived remotely.
2. **PXE / Kickstart Staging**: Preparing and publishing the kickstart (`.cfg`) file on the central PXE server.

---

### Step-by-Step Flow

```mermaid
flowchart TD
    A["Gather System State & Run backup.sh"] --> B["Transfer Archive to Central Backup Host (ops01-bd)"]
    B --> C["Create/Update Host KS in Git (bd-pxe)"]
    C --> D["Pull on PXE Host (ol8pxe01-bd) & Create Symlink"]
    D --> E["Validate DHCP Leases & Scope"]
```

---

### Phase Guides

* [Host Backup Runbook](backup-runbook.md) — Comprehensive commands & scripts to capture system baseline.
* [PXE & DHCP Setup](pxe-dhcp-setup.md) — Kickstart git workflow, web hosting permissions, and DHCP range check.
