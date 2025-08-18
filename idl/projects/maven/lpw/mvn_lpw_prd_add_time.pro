
; check if new additional time steps should be added to the data_l2_x array
;
; 2016-05-03: CMF: modification to routine for spectra packets. You must set type to 'spectra'. This prevents time stamps being added that are too close together
;                  in time that are identical time steps. This only affects spectra. Do not set type at all for other products - the routine will use the old method in this case.
;
;
;
pro  mvn_lpw_prd_add_time,data_l2_x,data, type

       IF size(data, /type) EQ 8 THEN  BEGIN
            
            if size(type,/type) eq 0. then type = 'another' 
            
            if type eq 'spectra' then begin
                ;The closest points can be in time is 4s (when we had 4s master cycle).
                ;So, if data is being added to data_l2_x, then the points added cannot be closer than 4s to any of those in data_l2_x.
                ;Based on 2015-10-01, the closest time is 3.9996676445007324d in data_l2_x, before additional points are added. So, lets only allow
                ;points to be added from data, if they are at 3.8s away from all data points in data_l2_x.
                          
                
                nele1 = n_elements(data_l2_x)
                nele2 = n_elements(data.x)
                val = 3.8d  ;points must be at least this length in seconds away from all other points data_l2_x
                
                for ii = 0., nele2-1. do begin
                    Ttmp = data.x[ii]
                    diff = abs(data_l2_x - Ttmp)
                    m1 = min(diff, /nan)
                    if (m1 gt val) then tmp_arr0=[data_l2_x, Ttmp]  ;add in the time stamp if it's not too close to any others        
                 
                endfor   ;ii
                
                tmp_nn0 = sort(tmp_arr0)
                data_l2_x = tmp_arr0[tmp_nn0]  ;into time order
            endif else begin                                   
                tmp_arr0=[data_l2_x,data.x]
                tmp_nn0=sort(tmp_arr0)            
                tmp_arr1=tmp_arr0(tmp_nn0)
                tmp_nn1=UNIQ(tmp_arr1)
                data_l2_x=tmp_arr1(tmp_nn1)
            endelse
          
       ENDIF

end