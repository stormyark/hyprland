# Install Arch using "archinstall" (dualboot)
## Download
1. Download the ISO from https://archlinux.org/download/
2. (Optional) Verifing Checksum: `certutil -hastfile "filename" SHA256`
## Boot
1. Boot from USB
2. connect to WiFi `iwctl`
3. change WiFi mode: 
	1. show: `station wlan0 show`
	2. scan: `station wlan0 scan`
	3. get networks: `station wlan0 get-networks`
	4. connect: `station wlan0 connect "SSID"`
	5. exit iwd: `exit`
	6. verify connection: `ping archlinux.org` & `ip a`
---
## SSH
1. on Install: `sudo systemctl enable sshd` & `sudo systemctl start sshd`
2. set a root password: `passwd`
3. connect: `ssh root@IP`
---
## Partitioning (dualboot with windows)
### Format Partitions (only recommended for advanced users)
⚠️ Caution: using `dd` can break your system, only use this if you know what you do
Partitions by writing random data: 
`dd if=/dev/urandom of=/dev/sda4 bs=4096 status=progress`
### Setup
```bash
mount /dev/sdaX /mnt          # root
mount /dev/sdaY /mnt/boot     # new /boot Partition
mount /dev/sdaZ /mnt/boot/efi # existing EFI
```
### Example
1. List partitions: `fdisk -l`
```bash
Device         Start       End   Sectors  Size Type  
/dev/sda1       2048    206847    204800  100M EFI System  
/dev/sda2     206848    239615     32768   16M Microsoft reserved  
/dev/sda3     239616 207740927 207501312 98.9G Microsoft basic data  
/dev/sda4  207740928 465610751 257869824  123G Linux filesystem  
/dev/sda6  465610752 467611647   2000896  977M Linux swap  
/dev/sda7  467611648 468660223   1048576  512M Windows recovery environment  
/dev/sda8  468660224 498020351  29360128   14G Windows recovery environment  
/dev/sda9  498020352 500117503   2097152    1G Windows recovery environment
```

2. Choose Mountpoints
```bash
/dev/sda4 123G Linux filesystem /mnt    # root
/dev/sda5 1G   EFI System /mnt/boot     # new /boot Partition
/dev/sda1 100M EFI System /mnt/boot/efi # existing EFI
/dev/sda6 977M Linux swap               # swap
```

3. Mount partitions
- #### `/mnt`
```bash
mkfs.ext4 /dev/sda4           or         //mkfs.btrfs -L root /dev/sda4
mount /dev/sda4 /mnt
```
- #### `/mnt/boot`
```bash
mkdir -p /mnt/boot
mount /dev/sda5 /mnt/boot
```
- #### `/mnt/boot/efi`
```bash
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
```
- Swap
```bash
mkswap /dev/sda6
swapon /dev/sda6
```
---
## Installation
1. Update GPG Key `pacman-key --init` & `pacman-key --populate archlinux` & `pacman -S archlinux-keyring`
2. Install `archinstall` and execute it
	1. Select your keyboard layout, language and mirror region
	2. for partitioning choose "preconfigured" on `/mnt`
	3. recommended bootloader `grub`
	4. its recommended to create a user
	5. most popular desktop environments are `kde` `hyprland` `gnome`
	6. best option for audio is `pulseaudio`
	7. hit install
3. After installation is done login into chroot
4. run `sudo pacman -S grub efibootmgr os-prober` to install GRUB
5. `grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB`
6. `grub-mkconfig -o /boot/grub/grub.cfg`
7. `exit` & `reboot`
---
## After installation
1. Login
2. connect to WiFi `nmcli device wifi connect "SSID" password 'PASSWORD'`
3. install yay `cd opt/` & `sudo git clone https://aur.archlinux.org/yay-git.git`
4. Update Mirrorlist `sudo reflector --country "country" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist`
	1. Update Mirrorlist automatically `sudo pacman -S reflector`
---
Author: stormyark
Website: stormyark.de
