pro mav_GSE_GPIB_load,pathname,starttime=starttime

if size(/type,starttime) eq 5 then t = time_string(starttime,tformat='YYYYMMDD_hhmmss_')
if size(/type,starttime) eq 7 then t= starttime

pathname = 'maven/sep/prelaunch_tests/EM2/20110502_113343_highrate2/20110502_113343_gpib_log.log'

source = mav_file_source()

file = file_retrieve(pathname,_extra = source)

dprint

end

