## HardwareConflict-Resolver
# UniqueHardwareFixes - LegacyGearRescue - CustomRig-Doctor


A felsorolás utal a „mentőöv” jellegre és az egyedi hardverekre:
- UniqueHardwareFixes (Közvetlen és érthető)
- LegacyGearRescue (Utal arra, hogy régebbi, de még értékes gépeket mentünk meg)
- CustomRig-Doctor (Egyedi gépek „doktora”)
- HardwareConflict-Resolver (Technikai, pontos leírás a célról)

# HardwareConflict-Resolver (Lenovo G500 Edition)
### UniqueHardwareFixes | LegacyGearRescue | CustomRig-Doctor

Ez a projekt célzott megoldást nyújt a Lenovo G500 (i3-3110M + AMD Radeon R5 M200) laptopoknál fellépő IRQ és driver-ütközésekre Windows 10 alatt.

## ⚠️ Fontos: A javítás menete
A fagyások elkerülése érdekében szigorúan kövesd az alábbi sorrendet!

### I. fázis: BIOS előkészítés
1. Kapcsold be a gépet, és lépj be a BIOS-ba (F2 vagy Fn+F2).
2. Keresd meg a **Configuration** fület.
3. **Graphics Device** értékét állítsd **Switchable Graphics**-ra.
4. Mentés és kilépés (F10).

### II. fázis: Csökkentett mód (Parancssorral)
Ha a rendszer nem indul el:
1. Indítsd a Windows-t **Csökkentett módban parancssorral**.
2. Navigálj a projekt mappájába: `cd C:\eleresi\ut\HardwareConflict-Resolver`
3. Indítsd el a vezérlő scriptet:
   ```powershell
   powershell -ExecutionPolicy Bypass -File Launcher.ps1
   ```

### III. fázis: Driver telepítés (Normál mód)
Miután a script lefutott és letiltotta a hibás eszközöket, indítsd újra a gépet normál módban:
1. Telepítsd az **Intel HD 4000** drivert.
2. Indítsd újra a gépet.
3. Telepítsd az **AMD Radeon** drivert (a telepítő engedélyezni fogja az eszközt).
4. Ha stabil a rendszer, a `Launcher.ps1` segítségével (vagy manuálisan) visszakapcsolhatod a hangkártyát.

## Projekt felépítése
- `/Fix`: A konkrét beavatkozást végző scriptek.
- `/Tests`: Diagnosztikai lekérdezések a hardver állapotáról.
- `/LOG`: Itt találod a futási naplókat (Hardware_Audit.log, Fix_Activity.log).
- `Launcher.ps1`: A teljes folyamat koordinátora.



# Tippek:
- Hogyan futtasd rendszergazdaként, hogy ne vándoroljon el?
Csökkentett módú parancssorba írd ezt:
powershell -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File C:\UT\A\SCRIPTEDHEZ\Launcher.ps1' -Verb RunAs"

Vagy:
- Navigálj a mappába a sima CMD-ben, majd:
powershell -ExecutionPolicy Bypass .\Launcher.ps1
(Mivel csökkentett módban a CMD alapból rendszergazdai joggal futhat, nem fog elvándorolni, ha a Set-Location benne van a scriptben.)



