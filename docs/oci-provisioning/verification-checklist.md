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

## 📝 Standardized Task-by-Task Check Commands

Execute or paste this standard verification sequence to audit tasks across the node:

```bash
echo "Task:01 | /etc/postfix/main.cf" && grep -E '^(myhostname|mydomain|relayhost)\s*=' /etc/postfix/main.cf
echo "Task:02 | /etc/cron.d/sysstat" && grep -E '59|MAILTO' /etc/cron.d/sysstat
echo "Task:03 | /etc/snmp/snmpd.conf" && grep -E '^\s*(syslocation|syscontact|rouser)' /etc/snmp/snmpd.conf
echo "Task:04 | /etc/issue.net" && grep 'You' /etc/issue.net
echo "Task:05 | /etc/sysconfig/sysstat" && grep 'HISTORY=30' /etc/sysconfig/sysstat
echo "Task:06 | /etc/chrony.conf" && grep -E '^(bindcmdaddress|cmdallow)' /etc/chrony.conf
echo "Task:07 | /etc/oci-hostname.conf" && grep 'PRESERVE_HOSTINFO' /etc/oci-hostname.conf 2>/dev/null || true
echo "Task:08 | /etc/security/limits.conf" && grep -Ei 'soft|hard|oracle' /etc/security/limits.conf
echo "Task:09 | /etc/logrotate.conf" && grep -A 5 -E '/var/log/(wtmp|btmp)' /etc/logrotate.conf
echo "Task:10 | /etc/logrotate.d/syslog" && grep -E 'rotate|size' /etc/logrotate.d/syslog
echo "Task:11 | /etc/rsyslog.conf" && grep -E '@syslog01-ta|@syslog01-oap' /etc/rsyslog.conf
echo "Task:12 | /etc/motd.d/cockpit" && ls -la /etc/motd.d/cockpit 2>/dev/null || echo "Cockpit MOTD clean"
echo "Task:13 | remove cockpit" && (rpm -q cockpit 2>/dev/null || echo "Cockpit not installed")
echo "Task:14 | List all the Disk" && lsblk && df -hT
echo "Task:15 | Check Crypto Policy" && update-crypto-policies --show
echo "Task:16 | Check umask" && umask
echo "Task:17 | Check Memory & Swap" && free -m
echo "Task:18 | Check /usr/local mounts" && ls -ld /usr/local/Oracle /usr/local/tomcat /usr/local/auth-tomcat /usr/local/therap 2>/dev/null || true
echo "Task:19 | Check /apps" && ls -ld /apps 2>/dev/null || echo "/apps not present on this host"
echo "Task:20 | Check /logs ACL" && (getfacl /logs 2>/dev/null || echo "/logs not present on this host")
echo "Task:21 | Check Application Directory" && ls -ld /usr/local/therap /usr/local/app 2>/dev/null || true
echo "Task:22 | Check User Login" && who -u
echo "Task:23 | Check User Shadow and Sudo" && sudo -l -U <USER>
echo "Task:24 | Check PermitRootLogin no" && grep -i "^PermitRootLogin" /etc/ssh/sshd_config
echo "Task:25 | Check ACL on Sorry Server" && (getfacl planned.html 2>/dev/null || echo "N/A for non-sorry hosts")
echo "Task:26 | Check NTP/chrony" && chronyc sources -v
echo "Task:27 | Check AIDE Configuration" && (ls -l /etc/aide.conf /var/lib/aide/aide.db.gz /root/aide/aide_check.sh 2>/dev/null || true)
echo "Task:28 | Check AIDE Crontab" && crontab -l -u root 2>/dev/null | grep -i aide || echo "No AIDE cron found"
```
