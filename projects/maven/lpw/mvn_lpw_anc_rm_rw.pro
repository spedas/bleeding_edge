
;+
;
;
;
;
; ;140718 clean up for check out L. Andersson
;  Version 1.0
;-

pro mvn_lpw_anc_rm_rw

;Get data from lf spectra
tplotnames = tnames()
name = 'mvn_lpw_anc_rm_rw'  ;routine name

;=======================
;Get spectra and RW info:
if total(strmatch(tplotnames, 'mvn_lpw_spec_lf_pas')) eq 1 then begin
    get_data, 'mvn_lpw_spec_lf_pas', data=dd1, dlimit=dl1, limit=ll1
    print, name, ": mvn_lpw_spec_lf_pas data available"
endif
if total(strmatch(tplotnames, 'mvn_lpw_spec_lf_act')) eq 1 then begin
    get_data, 'mvn_lpw_spec_lf_act', data=dd2, dlimit=dl2, limit=ll2
    print, name, ": mvn_lpw_spec_lf_act data available"
endif
if total(strmatch(tplotnames, 'mvn_lpw_anc_rw')) eq 1 then begin
    get_data, 'mvn_lpw_anc_rw', data=dd3, dlimit=dl3, limit=ll3
    print, name, ": mvn_lpw_anc_rw data available"
endif

if (size(dd3, /type) eq 0) then begin
    print, "### WARNING ### ", name, ": no reaction wheel information available. Exiting."
    retall
endif 
if (size(dd1, /type) eq 0) and (size(dd2, /type) eq 0) then begin
    print, "### WARNING ### ", name, ": no pas or act spectra data available. Exiting."
    retall
endif
;=======================
;Calculate how close together the RW are in freq
;=======================
;Looks as though we only see them when they overlap very closely in freq:
;Set RW 1 as the 'bsaeline', and compare abs freq to this:
nele_rw = n_elements(dd3.x)
rel_rw = fltarr(nele_rw,3)
for aa = 1, 3 do rel_rw[*,aa-1] = abs(dd3.y[*,0] - dd3.y[*,aa])


;=======================
;Go through orbit and determine some sort of spectra of the RW signature itself
;Passive data:
if size(dd1, /type) eq 8 then begin  ;dd1 is a structure
    nele_dd1 = n_elements(dd1.x)  ;number of spec data points
    winsize=5  ;number of timesteps to span anaveraging window over
    for ii = 0, nele_dd1-1-winsize do begin
        time = dd1.x[ii]
        tt = where(dd3.x gt time, ntt)
        if ntt ne -1 then begin   ;if we have RW coverage
            if tt[0] - time lt 120. then begin  ;make sure RW data is within 2 mins of data; not sure how reliable the RW timesteps are at being constant
                rw_time = tt[0] 
                rw_spd = dd3.
                
                
            endif
            
        endif else begin ;over ntt ne -1: no RW coverage left so come out of for loop
            ;### Do something here when no more RW coverage for this data point
        endelse
    
    endfor  ;over ii
    
    

endif  ;over dd1 type eq 8

;Go back over orbit and subtract the RW signature as a function of time?

;Save as new tplot variable











stop

end


