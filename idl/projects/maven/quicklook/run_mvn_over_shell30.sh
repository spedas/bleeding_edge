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
setenv CDF_TMP /mydisks/home/maven/muser

#check for lock file here
if (! -e /mydisks/home/maven/muser/MVN_OVER_SHELL30lock.txt) then
    cd /mydisks/home/maven/muser
    rm -f run_mvn_over_shell30.bm
    rm -f /mydisks/home/maven/muser/run_mvn_over_shell30.txt

    set line="run_mvn_over_shell30"
    echo $line > run_mvn_over_shell30.bm
    echo exit >> run_mvn_over_shell30.bm

    idl run_mvn_over_shell30.bm > /mydisks/home/maven/muser/run_mvn_over_shell30.txt &
else
    echo "Overshell30 Process not started" | mailx -s "Overshell30 process not started" jimm@ssl.berkeley.edu
endif 


