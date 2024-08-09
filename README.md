# CLI debloater for HyperOS/MIUI, OneUI and Pixel

This shell script uses adb to disable or uninstall unwanted packages from your device based in a JSON file (just like those in src/JSON)

## Usage

You need to connect your device to adb previously using any method as you want.

```shell
src/debloat.sh <json file> [adb options...]
```

The script will show you any package in your device which needs to be disabled. You can pass extra adb options, per example, to select what device you want to debloat (if there are many devices connected).

## Examples

First of all, connect the device to adb, through USB or TCP/IP.

```shell
adb connect <device's ip>:5555
```
Ensure the device is connected and authorized. Then, run the script and pass the JSON file based on your device's UI.

```shell
src/debloat.sh src/JSON/Xiaomi.json
```
![image](https://github.com/user-attachments/assets/070b3401-180e-4b8e-9e90-db47f1d464a1)

If you have more than one device connected, you can pass the option `-t <id>` to select. You can also pass `-e` or `-d` and so on.

```shell
src/debloat.sh src/JSON/Xiaomi.json -t 2
```
```shell
src/debloat.sh src/JSON/Xiaomi.json -d
```
```shell
src/debloat.sh src/JSON/Xiaomi.json -e
```

## Other Support

You can create or modify the json files in src/JSON as you want and use any debloat list in any device.
Sometimes, the packages cannot be disabled, then, the script will ask for uninstalling it.




