pro mvn_lpw_cdf_check_vars, tplot_var

;+
;Program written by CF on May 1st 2014. Routine checks dlimit and limit fields of the given tplot variable and ensures there are no
;blank string entries ' ' as these cause mvn_lpw_cdf_save_vars to crash.
;
;INPUTS:
; tplot_var: string, tplot variable name to be checked
; 
;OUTPUTS:
; routine will replace any '' entries in dlimit and limit with 'N/A', and restore tplot variable.
; 
;  Version 1.0
; 
;MODIFICATONS:
;
;;140718 clean up for check out L. Andersson
;
;-


tplotnames = tnames()  ;list of tplot names in memory

if total(strmatch(tplotnames, tplot_var)) eq 1 then begin
    get_data, tplot_var, data=dd, dlimit=dl, limit=ll
    
    change = 0  ;how many changes we make
    ;Check dlimit fields:
    nele_dl = n_tags(dl)  ;number of tags in structure dl
    for aa = 0, nele_dl-1 do begin
       ; if n_elements(dl.(aa)) eq 1 then begin
            if (size(dl.(aa)[0], /type) eq 7) and dl.(aa)[0] eq '' then begin
                dl.(aa)[*] = 'N/A'
                change += 1
            endif
      ;  endif else begin
      ;      if dl.(aa)[0] eq '' then begin
      ;          dl.(aa)[*] = 'N/A'  ;convert all entries to N/A if it's an array
      ;          change += 1
      ;      endif
      ;  endelse        
    endfor  ;over aa  
    
    nele_ll = n_tags(ll)
    for aa = 0, nele_ll-1 do begin
      ;  if n_elements(ll.(aa)) eq 1 then begin
      ;      if ll.(aa) eq '' then begin
      ;          ll.(aa) = 'N/A'
      ;          change += 1
      ;      endif
      ;  endif else begin
            if (size(ll.(aa)[0], /type) eq 7) and (ll.(aa)[0] eq '') then begin
                ll.(aa)[*] = 'N/A'  ;convert all entries to N/A if it's an array
                change += 1
            endif
      ;  endelse        
    endfor  ;over aa

    if change gt 0 then store_data, tplot_var, data=dd, dlimit=dl, limit=ll  ;only restore if we had to change some of the fields

endif else begin
    print, "### WARNING ###: can't find tplot variable ", tplot_var, " in IDL memory. Check it is loaded. Returning to IDL terminal."
    retall
endelse


;stop

end


