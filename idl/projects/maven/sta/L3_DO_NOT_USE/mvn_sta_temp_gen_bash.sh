#!/bin/csh

source /usr/local/setup/setup_idl8.5.1
setenv ROOT_DATA_DIR /disks/data/
setenv IDL_PATH +/home/gwen.hanley/maven/code:'<IDL_DEFAULT>'
setenv IDL_STARTUP /home/gwen.hanley/maven/code/SSLCode/idl_startup_batch.pro
setenv IDL_DLM_PATH +/home/mitchell/src/mvnidl/lib/idl851:/disks/apollo/export/idl_8.5.1/idl85/bin/bin.linux.x86_64

cd /mydisks/home/maven/gwen.hanley/work/
set logname='mvn_sta_temp_gen_'`date +%Y%m%d`'.log'
idl /home/gwen.hanley/maven/code/mvn_sta_temp_gen_wrapper.pro >&! /home/gwen.hanley/batch/phobos/$logname
