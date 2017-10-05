#!/bin/csh
source /usr/local/setup/setup_idl8.5.1
setenv BASE_DATA_DIR /disks/data/
setenv ROOT_DATA_DIR /disks/data/

setenv IDL_STARTUP /home/jimm/temp_idl_startup.pro
source /home/jimm/setup_themis

# create a date to append to batch otput
setenv datestr `date +%Y%m%d%H%M%S`
set suffix="$datestr"

#run in the temp cdf directory
cd $CDF_TMP

rm -f run_fa_esa_l2gen.bm
rm -f run_fa_esa_l2gen.txt

set line="run_fa_esa_l2gen"
echo $line > run_fa_esa_l2gen.bm
echo exit >> run_fa_esa_l2gen.bm

idl run_fa_esa_l2gen.bm > run_fa_esa_l2gen.txt &

endif 


