#! /bin/bash

# generate locales
sed --in-place=.bak 's/^#en_US\.UTF-8/en_US\.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.cong
echo "Generated locales..."

# set localtime
ln -sf /usr/share/zoneinfo/America/Seattle /etc/localtime
echo "Localtime set..."

# hardware clock
hwclock --systohc --utc
echo "Configured hardware clock..."

# name and host config
read -r -p "What would you like to call this computer? " HOSTNAME
echo $HOSTNAME > /etc/hostname
sed -i "/localhost/s/$/ $HOSTNAME/" /etc/hosts #MAY BE BROKEN :(

# install networkmanager
echo "installing NetworkManager..." && sleep 1
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# change password
echo "Set your root password please."
passwd

# Bootloader installation
echo "Sorry, computer's sometimes forget stuff too. What kind of system is this again?"
read -r -p "1) UEFI System	2) LEGACY System" sys
if [ $sys -eq 1 ] 
then
	# install grub and the boot manager
	echo "Installing boot manager..." && sleep 1
	pacman -S --noconfirm grub efibootmgr

	# mount bootmgr
	echo "Mounting all systems..." && sleep 1
	mkdir /boot/efi
	mount /dev/sda1 /boot/efi
	
	# Install grub to system
	echo "Installing and configuring grub..." && sleep 1
	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --removable --debug
	grub-mkconfig -o /boot/grub/grub.cfg
fi

if [ $sys -eq 2 ] 
then 
	echo "efi goes here :)"
fi

# complete setup
echo "Configuration complete! Unmounting and rebooting system. Please take out your arch installation medium."
umount -r /mnt
exit
