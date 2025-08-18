#designed to be run as an muser cronjob
#!/bin/csh

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

#check for lock file here, created here, deleted in the IDL program, not in this script since the idl program is run in batch mode
if (! -e /mydisks/home/maven/muser/MAGL2lock.txt) then
    touch /mydisks/home/maven/muser/MAGL2lock.txt
    rm -f /mydisks/home/maven/muser/run_mag_l2gen.txt
#mvn_mag_batch is runnable from batch mode
    idl /home/muser/export_socware/idl_socware/projects/maven/mag/mvn_mag_batch.pro > /mydisks/home/maven/muser/run_mag_l2gen.txt &
#else close quietly
endif 


