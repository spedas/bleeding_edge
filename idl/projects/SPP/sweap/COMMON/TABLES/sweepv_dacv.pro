pro sweepv_dacv, sweepv_dac, $
                 defv1_dac, $
                 defv2_dac, $
                 spv_dac, $
                 k = k, $
                 rmax = rmax, $
                 vmax = vmax, $
                 nen = nen, $
                 e0 = e0, $
                 emax = emax, $
                 spfac = spfac, $
                 maxspen = maxspen, $
                 plot = plot, $
                 hvgain = hvgain, $
                 spgain = spgain, $
                 fixgain = fixgain

message,'obsolete'
  max = 65536.

  if not keyword_set(k)       then k       = 16.7
  if not keyword_set(rmax)    then rmax    = 11.0
  if not keyword_set(vmax)    then vmax    = 4000
  if not keyword_set(nen)     then nen     = 128 
  if not keyword_set(e0)      then e0      = 5.0
  if not keyword_set(emax)    then emax    = 20000.
  if not keyword_set(spfac)   then spfac   = 0.
  if not keyword_set(maxspen) then maxspen = 5000.
  if not keyword_set(hvgain)  then hvgain  = 1000.
  if not keyword_set(spgain)  then spgain  = 20.12
  if not keyword_set(fixgain) then fixgain = 13.
  

  ;;----------------------------------------------
  ;; Generate S-LUT Table
  sweepv_new, sweepv, defv1, defv2, spv, $
              k = k, rmax = rmax, vmax = vmax, $
              nen = nen, e0 = e0, emax = emax, $
              spfac = spfac, maxspen = maxspen, $
              plot = plot
  
  ;;----------------------------------------------
  ;; Change to DAC
  sweepv_dac = max*sweepv/(4*hvgain)
  defv1_dac  = max*defv1/fixgain
  defv2_dac  = max*defv2/fixgain
  spv_dac    = max*spv*sweepv/(4*spgain)

  sweepv_dac = round(sweepv_dac)
  defv1_dac  = round(defv1_dac)
  defv2_dac  = round(defv2_dac)
  spv_dac    = round(spv_dac)
  


  
  nang = 4096/nen
  
  num = fltarr(50)
  for i = 0,49 do begin
     ;; Big fix for low resolution at low end of sweep
     w = where(sweepv_dac le i,nw) 
     num(i) = nw/nang
  endfor
  
  cut = where(indgen(50)-num gt 4)
  thresh = cut(0)
  
  w = where(sweepv_dac le thresh,nw)
  steps = nw/nang
  
  for i = 0,steps-1 do begin
     sweepv_dac(w(i*nang):w(i*nang+nang-1)) = replicate(thresh-i,nang)
  endfor
  
  ;; Fix spoiler at low end to match slut
  spv_dac(w) = round(spv(w)*sweepv_dac(w)*hvgain/spgain) 
  
  if keyword_set(plot) then begin
     window,1
     !p.multi = [0,1,3]
     plot,sweepv_dac,psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep DAC',$
          yrange = [0,max],$
          charsize = 2,$
          /ystyle
     oplot,defv1_dac,color = 50,psym = 10
     oplot,defv2_dac,color = 250,psym = 10
     oplot,spv_dac,color = 150,psym = 10     
     plot,sweepv_dac,psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep DAC (Log)',$
          yrange = [1,max],$
          /ylog,$
          charsize = 2,$
          /ystyle
     oplot,defv1_dac,color = 50,psym = 10
     oplot,defv2_dac,color = 250,psym = 10
     oplot,spv_dac,color = 150,psym = 10
     
     plot,sweepv_dac/max*4*hvgain,psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep (Log)',$
          yrange = [0.1,vmax],$
          /ylog,$
          charsize = 2,$
          /ystyle
     oplot,defv1_dac/max*fixgain*sweepv_dac/max*4*hvgain,color = 50,psym = 10
     oplot,defv2_dac/max*fixgain*sweepv_dac/max*4*hvgain,color = 250,psym = 10
     oplot,spv_dac/max*4*spgain,color = 150,psym = 10
     !p.multi = 0

  endif
    
end
