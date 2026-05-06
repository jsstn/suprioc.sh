#!/bin/bash

# --- Setup & Variables ---
HOSTNAME=$(hostname)
IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')
[ -z "$IP" ] && IP=$(hostname -I 2>/dev/null | awk '{print $1}')
CVE="CVE-2026-41940"
STATUS="CLEAN"
LOG_PREFIX="$HOSTNAME $IP $CVE"

echo "--- Starting Enhanced Audit for $HOSTNAME ($IP) ---"

# 1. Immutability Check (System Lock-down)
IFILE=$(lsattr /etc/passwd /etc/shadow /etc/group /etc/gshadow /etc/sudoers 2>/dev/null | grep -E '\-i\-')
if [ ! -z "$IFILE" ]; then
    echo "$LOG_PREFIX [COMPROMISED] IMMUTABILITY_ALERT: Critical files locked! $IFILE"
    STATUS="COMPROMISED"
fi

# 2. Ransomware Files (.sorry)
RANSOM=$(find /etc /root /usr/local/cpanel /home -maxdepth 1 -name '*.sorry' 2>/dev/null)
if [ ! -z "$RANSOM" ]; then
    echo "$LOG_PREFIX [INFECTED] RANSOMWARE: Found .sorry files in system/home paths"
    STATUS="INFECTED"
fi

# 3. Malicious Running Processes (SHA1 Signature)
if sha1sum /proc/*/exe 2>/dev/null | grep -Eq '731572b5fe2a7ac6905527a237af4f59de8f7253'; then
    echo "$LOG_PREFIX [INFECTED] MALICIOUS_PROCESS: Active malware hash detected in memory!"
    STATUS="INFECTED"
fi

# 4. Persistence (Bashrc Injection)
if grep -Eq '[0]xa59ac734' /root/.bashrc 2>/dev/null; then
    echo "$LOG_PREFIX [COMPROMISED] BASHRC_INJECTION: Malware trigger found in root .bashrc"
    STATUS="COMPROMISED"
fi

# 5. Credential Stealers (cPanel Templates)
if grep -q XMLHttpRequest /usr/local/cpanel/base/unprotected/cpanel/*.tmpl 2>/dev/null; then
    echo "$LOG_PREFIX [INFECTED] CREDENTIAL_STEALER: Injected JS found in cPanel templates"
    STATUS="INFECTED"
fi

# 6. Unauthorized SSH Access (Modified in last 7 days)
SSH_MOD=$(find /root/.ssh/authorized_keys -mtime -7 2>/dev/null)
if [ ! -z "$SSH_MOD" ]; then
    echo "$LOG_PREFIX [WARNING/COMPROMISED] SSH_KEYS: Authorized_keys modified recently!"
    # We don't force STATUS="COMPROMISED" here in case you edited it yourself, 
    # but it flags it for your manual review.
fi

# 7. Qtox Check
if grep -iq qtox /root/README.md /var/cpanel/ssl/dovecot/README.md 2>/dev/null; then
    echo "$LOG_PREFIX [COMPROMISED] QTOX: Communication traces found"
    STATUS="COMPROMISED"
fi

# --- Forensic Data Dumps ---
echo "--- BEGIN FORENSIC DUMP ---"
grep . /etc/shadow 2>/dev/null | perl -pe "s/^/$LOG_PREFIX SHADOW: /"
grep . /root/.ssh/authorized_keys 2>/dev/null | perl -pe "s/^/$LOG_PREFIX SSH_KEY: /"
grep . /root/.bash_history 2>/dev/null | tail -2000 | perl -pe "s/^/$LOG_PREFIX HISTORY: /"
grep . /usr/local/cpanel/version 2>/dev/null | perl -pe "s/^/$LOG_PREFIX CP_VERSION: /"
ls -lrtca /root | tail -100 | perl -pe "s/^/$LOG_PREFIX RECENT_FILES: /"

echo "--- Audit Complete ---"
echo "FINAL_VERDICT: $HOSTNAME is $STATUS"
