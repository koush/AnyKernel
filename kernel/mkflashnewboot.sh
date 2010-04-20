#!/sbin/sh
echo \#!/sbin/sh > /tmp/flashnewboot.sh
echo /tmp/mkbootimg --kernel /tmp/zImage --ramdisk /tmp/boot.img-ramdisk.gz --cmdline \"$(cat /tmp/boot.img-cmdline)\" --base $(cat /tmp/boot.img-base) --output /tmp/newboot.img >> /tmp/flashnewboot.sh
echo sync >> /tmp/flashnewboot.sh
chmod 777 /tmp/flashnewboot.sh
/tmp/flashnewboot.sh
return $?