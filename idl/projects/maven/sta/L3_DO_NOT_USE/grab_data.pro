;+
;Grab data for a set span of dates.
;
;d1, d2: 'yyyy-mm-dd': start and stop times
;
;grab_data, '2017-12-14', '2017-12-28'   ;two weeks from COI campaign
;
;.r /Users/cmfowler/IDL/STATIC_routines/Density_routines/grab_data.pro
;-
;

pro grab_data, d1, d2

t1 = time_double(d1)
t2 = time_double(d2)

ndays = long(floor((t2-t1)/86400d))

;Get SPICE kernels for entire time range:
time = (dindgen(ndays)*86400d)+t1

mvn_lpw_anc_get_spice_kernels, time, /notatlasp  ;don't load, just download

for dd = 0l, ndays-1l do begin
    store_data, '*', /delete
    
    dateTMP = time_string(t1 + (dd*86400d), precision=-3)
    
    timespan, dateTMP, 1.
    
    ;mvn_sta_l2_load, sta_apid=['c6', 'ca']
    mvn_sta_l2_load, sta_apid=['d1', 'c8']
    
   ; mvn_lpw_load_l2, ['lpnt', 'lpiv'], /notplot
  
endfor

end


