;+
;PROCEDURE load_3dp_data, time,  delta_time,quality=quality
;
;PURPOSE:
;  Opens and loads into memory the 3DP LZ data file(s) within the given time
;  range.
;  This must be called prior to any data retrieval!
;
;INPUTS:   (optional,  prompted if not provided)
;  time:   start time.string of the form: 'yy-mm-dd/hh:mm:ss'
;  deltat; int,float or double:  number of hours of data to load
;  quality; set bits to determine level of packet quality.
;	    the following bits will allow packets with these possible
;	    problems through the decommutator filter:
;		1: frame contains some fill data
;		2: the following packet is invalid
;		4: packet contains fill data
;	    default is quality = 0 (most conservative option)
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	@(#)load_3dp_data.pro	1.20 02/11/05
;-
pro load_3dp_data, time, deltat, memsize=memsize,quality=quality $
   ,if_needed=if_needed,noset=noset
@wind_com.pro
@tplot_com.pro

init_wind_lib

if n_elements(quality) ne 1 then quality = 0

if n_elements(time) eq 0 then begin
	get_timespan,time
	noset = 1
endif

if n_elements(time) eq 2 then t = time_double(time)
if n_elements(deltat) eq 0 then deltat=24.d

if n_elements(time) eq 1 then begin
   t=time_double(time)
;   t = t - t mod (3600.d*deltat)
   t = [t,t+3600.d*deltat]
endif

if (n_elements(t) ne 2) or (size(/type,t) ne 5) then message,'Improper time'

if keyword_set(memsize) then memsize = fix(memsize) else memsize = 30

if keyword_set(if_needed) and keyword_set(loaded_trange) then begin
    if t[1] le loaded_trange[1] and t[0] ge loaded_trange[0] then begin
       print,'WIND decom data already loaded.  Skipping'
       return
    endif
endif
;test=1
mf = lz_3dp_files
if file_test(mf) eq 0 then begin
    wind_init
    pathformat = 'wind/3dp/lz/YYYY/wi_lz_3dp_YYYYMMDD_v0?.dat'
    pathnames = file_dailynames(trange=t,file_format=pathformat,times=times)
    files = file_retrieve(pathnames,_extra=!wind,/last_version)
    mf = getenv('IDL_TMPDIR')+'wind/3dp/lz/index/wind_3dp_lz_index.txt'
    file_open,'w',mf,unit=unit,dir_mode='777'O ,file_mode='666'O
    for i=0,n_elements(times)-1 do begin
       printf,unit,format="(a,'  ',a,'  ',a,'  ',i3)",time_string(times[i]+[0,24d*3600d -1]),files[i],file_test(files[i])
    endfor
    free_lun,unit
endif
print,'Using decomutator: "',wind_lib,'"'
err = call_external(wind_lib,'load_data_files_idl',t,mf,memsize,quality)

loaded_trange = t

if not keyword_set(noset) then timespan,t

str = time_string(t)
refdate = strmid(str(0),0,strpos(str(0),'/'))
str_element,tplot_vars,'options.refdate',refdate,/add_replace

print,'Reference date is: ',refdate
return
end

