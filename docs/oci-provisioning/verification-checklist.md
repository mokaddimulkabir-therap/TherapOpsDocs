# OCI Post-Installation Verification Checklist

Execute these verification checks before releasing an OCI compute node into production.

---

## 📋 Comprehensive OCI Verification Checklist

- [ ] **Swap Disabled**: `free -m` reports swap as 0 MB; `/etc/fstab` contains no active swap entries.
- [ ] **Cockpit Removed**: `dnf list installed cockpit` reports not installed; `/etc/motd.d/cockpit` removed.
- [ ] **Cloud-Init Success**: `cloud-init.out` inspected with no fatal service failures.
- [ ] **Postfix / Mail Relay**: `grep -E '^(myhostname|mydomain|relayhost)\s*=' /etc/postfix/main.cf` verified; test mail sent.
- [ ] **Sysstat Accounting**: `grep -E '59|MAILTO' /etc/cron.d/sysstat` and `HISTORY=30` in `/etc/sysconfig/sysstat`.
- [ ] **SNMP Daemon**: `grep -E '^\s*(syslocation|syscontact|rouser)' /etc/snmp/snmpd.conf` verified.
- [ ] **Banner & MOTD**: Login warning verified in `/etc/issue.net`.
- [ ] **Time Synchronization**: Chrony configured and synced (`chronyc sources -v`); bind addresses validated.
- [ ] **Logrotate**: Rules verified in `/etc/logrotate.conf` (`wtmp`, `btmp`) and `/etc/logrotate.d/syslog`.
- [ ] **Hosts Resolution**: Static host entries verified in `/etc/hosts`.
- [ ] **SSH Security**: `PermitRootLogin no` confirmed in `/etc/ssh/sshd_config`.
- [ ] **OPC User Lockdown**: `/home/opc/.ssh/authorized_keys` disabled; sudo rules in `90-cloud-init-users` commented out.
- [ ] **OCI Hostname Preservation**: `PRESERVE_HOSTINFO` verified in `/etc/oci-hostname.conf`.
- [ ] **Security Limits**: Soft/hard nofile (`nofile 65536`) set in `/etc/security/limits.conf`.
- [ ] **Rsyslog Forwarding**: Central collector targets active in `/etc/rsyslog.conf` and `/etc/rsyslog.d/audit.conf`.
- [ ] **Storage & Mounts**: All partitions mounted via UUID/device in `/etc/fstab`; `df -hT` verified.
- [ ] **Crypto Policy**: Confirmed active via `update-crypto-policies --show` (e.g. `DEFAULT:NOCBC:NOSHA1:TERRAPIN`).
- [ ] **Sudo Access Validation**: `sudo -l -U <USER>` verified.

---

## ⚡ Automated Audit Execution (`oci_checker.sh`)

Instead of running checks manually one-by-one, download and execute the centralized audit script:

[:material-download: Download `oci_checker.sh`](../scripts/oci_checker.sh){ .md-button .md-button--primary }
[:material-file-code: View Script Documentation](../scripts/index.md#1-oci-post-installation-verification-script-oci_checkersh){ .md-button }

```bash
# Execute for the host's specific role:
sudo ./oci_checker.sh [app|db|ops|nms|syslog|nessus|jenkins]

# Example for Jenkins worker:
sudo ./oci_checker.sh jenkins

# Emit report directly to JSON for automated verification:
sudo ./oci_checker.sh app --json
```

---

## 📝 Manual Fallback Command Block

Run this composite check command directly on the host to generate the sign-off record:

```bash
echo "=== 1. SWAP STATUS ===" && free -m
echo "=== 2. MOTD CHECK ===" && ls -la /etc/motd.d/
echo "=== 3. POSTFIX CONFIG ===" && grep -E '^(myhostname|mydomain|relayhost)\s*=' /etc/postfix/main.cf
echo "=== 4. SYSSTAT CRON ===" && grep -E '59|MAILTO' /etc/cron.d/sysstat
echo "=== 5. SNMP CONFIG ===" && grep -E '^\s*(syslocation|syscontact|rouser)' /etc/snmp/snmpd.conf
echo "=== 6. LOGIN BANNER ===" && grep 'You' /etc/issue.net
echo "=== 7. SYSSTAT RETENTION ===" && grep 'HISTORY=30' /etc/sysconfig/sysstat
echo "=== 8. CHRONY CONFIG ===" && grep -E '^(bindcmdaddress|cmdallow)' /etc/chrony.conf
echo "=== 9. LOGROTATE CONFIG ===" && grep -A 5 -E '/var/log/(wtmp|btmp)' /etc/logrotate.conf
echo "=== 10. SSH ROOT LOGIN ===" && grep -i "^PermitRootLogin" /etc/ssh/sshd_config
echo "=== 11. OCI HOSTINFO ===" && grep 'PRESERVE_HOSTINFO' /etc/oci-hostname.conf 2>/dev/null || true
echo "=== 12. CRYPTO POLICY ===" && update-crypto-policies --show
echo "=== 13. FILESYSTEMS & MOUNTS ===" && lsblk && df -hT
echo "=== 14. CHRONY TRACKING ===" && chronyc sources -v
```
