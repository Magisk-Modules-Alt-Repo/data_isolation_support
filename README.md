# AppDataIsolation Legacy Support

- Simple module for enabling /data/data isolation for old Android version (Android 10 and lower). Require [Magisk Process Monitor tool](https://github.com/HuskyDG/magisk_proc_monitor) v1.1+
- Tested on Android 7 and Android 9 and it works. There might be some bugs.
- If the module is working, this command shall fail in Terminal Emulator:

```
stat /data/data/com.android.shell
```

<img src="https://i.imgur.com/VsKOLq9.jpg">
