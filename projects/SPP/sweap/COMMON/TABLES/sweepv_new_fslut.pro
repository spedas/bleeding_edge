pro sweepv_new_fslut, sweepv, $
                      defv1, $
                      defv2, $
                      spv, $
                      index,$
                      nen = nen, $
                      plot = plot, $
                      spfac = spfac
  
message,'obsolete'

  ;; NOTE: Need to add peak-detect bit to 
  ;; this when I make it into a table
  
  ;; Number of energies in coarse sweep 
  ;; (full table has 4x as many)
  if not keyword_set(nen) then nen = 32 


  ;;-----------------------------------
  ;; Create new S-LUT
  sweepv_new,sweepv,$
             defv1,$
             defv2,$
             spv,$
             plot  = plot,$
             nen   = nen*4, $
             spfac = spfac
  
  ;; Number of angles in coarse sweep, 
  ;; taking into account sub-steps
  nang = 256/nen * 4            
  
  index = 0.
  
  ;; This makes sure we go one way w/ deflectors 
  ;; on even steps, and the other on odds
  for i = 0,nen-1 do begin
     flip = i mod 2                                     
     index = [index,(i*4+2-flip)*nang+indgen(nang)]	
  endfor



  index = index[1:1024]
  if keyword_set(plot) then begin
     ;print,nen,nang
     window,2, xsize=900, ysize=1200
     !p.multi = [0,1,3]
     plot,sweepv[index],psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage',$
          yrange = [0,4000],$
          charsize = 2
     oplot,defv1[index]*sweepv[index],color = 50,psym = 10
     oplot,defv2[index]*sweepv[index],color = 250,psym = 10
     plot,sweepv[index],psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage (Log)',$
          yrange = [0.1,4000],$
          /ylog,$
          charsize = 2,$
          /ystyle
     oplot,defv1[index]*sweepv[index],color = 50,psym = 10
     oplot,defv2[index]*sweepv[index],color = 250,psym = 10
     oplot,spv[index]*sweepv[index],color = 150,psym = 10     
     plot,defv1[index],psym = 10, $
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage Ratio',$
          charsize = 2,$
          yrange = [0,12]
     oplot,defv1[index],psym=10,color = 50
     oplot,defv2[index],color = 250,psym = 10
     oplot,spv[index],color = 150,psym = 10
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
     plots,sweepv[index],defv1[index]-defv2[index], $
           psym = 7,color = 150
  endif
  
end
