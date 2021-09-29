PRO spp_swp_spi_thresh_parse_data, data, trange=trange

   ;;; Setup Time Range ;;;
   ;IF trange THEN ctime, trangefull
   ;timebar,trangefull
   ;ctime, trangefull


   ;;; Load Data ;;;
   rates = spp_apdat('3bb'x)
   hkp   = spp_apdat('3be'x)
   IF ~rates OR ~hkp THEN stop, 'Load tplot.'   
   mram_hi = hkp.data.array.MRAM_ADDR_HI
   mram_lo = hkp.data.array.MRAM_ADDR_LOW
   mcp_dac = reform(hkp.data.array.DACS[0,*])
   mcp_vvv = reform(hkp.data.array.MON_MCP_V)
   anode   = mram_hi AND '1f'x
   stp     = (anode AND '10'x) NE 0
   time    = hkp.data.array.time


   ;;; Interpolate to Rates to Housekeeping
   print, 'interpolating ...'
   rt                = rates.data.array.time
   ;start_nostop_cnts = interpolate(rates.data.array.START_NOSTOP_CNTS,rt,time)
   ;stop_nostart_cnts = interpolate(rates.data.array.STOP_NOSTART_CNTS,rt,time)
   ;valid_cnts        = interpolate(rates.data.array.VALID_CNTS,rt,time)
   ;multi_cnts        = interpolate(rates.data.array.MULTI_CNTS,rt,time)
   start_cnts = dblarr(16,n_elements(time))
   stop_cnts  = dblarr(16,n_elements(time))
   FOR i=0, 15 DO start_cnts[i,*] = interpol(reform(rates.data.array.STARTS_CNTS[i,*]),rt,time)
   FOR i=0, 15 DO stop_cnts[i,*]  = interpol(reform(rates.data.array.STOPS_CNTS[i,*]), rt,time)
   print, '... finished'
   

   ;;; Parse Data ;;;

   ;; Number of points required in one run
   npoints    = 200 

   ;; --- Find Times
   tim_good = ( time GE trange[0] AND $
                time LE trange[1])

   ;; --- Find Thresholds and Autozero
   thresh      = mram_lo and '1FF'x
   autozero    = ishft(mram_lo,-9) and  '11'b
   thresh_nn   = n_elements(thresh)
   thr_good    = (thresh NE 0)
   
   ;; --- Sort Runs
   runs = where((fix(thresh[0:thresh_nn-2]) - $
                 fix(thresh[1:thresh_nn-1])) LT 0,cc_runs) + 1
   IF cc_runs EQ 0 THEN stop, 'No Threshold marker.'  

   ;; --- Find unique MCP Dac values
   mcp_dac_u  = mcp_dac[uniq(mcp_dac,sort(mcp_dac))]
   mcp_dac_nn = n_elements(mcp_dac_u) 
   mcp_good   = boolarr(n_elements(mcp_dac))
   FOR i=0, mcp_dac_nn-1 DO $
    IF n_elements(where(mcp_dac_u[i] EQ mcp_dac)) GT npoints THEN $
     mcp_good[where(mcp_dac_u[i] EQ mcp_dac)] = 1


   ;;; Create Structre ;;;
   str  = ptrarr(cc_runs,/alloc)
   cntr = 0
   FOR i=1, cc_runs-1 DO BEGIN
      ind = [runs[i-1]:runs[i]-1]
      ind_mcp = replicate(1,n_elements(ind));mcp_good[ind]
      ind_thr = thr_good[ind]
      ind_tim = tim_good[ind]
      good    = where((ind_mcp AND $
                       ind_thr AND $
                       ind_tim) EQ 1,cc)
      
      ;good = 1
      ;good = good and (anode eq anodes)
      ;good = good and (thresh lt 50) and (thresh gt 5)
      ;good = good and (thresh eq shift(thresh,1)) and (thresh eq shift(thresh,-1))
      ;good = good and (cnts lt 3e4)
      ;good = good and ( other lt 2)

      IF cc GT npoints THEN BEGIN 

         ;; check if anode is constant within run
         ano     = anode[ind[good[0]]] AND 'f'x
         az      = autozero[ind[good[0]]]
         stpp    = stp[ind[good[0]]]
         thr     = thresh[ind[good]]
         mcp     = mcp_dac[ind[good]]
         mcp_v   = mean(mcp_vvv[ind[good]])
         IF stpp THEN cnts = reform(stop_cnts[(ano),ind[good]]) $
         ELSE cnts = reform(start_cnts[ano,ind[good]])
         cntsavg = average_hist(cnts,fix(thr),$
                                binsize=1,$
                                xbins=cntsavg_bins)
         dthavg = -deriv(cntsavg_bins,cntsavg)
         *(str)[cntr] = {az:      az,$
                         cnts:    cnts,$
                         stpp:    stpp,$
                         mcp:     mcp,$
                         mcp_v:   mcp_v,$
                         thresh:  thr,$
                         anode:   ano,$
                         cntsavg: cntsavg,$
                         cntsavg_bins: cntsavg_bins,$
                         dthavg:  dthavg}


         cntr=cntr+1
         print, cc, ano
      ENDIF
   ENDFOR
   
   data=str[0:cntr-1]
   save, filename='~/Desktop/thresh.sav',data

END



PRO spp_swp_spani_thresh_plot, data



   mcp_dacc = 'd400'x
   check_anode = 'f'x;'4'x
   nn_data = n_elements(data)

   wi,1
   !p.multi = [0,1,2]

   xr = [1,60]
   yr = [1,1e3]

   plot,[1,1],[1,1],$;thresh1,cnts1,$
        psym=-1,$
        xr=xr,$
        yr=yr,$
        ylog=1,$
        ;xtitle='threshold',$
        ;title='MCP = '+mcp_str+' V '+$
        ;'Anode = '+anode_str,$
        ;ytitle='counts',$
        /nodata

   FOR i=0, nn_data-2 DO begin
      dat = *(data[i])
      ;cntavg = average_hist(cnts,fix(thresh),binsize=1,xbins=tbins)
      clr = 250 * dat.mcp[0] / 'ffff'x
      clr = dat.anode / 16. * 250.

      az_str    = string(dat.az,  format='(I1)')
      mcp_str   = string(dat.mcp_v,format='(I4)')
      anode_str = string(dat.anode,format='("x",Z02)')
      ;IF dat.mcp[0] EQ 'd400'x THEN oplot,dat.thresh,dat.cnts, color=clr 
      IF dat.mcp[0] EQ mcp_dacc AND $
       dat.anode EQ check_anode THEN BEGIN
         ;oplot,dat.thresh,dat.cnts, psym=-1,color=clr 
         oplot,dat.cntsavg_bins,dat.cntsavg,psym=-1,color=clr
         ;stop
      ENDIF
      
   END
      
   plot,[1,1],[1,1],$           ;thresh1,cnts1,$
        psym=-1,$
        xr=xr,$
        yr=[0.1,1000],$
        xtitle='threshold',$
        title='MCP = '+mcp_str+' V '+$
        'Anode = '+anode_str,$
        ytitle='derivative',$
        ylog=1,$
        /nodata
   
   FOR i=0, nn_data-2 DO BEGIN
      dat = *(data[i])
      clr = 250 * dat.mcp[0] / 'ffff'x
      clr = dat.anode / 16. * 200. + 40
      IF dat.mcp[0] EQ mcp_dacc AND $
       dat.anode EQ check_anode THEN BEGIN
         oplot, dat.cntsavg_bins,abs(dat.dthavg),$
                psym=-1,$
                color=clr
      ENDIF
   ENDFOR
   
   wait,2
   
   !p.multi = 0
END





PRO spp_swp_spani_thresh_analysis, trange=trange
   
   spp_swp_spani_thresh_parse_data,data,trange=trange
   ;restore, data
   spp_swp_spani_thresh_plot, data

END
