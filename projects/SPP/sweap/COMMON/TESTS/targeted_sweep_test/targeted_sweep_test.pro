pro targeted_sweep_test

  
  ;;;----------------------------------------------------------------------
  ;;; LOAD DATA

  restore, './targeted_sweep_test.sav'
  ;;----------------------------------------------
  ;; VARIABLES WITHIN TARGETED_SWEEP_TEST.SAV FILE
  ;;
  ;; time_interval - min/max time of test
  ;; p1_cnts       - full sweep [16A] (energy and deflectors summed)
  ;; p2_cnts_a08   - full sweep [32E] for anode 08 (deflectors summed)
  ;; p3_cnts       - targeted sweep [16A] (energy and deflectors summed)
  ;; p4_cnts_a08   - targeted sweep [32E] for anode 08 (deflectors summed)
  ;; gun_volt      - Gun voltage [V] * 10.
  ;; *PEAK*        - Currently filled with 0s but should contain peak
  ;;                 info

  restore, './table_val_index.sav'
  ;;----------------------------------------------
  ;; VARIABLES WITHIN TABLE_VAL_INDEX.SAV FILE
  ;;
  ;; sweepv - Hemisphere [V]
  ;; defv1  - Deflector 1 [V]
  ;; defv2  - Deflector 2 [V]
  ;; spv    - Spoilter [V]
  ;; fsindex - Full Sweep index into Sweep LUT 
  ;; tsindex - Targeted Sweep index into Sweep LUT 

  rr = 300
  pp = where(p1_cnts.x gt time_interval[0] and $
             p1_cnts.x le time_interval[1] ,cc)

  pp_gun = where(gun_volt.x gt time_interval[0] and $
                 gun_volt.x le time_interval[1] ,cc)

  xx = p1_cnts.x[pp]
  yy = reform(p1_cnts.y[pp,8])

  pk  = [ 400., 600.,1000.,1300.,1575.,1800.,$
         2200.,2420.,2800.,3050.,3450.,3675.]

  nn   = n_elements(pk)
  xxx  = dblarr(rr,nn)
  yyy  = dblarr(rr,nn)
  coef = dblarr(3,nn)

  for i=0, nn-1 do begin
     ind  = (indgen(rr)-rr/2.) + pk[i]
     yfit = GAUSSFIT(xx[ind], yy[ind], coeff, NTERMS=3)
     plot, xx[ind], smooth(yy[ind],10)
     oplot, xx[ind], yfit, color=250
     oplot, replicate(coeff[1],2), [0,10000], color=250
     xxx[*,i]  = xx[ind]
     yyy[*,i]  = yfit
     coef[*,i] = coeff
     print, coeff
  endfor

  !p.multi = [0,0,4]
  window, 0, xsize= 600, ysize=900
  plot, xx, yy, ys=1, xtitle='Counts', ytitle='Time',title='Anode 08'
  for i=0, nn-1 do oplot, xxx[*,i], yyy[*,i], color=250, thick=2
  for i=0, nn-1 do oplot,replicate(coef[1,i],2), [0,10000], color=250 
  plot, gun_volt.x[pp_gun], gun_volt.y[pp_gun],ys=1,xtitle='Time',ytitle='Gun Voltage [V]'
  ;for i=0, nn-1 do oplot,replicate(coef[1,i],2), [0,10000], color=250 

  enrg  = reform(interp(smooth(gun_volt.y[pp_gun],100),gun_volt.x[pp_gun],coef[1,*]))
  enrg2 = sweepv[uniq(sweepv)]*16.7
  enrg3 = sweepv[uniq(sweepv)]*17.01
  index = [57,54,49,46,42,39,34,31,26,23,18,15]
  index = [57,54,49,46,42,39,34,31,26,23,18,15] + [1,1,1,1,0,0,0,0,0,0,0,0]


  plot, indgen(128), enrg2, $
        xr=minmax(index), $
        yr=[300,8500],ys=1,xs=1,$
        ytitle = 'Gun Voltage [V]',$
        xtitle = 'Energy Bin',psym=-1,/ylog
  oplot, indgen(128), enrg3, color=50, psym=-1
  oplot, index, enrg, color=250, psym=-1, thick=1,symsize=1
  xyouts, 40,6000, 'k = 16.7'
  xyouts, 40,5000, 'k = 17.0', color=50
  xyouts, 40,4000, 'Gun Voltage [V]', color=250

  plot,  index, ABS(enrg2[index]-enrg), psym=-1, /ylog, yr=[1,1000], ytitle='Gun [V] - k16.7', $
         xtitle='Energy Bin',title='Compare k=16.7 to k=17.p'
  oplot, index, ABS(enrg3[index]-enrg), psym=-1,color=50

  stop



end
