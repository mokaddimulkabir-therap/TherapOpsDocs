# Old Host Decommissioning Runbook

When a host is being permanently decommissioned or re-provisioned from scratch, cleanly unregister it from central identity and management infrastructure.

---

## 1. Prepare for Kickstart Overwrite

If the existing host is being re-imaged via PXE:

1. **Set Root Password to Default**:
   Temporarily change the root password to the corporate default Kickstart password so automated processes can connect if needed.

2. **Enable Temporary Root Login**:
   In `/etc/ssh/sshd_config`:
   ```text
   PermitRootLogin yes
   ```
   Reload SSH:
   ```bash
   systemctl reload sshd
   ```

---

## 2. Unregister from FreeIPA / IDM

Cleanly unenroll the host and remove its Kerberos keytab, certificates, and DNS records:

```bash
# Force unenrollment from IDM realm
ipa-client-install --uninstall --force

# Stop SSSD and purge local credential cache
systemctl stop sssd
rm -rf /var/lib/sss/db/*
```

---

## 3. Storage & Network Cleanup

Before shutting down the old instance:

1. **Unmount Filesystems**:
   ```bash
   umount /d00 2>/dev/null || true
   umount /rman 2>/dev/null || true
   umount /dumps_new 2>/dev/null || true
   ```

2. **Logout from iSCSI Sessions**:
   ```bash
   iscsiadm -m node --logoutall=all
   ```

3. **Power Down**:
   Once all backups and unregistrations are confirmed:
   ```bash
   poweroff
   ```
