#! /bin/bash

# generate locales
sed --in-place=.bak 's/^#en_US\.UTF-8/en_US\.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.cong
echo "Generated locales..."

# set localtime
ln -sf /usr/share/zoneinfo/America/Seattle /etc/localtime
echo "Set localtime..."

# hardware clock
hwclock --systohc --utc
echo "Configured hardware clock..."

# name and host config
read -r -p "What would you like to call this computer? " HOSTNAME
echo $HOSTNAME > /etc/hostname
sed -i "/localhost/s/$/ $HOSTNAME/" /etc/hosts #MAY BE BROKEN :(

# install networkmanager
echo "installing NetworkManager..."
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# change password | may also be broken first time writing :(
read -r -p "Set root password for $HOSTNAME: " ROOTPASSWD
echo $ROOTPASSWD | passwd
echo "Password set!"

# Bootloader installation
if [ $sys -eq 1 ] 
then
	# install grub and the boot manager
	echo "Installing boot manager..."
	pacman -S --noconfirm grub efibootmgr

	# mount bootmgr
	echo "Mounting all systems..."
	mkdir /boot/efi
	mount /dev/sda1 /boot/efi
	
	# Install grub to system
	echo "Installing and configuring grub..."
	grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi --removable --debug
	grub-mkconfig -o /boot/grub/grub.cfg

	# complete setup
	echo "Configuration complete! Unmounting and rebooting system. Please take out your arch installation medium."
	umount -r /mnt
	exit
fi

if [ $sys -eq 2 ] 
then 
	echo "efi goes here :)"
fi
