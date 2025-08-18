;+
;FUNCTION: time_zone_offset()
;PURPOSE:  Returns timezone offset in hours.  Will include any offset from daylight savings time
; 
;Usage:
;IDL> print,time_zone_offset()
;    -7
; 
;IDL> file_touch,somefile,systime(1),/mtime,toffset=time_zone_offset()
; 
; $LastChangedBy: pcruce $
; $LastChangedDate: 2014-02-06 17:49:56 -0800 (Thu, 06 Feb 2014) $
; $LastChangedRevision: 14190 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/time/time_zone_offset.pro $
;-

function time_zone_offset

  local_time_string = systime()
  utc_time = systime(/sec,/utc)

  fields = strsplit(local_time_string,' ',/extract)
  
  months = strlowcase(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'])
  
  date = fields[2] ;this is sometimes 1 character,sometimes 2, time_double will not choke on either format
  year = fields[4]
  month = string(where(strlowcase(fields[1]) eq months,c)+1,format='(I2.2)')
  time = fields[3]
  if c ne 1 then message,'Unexpected error detecting month'
  
  local_time = time_double(year+'-'+month+'-'+date+'/'+time)
   
  return, round((local_time-utc_time)/60./60.)

end