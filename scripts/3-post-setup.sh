#!/usr/bin/env bash
#github-action genshdoc
#
# @file Post-Setup
# @brief Finalizing installation configurations and cleaning up after script.
echo -ne "
-------------------------------------------------------------------------
   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
                        SCRIPTHOME: nabucodonosor
-------------------------------------------------------------------------

Final Setup and Configurations
GRUB EFI Bootloader Install & Check
"
source ${HOME}/nabucodonosor/configs/setup.conf

if [[ -d "/sys/firmware/efi" ]]; then
    grub-install --efi-directory=/boot ${DISK}
fi

echo -ne "
-------------------------------------------------------------------------
               Creating (and Theming) Grub Boot Menu
-------------------------------------------------------------------------
"
# set kernel parameter for decrypting the drive
if [[ "${FS}" == "luks" ]]; then
sed -i "s%GRUB_CMDLINE_LINUX_DEFAULT=\"%GRUB_CMDLINE_LINUX_DEFAULT=\"cryptdevice=UUID=${ENCRYPTED_PARTITION_UUID}:ROOT root=/dev/mapper/ROOT %g" /etc/default/grub
fi
# set kernel parameter for adding splash screen
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& splash /' /etc/default/grub

echo -e "Installing CyberRe Grub theme..."
THEME_DIR="/boot/grub/themes"
THEME_NAME=CyberRe
echo -e "Creating the theme directory..."
mkdir -p "${THEME_DIR}/${THEME_NAME}"
echo -e "Copying the theme..."
cd ${HOME}/nabucodonosor
cp -a configs${THEME_DIR}/${THEME_NAME}/* ${THEME_DIR}/${THEME_NAME}
echo -e "Backing up Grub config..."
cp -an /etc/default/grub /etc/default/grub.bak
echo -e "Setting the theme as the default..."
grep "GRUB_THEME=" /etc/default/grub 2>&1 >/dev/null && sed -i '/GRUB_THEME=/d' /etc/default/grub
echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub
echo -e "Updating grub..."
grub-mkconfig -o /boot/grub/grub.cfg
echo -e "All set!"

echo -ne "
-------------------------------------------------------------------------
                        Installing XQP and XDO
-------------------------------------------------------------------------
"
#XQP -----------------------------------------------------------------
cd ~/Downloads
git clone https://github.com/baskerville/xqp.git
cd xqp
make
sudo make install

# XDO -----------------------------------------------------------------
cd ~/Downloads
git clone https://github.com/baskerville/xdo
cd xdo
make
sudo make install
sudo usermod -aG adm $USER

cd ~
rm -rf ~/Downloads/xdo
rm -rf ~/Downloads/xqp

echo -ne "
-------------------------------------------------------------------------
               Enabling (and Theming) Login Display Manager
-------------------------------------------------------------------------
"
if [[ ${DESKTOP_ENV} == "kde" ]]; then
  systemctl enable sddm.service
  if [[ ${INSTALL_TYPE} == "FULL" ]]; then
    echo [Theme] >>  /etc/sddm.conf
    echo Current=Nordic >> /etc/sddm.conf
  fi

elif [[ "${DESKTOP_ENV}" == "gnome" ]]; then
  systemctl enable gdm.service

elif [[ "${DESKTOP_ENV}" == "lxde" ]]; then
  systemctl enable lxdm.service

elif [[ "${DESKTOP_ENV}" == "openbox" ]]; then
  systemctl enable lightdm.service
  if [[ "${INSTALL_TYPE}" == "FULL" ]]; then
    # Set default lightdm-webkit2-greeter theme to Litarvan
    sed -i 's/^webkit_theme\s*=\s*\(.*\)/webkit_theme = litarvan #\1/g' /etc/lightdm/lightdm-webkit2-greeter.conf
    # Set default lightdm greeter to lightdm-webkit2-greeter
    sed -i 's/#greeter-session=example.*/greeter-session=lightdm-webkit2-greeter/g' /etc/lightdm/lightdm.conf
  fi

else
  if [[ ! "${DESKTOP_ENV}" == "server"  ]]; then
  sudo pacman -S --noconfirm --needed lightdm lightdm-gtk-greeter
  systemctl enable lightdm.service
  fi
fi

echo -ne "
-------------------------------------------------------------------------
                    Enabling Essential Services
-------------------------------------------------------------------------
"

echo "Changed default shell to ZSH!"
chsh -s $(which zsh)

echo "Enabling NetworkManager"
systemctl enable NetworkManager.service

echo "Enabling Ly Display Manager..."
sudo systemctl enable ly.service
sudo cp /home/max/nabucodonosor/configs/config.ini /etc/ly/

echo "Enabling and Starting Plex Media Service..."
sudo systemctl enable plexmediaserver
sudo systemctl start plexmediaserver

echo "Enabling and Starting NordVPN..."
groupadd -r nordvpn
sudo usermod -aG nordvpn $USER
sudo systemctl enable nordvpnd.service
sudo systemctl start nordvpnd.service

echo "enabling virtualbox service"
sudo systemctl enable vboxservice.service

modprobe btusb
echo "enabling and starting bluetooth service..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

echo -ne "
-------------------------------------------------------------------------
                        Setting up Git Account
-------------------------------------------------------------------------
"

echo "Configuring git email and user..."
git config --global user.email "maxigor.ferreira@gmail.com"
git config --global user.name "Max"

echo "done"


echo -ne "
-------------------------------------------------------------------------
               Enabling (and Theming) Plymouth Boot Splash
-------------------------------------------------------------------------
"
# PLYMOUTH_THEMES_DIR="$HOME/nabucodonosor/configs/usr/share/plymouth/themes"
# PLYMOUTH_THEME="arch-glow" # can grab from config later if we allow selection
# mkdir -p /usr/share/plymouth/themes
# echo 'Installing Plymouth theme...'
# cp -rf ${PLYMOUTH_THEMES_DIR}/${PLYMOUTH_THEME} /usr/share/plymouth/themes
# if  [[ $FS == "luks"]]; then
#   sed -i 's/HOOKS=(base udev*/& plymouth/' /etc/mkinitcpio.conf # add plymouth after base udev
#   sed -i 's/HOOKS=(base udev \(.*block\) /&plymouth-/' /etc/mkinitcpio.conf # create plymouth-encrypt after block hook
# else
#   sed -i 's/HOOKS=(base udev*/& plymouth/' /etc/mkinitcpio.conf # add plymouth after base udev
# fi
# plymouth-set-default-theme -R arch-glow # sets the theme and runs mkinitcpio
# echo 'Plymouth theme installed'
#
echo -ne "
-------------------------------------------------------------------------
                    Cleaning
-------------------------------------------------------------------------
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

rm -r $HOME/nabucodonosor
rm -r /home/$USERNAME/nabucodonosor

# Replace in the same state
cd $pwd
