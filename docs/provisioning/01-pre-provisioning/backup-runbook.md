# Host Backup Runbook

Before rebuilding or reinstalling an OS on an existing server, collect and archive the system state to prevent data loss and ensure quick recovery of network/storage parameters.

---

## 1. Quick Info Gathering (CLI)

Run the following commands on the source host and save the terminal output:

### Standard Host Backup
```bash
# Network & Identity
ip a
ip route
cat /etc/hosts
cat /etc/resolv.conf
cat /etc/sysconfig/network-scripts/ifcfg-* 2>/dev/null || true

# Storage & Filesystems
lsblk
df -hT
cat /etc/fstab

# System & Directories
lscpu
free -h
ls -la /usr/local/
ls -la /
ls -la /home/
```

### RAC & Database Specific Backup
If the host is an **Oracle DB / RAC** node, also capture:
```bash
# iSCSI & Multipath
cat /etc/iscsi/initiatorname.iscsi
cat /etc/multipath.conf

# Oracle environment
ls -la /home/oracle/
```

---

## 2. Automated Backup Script Execution

A standard backup script (`backup.sh`) packages key configuration files, network scripts, and storage definitions into `/tmp/backup_<FQDN>.tar`.

[:material-download: Download `backup.sh`](../../scripts/backup.sh){ .md-button .md-button--primary }
[:material-file-code: View Script Documentation](../../scripts/index.md#2-host-configuration-backup-script-backupsh){ .md-button }

### Step 1: Run the Backup Script on Target Host
Run the backup script directly on the server to be rebuilt:
```bash
sudo ./backup.sh
```

### Step 2: Transfer Archive to Central Repository
From the centralized operations server (`ops01-bd`), pull the archive using `rsync`:

```bash
# Run on ops01-bd
cd /opsrepo/host_bakup/

# Example transfer:
rsync -avz --progress <USERNAME>@<SOURCE_HOST>.therapbd.net:/tmp/backup_<SOURCE_HOST>.therapbd.net.tar .
```

!!! tip "Verify Archive Size"
    Always run `ls -lh /opsrepo/host_bakup/backup_<SOURCE_HOST>*.tar` to verify the backup file is intact and non-empty before initiating OS re-installation.
