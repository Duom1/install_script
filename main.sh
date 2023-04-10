# partitioning, pacstrap and fstab
clear
lsblk
echo
echo "WARNING this will erase the entire disk"
read -p "enter hard drive to be installed on: " device_name
clear

(
echo g      # new gpt partition table
echo n      # new partition
echo p      # primary
echo 1      # make it first
echo        # default starting at beginning
echo +100m  # 100 MB more for boot partition
echo n      # new partition
echo p      # primary
echo 2      # make it secound
echo        # default starts after the previous partition
echo        # exted the partition to the ned of the disk
echo w      # writes changes and quits
) | fdisk "/dev/${device_name}"

mkfs.fat -F32 "/dev/${device_name}1"
mkfs.ext4 "/dev/${device_name}2"

mount "/dev/${device_name}2" /mnt
mount --mkdir "/dev/${device_name}1" /mnt/boot/efi

pacstrap /mnt base base-devel linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

# chroot
arch-chroot /mnt bash -c "
echo 'ict-linux' >> /etc/hostname;

sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers;

ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime;
whclock --systohc;

sed -i 's/#en_US.UTF-8/en_US.UTF-8/g' /etc/locale.gen;
locale-gen;

pacman -S grub efibootmgr sudo networkmanager xorg gdm gnome virtualbox libreoffice-fresh firefox discord --noconfirm;
grub-install;
grub-mkconfig -o /boot/grub/grub.cfg"

# user and passwords
clear
read -p "user to add: " user_name

arch-chroot /mnt bash -c "
useradd -m -s /bin/bash -G wheel $user_name;
passwd $user_name;
clear;
echo 'root password';
passwd;
clear"

# services
tmux new-session -d -s mysession "systemd-nspawn --boot --machine=m -D /mnt"
sleep 5s
systemctl --machine=m enable gdm
systemctl --machine=m enable NetworkManager
localectl --machine=m set-x11-keymap fi
localectl --machine=m set-keymap fi
machinectl poweroff m

echo
echo "install done"
read -p "press enter to reboot" jarkko
reboot
