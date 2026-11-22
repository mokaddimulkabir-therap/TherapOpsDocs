# Scripts & Operational Tooling

All utility and audit scripts referenced throughout this knowledge base are hosted here for direct viewing, execution, and download.

---

## 🛠️ Available Scripts

| Script | Category | Purpose | Direct Download |
| :--- | :--- | :--- | :--- |
| **`oci_checker.sh`** | OCI Provisioning | Standard post-install verification and audit script for OCI instances. | [:material-download: Download `oci_checker.sh`](oci_checker.sh) |
| **`backup.sh`** | On-Prem Provisioning | State capture and backup packager before host re-provisioning. | [:material-download: Download `backup.sh`](backup.sh) |

---

## 1. OCI Post-Installation Verification Script (`oci_checker.sh`)

An enterprise-grade, read-only audit tool for newly provisioned OCI Linux compute nodes. It inspects partition mounts, UUID mapping in `/etc/fstab`, root LV capacity, strict umask, crypto policies, AIDE baseline, auditd forwarding, swap removal, and administrator sudo permissions.

### Quick Run (Direct from Host)
```bash
# Run with default role (app)
sudo ./oci_checker.sh

# Run for a specific workload role
sudo ./oci_checker.sh jenkins
sudo ./oci_checker.sh db
sudo ./oci_checker.sh syslog

# Output JSON summary report
sudo ./oci_checker.sh app --json

# Save execution log to file
sudo ./oci_checker.sh app --log /root/post_install_audit.log
```

??? example "View Full Source: `oci_checker.sh`"
    ```bash
    --8<-- "docs/scripts/oci_checker.sh"
    ```

---

## 2. Host Configuration Backup Script (`backup.sh`)

Run this script as `root` on an existing host before re-imaging to collect network addresses, routing tables, installed packages, storage layouts, and `/etc` configs into `/tmp/backup_<FQDN>.tar`.

### Execution
```bash
sudo ./backup.sh
# Output saved to /tmp/backup_<HOSTNAME>.tar
```

??? example "View Full Source: `backup.sh`"
    ```bash
    --8<-- "docs/scripts/backup.sh"
    ```
