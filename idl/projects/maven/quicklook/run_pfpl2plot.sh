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
if (! -e /mydisks/home/maven/muser/PFPL2PLOTlock.txt) then
    cd /mydisks/home/maven
    rm -f run_pfpl2plot.bm
    rm -f /mydisks/home/maven/muser/run_pfpl2plot.txt

    set line="run_pfpl2plot"
    echo $line > run_pfpl2plot.bm
    echo exit >> run_pfpl2plot.bm

    idl run_pfpl2plot.bm > /mydisks/home/maven/muser/run_pfpl2plot.txt &
else
    echo "PFPL2 Process not started" | mailx -s "PFPL2 process not started" jimm@ssl.berkeley.edu
endif
    


