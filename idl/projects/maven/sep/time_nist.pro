;+
;Function:  TIME_NIST
;Purpose:  Returns NIST corrected system time (systime(1))
;    Correction is determined from NIST.  (Requires internet connection).
;    Typical computer clocks are highly variable often differing by a few seconds (or more) from UTC.
;    This routine will return a time that is typically accurate to a few 10s of milliseconds.
;    Time offsets are determined no more than once per hour (unless FORCETIME keyword is used)
;Written by Davin Larson (Feb 2012)
;-

function time_nist, toffset=toffset,netdelaytime=netdelaytime,forcetime=forcetime

common time_nist_com, last_checktime, time_offset

st = systime(1)
if n_elements(last_checktime) eq 0 then last_checktime = 0d
if n_elements(forcetime) eq 0 then forcetime=3600d ;  check no more often than once per hour

if st - last_checktime gt (forcetime > 5) then begin     ;  hardwired 5 second minimum time
    if n_elements(time_offset) eq 0 then time_offset = 0d
    dummy=''
    timestr=''
;    server='nist1.symmetricom.com'
;    server='nist1.aol-ca.symmetricom.com'
;    server='nist1-pa.ustiming.org'
    server = 'time.nist.gov'
    socket,fp,/get_lun,server,13,error=error ,connect_timeout=2
    if error ne 0 then begin
        dprint,dlevel=2,phelp=2,!error_state
    endif else if  ~eof(fp) then begin
        readf,fp,dummy
        readf,fp,timestr
        free_lun,fp
;        last_checktime = st
    endif else dprint,dlevel=2,'Unexpected EOF encountered'
    netdelaytime = systime(1) - st
    if strlen(timestr) gt 36  then begin
        truetime = time_double( strmid(timestr,6,17) ) - double( strmid(timestr,31,5) )/1000
        time_offset = truetime-st  - netdelaytime
    endif else dprint,dlevel=2,'Read error'
    dprint,dlevel=3,/phelp,server,timestr,time_offset,netdelaytime
    last_checktime = st
endif else netdelaytime = 0d
toffset = time_offset
return , st + time_offset
end

