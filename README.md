# suprioc.sh
The Forensic Super Script (V3 - Labeled Edition)

The script includes the logic for the specific signatures

**CVE-2026-41940**: Represented by the mp (malicious process) and bi (bashrc injection) variables.

**Ransomware Check**: The .sorry file search is fully integrated.

**Credential Stealer**: The XMLHttpRequest check in cPanel templates is included.

Before you run this across your fleet, ensure:

**Root Access**: Since you are grepping /etc/shadow, you must run this as root.

**Storage**: If your .bash_history or session caches are massive, the output file might get large. Ensure you have a few MBs of space in /tmp or wherever you save the log.
