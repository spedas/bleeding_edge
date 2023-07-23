;+
;Get sc pot from either just the STATIC common blocks, or the routine mvn_scpot, and put into tplot at the STATIC time cadence
;for the specified sta_apid. User specifies which sta apid to use.
;
;sta_apid: string: data product to use, e.g. 'c6', 'd0'. Default is 'c6' if not set (note, all sc potentials in STATIC data products
;                  are ultiamtely from c6 data, but added to the other data products).
;
;By default, this routine will alsorun mvn_scpot, which loads in save files that have the sc potential generated from a combination of 
;SWEA, STATIC and LPW data, for the entire orbit. mvn_scpot will also update the STATIC common blocks, so that all timestamps have a valid 
;sc pot value. There are still some times when the sc pot cannot be calculated, which are set to NaNs in mvn_scpot.
;
;Setting /staticonly will produce the tplot variable using sc potentials stored only in the STATIC common blocks. Note that if you have already
;run mvn_scpot, the STATIC common blocks will already contain the full set of sc pot values and you will have to load in STATIC data 
;using mvn_sta_l2_load again.
;
;
;
;NOTES:
;This routine requires that the STATIC common block is loaded for the relevant data product, by running mvn_sta_l2_load beforehand. The
;common block for c6 data must also be loaded, otherwise, only sc potentials measured by STATIC will be included. c6 data are needed so that
;all other sc potentials can be interpolated to the requested apid timestamps.
;
;EGS:
;timespan, '2019-01-01',1
;mvn_sta_l2_load, sta_apid='c6'
;mvn_sta_tplot_scpot, sta_apid='c6'
;
;The routine produces a tplot variable named mvn_sta_[sta_apid]_cb_scpot, where "cb" stands for common block.
;
;For testing:
;.r /Users/cmfowler/IDL/STATIC_routines/Spacecraft_potential/mvn_sta_tplot_scpot.pro
;
;
;-
;

pro mvn_sta_tplot_scpot, sta_apid=sta_apid, staticonly=staticonly, trange=trange

if not keyword_set(sta_apid) then sta_apid='c6'

if not keyword_set(staticonly) then mvn_scpot  ;obtain full set of sc pot values, and update them into the STATIC common blocks

;Get STATIC common block to get time array:
;Create a tplot variable with the spacecraft potential in:
res = execute("common mvn_"+sta_apid+", get_ind_"+sta_apid+", all_dat_"+sta_apid)

fname = 'mvn_sta_'+sta_apid+'_cb_scpot'  ;tplot variable name on output

if res eq 1 then begin
    resb = execute("type_apid = size(all_dat_"+sta_apid+",/type)")
  
    if type_apid eq 8 then begin
    
        res1 = execute("time1 = all_dat_"+sta_apid+".time")
        res2 = execute("time2 = all_dat_"+sta_apid+".end_time")
        res3 = execute("data = all_dat_"+sta_apid+".sc_pot")
    
        time = time1 + ((time2 - time1)/2.d)  ;mid point in time between each sweep
        
        if keyword_set(trange) then begin
            tinds = where(time ge trange[0] and time le trange[1], ntinds)
            if ntinds gt 1 then begin
                time_save = time[tinds]
                data_save = data[tinds]
            endif else begin
                time_save = !values.f_nan
                data_save = !values.f_nan
            endelse        
        endif else begin
              time_save = time
              data_save = data
        endelse
        
        store_data, fname, data={x: time_save, y: data_save}
            options, fname, ytitle='SC pot!C[V]'
    endif  ;type_apid
  
endif  ;res

   
end


