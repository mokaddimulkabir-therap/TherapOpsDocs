# App Server Network Configuration

Application servers typically operate on two distinct interfaces:
* **Primary / Public LAN**: Handles traffic, default gateway routing, and DNS.
* **Secondary / Internal LAN**: Handles internal RPC and service communications.

---

## 1. Interface Setup via `nmcli`

Run the following commands as `root` (replace `<IP>` and `<GATEWAY>` with values from the pre-provisioning backup):

### Interface 1 (e.g. `ens33` / Primary Management)
```bash
nmcli connection add type ethernet con-name ens33 ifname ens33 \
  ipv6.method ignore \
  ipv4.method manual \
  ipv4.never-default no \
  connection.autoconnect yes \
  ipv4.ignore-auto-dns yes \
  ipv4.addresses <APP_PUB_IP>/24 \
  ipv4.gateway <APP_PUB_GATEWAY> \
  ipv4.dns 192.168.51.54,192.168.52.54 \
  ipv4.dns-search therapbd.net \
  ipv4.dns-options "timeout:1 attempts:2"
```

### Interface 2 (e.g. `ens35` / Secondary Service)
```bash
nmcli connection add type ethernet con-name ens35 ifname ens35 \
  ipv6.method ignore \
  ipv4.method manual \
  ipv4.never-default yes \
  connection.autoconnect yes \
  ipv4.ignore-auto-dns yes \
  ipv4.addresses <APP_INT_IP>/24 \
  ipv4.gateway <APP_INT_GATEWAY>
```

---

## 2. Remove Temporary PXE Connection

Once production connections are verified active:

```bash
# List active connections
nmcli con show

# Delete the temporary PXE connection (e.g., ops48 / Wired connection 1)
nmcli connection delete ops48 2>/dev/null || true
nmcli connection delete "Wired connection 1" 2>/dev/null || true
```

---

## 3. Telemetry & Agent Installation

Install standard monitoring agents required on application servers:

```bash
# Vector log collector
dnf install -y vector

# Datadog monitoring agent
dnf install -y datadog-agent-7.58.0-1.x86_64
```
