# System Sanitization & Access Control

Before handing over an OCI compute node, default cloud access vectors and unnecessary services must be locked down.

---

## 1. Remove Swap & Cockpit Web Console

OCI images often bundle Cockpit and swap configs that conflict with production database and container guidelines.

### Swap Deactivation
```bash
# Check current swap
free -h

# Deactivate swap and remove entries from /etc/fstab
swapoff -a
sed -i '/swap/d' /etc/fstab
systemctl daemon-reload
```

### Cockpit Removal
```bash
dnf remove -y cockpit
rm -f /run/cockpit/motd
rm -f /etc/motd.d/cockpit
```

### Disable Ksplice Cron (if required)
```bash
if [ -f /etc/cron.d/ksplice.rpmsave ]; then
    sed -i 's/^/#/' /etc/cron.d/ksplice.rpmsave
fi
```

---

## 2. Lock Down Default `opc` User

The default cloud-provisioned `opc` user must be disabled from SSH access and passwordless sudo:

### Step 1: Backup & Invalidate SSH Authorized Keys
```bash
if [ -f /home/opc/.ssh/authorized_keys ]; then
    mv /home/opc/.ssh/authorized_keys /home/opc/.ssh/authorized_keys.bak
    chmod 600 /home/opc/.ssh/authorized_keys.bak
fi
```

### Step 2: Disable Cloud-Init Sudo Rule
Edit `/etc/sudoers.d/90-cloud-init-users`:
```text
# User rules for opc
# opc ALL=(ALL) NOPASSWD:ALL
```

---

## 3. SSH Configuration & Root Access

1. **Disable Remote Root Login**:
   In `/etc/ssh/sshd_config`:
   ```text
   PermitRootLogin no
   ```

2. **Password Authentication Policy**:
   * **Standard Nodes**: `PasswordAuthentication no`
   * **Hopping / Bastion Nodes**: `PasswordAuthentication yes` (only if designated as corporate jump host).

Apply changes:
```bash
systemctl restart sshd
```

---

## 4. Operational Users & Key Distribution

When onboarding authorized engineers:

```bash
# Transfer post-installation task tools from ops staging server:
# rsync -avz -e "ssh -i opc_key" post-installation-task-oap root@<HOST_IP>:/root/

cd /root/post-installation-task-oap/shadow
./shadow.sh shadow user_list

cd ../key-update-dir
./key-update.sh <USER_1> <USER_2> <USER_3>
```
