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

setenv CDF_TMP /mydisks/home/maven

#check for lock file here
if (! -e /mydisks/home/maven/muser/SWEL2lock.txt) then
    cd /mydisks/home/maven
    rm -f run_swe_l2gen.bm
    rm -f /mydisks/home/maven/muser/run_swe_l2gen.txt

    set line="run_swe_l2gen"
    echo $line > run_swe_l2gen.bm
    echo exit >> run_swe_l2gen.bm

    idl run_swe_l2gen.bm > /mydisks/home/maven/muser/run_swe_l2gen.txt &
#else close quietly
endif 


