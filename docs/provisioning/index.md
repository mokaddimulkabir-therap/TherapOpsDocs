# Host Provisioning & Lifecycle Guide

This section contains the end-to-end operational guide for provisioning, configuring, hardening, and verifying enterprise Linux systems (Oracle Linux 8) across Application, Database, and Oracle RAC nodes.

---

## 🗺️ Provisioning Lifecycle Overview

```mermaid
flowchart TD
    A["1. Pre-Provisioning\n(Backup & PXE Staging)"] --> B["2. Kickstart Execution\n(OS Installation)"]
    B --> C["3. Base OS Setup\n(CIS, Kernel, IDM, Syslog)"]
    C --> D["4. Network Migration\n(nmcli & Persistent Naming)"]
    D --> E["5. Workload Configuration\n(Oracle DB & RAC Storage)"]
    E --> F["6. Handover & Verification\n(Checklist & Decommissioning)"]
```

---

## 📑 Provisioning Stages

| Stage | Section | Description |
| :--- | :--- | :--- |
| **Stage 1** | [Pre-Provisioning](01-pre-provisioning/index.md) | Backup procedures and PXE/DHCP staging. |
| **Stage 2** | [OS Provisioning](02-provisioning/kickstart-execution.md) | Kickstart installation and validation. |
| **Stage 3** | [Base OS & Hardening](03-post-install-base/index.md) | CIS hardening, kernel management, IDM enrollment, and syslog. |
| **Stage 4** | [Network Migration](04-network-migration/index.md) | App & DB network configuration, interface renaming. |
| **Stage 5** | [Workload & Storage](05-workload-specific/oracle-prereqs.md) | Oracle database prerequisites and NetApp iSCSI/multipath. |
| **Stage 6** | [Verification & Handover](06-verification-handover/checklist.md) | Final verification checklist and old host decommissioning. |
