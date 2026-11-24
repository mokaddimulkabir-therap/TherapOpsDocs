# OCI Security Hardening, AIDE & Auditd

OCI cloud instances require cloud-adapted CIS benchmarking, strict crypto policies, file integrity monitoring, and centralized audit forwarding.

---

## 1. Apply OCI CIS Hardening Benchmark

Execute the customized OCI CIS script:

```bash
mkdir -p /root/cis-hardening
cd /root/cis-hardening

# Place or download ol8-cis-hardening_oci.sh
chmod u+x ol8-cis-hardening_oci.sh
./ol8-cis-hardening_oci.sh

# Verify logs for failures
grep -iE "fail|warn|err" cis_script_logs_backups/ol8-cis-hardening-script.log

# Reboot to apply kernel and sysctl parameters
reboot
```

After reboot, verify the system umask:
```bash
umask
# Expected: 0027
```

---

## 2. Cryptographic Policies

### Baseline / Standard Policy
```bash
update-crypto-policies --show
mv /etc/crypto-policies/policies/modules/CBC.pmod /etc/crypto-policies/policies/modules/NOCBC.pmod 2>/dev/null || true
mv /etc/crypto-policies/policies/modules/SHA1.pmod /etc/crypto-policies/policies/modules/NOSHA1.pmod 2>/dev/null || true

update-crypto-policies --set DEFAULT:NOCBC:NOSHA1:TERRAPIN
update-crypto-policies --show
```

---

## 3. File Integrity Monitoring (AIDE)

Install and initialize AIDE (Advanced Intrusion Detection Environment):

```bash
dnf install -y aide

# Initialize database
aide --init
mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Test check
aide --check
```

### Automated Weekly Check Script
Create `/root/aide/aide_check.sh`:

```bash
#!/bin/bash
HOSTNAME=$(hostname)
AIDE_OUTPUT=$(sudo /sbin/aide --check)
MAILLIST="sysops@example.com oncallops@example.com secops@example.com"

if echo "$AIDE_OUTPUT" | grep -q 'found differences between database and filesystem'; then
   echo "$AIDE_OUTPUT" | mail -s "AIDE Alert: File Changes Detected on $HOSTNAME" $MAILLIST
fi
```

Set permissions and schedule via root cron:
```bash
chmod u+x /root/aide/aide_check.sh

# Add to crontab: runs every Saturday at 10:00 AM
crontab -e
# 0 10 * * 6 /root/aide/aide_check.sh > /dev/null 2>&1
```

---

## 4. Central Rsyslog & Auditd Forwarding

Forward audit and security logs to regional collectors. Add an entry for each destination collector (`<SYSLOG_HOST_01>`, `<SYSLOG_HOST_02>`):

### Step 1: Configure Rsyslog Audit Forwarding
Add destination entry for your primary syslog host:
```bash
cat >> /etc/rsyslog.d/audit.conf << 'EOF'
## Audit log to <SYSLOG_HOST_01>
local3.info                                             @<SYSLOG_HOST_01>
local3.info                                             stop
EOF
```

If forwarding to a secondary/failover syslog host, append:
```bash
cat >> /etc/rsyslog.d/audit.conf << 'EOF'
## Audit log to <SYSLOG_HOST_02>
local3.info                                             @<SYSLOG_HOST_02>
local3.info                                             stop
EOF
```

### Step 2: Configure Auditd Syslog Plugin
```bash
# Configure auditd syslog plugin
cp /etc/audit/plugins.d/syslog.conf /etc/audit/plugins.d/syslog.conf.orig

cat << 'EOF' > /etc/audit/plugins.d/syslog.conf
active = yes
direction = out
path = /sbin/audisp-syslog
type = always
args = LOG_INFO LOG_LOCAL3
format = string
EOF
```

### Step 3: Restart & Verify Services
Restart both services and inspect their running status in a single command:
```bash
systemctl restart rsyslog.service && service auditd restart && systemctl status rsyslog auditd --no-pager
```
