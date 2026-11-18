# Repositories & Kernel Management

Enterprise applications (specifically Oracle 19c Grid Infrastructure and ASM) require precise kernel versions and module support.

---

## 1. Configure UEK Repositories

Disable Unbreakable Enterprise Kernel Release 7 (UEKR7) if deploying systems that require UEKR6 or strict certified kernels:

```bash
# In /etc/yum.repos.d/uek-ol8.repo:
# Set enabled=0 under [ol8_UEKR7]
sed -i '/\[ol8_UEKR7\]/,/enable/ s/enabled=1/enabled=0/' /etc/yum.repos.d/uek-ol8.repo

# Refresh DNF repository cache
dnf clean all
dnf repolist
```

---

## 2. Install Required Kernel Version & Pin Default

If pinning to the standard certified UEKR6 release (`5.4.17-2136.336.5.1.el8uek`):

```bash
# Install target kernel
dnf install -y kernel-uek-5.4.17-2136.336.5.1.el8uek.x86_64

# List available kernels and identify index
grubby --info=ALL | grep -E "^kernel|^index"
```

*Example output:*
```text
index=0
kernel="/boot/vmlinuz-5.15.0-304.171.4.3.el8uek.x86_64"
index=1
kernel="/boot/vmlinuz-5.4.17-2136.336.5.1.el8uek.x86_64"
```

Set the target kernel index as default (e.g. index 1):
```bash
grubby --set-default-index=1
```

---

## 3. Apply Base System Updates & Modules

Enable required modules and install standard tools:

```bash
# IDM module enable
dnf module reset idm -y
dnf module enable idm:DL1 -y
dnf module install idm:DL1/client -y

# Install client packages
dnf install -y ipa-client

# General system update
dnf update -y
```

!!! tip "Reboot Required"
    Always reboot the server after updating the kernel and system packages:
    ```bash
    reboot
    ```
    After reboot, verify the running kernel:
    ```bash
    uname -r
    ```
