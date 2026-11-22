#!/usr/bin/env bash
# ============================================================================
# OCI Post-Installation Verification & Audit Script
# Enterprise Standard Operating Procedure
# Run as root on newly provisioned OCI Linux instances.
# All checks are read-only — no system files are modified.
#
# Usage:
#   ./oci_checker.sh [ROLE] [OPTIONS]
#
# Arguments:
#   ROLE:
#     app      - Application servers (/logs, /usr/local/Oracle, /apps)
#     db       - Database instances (/logs, /usr/local/Oracle)
#     ops      - Operations / Jump / Bastion hosts
#     nms      - Network monitoring systems (/cacti)
#     syslog   - Central syslog-ng aggregators (/syslogng)
#     nessus   - Security scanners (/opt/nessus)
#     jenkins  - CI/CD workers (/usr/local/jenkins)
#     (Default: app)
#
# Options:
#   --json              Emit summary report in JSON format
#   --log <FILE>        Save complete execution output to specified file
#   --admin-user <USER> Specify primary admin user for sudo check (default: opsuser)
#   --help, -h          Display this help text
# ============================================================================

set -o pipefail
set +e

# --- Default Variables ---
ROLE="app"
OUTPUT_JSON=false
LOG_FILE=""
ADMIN_USER="opsuser"
TARGET_SYSLOG_COLLECTOR="syslog01-oap"

# Parse Command-Line Arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    app|db|ops|nms|syslog|nessus|jenkins)
      ROLE="$1"
      shift
      ;;
    --json)
      OUTPUT_JSON=true
      shift
      ;;
    --log)
      LOG_FILE="$2"
      shift 2
      ;;
    --admin-user)
      ADMIN_USER="$2"
      shift 2
      ;;
    --syslog-host)
      TARGET_SYSLOG_COLLECTOR="$2"
      shift 2
      ;;
    -h|--help)
      grep '^# ' "$0" | cut -c 3-
      exit 0
      ;;
    *)
      echo "Unknown option or role: $1" >&2
      echo "Run with --help for usage information." >&2
      exit 2
      ;;
  esac
done

# If log file is requested, tee output
if [[ -n "$LOG_FILE" ]]; then
  exec > >(tee -a "$LOG_FILE") 2>&1
fi

# --- Terminal Styling ---
if [[ -t 1 && "$OUTPUT_JSON" == false ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN='' RED='' YELLOW='' CYAN='' BOLD='' RESET=''
fi

PASS="${GREEN}[PASS]${RESET}"
FAIL="${RED}[FAIL]${RESET}"
WARN="${YELLOW}[WARN]${RESET}"
INFO="${CYAN}[INFO]${RESET}"

DIVIDER="$(printf '=%.0s' {1..74})"
TASK=0
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# --- Helper Functions ---
header() {
  TASK=$((TASK + 1))
  printf "\n${BOLD}Task %02d | %s${RESET}\n" "$TASK" "$1"
  printf '%s\n' "$DIVIDER"
}

result_pass() { printf "  %b %s\n" "$PASS" "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
result_fail() { printf "  %b %s\n" "$FAIL" "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
result_warn() { printf "  %b %s\n" "$WARN" "$1"; WARN_COUNT=$((WARN_COUNT + 1)); }
result_info() { printf "  %b %s\n" "$INFO" "$1"; }

check_file_exists() {
  if [[ -f "$1" ]]; then
    return 0
  else
    result_fail "File $1 does not exist"
    return 1
  fi
}

# ============================================================================
#  BANNER & ENVIRONMENT
# ============================================================================
printf "\n${BOLD}OCI Post-Installation Verification Report${RESET}\n"
printf "Host: %s | Role: %s | Timestamp: %s\n" "$(hostname -f 2>/dev/null || hostname)" "$ROLE" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
printf '%s\n' "$DIVIDER"

# ============================================================================
#  1. STORAGE & MOUNTPOINT VERIFICATION
# ============================================================================
header "Data volume mounts and fstab UUID mapping (Role: $ROLE)"

MOUNT_POINTS=()
case "$ROLE" in
  app)     MOUNT_POINTS=(/logs /usr/local/Oracle) ;;
  db)      MOUNT_POINTS=(/logs /usr/local/Oracle) ;;
  ops)     MOUNT_POINTS=() ;;
  nms)     MOUNT_POINTS=(/cacti) ;;
  syslog)  MOUNT_POINTS=(/syslogng) ;;
  nessus)  MOUNT_POINTS=(/opt/nessus) ;;
  jenkins) MOUNT_POINTS=(/usr/local/jenkins) ;;
esac

# Auto-detect optional workload mounts
for opt_mp in /apps /usr/local/tac /usr/local/html2pdf /usr/local/jenkins /sftp; do
  if mountpoint -q "$opt_mp" 2>/dev/null; then
    # Add if not already present
    if [[ ! " ${MOUNT_POINTS[*]} " =~ " ${opt_mp} " ]]; then
      MOUNT_POINTS+=("$opt_mp")
    fi
  fi
done

if [[ ${#MOUNT_POINTS[@]} -eq 0 ]]; then
  result_info "No role-specific data mounts configured for role: $ROLE"
fi

for mp in "${MOUNT_POINTS[@]}"; do
  if mountpoint -q "$mp" 2>/dev/null; then
    result_pass "$mp is mounted"
    df -hT "$mp" | tail -1 | awk '{printf "         Filesystem: %-25s Type: %-5s Size: %-5s Used: %-5s Avail: %-5s (%s)\n", $1,$2,$3,$4,$5,$6}'
  else
    result_fail "$mp is NOT mounted"
  fi

  # Check fstab UUID adherence
  fstab_line=$(grep -E "[[:space:]]${mp}[[:space:]]" /etc/fstab 2>/dev/null || true)
  if [[ -z "$fstab_line" ]]; then
    result_fail "No /etc/fstab entry found for mountpoint $mp"
  elif echo "$fstab_line" | grep -qi 'UUID='; then
    result_pass "/etc/fstab uses UUID for $mp"
    result_info "  $fstab_line"
  else
    result_fail "/etc/fstab does NOT use UUID for $mp (uses raw device path)"
    result_info "  $fstab_line"
  fi
done

header "Root Logical Volume Capacity"
df -hT / | tail -1 | awk '{printf "  Root LV: %-25s Type: %-5s Size: %-5s Used: %-5s Avail: %-5s (%s)\n", $1,$2,$3,$4,$5,$6}'

# ============================================================================
#  2. SECURITY, HARDENING & POLICY VALIDATION
# ============================================================================
header "Crypto Policy Configuration"
policy=$(update-crypto-policies --show 2>/dev/null || echo "UNKNOWN")
result_info "Active crypto policy: $policy"
if [[ "$policy" == *"DEFAULT:NOCBC:NOSHA1:TERRAPIN"* || "$policy" == *"DEFAULT:NOINSECURE"* ]]; then
  result_pass "Cryptographic policy complies with enterprise baseline ($policy)"
elif [[ "$policy" == "DEFAULT" || "$policy" == "DEFAULT:SHA1" ]]; then
  result_warn "Crypto policy is $policy — consider applying DEFAULT:NOCBC:NOSHA1:TERRAPIN"
else
  result_warn "Non-standard crypto policy detected: $policy"
fi

header "umask Security Setting"
current_umask=$(umask)
result_info "Active session umask: $current_umask"
if [[ "$current_umask" == "0027" || "$current_umask" == "027" ]]; then
  result_pass "Strict CIS umask verified ($current_umask)"
elif [[ "$current_umask" == "0022" || "$current_umask" == "022" ]]; then
  result_warn "Standard umask detected ($current_umask) — corporate CIS recommendation is 0027"
else
  result_warn "Unexpected umask: $current_umask"
fi

header "SSH Daemon Configuration"
if check_file_exists /etc/ssh/sshd_config; then
  prl=$(grep -iE "^[#[:space:]]*PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null | tail -1 || true)
  if echo "$prl" | grep -qiE '^[[:space:]]*PermitRootLogin[[:space:]]+no'; then
    result_pass "PermitRootLogin is explicitly set to 'no'"
  else
    result_fail "PermitRootLogin is NOT set to 'no' (Current: ${prl:-Unset})"
  fi

  pass_auth=$(grep -iE "^[#[:space:]]*PasswordAuthentication" /etc/ssh/sshd_config 2>/dev/null | tail -1 || true)
  result_info "PasswordAuthentication: ${pass_auth:-Defaults to yes}"
fi

header "Root Account Shadow Security"
if grep -qE '^root:\$[0-9a-zA-Z]+\$' /etc/shadow 2>/dev/null; then
  result_pass "Root account has a valid encrypted password hash in /etc/shadow"
else
  result_fail "Root shadow entry is empty, locked without hash, or malformed"
fi

header "Default Cloud User (opc) Lockdown"
if [[ -f /home/opc/.ssh/authorized_keys ]]; then
  key_count=$(grep -v '^[[:space:]]*#' /home/opc/.ssh/authorized_keys 2>/dev/null | grep -c '[^[:space:]]' || echo 0)
  if [[ "$key_count" -gt 0 ]]; then
    result_fail "User 'opc' still has $key_count active SSH key(s) in authorized_keys"
  else
    result_pass "User 'opc' authorized_keys is empty"
  fi
elif [[ -f /home/opc/.ssh/authorized_keys.bak ]]; then
  result_pass "User 'opc' authorized_keys is securely disabled (.bak)"
else
  result_pass "User 'opc' has no active authorized_keys"
fi

if [[ -f /etc/sudoers.d/90-cloud-init-users ]]; then
  if grep -qE '^[[:space:]]*opc[[:space:]]+ALL' /etc/sudoers.d/90-cloud-init-users 2>/dev/null; then
    result_fail "User 'opc' still has active passwordless sudo in 90-cloud-init-users"
  else
    result_pass "User 'opc' sudo rule in 90-cloud-init-users is disabled/commented out"
  fi
else
  result_pass "90-cloud-init-users sudo rule not present"
fi

header "AIDE (Advanced Intrusion Detection Environment)"
if [[ -f /etc/aide.conf ]]; then
  result_pass "/etc/aide.conf exists"
else
  result_fail "/etc/aide.conf is missing"
fi

if [[ -f /var/lib/aide/aide.db.gz ]]; then
  result_pass "AIDE baseline database exists (/var/lib/aide/aide.db.gz)"
else
  result_fail "AIDE database missing — initialize via: aide --init && mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz"
fi

if [[ -x /root/aide/aide_check.sh ]]; then
  result_pass "AIDE alert script is executable at /root/aide/aide_check.sh"
else
  result_fail "/root/aide/aide_check.sh is missing or not executable"
fi

cron_out=$(crontab -l -u root 2>/dev/null || true)
if echo "$cron_out" | grep -qi 'aide'; then
  result_pass "AIDE recurring check scheduled in root crontab"
else
  result_warn "AIDE check script is not found in root crontab"
fi

# ============================================================================
#  3. SYSTEM INTEGRITY, AUDIT & LOGGING
# ============================================================================
header "Linux Audit Daemon (auditd) & Forwarding"
if systemctl is-active auditd &>/dev/null; then
  result_pass "auditd service is active"
else
  result_fail "auditd service is NOT running"
fi

if check_file_exists /etc/audit/plugins.d/syslog.conf; then
  if grep -qE '^[[:space:]]*active[[:space:]]*=[[:space:]]*yes' /etc/audit/plugins.d/syslog.conf 2>/dev/null; then
    result_pass "Audit syslog plugin (audisp-syslog) is active"
  else
    result_fail "Audit syslog plugin is inactive (requires active = yes)"
  fi
fi

if check_file_exists /etc/rsyslog.d/audit.conf; then
  result_pass "/etc/rsyslog.d/audit.conf exists"
  grep -v '^[[:space:]]*#' /etc/rsyslog.d/audit.conf | grep '[^[:space:]]' | while IFS= read -r line; do
    result_info "  $line"
  done
else
  result_fail "/etc/rsyslog.d/audit.conf is missing"
fi

header "Central Rsyslog Forwarding"
if check_file_exists /etc/rsyslog.conf; then
  if grep -qE "@${TARGET_SYSLOG_COLLECTOR}" /etc/rsyslog.conf 2>/dev/null || grep -qE "@${TARGET_SYSLOG_COLLECTOR}" /etc/rsyslog.d/*.conf 2>/dev/null; then
    result_pass "Forwarding to @${TARGET_SYSLOG_COLLECTOR} configured"
  else
    result_warn "Remote syslog forwarding rule for @${TARGET_SYSLOG_COLLECTOR} not detected"
  fi
fi

header "Logrotate Configuration"
if check_file_exists /etc/logrotate.conf; then
  if grep -A 5 -E '/var/log/(wtmp|btmp)' /etc/logrotate.conf 2>/dev/null | grep -q 'rotate'; then
    result_pass "/etc/logrotate.conf contains wtmp/btmp rotation"
  else
    result_warn "wtmp/btmp rotation rules not found in /etc/logrotate.conf"
  fi
fi

if check_file_exists /etc/logrotate.d/syslog; then
  result_pass "/etc/logrotate.d/syslog exists"
else
  result_warn "/etc/logrotate.d/syslog does not exist"
fi

# ============================================================================
#  4. SYSTEM SANITIZATION & RESOURCE LIMITS
# ============================================================================
header "Swap Status (Must be completely disabled)"
swap_total=$(free -m | awk '/^Swap:/{print $2}')
if [[ "$swap_total" -eq 0 ]]; then
  result_pass "Swap space is deactivated (0 MB)"
else
  result_fail "Swap is still ACTIVE: ${swap_total} MB (Must be swapoff -a)"
fi

if grep -qE '^[^#].*\sswap\s' /etc/fstab 2>/dev/null; then
  result_fail "Active swap mount entry exists in /etc/fstab"
else
  result_pass "No active swap entries in /etc/fstab"
fi

header "Cockpit Web Console Removal"
if rpm -q cockpit &>/dev/null; then
  result_fail "Cockpit package is INSTALLED (Run: dnf remove -y cockpit)"
else
  result_pass "Cockpit package is not installed"
fi

if [[ -f /etc/motd.d/cockpit ]]; then
  result_warn "Cockpit MOTD file /etc/motd.d/cockpit exists (Remove file)"
else
  result_pass "Cockpit MOTD is clean"
fi

header "Security Limits & File Descriptors"
if check_file_exists /etc/security/limits.conf; then
  limits_found=$(grep -v '^[[:space:]]*#' /etc/security/limits.conf 2>/dev/null | grep -ciE 'nofile|nproc|memlock' || echo 0)
  if [[ "$limits_found" -gt 0 ]]; then
    result_pass "$limits_found explicit limit definition(s) found in /etc/security/limits.conf"
    grep -v '^[[:space:]]*#' /etc/security/limits.conf | grep -iE 'nofile|nproc|memlock' | head -10 | while IFS= read -r line; do
      result_info "  $line"
    done
  else
    result_warn "No explicit nofile/nproc limits found in /etc/security/limits.conf"
  fi
fi

header "OCI Hostname Preservation"
if check_file_exists /etc/oci-hostname.conf; then
  if grep -qE '^[[:space:]]*PRESERVE_HOSTINFO' /etc/oci-hostname.conf 2>/dev/null; then
    result_pass "PRESERVE_HOSTINFO is enabled in /etc/oci-hostname.conf"
  else
    result_warn "PRESERVE_HOSTINFO is not set in /etc/oci-hostname.conf"
  fi
else
  result_warn "/etc/oci-hostname.conf not present"
fi

# ============================================================================
#  5. NETWORKING, TIME & SERVICES
# ============================================================================
header "Chrony Time Synchronization"
if systemctl is-active chronyd &>/dev/null; then
  result_pass "chronyd daemon is active"
else
  result_fail "chronyd daemon is NOT active"
fi

sync_status=$(chronyc tracking 2>/dev/null || true)
if echo "$sync_status" | grep -qi 'Leap status.*Normal'; then
  result_pass "Clock is synchronized with upstream source (Leap status: Normal)"
else
  result_warn "Chrony clock synchronization in progress or unsynchronized"
fi

header "DNS Resolver Configuration (/etc/resolv.conf)"
if check_file_exists /etc/resolv.conf; then
  ns_count=$(grep -c '^[[:space:]]*nameserver' /etc/resolv.conf 2>/dev/null || echo 0)
  if [[ "$ns_count" -ge 1 ]]; then
    result_pass "$ns_count nameserver(s) configured"
    grep -E '^(nameserver|search|domain)' /etc/resolv.conf | while IFS= read -r line; do
      result_info "  $line"
    done
  else
    result_fail "No nameservers found in /etc/resolv.conf"
  fi
fi

header "Kernel & Operating System"
kernel_ver=$(uname -r)
result_info "Running Kernel: $kernel_ver"
if echo "$kernel_ver" | grep -q 'uek'; then
  result_pass "Unbreakable Enterprise Kernel (UEK) is running"
else
  result_info "Standard RHCK / non-UEK kernel is active"
fi

header "Key System Daemons Health"
CORE_SERVICES=(sshd rsyslog crond postfix snmpd auditd chronyd)
for svc in "${CORE_SERVICES[@]}"; do
  if systemctl is-active "$svc" &>/dev/null; then
    result_pass "Service '$svc' is active"
  elif systemctl is-enabled "$svc" &>/dev/null; then
    result_warn "Service '$svc' is enabled but inactive"
  else
    result_info "Service '$svc' is inactive/not enabled"
  fi
done

header "Administrator Sudo Access ($ADMIN_USER)"
if id "$ADMIN_USER" &>/dev/null; then
  result_pass "Admin user '$ADMIN_USER' exists"
  sudo_test=$(sudo -l -U "$ADMIN_USER" 2>/dev/null || true)
  if echo "$sudo_test" | grep -qiE 'not allowed|unknown|sorry'; then
    result_fail "User '$ADMIN_USER' does NOT have sudo privileges"
  elif [[ -n "$sudo_test" ]]; then
    result_pass "User '$ADMIN_USER' has verified sudo privilege"
  fi
else
  result_info "Admin user '$ADMIN_USER' not present on this host (set via --admin-user)"
fi

# ============================================================================
#  SUMMARY REPORT
# ============================================================================
printf "\n%s\n" "$DIVIDER"
printf "${BOLD}POST-INSTALLATION AUDIT SUMMARY${RESET}\n"
printf "%s\n" "$DIVIDER"
printf "  Total Tasks Executed : %d\n" "$TASK"
printf "  %b Checks Passed     : %d\n" "$PASS" "$PASS_COUNT"
printf "  %b Checks Failed     : %d\n" "$FAIL" "$FAIL_COUNT"
printf "  %b Warnings          : %d\n" "$WARN" "$WARN_COUNT"
printf "%s\n" "$DIVIDER"

if [[ "$OUTPUT_JSON" == true ]]; then
  printf '{"host":"%s","role":"%s","timestamp":"%s","tasks":%d,"passed":%d,"failed":%d,"warnings":%d}\n' \
    "$(hostname -f 2>/dev/null || hostname)" "$ROLE" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    "$TASK" "$PASS_COUNT" "$FAIL_COUNT" "$WARN_COUNT"
fi

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  printf "\n${RED}*** AUDIT RESULT: FAILED (%d issue(s) require remediation) ***${RESET}\n\n" "$FAIL_COUNT"
  exit 1
else
  printf "\n${GREEN}*** AUDIT RESULT: PASSED (Host is compliant and verified) ***${RESET}\n\n"
  exit 0
fi
