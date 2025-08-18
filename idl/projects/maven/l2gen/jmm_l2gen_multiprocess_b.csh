#!/bin/csh
# mvn_l2gen_multiprocess_b function_in nproc offset proc_workdir comment
# added offset, 2013-10-06, jmm
# RUn as jimm, so IDL path is different, 2020-08-04
# get arguments
set function_in=$1
set nproc=$2
set offset=$3
set proc_workdir=$4
set comment=$5

# Set up IDL path
unsetenv IDL_PATH
source /usr/local/setup/setup_idl8.5.1		# IDL
setenv BASE_DATA_DIR /disks/data/
setenv ROOT_DATA_DIR /disks/data/
#for CDFs
setenv CDF_TMP /mydisks/home/maven
#IDL SETUP for MAVEN
if !( $?IDL_BASE_DIR ) then
    setenv IDL_BASE_DIR /home/jimm/themis_sw
endif

if !( $?IDL_PATH ) then
   setenv IDL_PATH '<IDL_DEFAULT>'
endif

setenv IDL_PATH $IDL_PATH':'+$IDL_BASE_DIR

# create a date to append to batch output
setenv datestr `date +%Y%m%d%H%M%S`
set line="$datestr"
# Now start a process in each directory
set i=$offset
set endproc=0
@ endproc = ( $nproc + $offset ) 
while ($i < $endproc) 
    echo $i
    cd $proc_workdir/$function_in$i
    if (-e $function_in'_lock') then
	echo $proc_workdir/$function_in$i/$function_in'_lock' Exists
    else
#        rm -rf $function_in.out$line
        idl $function_in.pro > $function_in.out$line &
    endif
    @ i = ($i + 1)
end
cd $proc_workdir
