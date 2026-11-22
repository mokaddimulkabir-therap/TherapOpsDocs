# OCI Workloads & Services

Standard procedures for Docker CE, Mail/Postfix relay configuration, and Syslog-NG daemon services on OCI hosts.

---

## 1. Docker CE Installation with Version Locking

To prevent unexpected container runtime upgrades across Jenkins workers or app nodes:

### Step 1: Add Docker CE Repo & GPG Key
```bash
cat << 'EOF' > /etc/yum.repos.d/docker-ce.repo
[ol8_oracle_docker_ce]
name=Oracle Linux 8 Docker (x86_64)
baseurl=https://download.docker.com/linux/rhel/8/x86_64/stable/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-DOCKER
proxy=http://proxy.internal.example.com:3128
EOF

# Import Docker Release GPG key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-DOCKER 2>/dev/null || true
```

### Step 2: Lock Package Versions
Lock tested versions using `dnf-plugins-core` / `versionlock`:

```bash
dnf versionlock add \
  'docker-buildx-plugin-0:0.36.1-1.el8' \
  'docker-ce-cli-1:29.7.2-1.el8' \
  'docker-ce-3:29.7.2-1.el8' \
  'docker-compose-plugin-0:5.4.0-1.el8' \
  'docker-ce-rootless-extras-0:29.7.2-1.el8'

# Verify locked list
dnf versionlock list
```

### Step 3: Install Docker Components
```bash
dnf install -y docker-ce docker-ce-cli docker-ce-rootless-extras \
               docker-buildx-plugin docker-compose-plugin libcgroup

systemctl enable docker --now
```

---

## 2. Mailserver / Postfix Configuration

For instances configured as mail relays or local notification senders:

```bash
# Validate configuration
postfix check

# Configure compatibility level
postconf compatibility_level=2

# Check main.cf settings
grep -E '^(myhostname|mydomain|relayhost)\s*=' /etc/postfix/main.cf
systemctl reload postfix.service
```

### Test Email Dispatch
```bash
echo "HOSTNAME: $(hostname), test mail for postfix configuration. ignore" | \
  mail -s "Test Email from $(hostname)" sysops@example.com
```

### Nagios Mail Queue Plugin
Install `mailqstats.sh` under `/usr/local/nagios/plugins/` with permissions `750` and reload SNMP if monitored.

---

## 3. Syslog-NG Service Management

For central logging aggregator nodes using Syslog-NG:

```bash
# Verify syntax
syslog-ng --syntax-only

# Manage service alias via systemd socket
ls -l /etc/systemd/system/syslog.service
systemctl daemon-reload
systemctl restart syslog.socket
systemctl restart syslog-ng.service
```
