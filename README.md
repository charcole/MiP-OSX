MiP-OSX
=======

An attempt to control a WowWee MiP from OSX using CoreBluetooth.

This is not the definitive library for MiP or anything. In fact, it's pretty flakey. It might help someone else to get something working though, so thought I'd add it to github anyway. It's a simple command line tool that someone could maybe build off.

To compile and run...

```
clang main.m -framework Foundation -framework CoreBluetooth -o mip.out && ./mip.out
```

With a bit of luck it'll prompt you with "Enter hex command:" after a few seconds. You can then type in commands as hex such as...

| Code | Effect |
|------|--------|
| 0630 | To play a tune |
| 83FF00FF | To change the front LED colour |
| FE | Disconnect |

WowWee publish [more commands](https://github.com/WowWeeLabs/MiP-BLE-Protocol/blob/master/MiP-Protocol.md) for MiP on their github.

To disconnect gracefully use the "FE" command then enter an empty command to disconnect from the OSX end.

The things I don't understand:
- It only connects if I call connectPeripheral in didDiscoverPerphipheral AND on main thread
- Also between the two connects there seems to need to be a gap
- *But it does work..... I'm just not happy about it*

*Nb. MiP uses Bluetooth LE so you either need a very up-to-date Mac or a USB Bluetooth LE dongle*
