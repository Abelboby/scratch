## NPW30 Scale over CH340 on Windows – flutter_libserialport help request

Hi there! I’m trying to read weight data from an NPW series tabletop weighing scale via RS‑232 using a CH340 USB‑to‑Serial adapter on Windows, with `flutter_libserialport`.

I’ve put together a tiny, reproducible Flutter app and collected all system details and logs here to make troubleshooting easy. I’d be very grateful for any guidance.

### TL;DR
- **Goal**: Read NPW30 scale data over COM4 in Flutter using `flutter_libserialport`.
- **Status**: COM4 is visible and healthy in Windows tools, but `openReadWrite()` returns `false` with intermittent `errno = 31` ("A device attached to the system is not functioning.") or sometimes `errno = 0` while still failing to open.
- **Repo**: Add your link here → `[<repo link>](https://github.com/Abelboby/scratch)`

### Device and setup
- **Device**: NPW SERIES TABLETOP WEIGHING SCALE – 30 KG (Model: NPW30)
- **Connection**: RS‑232 on the scale → RS232‑to‑USB cable → PC
- **Adapter**: USB‑SERIAL CH340 (wch.cn)
- **Target Port**: COM4

### Environment
- **OS**: Windows 10 (build 26100)
- **Flutter package**: `flutter_libserialport: 0.6.0`
- **Driver**: CH340 official VCP installed; Device Manager shows “This device is working properly.”

### Story points (what I did)
1. Connected NPW30 to PC via CH340 USB‑to‑Serial.
2. Installed/verified CH340 driver (`wch.cn`). Device Manager reports OK.
3. Confirmed COM4 exists across multiple tools (see logs below).
4. Built a minimal Flutter app using `flutter_libserialport` to enumerate ports, open COM4, and read via `SerialPortReader`.
5. Tried `openReadWrite()`, `openRead()`, `openWrite()`; tried configuring before open and after open; ensured baud 9600‑8‑N‑1; added a one‑time write `R\r\n` to wake the device.
6. Ensured no other application is using COM4, unplugged/replugged, tried other USB ports, and rebooted.
7. Result is consistently: open fails. Sometimes the reported error is `errno = 0`, sometimes `errno = 31`.

### Minimal code snippet
```dart
final ports = SerialPort.availablePorts; // prints: [COM1, COM4]
final port = SerialPort('COM4');

final opened = port.openReadWrite();
print('Opened: $opened  err=${SerialPort.lastError}  desc=${port.description}');
if (!opened) {
  print('Failed to open port: COM4');
  return;
}

final cfg = SerialPortConfig()
  ..baudRate = 9600
  ..bits = 8
  ..stopBits = 1
  ..parity = 0
  ..setFlowControl(SerialPortFlowControl.none);
port.config = cfg;

// Optional one‑time request/wake command
port.write(Uint8List.fromList('R\r\n'.codeUnits));

final reader = SerialPortReader(port);
reader.stream.listen((data) {
  print(String.fromCharCodes(data));
});
```

### Actual console output (Flutter)
```
flutter: [COM1, COM4]
flutter: Opened: false  err=SerialPortError: The operation completed successfully., errno = 0  desc=USB-SERIAL CH340 (COM4)
flutter: Failed to open port: COM4

// Also seen at times:
err=SerialPortError: A device attached to the system is not functioning., errno = 31
```

### Windows confirmations (PowerShell logs)
```
PS H:\Caddayn\weigh_Scale\scratch> reg query HKLM\HARDWARE\DEVICEMAP\SERIALCOMM

HKEY_LOCAL_MACHINE\HARDWARE\DEVICEMAP\SERIALCOMM
    \Device\Serial0    REG_SZ    COM1
    \Device\Serial2    REG_SZ    COM4

PS H:\Caddayn\weigh_Scale\scratch> Get-CimInstance Win32_PnPEntity | Where-Object { $_.Name -match 'COM\\d+' } | Select-Object Name, DeviceID
PS H:\Caddayn\weigh_Scale\scratch> Get-PnpDevice -Class Ports | Select-Object FriendlyName, InstanceId

FriendlyName               InstanceId
------------               ----------
Communications Port (COM1) ACPI\PNP0501\0
USB-SERIAL CH340 (COM3)    USB\VID_1A86&PID_7523\5&3163F8D&0&7
USB-SERIAL CH340 (COM4)    USB\VID_1A86&PID_7523\6&3504FC2D&0&3


PS H:\Caddayn\weigh_Scale\scratch> [System.IO.Ports.SerialPort]::GetPortNames()
COM1
COM4

PS H:\Caddayn\weigh_Scale\scratch> mode

Status for device COM1:
-----------------------
    Baud:            1200
    Parity:          None
    Data Bits:       7
    Stop Bits:       1
    Timeout:         OFF
    XON/XOFF:        OFF
    CTS handshaking: OFF
    DSR handshaking: OFF
    DSR sensitivity: OFF
    DTR circuit:     ON
    RTS circuit:     ON


Status for device COM4:
-----------------------
    Baud:            9600
    Parity:          None
    Data Bits:       8
    Stop Bits:       1
    Timeout:         OFF
    XON/XOFF:        OFF
    CTS handshaking: OFF
    DSR handshaking: OFF
    DSR sensitivity: OFF
    DTR circuit:     ON
    RTS circuit:     ON


Status for device CON:
----------------------
    Lines:          18
    Columns:        143
    Keyboard rate:  31
    Keyboard delay: 1
    Code page:      850
```

### Error summary
- `SerialPort.openReadWrite()` returns `false` for COM4.
- `SerialPort.lastError` observed values:
  - `errno = 0` ("The operation completed successfully") but still not open
  - `errno = 31` ("A device attached to the system is not functioning.")

### Questions for maintainers
- Is this a known issue with CH340 on Windows with the libserialport backend?
- Any recommended sequence (open before/after config), DTR/RTS toggling, or timeouts?
- How can I enable more verbose/low‑level error info from Dart (e.g., underlying Win32 error)?
- Any patches or workarounds I can test?

### Contact
- Name: `Abel Davis Boby`
- Email: `abeldavisboby@gmail.com`
- Timezone: `Asia/Kolkata`
- Repo: `https://github.com/Abelboby/scratch`

If you’re able to take a quick look, I’d be delighted to hear your thoughts. Thank you!
