#!/sbin/sh
mount /system
sed -i 's/ro.product.device=sapphire/ro.product.device=sapphire32a/' /system/build.prop
