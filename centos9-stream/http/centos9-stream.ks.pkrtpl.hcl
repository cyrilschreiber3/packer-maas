url ${KS_OS_REPOS} ${KS_PROXY}
poweroff
firewall --enabled --service=ssh
firstboot --disable
ignoredisk --only-use=vda
lang en_US.UTF-8
keyboard --xlayouts='ch(fr)'
network --device eth0 --bootproto=dhcp
firewall --enabled --service=ssh
selinux --disabled
timezone Europe/Zurich --utc
bootloader --location=mbr --driveorder="vda" --timeout=1
rootpw --plaintext password

repo --name=baseos ${KS_BASEOS_REPOS} ${KS_PROXY}
repo --name=appstream ${KS_APPSTREAM_REPOS} ${KS_PROXY}
repo --name=centos ${KS_CENTOS_REPOS} ${KS_PROXY}

zerombr
clearpart --all --initlabel
part / --size=1 --grow --asprimary --fstype=ext4

user --name=admin --groups=wheel --iscrypted --password=$6$z9iHyBD7MTgyUicn$kwrWplC3xM29JNoNWD9WVSuo3JR/wLZ4Ksi0FMIpmEN/a/rB/lZYuIr.ecdbq4pXLLXBqRRNrH5CbsX0/RcVU1

%post --erroronfail
# workaround anaconda requirements and clear root password
passwd -d root
passwd -l root

#---- Install our SSH key ----
mkdir -m0700 /home/admin/.ssh/

cat <<EOF >/home/admin/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILarrmNyrYIAOc2EWvwyZor+CMlTGGChYwwwfRXCFLyH cyril@scorpius-cl-01
EOF

chmod 0600 /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh/

# Clean up install config not applicable to deployed environments.
for f in resolv.conf fstab; do
    rm -f /etc/$f
    touch /etc/$f
    chown root:root /etc/$f
    chmod 644 /etc/$f
done

rm -f /etc/sysconfig/network-scripts/ifcfg-[^lo]*

# Kickstart copies install boot options. Serial is turned on for logging with
# Packer which disables console output. Disable it so console output is shown
# during deployments
sed -i 's/^GRUB_TERMINAL=.*/GRUB_TERMINAL_OUTPUT="console"/g' /etc/default/grub
sed -i '/GRUB_SERIAL_COMMAND="serial"/d' /etc/default/grub
sed -ri 's/(GRUB_CMDLINE_LINUX=".*)\s+console=ttyS0(.*")/\1\2/' /etc/default/grub
sed -i 's/GRUB_ENABLE_BLSCFG=.*/GRUB_ENABLE_BLSCFG=false/g' /etc/default/grub

dnf clean all
%end

%packages
@core
bash-completion
cloud-init
# cloud-init only requires python3-oauthlib with MAAS. As such upstream
# removed this dependency.
python3-oauthlib
rsync
tar
# grub2-efi-x64 ships grub signed for UEFI secure boot. If grub2-efi-x64-modules
# is installed grub will be generated on deployment and unsigned which breaks
# UEFI secure boot.
grub2-efi-x64
efibootmgr
shim-x64
dosfstools
lvm2
mdadm
device-mapper-multipath
iscsi-initiator-utils
-plymouth
# Remove Intel wireless firmware
-i*-firmware
%end
