# CIS Benchmark Hardening

All Oracle Linux 8 nodes must be hardened according to the corporate CIS benchmark policy.

---

## 1. Download & Execute Hardening Script

Run these steps as `root`:

```bash
# Create working directory
mkdir -p /root/cis-hardening
cd /root/cis-hardening

# Fetch script from PXE server
curl -s http://192.168.48.239/ol8-cis-hardening.sh -o ol8-cis-hardening.sh
chown root:root ol8-cis-hardening.sh
chmod 700 ol8-cis-hardening.sh

# Run the hardening script
./ol8-cis-hardening.sh
```

---

## 2. Verify Execution Logs

After completion, inspect the log file for critical errors:

```bash
cd /root/cis-hardening/cis_script_logs_backups/
grep -E 'err|warn|fail' ol8-cis-hardening-script.log
```

---

## 3. Post-Hardening Permissions Sanity Check

Certain directories require specific permissions after CIS script execution:

```bash
# Ensure logbak permissions for system accounting
chmod 644 /var/log/sa/* 2>/dev/null || true

# Verify /usr/local and / permissions
chmod 755 /usr/local
chmod 755 /
```
