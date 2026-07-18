# Run CargoConnect On A Physical Android Device

Last updated: 2026-05-18

This guide explains how to run the CargoConnect Customer App and Driver App on a real Android phone using USB debugging.

## 1. Requirements

Install and verify these first:

- Flutter SDK
- Android Studio Android SDK and Platform Tools
- A USB data cable
- A physical Android phone
- CargoConnect backend running on your laptop
- Phone and laptop connected to the same Wi-Fi network when testing backend APIs

Verify Flutter:

```powershell
flutter doctor
```

## 2. Enable Developer Options On Android

Exact labels vary slightly by phone brand, but the flow is usually:

1. Open `Settings`.
2. Open `About phone`.
3. Find `Build number`.
4. Tap `Build number` seven times.
5. Enter your phone PIN, pattern, or password if prompted.
6. Confirm the phone shows a message like:

```txt
You are now a developer.
```

On some devices, `Build number` is under:

```txt
Settings > About phone > Software information > Build number
```

## 3. Enable USB Debugging

1. Open `Settings`.
2. Open `System` or `Additional settings`.
3. Open `Developer options`.
4. Enable `USB debugging`.
5. Optional but useful: enable `Install via USB` if your phone shows this option.

Keep Developer Options enabled while testing the app.

## 4. Connect The Phone

1. Connect the phone to the laptop using a USB data cable.
2. Unlock the phone.
3. If Android asks for USB mode, choose:

```txt
File Transfer / Android Auto
```

4. When the phone shows:

```txt
Allow USB debugging?
```

5. Check `Always allow from this computer`.
6. Tap `Allow`.

If the trust prompt does not appear, unplug and reconnect the cable, then unlock the phone again.

## 5. Verify Device In Flutter

From PowerShell:

```powershell
flutter devices
```

Expected result:

```txt
1 connected device:
<Phone Name> (mobile) • <device-id> • android-arm64 • Android <version>
```

Copy the device ID. You can use it with `-d`.

Example:

```powershell
flutter devices
```

Output example:

```txt
sdk gphone64 x86 64 (mobile) • RZ8N12345AB • android-arm64 • Android 14
```

Use:

```powershell
-d RZ8N12345AB
```

## 6. Start Backend Before Running The Mobile Apps

Start XAMPP MySQL first, then run:

```powershell
cd D:\Projects\cargoconnect\backend
npm run dev
```

Verify backend:

```powershell
Invoke-RestMethod http://localhost:5000/api/v1/health
Invoke-RestMethod http://localhost:5000/api/v1/health/db
```

## 7. Find Laptop IP Address

A real phone cannot use `localhost` to reach the laptop backend. On a physical phone, `localhost` means the phone itself.

Find your laptop IPv4 address:

```powershell
ipconfig
```

Look under your active Wi-Fi or Ethernet adapter:

```txt
IPv4 Address . . . . . . . . . . . : 192.168.1.25
```

Your API base URL becomes:

```txt
http://192.168.1.25:5000/api/v1
```

Use your real laptop IP in place of `192.168.1.25`.

## 8. Base URL Rules

Use the correct base URL for each target:

| Target | Base URL |
| --- | --- |
| Android emulator | `http://10.0.2.2:5000/api/v1` |
| Physical Android phone | `http://<LAPTOP_IP>:5000/api/v1` |
| Chrome web on laptop | `http://localhost:5000/api/v1` |
| Backend/Postman on laptop | `http://localhost:5000/api/v1` |

Both mobile apps read the API URL from this Flutter dart define:

```txt
CARGOCONNECT_API_BASE_URL
```

If you skip the dart define, the apps default to:

```txt
http://localhost:5000/api/v1
```

That default is not correct for a physical Android phone.

## 9. Run Customer App On Phone

Replace `<DEVICE_ID>` and `<LAPTOP_IP>` with your actual values:

```powershell
cd D:\Projects\cargoconnect\customer_app
flutter pub get
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<LAPTOP_IP>:5000/api/v1
```

Example:

```powershell
cd D:\Projects\cargoconnect\customer_app
flutter run -d RZ8N12345AB --dart-define=CARGOCONNECT_API_BASE_URL=http://192.168.1.25:5000/api/v1
```

## 10. Run Driver App On Phone

Replace `<DEVICE_ID>` and `<LAPTOP_IP>` with your actual values:

```powershell
cd D:\Projects\cargoconnect\driver_app
flutter pub get
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<LAPTOP_IP>:5000/api/v1
```

Example:

```powershell
cd D:\Projects\cargoconnect\driver_app
flutter run -d RZ8N12345AB --dart-define=CARGOCONNECT_API_BASE_URL=http://192.168.1.25:5000/api/v1
```

## 11. Quick Login Smoke Tests

Use seeded local credentials after running `npm run seed`.

Customer:

```txt
Email: customer@cargoconnect.local
Password: Password123!
```

Driver:

```txt
Email: driver@cargoconnect.local
Password: Password123!
```

Admin is not a mobile app, but the backend seed admin is:

```txt
Email: admin@cargoconnect.local
Password: Password123!
```

## 12. Troubleshoot No Device Found

If `flutter devices` does not show the phone:

1. Unlock the phone and keep the screen on.
2. Reconnect the USB cable.
3. Use a USB data cable, not a charge-only cable.
4. Change the phone USB mode to `File Transfer`.
5. Confirm `USB debugging` is enabled.
6. Revoke and re-accept USB debugging trust:

```txt
Settings > Developer options > Revoke USB debugging authorizations
```

Then reconnect the phone and tap `Allow`.

7. Restart ADB:

```powershell
adb kill-server
adb start-server
adb devices
flutter devices
```

8. If `adb` is not found, use the Android SDK platform-tools path:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

9. Install the phone manufacturer's USB driver if Windows Device Manager shows an unknown Android device.

10. Run:

```powershell
flutter doctor -v
```

Fix any Android toolchain issues shown by Flutter.

## 13. Troubleshoot App Cannot Reach Backend

If login or API screens fail on the physical phone:

1. Confirm backend is running:

```powershell
Invoke-RestMethod http://localhost:5000/api/v1/health
```

2. Confirm phone and laptop are on the same Wi-Fi.
3. Confirm you used laptop IP, not `localhost`:

```powershell
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<LAPTOP_IP>:5000/api/v1
```

4. Open the phone browser and test:

```txt
http://<LAPTOP_IP>:5000/api/v1/health
```

5. Allow Node.js through Windows Defender Firewall on private networks.
6. Confirm backend is listening on port `5000`.
7. Restart backend after `.env` changes.

## 14. Useful Commands

List Flutter devices:

```powershell
flutter devices
```

List ADB devices:

```powershell
adb devices
```

Run Customer App:

```powershell
cd D:\Projects\cargoconnect\customer_app
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<LAPTOP_IP>:5000/api/v1
```

Run Driver App:

```powershell
cd D:\Projects\cargoconnect\driver_app
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<LAPTOP_IP>:5000/api/v1
```

Clean and reinstall if a build gets stuck:

```powershell
flutter clean
flutter pub get
flutter run -d <DEVICE_ID> --dart-define=CARGOCONNECT_API_BASE_URL=http://<LAPTOP_IP>:5000/api/v1
```
