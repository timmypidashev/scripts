#! /bin/bash

echo "Timmy's Arch Installer" && sleep 1

# Figure out if we are running on a Legacy or UEFI system
echo "1) UEFI System 	2) Legacy System"
read -r -p "What kind of computer are you running on? (default 1): " sys

case $sys in 
[1])
    SYSTEM="UEFI"
    ;;
[2])
    SYSTEM="LEGACY"
    ;;
[4])
    SYSTEM=""
    ;;
[*])
    SYSTEM="UEFI"
    ;;
esac

# Format disk with FDisk
echo "Formatting /dev/sda for $SYSTEM system..."

# UEFI format
if [ $sys -eq 1 ]
then
	# fdisk formatting
	(
	echo g;
	echo w;
	echo q
	) } fdisk /dev/sda
	
	(
	echo n;
	echo "";
	echo "";
	echo +512M;
	echo t;
	echo 1;
	echo n;
	echo "";
	echo "";
	echo +25G;
	echo n;
	echo "";
	echo "";
	echo ""
	echo w;
	echo q
	) | fdisk /dev/sda

	# actually format the partitions afterwards...
	mkfs.fat -F32 /dev/sda1
	mkfs.ext4 /dev/sda2
	mkfs.ext4 /dev/sda3

	# mount partitions
	echo "Mounting partitions..." && sleep 1
	mount /dev/sda2 /mnt
	mkdir /mnt/home
	mount /dev/sda3 /mnt/home
	
	echo "Disk-related stuff complete. phew..."
fi
	
# EFI format
if [ $sys -eq 2 ]
then
	echo "efi"
fi

# download linux firmware and important modules
echo "Downloading needed dependencies..."
pacstrap - /mnt base linux linux-firmware sudo nano git

# generate file-system table
genfstab -U -p /mnt >> /mnt/etc/fstab && sleep 1
echo "Generated file-system table..."

# post install 
echo "Fetching post-install script and chrooting..." && sleep 1
cp arch-post.sh /mnt/root/arch-post.sh
arch-chroot /mnt "/bin/bash" "/root/arch-post.sh"

#after post-install completes
umount /mnt
echo "Configuration complete! Please reboot your system and take out your arch installation medium."
