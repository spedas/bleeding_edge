;+
;Procedure: ACE_INIT
;
;Purpose: Initializes a settings for ace_mag_swepam_load & noaa_ace_nrt_load
; 
;Notes:
;
; Author: Cindy Goethel
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-02-06 01:14:57 -0800 (Thu, 06 Feb 2014) $
; $LastChangedRevision: 14170 $
; $URL $
;-


function create_ace_tstring,time_array

    ntimes = n_elements(time_array(0,*))
    timestr = make_array(6, ntimes, /string)
    timestr=strcompress(string(time_array))

    ; deal with hours and minutes (parse the hhmm string)
    for i=0, ntimes-1 do Begin
         if (time_array(3,i) lt 100)then Begin
           timestr(3,i)= '0'
           if (time_array(3,i) lt 10) then ndigits=1 else ndigits=2
           hm = strcompress(string(time_array(3,i)))
           timestr(4,i)=strmid(hm, 1, ndigits)
         endif
         if (time_array(3,i) ge 100 and time_array(3,i) lt 1000) then Begin
           hm = strcompress(string(time_array(3,i)))
           timestr(3,i)=strmid(hm, 1, 1)
           timestr(4,i)=strmid(hm, 2, 2)
        endif
        if (time_array(3,i) ge 1000) then Begin
           hm = strcompress(string(time_array(3,i)))
           timestr(3,i)=strmid(hm, 1, 2)
           timestr(4,i)=strmid(hm, 3, 2)
        endif
    endfor

    ; parse year, month, day
    year = strmid(timestr(0,*), 1, 4)
    month = strmid(timestr(1,*), 1, strlen(timestr(1,*)))
    day = strmid(timestr(2,*), 1, strlen(timestr(2,*)))

    ;create the time string
    tstring = strcompress(year+'-'+month+'-'+day+'/'+ timestr(3,*)+':'+timestr(4,*))

    return, tstring

end

pro ace2tplot, data, data_type

  ; create an array of times (time format is double)
  time_array = fix(data.field01[0:5,*])
  ace_tstring = create_ace_tstring(time_array)
  ace_time = reform(time_double(ace_tstring))
  
  ; create variable names and store data
  if (data_type eq 'mag') then Begin
    fields = transpose(reform(data.field01[7:9,*]))
    store_data,'ace_mag',dat={x:(ace_time), y:fields},$
                dlim={ytitle:'Fields, nT', coord:'GSM'}
    store_data,'ace_mag_bt',dat={x:ace_time, y:reform(data.field01[10,*])}
    store_data,'ace_mag_lat',dat={x:ace_time, y:reform(data.field01[11,*])},$
                dlim={ytitle:'Lat, deg'}
    store_data,'ace_mag_lon',dat={x:ace_time, y:reform(data.field01[12,*])},$
                dlim={ytitle:'Lon, deg'}
    store_data,'ace_mag_stat',dat={x:ace_time, y:reform(data.field01[6,*])}
  endif else Begin
    store_data,'ace_swepam_pden',dat={x:ace_time, y:reform(data.field01[7,*])}
    store_data,'ace_swepam_bspd',dat={x:ace_time, y:reform(data.field01[8,*])}
    store_data,'ace_swepam_itmp',dat={x:ace_time, y:reform(data.field01[9,*])}
    store_data,'ace_swepam_stat',dat={x:ace_time, y:reform(data.field01[6,*])}
  endelse

end

pro ace_init, reset=reset, local_data_dir=local_data_dir, remote_data_dir=remote_data_dir

    defsysv,'!ace',exists=exists
    if not keyword_set(exists) then begin
       defsysv,'!ace',  file_retrieve(/structure_format)
    endif

    if keyword_set(reset) then !ace.init=0

    if !ace.init ne 0 then return

    !ace = file_retrieve(/structure_format)
    !ace.local_data_dir = root_data_dir()
    !ace.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/'

    if file_test(!ace.local_data_dir+'ace/.master') then begin ; Local directory IS the master directory
       !ace.no_server=1  
       !ace.no_download=1  ; this line is superfluous
    endif

    if keyword_set(name) then call_procedure,name

    !ace.init = 1
end