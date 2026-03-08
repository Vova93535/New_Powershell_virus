# ⚠️ WARNING: EXTREMELY DANGEROUS CODE ⚠️

This repository contains the script `dead.ps1`, which **completely destroys the Windows operating system**.  
**NEVER RUN IT ON YOUR MAIN COMPUTER OR ON A NETWORK THAT YOU CARE ABOUT!**

## Purpose
This code is provided **solely for educational purposes** for:
- Studying the mechanisms of malware.
- Testing in isolated environments (virtual machines, sandboxes such as Browserling, Any.Run).
- Understanding the importance of system backup and protection.

 The author is not responsible for any misuse of this material.

## What does the script do?
When run with administrator privileges, the script performs the following irreversible actions:

- **Disables protection:** Microsoft Defender, UAC, and monitoring.
- **Disables protection:** Microsoft Defender, UAC, and monitoring.Damages system files** (including `exe`, `dll`, `sys`) in the `System32`, `Program Files`, and `AppData` folders by replacing random bytes.
- **Destroys the registry** by deleting critical branches (`Services`, `Run`, `Winlogon`), which renders Windows inoperable.
- **Removes shadow copies** and disables system recovery (`vssadmin`).
- **Blocks administration tools:** Task Manager, Registry Editor, and Search.- **Creates chaos**: constantly changes cursors, opens multiple `cmd` windows with the message "PANDEMIC", and fills the disk with garbage.
- **Stays in the system**: copies itself to the startup and task scheduler.

## How to test safely?
Only in a **strictly isolated environment**:
- Online sandboxes: [Browserling](https://www.browserling.com), [Any.Run](https://app.any.run), [Cuckoo Sandbox](https://cuckoo.cert.ee).
- Local virtual machine (VirtualBox, VMware) with disabled network.
- **Never run on real hardware!**

## License
This code is distributed for research purposes only. Any use for causing damage is prohibited.
