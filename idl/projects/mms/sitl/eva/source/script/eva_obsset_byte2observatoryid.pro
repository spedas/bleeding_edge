; This program converts the 'OBSSET' byte value to the 'ObservatoryID' string.  
; The string value shall be “ALL” or a comma separated list with one or more of these 
; Observatory IDs: “MMS1”, “MMS2”, “MMS3”, “MMS4”
;
; $LastChangedBy: moka $
; $LastChangedDate: 2023-08-21 20:46:44 -0700 (Mon, 21 Aug 2023) $
; $LastChangedRevision: 32050 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/script/eva_obsset_byte2observatoryid.pro $
FUNCTION eva_obsset_byte2observatoryID, this_byte 
  compile_opt idl2
  
  bitarray = eva_obsset_byte2bitarray(this_byte)
  
  if(array_equal(bitarray, [1,1,1,1]))then begin
    observatoryID = 'ALL'
  endif else begin
    observatoryID = '' ; add dummy
    imax = 4
    for i=0,imax-1 do begin
      if(bitarray[i] eq 1) then begin
        observatoryID = [observatoryID, 'MMS'+strtrim(string(i+1),2)]
      endif
    endfor
    if n_elements(observatoryID) gt 1 then begin
      jmax = n_elements(observatoryID)
      observatoryID = observatoryID[1:jmax-1]; remove dummy
      observatoryID = strjoin(observatoryID,',')
    endif
  endelse
  return, observatoryID
END
