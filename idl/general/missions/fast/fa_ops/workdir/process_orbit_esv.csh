#!/bin/csh

# Reads in the FAST orbit to process, creates a lock file, writes SDT
# configuration file, calls SDT_BATCH. The IDL process called by
# sdt_batch will handle deleting the lock file, incrementing the orbit
# number and writng the new orbit.txt file.

# Set up IDL path                                                               
unsetenv IDL_PATH
source /usr/local/setup/setup_idl8.7.2          # IDL                           
setenv BASE_DATA_DIR /disks/data/
setenv ROOT_DATA_DIR /disks/data/
#for CDFs                                                                       
setenv CDF_TMP /home/jimm/data/
#IDL SETUP for MAVEN                                                            
if !( $?IDL_BASE_DIR ) then
    setenv IDL_BASE_DIR /home/jimm/themis_sw
endif

if !( $?IDL_PATH ) then
   setenv IDL_PATH '<IDL_DEFAULT>'
endif

setenv IDL_PATH $IDL_PATH':'+$IDL_BASE_DIR

#Run in /home/jimm/fast_idl
cd /home/jimm/fast_idl

# setup SDT
source setup_sdt

# Check for Lock file, if it's there nothing happens, note that the esv,
# e4k and e16k processes all look for the same file, to avoid piling on
# processes
if (! -e process_orbit.lock) then

# Run your IDL program (batch mode, no prompt)
    rm -f killsdt0_log
    idl killsdt_all.pro > killsdt0_log
# Kill any SDT processes
    ps -ef | grep 'SDTRunIndex' | grep -v grep | awk '{print $2}' | xargs kill -9

#clean out all CDF files
    rm -f *.cdf

# create lock file
    echo process_orbit_esv > process_orbit.lock
    
# Check if orbit.txt exists
    if (! -e orbit.txt) then
	echo "orbit.txt does not exist."
	exit 1
    endif
    
# Read the number from orbit.txt
    set number = `cat orbit.txt`

# Write file for sdt_batch,
    rm -rf process_orbit_esv.batch
    set line="BatchJob:  cdftest"
    echo $line > process_orbit_esv.batch
    set line="Printer:  clf0"
    echo $line >> process_orbit_esv.batch
    set line="#FileDestination:  1996_03_06_esa.ps"
    echo $line >> process_orbit_esv.batch
    set line="Output:   ColorPostScript"
    echo $line >> process_orbit_esv.batch
    set line="PlotsPerPage: 8"
    echo $line >> process_orbit_esv.batch
    set line="PageSize:   ASize"
    echo $line >> process_orbit_esv.batch
    set line="Orientation:  portrait"
    echo $line >> process_orbit_esv.batch
    set line="PageTag:  cdf_test"
    echo $line >> process_orbit_esv.batch
    set line="DataOutputFile: orbit_process_$number CDF "
    echo $line >> process_orbit_esv.batch
    set line="NoPlots:"
    echo $line >> process_orbit_esv.batch
    set line="IDL: run_process_despin_esv.pro"
    echo $line >> process_orbit_esv.batch
    set line="DataBaseRequest:"
    echo $line >> process_orbit_esv.batch
    set line="Orbit $number"
    echo $line >> process_orbit_esv.batch
    set line="PlotConfigurationDir: SDT_config"
    echo $line >> process_orbit_esv.batch
    set line="PlotConfigurationFile: ESV3_NoData"
    echo $line >> process_orbit_esv.batch
#Now call sdt_batch using this file
    sdt_batch process_orbit_esv.batch
else
    echo "process_orbit.lock exists"
#check to see if the lock file is more than 5 minutes old
    set lfile = process_orbit.lock
    set mtime = `stat -c %Y $lfile`   # GNU/Linux 'stat'
    set now   = `date +%s`
# Compute age in seconds
    @ age = $now - $mtime
# Threshold = 300 seconds (5 minutes)
    if ($age > 300) then
	echo "$lfile is older than 5 minutes ($age seconds old). Running IDL..."
	# Run your IDL program (batch mode, no prompt)
	rm -f killsdt0_log
	idl killsdt_all.pro > killsdt0_log
#clean out all CDF files
        rm -f *.cdf
#delete lock file
	rm -f process_orbit.lock
    else
	echo "$lfile is newer than 5 minutes ($age seconds old). Doing nothing."
    endif
endif


