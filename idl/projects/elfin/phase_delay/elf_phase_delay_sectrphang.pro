;+
; FUNCTION:
;          
;
; PURPOSE:
;         elf_phase_delay_SectrPhAng
;         
; KEYWORDS:
;         current_median = current median value 
;         angpersector = current angle per sector.
;
; OUTPUT:
;         latestmediansectr = latest median sector to add
;         latestmedianphang = latest median phase angle to add
;
;
;VERSION LAST EDITED: akroosnovo@gmail.com, jwu@epss.ucla.edu 02/27/2022

; function to determine Sectr and PhAng for phase delay 
pro elf_phase_delay_SectrPhAng, current_median, angpersector, LatestMedianSectr=LatestMedianSectr, LatestMedianPhAng=LatestMedianPhAng
  case 1 of
    (abs(current_median) gt angpersector*11.5) and (abs(current_median) le angpersector*12.5):begin
      LatestMedianSectr=round(12*sign(current_median))
      LatestMedianPhAng=current_median-12*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*10.5) and (abs(current_median) le angpersector*11.5):begin
      LatestMedianSectr=round(11*sign(current_median))
      LatestMedianPhAng=current_median-11*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*9.5) and (abs(current_median) le angpersector*10.5):begin
      LatestMedianSectr=round(10*sign(current_median))
      LatestMedianPhAng=current_median-10*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*8.5) and (abs(current_median) le angpersector*9.5):begin
      LatestMedianSectr=round(9*sign(current_median))
      LatestMedianPhAng=current_median-9*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*7.5) and (abs(current_median) le angpersector*8.5):begin
      LatestMedianSectr=round(8*sign(current_median))
      LatestMedianPhAng=current_median-8*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*6.5) and (abs(current_median) le angpersector*7.5):begin
      LatestMedianSectr=round(7*sign(current_median))
      LatestMedianPhAng=current_median-7*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*5.5) and (abs(current_median) le angpersector*6.5):begin
      LatestMedianSectr=round(6*sign(current_median))
      LatestMedianPhAng=current_median-6*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*4.5) and (abs(current_median) le angpersector*5.5):begin
      LatestMedianSectr=round(5*sign(current_median))
      LatestMedianPhAng=current_median-5*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*3.5) and (abs(current_median) le angpersector*4.5):begin
      LatestMedianSectr=round(4*sign(current_median))
      LatestMedianPhAng=current_median-4*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*2.5) and (abs(current_median) le angpersector*3.5):begin
      LatestMedianSectr=round(3*sign(current_median))
      LatestMedianPhAng=current_median-3*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*1.5) and (abs(current_median) le angpersector*2.5):begin
      LatestMedianSectr=round(2*sign(current_median))
      LatestMedianPhAng=current_median-2*angpersector*sign(current_median)
    end
    (abs(current_median) gt angpersector*0.5) and (abs(current_median) le angpersector*1.5):begin
      LatestMedianSectr=round(1*sign(current_median))
      LatestMedianPhAng=current_median-angpersector*sign(current_median)
    end
    (abs(current_median) le angpersector*0.5):begin
      LatestMedianSectr = 0
      LatestMedianPhAng = current_median
    end
    else: print,'ERROR: median convert fail!'
  endcase
  
  ;  if abs(current_median) gt angpersector*2.5 then begin
  ;    LatestMedianSectr=round(3*sign(current_median))
  ;    LatestMedianPhAng=current_median-3*angpersector*sign(current_median)
  ;  endif else if abs(current_median) gt angpersector*1.5 then begin
  ;    LatestMedianSectr=round(2*sign(current_median))
  ;    LatestMedianPhAng=current_median-2*angpersector*sign(current_median)
  ;  endif else if abs(current_median) gt angpersector*0.5 then begin
  ;    ;and abs(abs(current_median)-angpersector) le 11 then begin
  ;    LatestMedianSectr=round(1*sign(current_median))
  ;    LatestMedianPhAng=current_median-angpersector*sign(current_median)
  ;  endif else if abs(current_median) le angpersector*0.5 then begin
  ;    LatestMedianSectr = 0
  ;    LatestMedianPhAng = current_median
  ;    ;if abs(current_median) ge 11 or abs(abs(current_median)-angpersector) le 11 then begin
  ;    ;  LatestMedianSectr=round(1*sign(current_median))
  ;    ;  LatestMedianPhAng=current_median-angpersector*sign(current_median)
  ;    ;endif else if abs(current_median) gt 34 then begin
  ;    ;  LatestMedianSectr=round(2*sign(current_median))
  ;    ;  LatestMedianPhAng=current_median-2*angpersector*sign(current_median)
  ;    ;endif else if abs(current_median) gt 56.5 then begin
  ;    ;  LatestMedianSectr=round(3*sign(current_median))
  ;    ;  LatestMedianPhAng=current_median-3*angpersector*sign(current_median)
  ;    ;endif else if abs(current_median) le 11 then begin
  ;    ;  LatestMedianSectr = 0
  ;    ;  LatestMedianPhAng = current_median
  ;  endif else begin
  ;    print, 'no recognized median'
  ;  endelse

end