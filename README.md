Still in development, bugs may occur in which case you can file an issue.

## How to install
### Cyan BIOS
Go to Netboot, enter `https://raw.githubusercontent.com/OpenGCX/BlueBIOS/unstable/netboot.lua` and run. It will automatically flash Blue for you.
### OpenOS
Run these commands in order:
```
wget https://raw.githubusercontent.com/OpenGCX/BlueBIOS/unstable/binaries/blue.bin
flash blue.bin
```
The `flash` command will require input. It'll ask you to enter another EEPROM to flash. Don't, instead just input `y`. Then, it will ask you for the label after flashing. Input `Blue BIOS`, and if you don't want to, you can choose really any name you want.

---
LICENSE USED: `GNU GPL 3.0`
