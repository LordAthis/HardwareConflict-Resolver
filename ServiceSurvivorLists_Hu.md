# 🛠️ Windows Szerviz Túlélőlista (Anti-MS Csapda)
*Használat: Telepítéskor és szervizeléskor a jelszó- és fiókhibák elkerülésére.*

---

### 1. 🛡️ Telepítés: MS-fiók kényszerítése ellen
Ha a telepítő (Win 10/11) netet és Microsoft-fiókot követel:
*   **A trükk:** Ne csatlakozz Wi-Fi-re vagy kábelre!
*   **Win 11 parancs:** Ha nincs "Nincs internetem" gomb, nyomj `Shift + F10`-et, és írd be:  
    `OOBE\BYPASSNRO`  
    *(A gép újraindul, és megjelenik a helyi fiók létrehozásának lehetősége.)*

### 2. 🚪 A "Szerviz Hátsó Kapu" (Minden gépnél alap!)
Mielőtt bármilyen drivert feltennél, hozz létre egy jelszó nélküli helyi admint.
*   **Parancssor (Admin):**
    ```cmd
    net user Szerviz /add
    net localgroup Rendszergazdak Szerviz /add
    ```
    *(Angol Windows esetén: `net localgroup Administrators Szerviz /add`)*

### 3. 🔑 PIN és Biometria (Windows Hello) kiiktatása
A PIN-kód hardverfüggő (TPM). Ha VGA-t tiltasz vagy BIOS-t frissítesz, érvénytelenné válhat.
*   **Szabály:** Kérd meg az ügyfelet, hogy a szerviz idejére **törölje a PIN-t**, és csak a sima jelszót hagyja meg.

### 4. 🔐 BitLocker – A legveszélyesebb csapda
Sok laptop (Lenovo, Dell, HP) automatikusan titkosítja a lemezt, ha MS-fiókot lát. Kulcs nélkül a parancssor és a csökkentett mód is zárolva lesz!
*   **Ellenőrzés (Admin CMD):** `manage-bde -status`
*   **Kikapcsolás:** Ha a védelem aktív (Protection On), azonnal lődd le:  
    `manage-bde -off C:`

### 5. 📀 Szerviz Pendrive (Rufus beállítások)
Amikor a Rufus-szal készíted a telepítőt, pipáld be:
*   [x] *Remove requirement for an online Microsoft account*
*   [x] *Create a local account with username: Szerviz*
*   [x] *Disable BitLocker automatic device encryption*

### 6. 🔄 "Utolsó helyes konfiguráció" veszélye
**Vigyázat!** Ha visszaállítási pontot vagy "Last Known Good Configuration"-t használsz, a Registry visszaállhat egy korábbi állapotra, így az időközben megváltoztatott jelszók vagy PIN kódok **nem fognak működni**.
*   **Megoldás:** Visszaállítás előtt mindig legyen aktív a jelszó nélküli "Szerviz" fiókod!

### 7. 🆘 Ha már kizárt a rendszer (Utilman trükk)
Ha nincs meg a jelszó, használd a **Win10 telepítő pendrive-ot**:
1.  Bootolj be róla -> **Shift + F10**
2.  `copy C:\Windows\System32\utilman.exe C:\utilman.bak`
3.  `copy /y C:\Windows\System32\cmd.exe C:\Windows\System32\utilman.exe`
4.  Restart -> Bejelentkező képernyőn jobb alul az ikonra kattintva felugrik a CMD.
5.  `net user Felhasznalonev UjJelszo` parancsal írd felül a kódot.

---
**Megjegyzés a Lenovo G500-hoz:** Mindig legyen a BIOS-ban az **UMA Only** mód a mentőöv, ha a VGA driver miatt nem indulna a gép!
