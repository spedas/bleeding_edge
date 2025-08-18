#!/bin/csh

#A script for a cronjob for 0 length file removal
# 27 * * * * /bin/csh /home/muser/export_socware/idl_socware/projects/maven/l2gen/mvn_l2gen_remove_0logs.sh >/dev/null 2>&1
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

#check for lock file here, no messing around if process is running
if (! -e /mydisks/home/maven/muser/STAL2lock.txt) then
    cd /mydisks/home/maven

    rm -f mvn_l2gen_remove_0logs.bm
    rm -f /mydisks/home/maven/muser/mvn_l2gen_remove_0logs.txt

    set line="mvn_l2gen_remove_0logs"
    echo $line > mvn_l2gen_remove_0logs.bm
    echo exit >> mvn_l2gen_remove_0logs.bm

    idl mvn_l2gen_remove_0logs.bm > /mydisks/home/maven/muser/mvn_l2gen_remove_0logs.txt &
endif
