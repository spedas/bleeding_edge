#!/bin/csh

source /usr/local/setup/setup_idl8.5.1		# IDL
setenv BASE_DATA_DIR /disks/data/
setenv THEMIS_DATA_DIR /disks/themisdata/
setenv IDL_STARTUP /home/jimm/temp_idl_startup.pro
source /home/jimm/setup_themis

# create a date to append to batch otput
setenv datestr `date +%Y%m%d%H%M%S`
set suffix="$datestr"

#check for lock file here
if (! -e /mydisks/home/maven/muser/STAL2lock.txt) then
    cd /mydisks/home/maven
    rm -f run_sta_l2gen.bm
    rm -f /mydisks/home/maven/muser/run_sta_l2gen.txt

    set line="run_sta_l2gen"
    echo $line > run_sta_l2gen.bm
    echo exit >> run_sta_l2gen.bm

    idl run_sta_l2gen.bm > /mydisks/home/maven/muser/run_sta_l2gen.txt &

#else close quietly
endif 


