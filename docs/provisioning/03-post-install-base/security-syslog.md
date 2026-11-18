# Security Policies, Auditd & Central Syslog

This guide outlines system cryptographic policies, central rsyslog, Linux audit forwarding (`auditd`), and privileged session auditing (`rootsh`).

---

## 1. System-Wide Cryptographic Policy

### Standard Policy (`NOINSECURE`)
The baseline cryptographic policy across all enterprise hosts enforces modern encryption by disabling legacy algorithms:

```bash
cat << 'EOF' > /etc/crypto-policies/policies/modules/NOINSECURE.pmod
cipher@ssh = -*-CBC -CHACHA20*
hash = -SHA1
sign = -*-SHA1
sha1_in_certs = 0
etm@SSH = DISABLE_ETM
mac@ssh = -HMAC-SHA1
EOF

update-crypto-policies --set DEFAULT:NOINSECURE && update-crypto-policies --show
```

---

### Alternative / Sub-Module Policy (e.g., Jenkins / Specific Worker Nodes)

For nodes requiring explicit Terrapin mitigation modules or custom modular exclusions (such as build servers):

=== "Step 1: Create Module Rules"
    ```bash
    # Create NOSHA1 module
    cat << 'EOF' > /etc/crypto-policies/policies/modules/NOSHA1.pmod
    hash = -SHA1
    sign = -*-SHA1
    sha1_in_certs = 0
    EOF

    # If CBC.pmod exists, rename or create NOCBC module
    mv /etc/crypto-policies/policies/modules/CBC.pmod /etc/crypto-policies/policies/modules/NOCBC.pmod 2>/dev/null || true
    ```

=== "Step 2: Apply Combined Policy"
    ```bash
    update-crypto-policies --set DEFAULT:NOCBC:NOSHA1:TERRAPIN
    update-crypto-policies --show
    ```

=== "Step 3: Test HBAC SSH Access"
    ```bash
    ipa hbactest --host=<HOSTNAME> --user=<TEST_USER> --service=ssh
    ```

---

## 2. Centralized Rsyslog Forwarding

Ensure standard system logs forward critical events to central syslog (`syslog01-bd.therapbd.net`):

```bash
# In /etc/rsyslog.conf:
# Ensure local messages file is defined:
# *.info;mail.none;authpriv.none;cron.none;                    /var/log/messages

# Uncomment or append forwarder line to central log host:
# *.err;mail.crit;auth.notice                                 @syslog01-bd

# Restart rsyslog service
systemctl restart rsyslog.service
```

---

## 3. Linux Audit Daemon (`auditd`) Forwarding

Forward audit logs to `syslog01-bd`:

```bash
# Install audit syslog plugin
dnf install -y audispd-plugins

# Configure rsyslog audit rule
cat << 'EOF' >> /etc/rsyslog.d/audit.conf
## Audit log to syslog01-bd
local3.info                                             @syslog01-bd
local3.info                                             stop
EOF

# Backup and update syslog plugin configuration
cp /etc/audit/plugins.d/syslog.conf /etc/audit/plugins.d/syslog.conf.orig

cat << 'EOF' > /etc/audit/plugins.d/syslog.conf
active = yes
direction = out
path = /sbin/audisp-syslog
type = always
args = LOG_INFO LOG_LOCAL3
format = string
EOF

# Restart auditd and rsyslog
systemctl restart rsyslog
service auditd restart
systemctl enable auditd.service --now
```

---

## 4. Rootsh Privileged Session Configuration

Import required repository GPG keys and configure `rootsh`:

```bash
# Import EPEL GPG Key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8 2>/dev/null || \
rpm --import https://mirrors.kernel.org/fedora-epel/RPM-GPG-KEY-EPEL-8

# Import Vector GPG Key if present
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-vector 2>/dev/null || true
```

### Sudoers Configuration
In `/etc/sudoers`:
```text
User_Alias DEVELS= asif, tahseen, jahangir
```

---

## 5. Security Lockdown Before Handover

1. **Kernel SELinux State**:
   ```bash
   grubby --update-kernel ALL --remove-args selinux
   # Ensure SELinux is in enforcing mode and Firewalld is enabled
   ```

2. **Disable Remote Direct Root Login**:
   Ensure `/etc/ssh/sshd_config` has:
   ```text
   PermitRootLogin no
   ```
   Reload SSH:
   ```bash
   systemctl reload sshd
   ```

3. **Update Root Password Shadow**:
   Update the root entry in `/etc/shadow` with the standard corporate shadow hash provided by the team:
   ```text
   root:$6$XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0::0:99999:7:::
   ```
