# AnyKernel 2.0 Ramdisk Mod Script 
# osm0sis @ xda-developers

## AnyKernel setup
# EDIFY properties
kernel.string=DirtyV by bsmitty83 @ xda-developers
do.initd=1
do.devicecheck=1
do.cleanup=1
device.name1=maguro
device.name2=toro
device.name3=toroplus

# shell variables
block=/dev/block/platform/omap/omap_hsmmc.0/by-name/boot;

## end setup


## AnyKernel methods (DO NOT CHANGE)
# set up extracted files and directories
ramdisk=/tmp/anykernel/ramdisk;
bin=/tmp/anykernel/tools;
split_img=/tmp/anykernel/split_img;
patch=/tmp/anykernel/patch;

cd $ramdisk;
chmod -R 755 $bin;
mkdir -p $split_img;

# dump boot and extract ramdisk
dump_boot() {
  dd if=$block of=/tmp/anykernel/boot.img;
  $bin/unpackbootimg -i /tmp/anykernel/boot.img -o $split_img;
  gunzip -c $split_img/boot.img-ramdisk.gz | cpio -i;
}

# repack ramdisk then build and write image
write_boot() { 
  find . | cpio -o -H newc | gzip > /tmp/anykernel/ramdisk-new.cpio.gz;
  if [ ! -z `cat $split_img/boot.img-cmdline` ]; then
    cmdline="--cmdline `cat $split_img/boot.img-cmdline`";
  fi;
  $bin/mkbootimg --kernel /tmp/anykernel/zImage --ramdisk /tmp/anykernel/ramdisk-new.cpio.gz $cmdline --base 0x`cat $split_img/boot.img-base` --pagesize `printf "%d\n" 0x$(cat $split_img/boot.img-pagesize)` --output /tmp/anykernel/boot-new.img;
  dd if=/tmp/anykernel/boot-new.img of=$block;
}

# backup_file <file>
backup_file() { cp $1 $1~; }

# replace_string <file> <if search string> <original string> <replacement string>
replace_string() {
  if [ -z "$(grep "$2" $1)" ]; then
      sed -i "s;${3};${4};" $1;
  fi;
}

# insert_line <file> <if search string> <line before string> <inserted line>
insert_line() {
  if [ -z "$(grep "$2" $1)" ]; then
    line=$((`grep -n "$3" $1 | cut -d: -f1` + 1));
    sed -i $line"s;^;${4};" $1;
  fi;
}

# replace_line <file> <line replace string> <replacement line>
replace_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i $line"s;.*;${3};" $1;
  fi;
}

# prepend_file <file> <if search string> <patch file>
prepend_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo "$(cat $patch/$3 $1)" > $1;
  fi;
}

# append_file <file> <if search string> <patch file>
append_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo -ne "\n" >> $1;
    cat $patch/$3 >> $1;
    echo -ne "\n" >> $1;
  fi;
}

# replace_file <file> <permissions> <patch file>
replace_file() {
  cp -fp $patch/$3 $1;
  chmod $2 $1;
}

## end methods


## AnyKernel permissions
# set permissions for included files
chmod -R 755 $ramdisk
chmod 644 $ramdisk/sbin/media_profiles.xml


## AnyKernel install
dump_boot;

# begin ramdisk changes

# init.rc
backup_file init.rc;
replace_string init.rc "cpuctl cpu,timer_slack" "mount cgroup none /dev/cpuctl cpu" "mount cgroup none /dev/cpuctl cpu,timer_slack";
append_file init.rc "run-parts" init;

# init.tuna.rc
backup_file init.tuna.rc;
insert_line init.tuna.rc "nodiratime barrier=0" "mount_all /fstab.tuna" "\tmount ext4 /dev/block/platform/omap/omap_hsmmc.0/by-name/userdata /data remount nosuid nodev noatime nodiratime barrier=0\n";
append_file init.tuna.rc "dvbootscript" init.tuna;

# init.superuser.rc
if [ -f init.superuser.rc ]; then
  backup_file init.superuser.rc;
  replace_string init.superuser.rc "Superuser su_daemon" "# su daemon" "\n# Superuser su_daemon";
  prepend_file init.superuser.rc "SuperSU daemonsu" init.superuser;
else
  replace_file init.superuser.rc 750 init.superuser.rc;
  insert_line init.rc "init.superuser.rc" "on post-fs-data" "    import /init.superuser.rc\n\n";
fi;

# fstab.tuna
backup_file fstab.tuna;
replace_line fstab.tuna "/by-name/system" "/dev/block/platform/omap/omap_hsmmc.0/by-name/system    /system             ext4      nodev,noatime,nodiratime,barrier=0,data=writeback,noauto_da_alloc,discard    wait";
replace_line fstab.tuna "/by-name/cache" "/dev/block/platform/omap/omap_hsmmc.0/by-name/cache     /cache              ext4      nosuid,nodev,noatime,nodiratime,errors=panic,barrier=0,nomblk_io_submit,data=writeback,noauto_da_alloc    wait,check";
replace_line fstab.tuna "/by-name/userdata" "/dev/block/platform/omap/omap_hsmmc.0/by-name/userdata  /data               ext4      nosuid,nodev,noatime,errors=panic,nomblk_io_submit,data=writeback,noauto_da_alloc    wait,check,encryptable=/dev/block/platform/omap/omap_hsmmc.0/by-name/metadata";
append_file fstab.tuna "usbdisk" fstab;

# end ramdisk changes

write_boot;

## end install

