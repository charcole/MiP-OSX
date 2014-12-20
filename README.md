MiP-OSX
=======

An attempt to control a WowWee MiP from OSX using CoreBluetooth.

It's not the definitive library. In fact, it's pretty flakey. It might help someone else to get something working though, so thought I'd add it to github anyway.

To compile and run...

```
clang main.m -framework Foundation -framework CoreBluetooth -o mip.out && ./mip.out
```

With any luck it'll prompt you with "Get command". You can then type in commands as hex such as...

| Code | Effect |
|---------------|
| 0630 | To play a tune |
| 83FF00FF | To change front LED colour |
| FE | Disconnect |

[More commands](https://github.com/WowWeeLabs/MiP-BLE-Protocol/blob/master/MiP-Protocol.md)

To disconnect gracefully use the "FE" command then enter an empty command to disconnect from the OSX end.

The things I don't understand:
- It only connects if I call connectPeripheral in didDiscoverPerphiferal AND after the CFRunLoopRunInMode is done
- Cancelling the run loop as soon as the discover happens also makes connect fail
- Timings of CFRunLoops can also cause it not to connect
- *But it does work..... just not happy about it. It doesn't feel correct*

*MiP uses Bluetooth LE so you either need a very up-to-date Mac or a Bluetooth LE dongle.*
