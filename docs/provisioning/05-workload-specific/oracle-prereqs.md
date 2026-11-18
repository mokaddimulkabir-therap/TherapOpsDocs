# Oracle Database & RAC Prerequisites

Before installing Oracle 19c Grid Infrastructure or Database software, configure the OS accounts, system limits, and required Oracle RPM packages.

---

## 1. User & Group Hygiene

Ensure the `oracle` user and DBA groups adhere to the corporate UID/GID structure.

### Step 1: Clean Up Duplicate Groups
In `/etc/group`, remove the default/stale `oinstall` and `dba` entries, and remove the `oracle` user from secondary groups:

*Before:*
```text
oper:x:54323:oracle
backupdba:x:54324:oracle
dgdba:x:54325:oracle
kmdba:x:54326:oracle
racdba:x:54330:oracle
```

*After:*
```text
oper:x:54323:
backupdba:x:54324:
dgdba:x:54325:
kmdba:x:54326:
racdba:x:54330:
```

### Step 2: Configure `oracle` User UID/GID
Ensure `/etc/passwd` and `/etc/shadow` contain the standard system entry:

```bash
# Verify or update /etc/passwd:
# oracle:x:110:101::/home/oracle:/bin/bash

# Ensure proper home ownership
chown -R oracle:oinstall /home/oracle/
chmod 700 /home/oracle
```

---

## 2. Resource Limits & Memlock Configuration

Oracle Grid Infrastructure requires `memlock` configured to approximately 80% of total physical RAM for hugepages support.

Edit `/etc/security/limits.conf`:

```text
# Memlock limit for grid and oracle users (~80% of RAM)
grid    soft    memlock         21390950
grid    hard    memlock         21390950
oracle  soft    memlock         21390950
oracle  hard    memlock         21390950
```

---

## 3. Install Oracle Preinstall & ASMLib Packages

```bash
# Install Oracle preinstall RPM
dnf install -y oracle-database-preinstall-19c

# Install Oracle ASMLib and Support tools
dnf install -y oracleasm-support oracleasmlib

# Verify all required Oracle packages are present
rpm -qa | grep -E 'policycoreutils-python|asm|19c'
```

*Expected packages:*
* `oracle-database-preinstall-19c`
* `oracleasm-support`
* `oracleasmlib`
* `kmod-redhat-oracleasm`
* `policycoreutils-python-utils`

### Initialize and Enable ASMLib
```bash
systemctl enable oracleasm.service --now
oracleasm status
```
