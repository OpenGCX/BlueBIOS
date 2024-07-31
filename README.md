# Blue BIOS
We've reached stable!
This is an OpenComputers BIOS designed to compete with Cyan BIOS.
## Functionality
Blue BIOS has a lightweight EEPROM which will automatically download the bootloader (bl) binaries from the internet. Upon downloading, it'll save the binary to the drive for quick loading (but only if there is a drive). Blue BIOS also supports plugins under `/bios/plugins`.
## How to install
### Cyan BIOS
Go to Netboot, enter `https://raw.githubusercontent.com/OpenGCX/BlueBIOS/main/netboot.lua` and run. It will automatically flash Blue for you.
### OpenOS
Run these commands in order:
```
wget https://raw.githubusercontent.com/OpenGCX/BlueBIOS/main/binaries/blue.bin
flash blue.bin
```
The `flash` command will require input. It'll ask you to enter another EEPROM to flash. Don't, instead just input `y`. Then, it will ask you for the label after flashing. Input `Blue BIOS`, and if you don't want to, you can choose really any name you want.
