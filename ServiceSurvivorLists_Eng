# 🛠️ Windows Service Survival Guide (Anti-MS Trap)
*Usage: To avoid password and account errors during installation and servicing.*

---

### 1. 🛡️ Installation: Against Forced MS Accounts
If the installer (Win 10/11) demands internet and a Microsoft account:
*   **The Trick:** Do not connect to Wi-Fi or plug in a cable!
*   **Win 11 Command:** If there is no "I don't have internet" button, press `Shift + F10` and type:  
    `OOBE\BYPASSNRO`  
    *(The PC will restart, and the option to create a local account will appear.)*

### 2. 🚪 The "Service Backdoor" (Standard for every PC!)
Before installing any drivers, create a local admin account without a password.
*   **Command Prompt (Admin):**
    ```cmd
    net user Service /add
    net localgroup Administrators Service /add
    ```
    *(Note: For Hungarian Windows use: `net localgroup Rendszergazdak Service /add`)*

### 3. 🔑 Disabling PIN and Biometrics (Windows Hello)
The PIN code is hardware-dependent (TPM). If you disable the GPU or update the BIOS, it may become invalid.
*   **Rule:** Ask the client to **remove the PIN** for the duration of the service and leave only the standard password.

### 4. 🔐 BitLocker – The Most Dangerous Trap
Many laptops (Lenovo, Dell, HP) automatically encrypt the disk if they detect an MS account. Without the key, both the Command Prompt and Safe Mode will be locked!
*   **Check (Admin CMD):** `manage-bde -status`
*   **Disabling:** If protection is active (Protection On), kill it immediately:  
    `manage-bde -off C:`

### 5. 📀 Service Pendrive (Rufus Settings)
When creating the installer with Rufus, check these boxes:
*   [x] *Remove requirement for an online Microsoft account*
*   [x] *Create a local account with username: Service*
*   [x] *Disable BitLocker automatic device encryption*

### 6. 🔄 Danger of "Last Known Good Configuration"
**Caution!** If you use a restore point or "Last Known Good Configuration," the Registry may revert to an earlier state, meaning passwords or PINs changed in the meantime **will not work**.
*   **Solution:** Always ensure your passwordless "Service" account is active before performing a restore!

### 7. 🆘 If you are already locked out (Utilman Trick)
If the password is lost, use a **Win10 installer USB**:
1.  Boot from it -> **Shift + F10**
2.  `copy C:\Windows\System32\utilman.exe C:\utilman.bak`
3.  `copy /y C:\Windows\System32\cmd.exe C:\Windows\System32\utilman.exe`
4.  Restart -> At the login screen, click the accessibility icon (bottom right) to open CMD.
5.  Overwrite the password with: `net user Username NewPassword`

---
**Note for Lenovo G500:** Always keep **UMA Only** mode in BIOS as a safety net if the machine fails to boot due to GPU driver issues!
