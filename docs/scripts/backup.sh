#!/usr/bin/env bash
# ============================================================================
# Host Configuration Backup Script
# Preserves critical system identity, networking, filesystems, and configs.
# Output: /tmp/backup_$(hostname -f).tar
# ============================================================================

set -o pipefail
set +e

HOSTNAME_FQDN=$(hostname -f 2>/dev/null || hostname)
BACKUP_DIR="/tmp/host_backup_${HOSTNAME_FQDN}"
ARCHIVE_FILE="/tmp/backup_${HOSTNAME_FQDN}.tar"

echo "=== Starting Host Backup for ${HOSTNAME_FQDN} ==="
rm -rf "${BACKUP_DIR}" "${ARCHIVE_FILE}"
mkdir -p "${BACKUP_DIR}"

# 1. Capture Command State
ip a > "${BACKUP_DIR}/ip_addr.txt" 2>&1
ip route > "${BACKUP_DIR}/ip_route.txt" 2>&1
lsblk > "${BACKUP_DIR}/lsblk.txt" 2>&1
df -hT > "${BACKUP_DIR}/df_hT.txt" 2>&1
lscpu > "${BACKUP_DIR}/lscpu.txt" 2>&1
free -h > "${BACKUP_DIR}/free_h.txt" 2>&1
rpm -qa > "${BACKUP_DIR}/installed_rpms.txt" 2>&1
uname -a > "${BACKUP_DIR}/uname.txt" 2>&1

# 2. Capture Key System Configurations
mkdir -p "${BACKUP_DIR}/etc"
cp -a /etc/hosts /etc/resolv.conf /etc/fstab /etc/sysctl.conf "${BACKUP_DIR}/etc/" 2>/dev/null || true
cp -a /etc/security/limits.conf /etc/ssh/sshd_config "${BACKUP_DIR}/etc/" 2>/dev/null || true
cp -a /etc/rsyslog.conf /etc/rsyslog.d "${BACKUP_DIR}/etc/" 2>/dev/null || true

# 3. Capture Network Configurations
if [[ -d /etc/sysconfig/network-scripts ]]; then
  mkdir -p "${BACKUP_DIR}/etc/sysconfig"
  cp -a /etc/sysconfig/network-scripts "${BACKUP_DIR}/etc/sysconfig/" 2>/dev/null || true
fi
if [[ -d /etc/NetworkManager/system-connections ]]; then
  mkdir -p "${BACKUP_DIR}/etc/NetworkManager"
  cp -a /etc/NetworkManager/system-connections "${BACKUP_DIR}/etc/NetworkManager/" 2>/dev/null || true
fi

# 4. Storage & Oracle Configurations (if present)
if [[ -d /etc/iscsi ]]; then
  cp -a /etc/iscsi "${BACKUP_DIR}/etc/" 2>/dev/null || true
fi
if [[ -f /etc/multipath.conf ]]; then
  cp -a /etc/multipath.conf "${BACKUP_DIR}/etc/" 2>/dev/null || true
fi
if [[ -d /etc/oracle ]]; then
  cp -a /etc/oracle "${BACKUP_DIR}/etc/" 2>/dev/null || true
fi

# 5. Compress Archive
tar -cf "${ARCHIVE_FILE}" -C "/tmp" "host_backup_${HOSTNAME_FQDN}"
rm -rf "${BACKUP_DIR}"

echo "=== Backup Complete ==="
echo "Archive File: ${ARCHIVE_FILE} ($(du -h "${ARCHIVE_FILE}" | cut -f1))"
