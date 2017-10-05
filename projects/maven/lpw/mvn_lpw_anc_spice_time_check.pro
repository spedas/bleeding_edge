function mvn_lpw_anc_spice_time_check, et_last

;+
;Program written by CF on April 26th 2014. Routine takes an input ET time, and checks to see if it is in the predicted or reconstructed part of the MAVEN
;sclk kernel.
;
;USAGE: 
;last_et_time_in_kernel = mvn_lpw_spice_time_check
;
;INPUTS: 
;- et_last: the last timestamp of the orbit to be checked, in ET time
;
;OUTPUTS: Double precision ET time of the last reconstructed kernel time in the laoded MAVEN sclk kernel.
;
;NOTES: This routine requires that a MAVEN LSK and SCLK kernel are loaded. Routine will return that all times are predicted if these are not present.
;
; Version 1.0
;
;CREATED: By Chris Fowler, 26th April 2014.
;LAST MODIFICATION:
;04/29/14 CF: finished routine. Routine now returns a string, 'Reconstructed' or 'Predicted', which is added to dlimit.time_field and also the xtitle.
;140718 clean up for check out L. Andersson
;-

if (size(et_last, /type) ne 5) or (n_elements(et_last) ne 1) then begin
    print, "#### WARNING ####: mvn_lpw_anc_spice_time_check: et_last must be a single double precision number; the last time in the data set you want to look at."
    retall
endif


;These names won't change over time, they are arrays in all versions of the kernel files:
name1 = 'SCLK01_COEFFICIENTS_202'  ;kernel times in MAVEN sclk file
name2 = 'DELTET/DELTA_AT'  ;check lsk is loaded

;Check sclk file is loaded:
cspice_dtpool, name1, found1, n, type1   ;type: n = numbers, c = characters
if (found1 eq 1) and (type1 eq 'N') then begin
    ;Extract second to last value in the array, which is the last reconstructed time:
    cspice_gdpool, name1, n-2, 1, value, found2   ;second to last point is n-2 (IDL counting!)
    
    if (found2 eq 1) then begin  ;if IDL was able to pull at the second to last point above...
        ;Check for lsk file:
        cspice_dtpool, name2, found3, n, type3  ;check we have the lsk file loaded...
        
        if (found3 eq 1) then begin  ;if lsk file is loaded...
            et_klast = cspice_unitim( value[0], 'TDT', 'ET')  ;convert last reconstructed kernel time to ET time.
            ;Is et_last <= et_klast?
            if et_last le et_klast then result = "(Reconstructed)" else result = "(Predicted)"
           
            return, result  ;return the dbl last time, ET.
        endif else begin
            print, "#### WARNING ####: No leapsecond kernel loaded. This must be loaded to check for reconstructed kernel times. Exiting."
            result = 'PREDICTED: NO_LSK_KERNEL_FOUND'
            return, result
        endelse  ;over found3
   endif else begin
      print, "#### WARNING ####: No sclk data found. Check correct sclk kernel is loaded. Exiting."
      result = 'PREDICTED: NO_SCLK_KERNEL_DATA_FOUND'
      return, result
   endelse  ;over found2
endif else begin
    print, "#### WARNING ####: MAVEN sclk kernel not loaded. Can't use SPICE!. Exiting."
    result = 'PREDICTED: NO_SCLK_KERNEL_FOUND'
    return, result
endelse  ;over found1

;return, 1
end



