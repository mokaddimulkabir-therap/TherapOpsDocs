# Kickstart Execution & Log Validation

Once the server boots from the network into the Kickstart installer, monitor the installation and validate logs upon completion.

---

## 1. Network Boot Initiation

1. Power on or reboot the host machine (via iLO, iDRAC, IPMI, or vCenter console).
2. Choose **Network Boot / PXE** (F12 or boot menu selector).
3. Confirm the machine acquires a dynamic IP within the `192.168.48.241` – `192.168.48.250` range.
4. Let the automated installation run to completion until the system prompts for the first reboot or reboots automatically.

---

## 2. Post-Boot Kickstart Log Verification

Immediately after the first login (SSH to the temporary DHCP IP, e.g. `192.168.48.243`):

### Inspect Errors & Warnings in Kickstart Logs
```bash
grep -E 'err|warn|fail' /root/kickstart.log
```

!!! note "Expected Non-Fatal Warnings"
    You may observe syntax warnings related to comment forwarding or rsyslog formatting in `kickstart.log` such as:
    ```text
    + perl -i -pe 's/^(mail\.\* ...
    ol8-cis-hardening.sh: line 1: syntax error near unexpected token `newline'
    ```
    These are addressed during the explicit post-installation CIS run in Stage 3.

---

## 3. Baseline Verification Commands

Confirm disk partitioning, memory, and OS release before applying configuration:

```bash
cat /etc/oracle-release
lsblk
grep 'MemTotal' /proc/meminfo
nproc
ip -f inet addr show | grep -Po 'inet \K[\d.]+' | grep -v 127
```
