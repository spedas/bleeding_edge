;+
;Routine to find appropriate points.
;
;Inputs: For REE, 1 = boom1, 2 = boom2
;vswp1[*,128]   <= fitstruc.lpstruc.data.vswp / iswp
;iswp1[*,128]
;timeIn1[*]  <= fitstruc.lpstruc.time
;ErrA1[*]    <= fitstruc.lpstruc.ree.val.ErrA
;N1[*]       <= fitstruc.lpstruc.ree.val.N
;T1[*]       <= fitstruc.lpstruc.ree.val.Te
;valid1[*]   <= fitstruc.lpstruc.ree.val.valid
;vswp2
;iswp2
;timeIn2
;ErrA2
;N2
;T2
;valid2[*]
;
;Returns:
;indices of matching useable points for both booms in an array [*,2] long, or the string 'none_found'
;
;-
;

function mvn_lpw_prd_iv_find_points2, vswp1, iswp1, timeIn1, ErrAIn1, NeIn1, TeIn1, valid1, vswp2, iswp2, timeIn2, ErrAIn2, NeIn2, TeIn2, valid2


;Take data from lp1 and lp2:

;print,'#### ', n_elements(vswp1[*,0])
neleswp = n_elements(vswp1[*,0])
tmp = where(valid1 eq 1, ntmp)
indsf = fltarr(1,2)

for jj = 0, neleswp-1 do begin
    time1 = timeIn1[jj]
    valid = valid1[jj]
    inds1 = where((timeIn2 ge time1) and (timeIn2 - time1) lt 10. and (valid eq 1), ninds1)
  
    if ninds1 gt 0 then begin
        jj2 = inds1[0]  ;take first point
        N1 = NeIn1[jj]
        N2 = NeIN2[jj2]
        T1 = TeIn1[jj]
        T2 = TeIn2[jj2]
   
   
  ; help, vswp1,    iswp1
  ; print,jj,jj2
        ;Check for single or BiDir sweeps. BiDir have more error inherently.
        swpInfo1 = mvn_lpw_prd_iv_sweep_info(vswp1[jj,*], iswp1[jj,*])
        swpInfo2 = mvn_lpw_prd_iv_sweep_info(vswp2[jj2,*], iswp2[jj2,*])
        
        if swpInfo1.BiDir eq 0. then errA1 = 10. else errA1 = 35.
        if swpInfo2.BiDir eq 0. then errA2 = 10. else errA2 = 35.        
       
        if ( (ErrAIn1[jj] lt errA1) and (ErrAIn2[jj2] lt errA2) and ((abs(N1 - N2)/N1) lt 0.4) and ((abs(T1 - T2)/T1) lt 0.4) ) then yes = 1. else yes = 0.
          if yes eq 0. then begin
              if ((ErrAIn1[jj] lt errA1) and (ErrAIn2[jj2] lt errA2) and ((abs(N1 - N2)/N1) lt 0.2)) then yes = 1.           
          endif
          if yes eq 0. then begin
              if ((ErrAIn1[jj] lt 50.) and (ErrAIn2[jj2] lt errA2) and ((abs(N1 - N2)/N1) lt 0.4) and ((abs(T1 - T2)/T1) lt 0.4) ) then yes = 1.
          endif
          if yes eq 0. then begin
            if ((ErrAIn1[jj] lt 50.) and (ErrAIn2[jj2] lt errA2) and ((abs(N1 - N2)/N1) lt 0.2) and ((abs(T1 - T2)/T1) lt 0.8) ) then yes = 1.
          endif          
          
;    
    
    
        if yes eq 1. then indsf = [indsf, [[jj], [jj2]]]       
    endif
endfor

neleF = n_elements(indsf[*,0])

if neleF gt 1 then begin
    indsf = indsf[1:neleF-1,*] 
    neleF -= 1.
    print, neleF, " out of ", ntmp, " points found."
endif else begin
  indsf = 'none_found'
  print, "No points found."
endelse

return, indsf

end


;.r /Users/chfo8135/IDL/MAVEN/Software/compare_fits/find_points.pro
;res = find_points(lp1,lp2)
;;store_data, 'Val', data={x:lp1[res[*,0]].time, y:fltarr(n_elements(res))+1}
;ylim, 'Val', [-1,2]