function thm_fgm_find_shift_1p1c, b, threshold, th_slope, jump, $
	                      constant=constant, fixed=fixed, datatype=datatype, calc_freq=calc_freq
;+
; Function: thm_fgm_find_shift_1p1c
;
; Description:       Returns the vector to be added to l1 data to correct 
;	             the '390 nT' jumps for one probe and one component.
;
; Input: 
;
;   b =              the uncorrected measurements
;
;   threshold =      threshold matrix (probe x component). A jump occurs when the field
;                    crosses this value. Note that the actual threshold depends on the 
;                    field derivative. The value given here is for constant field (th0).            
;
;   th_slope =       slope of the threshold: threshold=th0+th_slope*(db/dt)
;                    
;   jump =           jump matrix (probe x component). The expected values of the jumps.
;
;   datatype=        'fgl' or        -> low resolution   (4Hz)
;                    'fgh' or        -> high resolution  (128 Hz)
;                    'fge'           -> engeneering data (8 Hz)
;
; Keywords:
;
;   /fixed:          take the correction from the jump matrix. Default for fgh
;                    is to  compute the correction for each jump such  way that
;                    the first derivative is constant across the jump from low
;                    to high values. It has no effect for fge or fgl data for 
;                    which the correction is taken by default from the jump
;                    matrix.     
;                    
;   /constant:       average the correction over all jumps for fgh. It has no 
;                    effect for fge or fgl.
;
; Return value:      the correction vector
;
; Example: 
;
;  corr = thm_fgm_find_shift_1p1c(b, th_up, th_dn, jump, /constant, datatype='fgh')
;
; Notes
;	- this function is used by fgm_find_shift
;
; Written by Dragos Constantinescu
; 
; Minor modifications by Patrick Cruce for incorporation into TDAS.
; Specifically:  
;    1. Changed Function Name
;    2. Disabled output of statistics to file.
; 
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-09-16 10:41:52 -0700 (Wed, 16 Sep 2015) $
;$LastChangedRevision: 18806 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_fgm_find_shift_1p1c.pro $
;-

  if (datatype ne 'fgh') then begin
    constant=0 & fixed=0
  endif
;  else begin                  ; only used to build statistics for better determination
;      openw, 1, 'stats_up.dat'      ; of thresholds and offset values
;      openw, 2, 'stats_down.dat'    ;
;  endelse
  
  n=n_elements(b)
  correction=0
  b_shift=dblarr(n) & avgcor = 0.d0 & count=0l
  for i=2l,n-2l do begin
    db1=abs(b[i]-b[i-1])    ; change rate (1st deriv) - compromised if just after jump
    db2=abs(b[i-1]-b[i-2])  ; change rate (1st deriv)
    db=abs(db1-db2)         ; difference ... (2nd deriv) =0 if linear 
    
    ; >>>>>>>>>>> FGH <<<<<<<<<<<<<<
    if (datatype eq 'fgh') then begin
      threshold_up=  threshold+th_slope*db2
      threshold_down=threshold-th_slope*db2
      ; correction for i using i-1 and i-2
      if (correction eq 0) then begin
        if ((b[i] ge threshold_up) and $     ; above threshold
            (b[i] ge b[i-1]) and $           ; increasing
            (db le 10.0^6) and $             ; (10^6 DU =~ 3000 nT)
            (db ge jump*(2.d0/3.d0)) $       ; jump occurs - subunitary factor necessary
                                     $       ; because uncertainty in offset 
           ) then begin
            correction=-db      ; assume linear field variation
           ; printf,1,b[i-1],db2,db,b[i] ; value before jump, slope, jump, value after 
            if (keyword_set(fixed)) then correction=-jump   
            if (abs(correction) le 1.5*jump) then avgcor+=correction 
            count+=1
        endif 
      endif
      if ((correction ne 0) and $
          (b[i] le threshold_down) and $  ; below threshold
          (b[i] le b[i-1]) and $          ; decreasing
          (db le 10.0^6) and $            ; (10^6 DU =~ 3000 nT)
          (db ge jump*(2.d0/3.d0))$       ; jump occurs          
         ) then begin
        correction=0
       ; printf,2,b[i-1],db2,db,b[i] ; value before recovery, slope, jump, value after
      endif
    endif
    ;--------------------------------
    
    ; >>>>>>>>>>> FGE <<<<<<<<<<<<<<
    if (datatype eq 'fge') then begin
      threshold_up=  threshold+th_slope*db2/16.0
      threshold_down=threshold-th_slope*db2/16.0
      ;correction for i
      if ((correction eq 0) and $
          (b[i] ge threshold_up) and $
          (b[i] ge b[i-1]) $
         ) then begin
        correction=-jump
        avgcor+=correction
        count+=1
      endif
      if ((correction ne 0) and $
          (b[i] le threshold_down) $
         ) then begin
        correction=0
      endif
    endif
    ;--------------------------------
    
    
    ; >>>>>>>>>>> FGL <<<<<<<<<<<<<<
    if (datatype eq 'fgl') then begin
      ; these are averaged data, we have to guess when the threshold
      ; has been crossed. 
      ; correction for i, using i-1 and i+1 
      threshold_up=  threshold+th_slope*(abs(b[i+1]-b[i-1])/2.0)*(calc_freq/128.0)
      threshold_down=threshold-th_slope*(abs(b[i+1]-b[i-1])/2.0)*(calc_freq/128.0)
      
      ; no correction:
      if (((b[i-1]+b[i])/2.0 lt threshold_down) and $
          ((b[i]+b[i+1])/2.0 lt threshold_down)) then correction=0
      
      ; parial correction, b[i] max (b[i-1]<b[i]>b[i+1])
      if (((b[i-1]+b[i])/2.0 lt threshold_up) and $
          ( b[i] gt threshold_up) and $
          ((b[i]+b[i+1])/2.0 lt threshold_up)) then begin
        if ((b[i]+b[i+1])/2.0 gt threshold_down) then begin
          w=0.5+double(b[i]-threshold_up)/(b[i]-b[i-1])
        endif else begin
          w=double(b[i]-threshold_up)/(b[i]-b[i-1])+ $
            double(b[i]-threshold_down)/(b[i]-b[i+1])
        endelse
        correction=-round(w*jump) 
        avgcor+=correction & count+=1
      endif   
       
      ; partial correction, increasing
      if (( (b[i-1]+b[i])/2.0 lt threshold_up      ) and $ 
          ( threshold_up      lt (b[i]+b[i+1])/2.0 )     $ 
         ) then begin 
         if threshold_up lt b[i] then begin
           w=0.5+double(b[i]-threshold_up)/(b[i]-b[i-1]) 
         endif else begin
           if (b[i] eq b[i+1]) then begin ; do not divide by 0
             w=0.5
           endif else begin
             w=0.5-double(threshold_up-b[i])/(b[i+1]-b[i])
           endelse
         endelse
         correction=-round(w*jump) 
         avgcor+=correction & count+=1
       endif
       
       ; full correction
       if (((b[i-1]+b[i])/2.0 gt threshold_up) and $
           ((b[i]+b[i+1])/2.0 gt threshold_up)) then begin 
         correction=-jump 
       endif

       ; partial correction, decreasing
       if (( (b[i-1]+b[i])/2.0 gt  threshold_down   ) and $ 
           ( threshold_down    gt (b[i]+b[i+1])/2.0 )     $
          ) then begin
         if (threshold_down gt b[i]) then begin
           w=0.5-double(threshold_down-b[i])/(b[i-1]-b[i])
         endif else begin
           if (b[i] eq b[i+1]) then begin ; do not divide by 0
             w=0.5 
           endif else begin
             w=0.5+double(b[i]-threshold_down)/(b[i]-b[i+1])
           endelse
         endelse
         correction=-round(w*jump) 
       endif
       
    endif
    ;--------------------------------
    
    if (correction ne 0) then b_shift[i]=1l
    if (not keyword_set(constant)) then b_shift[i]=correction
  endfor
  
  if (count ne 0) then avgcor/=double(count)
  avgcor=round(avgcor)
  if (keyword_set(constant)) then b_shift*=avgcor
  dprint, dlevel=4,  "corrected ", count, " jumps,    (mean corr: ", avgcor, " )"
  
;  if (datatype eq 'fgh') then begin
;    if (not keyword_set(fixed)) then begin
;      openw, 3, 'stats_jumps.dat'
;      printf,3, avgcor
;      close,3
;    endif
;    close,1
;    close,2
;  endif
  
  return, b_shift
end

;-----------------------------------------------------
