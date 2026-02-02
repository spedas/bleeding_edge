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

#Run in /home/jimm/fast_idl3
cd /home/jimm/fast_idl3

# setup SDT
source setup_sdt

# Check for Lock file, if it's there nothing happens, note that the esv,
# e4k and e16k processes all look for the same file, to avoid piling on
# processes
if (! -e process_orbit.lock) then

#Cleanup SDT
    rm -f killsdt0_log
    idl killsdt_all.pro > killsdt0_log
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

# Check for version 1 file, check to see if orbit is an integer
    set raw = `tr -d ' \t\r\n' < orbit.txt`
    if ("$raw" !~ [0-9]*) then
	echo "orbit.txt does not contain a valid integer: '$raw'"
	exit 1
    endif
# Zero-pad orbit to 5 digits
    set orbit = `/usr/bin/printf "%05d" $raw`
    echo $orbit
# Check for file , e.g., fa_despun_e16k_l2_19961211093933_01211_v02.cdf
#    set pattern = "/disks/data/fast/l2/e16k/*/fa_despun_e16k_l2_*_${orbit}_v02.cdf"
#    set files = ( `/bin/ls -1d $pattern` )
#    if ( $#files > 0 ) then
#	echo "File found: orbit: '$raw'"    
#        @ next_orbit = $raw + 1
#	rm -f orbit.txt
#        echo $next_orbit > orbit.txt
#        echo "Updated orbit.txt to $next_orbit"
#	rm -f process_orbit.lock
#    else
    echo "Processing orbit: '$raw'"
# Write file for sdt_batch,
    rm -rf process_orbit_e16k.batch
    set line="BatchJob:  cdftest"
    echo $line > process_orbit_e16k.batch
    set line="Printer:  clf0"
    echo $line >> process_orbit_e16k.batch
    set line="#FileDestination:  1996_03_06_esa.ps"
    echo $line >> process_orbit_e16k.batch
    set line="Output:   ColorPostScript"
    echo $line >> process_orbit_e16k.batch
    set line="PlotsPerPage: 8"
    echo $line >> process_orbit_e16k.batch
    set line="PageSize:   ASize"
    echo $line >> process_orbit_e16k.batch
    set line="Orientation:  portrait"
    echo $line >> process_orbit_e16k.batch
    set line="PageTag:  cdf_test"
    echo $line >> process_orbit_e16k.batch
    set line="DataOutputFile: orbit_process_$number CDF "
    echo $line >> process_orbit_e16k.batch
    set line="NoPlots:"
    echo $line >> process_orbit_e16k.batch
    set line="IDL: run_process_despin_e16k.pro"
    echo $line >> process_orbit_e16k.batch
    set line="DataBaseRequest:"
    echo $line >> process_orbit_e16k.batch
    set line="Orbit $number"
    echo $line >> process_orbit_e16k.batch
    set line="PlotConfigurationDir: SDT_config"
    echo $line >> process_orbit_e16k.batch
    set line="PlotConfigurationFile: Despin16k_NoData_All"
    echo $line >> process_orbit_e16k.batch
#Now call sdt_batch using this file
    sdt_batch process_orbit_e16k.batch
#    endif
else
    echo "process_orbit.lock exists"
#check to see if the lock file is old
    set lfile = process_orbit.lock
    set mtime = `stat -c %Y $lfile`   # GNU/Linux 'stat'
    set now   = `date +%s`
# Compute age in seconds
    @ age = $now - $mtime
# Aggresively restart if the age is greater than 5 minutes
    if ($age > 300) then
        echo "$lfile is older than 10 minutes ($age seconds old). Killing all SDT processes"
        ps -ef | grep 'SDTRunIndex' | grep -v grep | awk '{print $2}' | xargs kill -9
#clean out all CDF files
        rm -f *.cdf
#delete lock file
	rm -f process_orbit.lock
    else
        echo "$lfile is newer than 5 minutes ($age seconds old). Doing nothing."
    endif
endif
exit 0


