#!/bin/bash -x

cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
TYPE=Ethernet
USERCTL=no
PEERDNS=yes
IPV6INIT=no
EOF

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

chkconfig network on

yum install -y python-pyasn1

# Make new grub
sed -i 's/^GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=\"rootdelay=300\ console=ttyS0\ earlyprintk=ttyS0\ net\.ifnames=0\"/g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Make new initrd
echo "add_drivers+=\"hv_vmbus hv_netvsc hv_storvsc hv_balloon hv_utils hid_hyperv hyperv_keyboard hyperv_fb \"" >> /etc/dracut.conf
dracut -f -v

# Enable addon repo
if [[ `cat /etc/oracle-release` =~ .*7.7$ ]]; then
    sed -i '/\[ol7_addons\]/,/^$/ s/enabled=0/enabled=1/' /etc/yum.repos.d/oracle-linux-ol7.repo
elif [[ `cat /etc/oracle-release` =~ .*7.6$ ]]; then
    sed -i '/\[ol7_addons\]/,/^$/ s/enabled=0/enabled=1/' /etc/yum.repos.d/public-yum-ol7.repo
fi

# Install and enable agent
yum install -y WALinuxAgent
systemctl enable waagent
