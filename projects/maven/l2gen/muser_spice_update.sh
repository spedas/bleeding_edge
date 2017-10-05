#!/bin/csh

#An muser cronjob for SPICE kernel updates
# 27 * * * * /bin/csh /home/muser/export_socware/idl_socware/projects/maven/l2gen/muser_spice_update.sh >/dev/null 2>&1

source /usr/local/setup/setup_idl8.5.1		# IDL
setenv BASE_DATA_DIR /disks/data/
setenv ROOT_DATA_DIR /disks/data/
#IDL SETUP for MAVEN
if !( $?IDL_BASE_DIR ) then
    setenv IDL_BASE_DIR ~/export_socware/idl_socware
endif

if !( $?IDL_PATH ) then
   setenv IDL_PATH '<IDL_DEFAULT>'
endif

setenv IDL_PATH $IDL_PATH':'+$IDL_BASE_DIR

# Set path for tmp files
setenv CDF_TMP /mydisks/home/maven

# create a date to append to batch otput
setenv datestr `date +%Y%m%d%H%M%S`
set suffix="$datestr"

cd /mydisks/home/maven
rm -f mvn_spice_kernels_update.bm
set line="mvn_spice_kernels_update"
echo $line > mvn_spice_kernels_update.bm
echo exit >> mvn_spice_kernels_update.bm
rm -f /mydisks/home/maven/muser/spice_update.txt
idl mvn_spice_kernels_update.bm > /mydisks/home/maven/muser/spice_update.txt &

endif 

