;+
; PURPOSE: 
; determine spacecraft is inside or outside the magnetopause, according to the Fairfield model (JGR, 1971)
; assume magnetopause is symmetrical around x axis, in other words, magnetopause is a circle in yz plane
; 
; INPUT:
;   SC x: spacecraft position (RE)
;   SC y: spacecraft position (RE)
;   SC z: spacecraft position (RE)
;   xmp: magnetopasue position (RE)
;   ymp: magnetopasue position (RE)
;   
; OUTPUT:
;   mpauseflag: 1 spacecraft inside magnetopause
;               0 spacecraft outside magnetopause
;               
; NOTES:
;   To be used with mpause_2
;   
; AUTHOR:
;      Jiashu Wu, 2021-08-10
;-
pro mpause_flag, xSC, ySC, zSC, xmp, ymp, mpauseflag=mpauseflag
  if (n_elements(xSC) ne n_elements(ySC)) or (n_elements(ySC) ne n_elements(zSC)) then begin
    print,'mpause_flag: SCxyz not same size!'
    return
  endif
  if (n_elements(xmp) ne n_elements(ymp)) then begin
    print,'mpause_flag: MPxy not same size!'
    return
  endif
  rsc = sqrt(ySC^2+xSC^2) ;SC radius at yz plane
  index = indgen(n_elements(xSC))
  mpauseflag = make_array(n_elements(xSC), value=0) 
  for sca=0,n_elements(rsc)-1 do begin
    if xSC[sca] lt max(xmp) then begin ; if xSC > xmp peak, definitely outside
      X_ind = where(xmp[index] ge xSC[sca] and xmp[index+1] lt xSC[sca],count) ; search for xSC=xmp
      if count gt 1 then begin
        print,'mpause_flag: multiple index selected, please check'
        return
      endif 
      if rsc[sca] le abs(ymp[X_ind]) then begin ; compare SC radius with MP radius in the slice of xSC=xmp
        mpauseflag[sca] = 1
      endif
    endif
  endfor
  
end