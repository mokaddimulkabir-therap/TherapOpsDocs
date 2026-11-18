# Persistent NIC Naming Rules

When migrating virtual machines or deploying new hardware, Linux predictable network interface naming may assign new device names (e.g. `ens33` instead of expected `ens192`). 

This guide details how to lock interface names persistently using systemd `.link` files.

---

## 1. Identify MAC Addresses

Match the physical/virtual MAC address to the desired target name:

```bash
# View existing device names and HWADDR (MAC)
nmcli device show | grep -E 'GENERAL.DEVICE|GENERAL.HWADDR'
```

*Example output:*
```text
GENERAL.DEVICE:  ens33
GENERAL.HWADDR:  00:50:56:AB:16:DC
```

---

## 2. Create Systemd Link Configuration

Create a dedicated `.link` rule in `/etc/systemd/network/` for each interface to be renamed:

### Example: Pin MAC `00:50:56:AB:16:DC` to `ens192`
```bash
mkdir -p /etc/systemd/network

cat << 'EOF' > /etc/systemd/network/70-ens192.link
[Match]
MACAddress=00:50:56:ab:16:dc

[Link]
Name=ens192
EOF
```

### Example: Pin MAC `00:50:56:AB:F5:C6` to `ens161`
```bash
cat << 'EOF' > /etc/systemd/network/70-ens161.link
[Match]
MACAddress=00:50:56:ab:f5:c6

[Link]
Name=ens161
EOF
```

---

## 3. Regenerate Initramfs & Apply

Rebuild the initramfs using `dracut` so the kernel applies link names during early boot:

```bash
# Rebuild initramfs
dracut -f

# Reboot to apply naming changes
reboot
```

After reboot, verify with:
```bash
ip link show
nmcli device status
```
