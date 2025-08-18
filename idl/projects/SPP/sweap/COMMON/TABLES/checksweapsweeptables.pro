pro checksweapsweeptables, slut, $
                           sweepv_dac, $
                           defv1_dac,$
                           defv2_dac,$
                           spv_dac, $
                           fsindex, $
                           tsindex, $
                           index,$
                           edpeak = edpeak, $
                           plot = plot, $
                           k = k, $
                           rmax = rmax, $
                           vmax = vmax, $
                           nen = nen, $
                           e0 = e0, $
                           emax = emax, $
                           spfac = spfac, $
                           maxspen = maxspen, $
                           hvgain = hvgain, $
                           spgain = spgain, $
                           fixgain = fixgain

  max = 65536L
  
  if not keyword_set(k) then k = 16.7
  if not keyword_set(rmax) then rmax = 11.0
  if not keyword_set(vmax) then vmax = 4000
  if not keyword_set(nen) then nen = 128 
  if not keyword_set(e0) then e0 = 5.0
  if not keyword_set(emax) then emax = 20000.
  if not keyword_set(spfac) then spfac = 0.
  if not keyword_set(maxspen) then maxspen = 5000.
  if not keyword_set(hvgain) then hvgain = 1000.
  if not keyword_set(spgain) then spgain = 20.12
  if not keyword_set(fixgain) then fixgain = 13.
  if not keyword_set(edpeak) then edpeak = 0
  
  
  slut = lonarr(4096*4)
  
  blah = long64(0)
  
  openr,1,'slut.txt'
  for i = 0,4095L do begin
     readf,1,blah,format = '(Z08)'
     slut[i*4] = floor(blah/max)
     slut[i*4+1] = blah mod max
     readf,1,blah,format = '(Z08)'
     slut[i*4+2] = floor(blah/max)
     slut[i*4+3] = blah mod max
  endfor
  
  close,1
  
  spv_dac = slut[lindgen(4096)*4]
  sweepv_dac = slut[lindgen(4096)*4+1]
  defv2_dac = slut[lindgen(4096)*4+2]
  defv1_dac = slut[lindgen(4096)*4+3]
  
  sweepv = 1.0*sweepv_dac/max*4*hvgain
  defv1 = 1.0*defv1_dac/max*fixgain
  defv2 = 1.0*defv2_dac/max*fixgain
  spv = 1.0*spv_dac/max*4*spgain/sweepv
  
  if keyword_set(plot) then begin
     window,1
     !p.multi = [0,1,3]
     plot,sweepv_dac,psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep DAC',$
          yrange = [0,max],$
          charsize = 2,$
          /ystyle
     oplot,defv1_dac, color = 50,  psym = 10
     oplot,defv2_dac, color = 250, psym = 10
     oplot,spv_dac,   color = 150, psym = 10     
     plot,sweepv_dac,psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep DAC (Log)',$
          yrange = [1,max],$
          /ylog,$
          charsize = 2,$
          /ystyle
     oplot,defv1_dac, color = 50,  psym = 10
     oplot,defv2_dac, color = 250, psym = 10
     oplot,spv_dac,   color = 150, psym = 10
     plot,sweepv,psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep (Log)',$
          yrange = [0.1,vmax],$
          /ylog,$
          charsize = 2,$
          /ystyle
     oplot,sweepv*defv1, color = 50,  psym = 10
     oplot,sweepv*defv2, color = 250, psym = 10
     oplot,sweepv*spv,   color = 150, psym = 10
     !p.multi = 0
  endif
  
  
  
  fsindex = lonarr(1024)  
  blah = long64(0)
  openr,1,'fslut.txt'
  for i = 0,255L do begin
     readf,1,blah,format = '(Z08)'
     fsindex[i*4] = floor(blah/max) mod 4096L
     fsindex[i*4+1] = (blah mod max) mod 4096L
     readf,1,blah,format = '(Z08)'
     fsindex[i*4+2] = floor(blah/max) mod 4096L
     fsindex[i*4+3] = (blah mod max) mod 4096L
  endfor
  
  close,1
  
  
  
  if keyword_set(plot) then begin
     window,2
     !p.multi = [0,1,3]
     plot,sweepv[fsindex],psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage',$
          yrange = [0,4000],$
          charsize = 2
     oplot,defv1[fsindex]*sweepv[fsindex],color = 50, psym = 10
     oplot,defv2[fsindex]*sweepv[fsindex],color = 250,psym = 10
     plot,sweepv[fsindex],psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage (Log)',$
          yrange = [0.1,4000],$
          /ylog,$
          charsize = 2,$
          /ystyle
     oplot,defv1[fsindex]*sweepv[fsindex],color = 50,  psym = 10
     oplot,defv2[fsindex]*sweepv[fsindex],color = 250, psym = 10
     oplot,spv[fsindex]*sweepv[fsindex],  color = 150, psym = 10     
     plot,defv1[fsindex],psym = 10, $
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage Ratio',$
          charsize = 2,$
          yrange = [0,12]
     oplot,defv1[fsindex],color = 50,  psym=10
     oplot,defv2[fsindex],color = 250, psym = 10
     oplot,spv[fsindex],  color = 150, psym = 10
     !p.multi = 0

     window,4
     plot,sweepv,defv1-defv2,$
          psym = 7,$
          /xlog, $
          xtitle = 'V_SWEEP (Volts)',$
          ytitle = 'V_DEF/V_SWEEP (D1+, D2-)',$
          charsize = 2,$
          /xstyle,$
          /ystyle
     plots,sweepv[fsindex],defv1[fsindex]-defv2[fsindex], $
           psym = 7,$
           color = 150
  endif
  
  
  index = lonarr(65536L)  
  blah = long64(0)  
  openr,1,'tslut.txt'
  for i = 0,32767L do begin
     readf,1,blah,format = '(Z08)'
     index[i*2] = floor(blah/max)
     index[i*2+1] = (blah mod max)
  endfor  
  close,1
  
  tsindex = index[edpeak*256L:edpeak*256L+255]
  if keyword_set(plot) then begin
     window,3
     !p.multi = [0,1,3]
     plot,sweepv[tsindex],$
          psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage',$
          yrange = [0,4000],$
          charsize = 2
     oplot,defv1[tsindex]*sweepv[tsindex], color = 50,  psym = 10
     oplot,defv2[tsindex]*sweepv[tsindex], color = 250, psym = 10
     plot,sweepv[tsindex],psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage (Log)',$
          yrange = [0.1,4000],$
          /ylog,$
          charsize = 2,$
          /ystyle
     oplot,defv1[tsindex]*sweepv[tsindex], color = 50,  psym = 10
     oplot,defv2[tsindex]*sweepv[tsindex], color = 250, psym = 10
     oplot,spv[tsindex]*sweepv[tsindex],   color = 150, psym = 10
     plot,defv1[tsindex],psym = 10, $
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage Ratio',$
          charsize = 2,$
          yrange = [0,12]
     oplot,defv1[tsindex],psym=10,color = 50
     oplot,defv2[tsindex],color = 250,psym = 10
     oplot,spv[tsindex],color = 150,psym = 10
     !p.multi = 0
     
     window,5
     plot,sweepv,defv1-defv2,$
          psym = 7,$
          /xlog, $
          xtitle = 'V_SWEEP (Volts)',$
          ytitle = 'V_DEF/V_SWEEP (D1+, D2-)',$
          charsize = 2,$
          /xstyle,$
          /ystyle
     plots,sweepv[tsindex],defv1[tsindex]-defv2[tsindex],$
           psym = 7,$
           color = 150
  endif



end

