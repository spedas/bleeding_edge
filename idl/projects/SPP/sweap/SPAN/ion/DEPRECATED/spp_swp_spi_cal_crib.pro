
pro spp_swp_spi_cal_DEF_YAW_scan,trange=trange


   if ~keyword_set(trange) then $
    ;; YAW DEFLector scan
    trange =  ['2016-10-26/23:30:30', '2016-10-27/01:06:30'] 

   hkp      = spp_apdat('3be'x)
   hkps     = hkp.array
   hkps_def = hkps.dac_defl
   
   rates  = (spp_apdat('3bb'x)).array
   manips = (spp_apdat('7c3'x)).array

   tr=time_double(trange)
   w = where(rates.time gt tr[0] and rates.time le tr[1])
   rates=rates[w]
   
   yaw  = interp(float(manips.yaw_pos),   manips.time,rates.time)
   def  = interp(float(hkps.dac_defl),    hkps.time,  rates.time)
   flag = interp(float(hkps.mram_addr_hi),hkps.time,  rates.time)
   
   counts = rates.valid_cnts[13]
   w =  where(flag ne 1,/null)
   counts[ w] = !values.f_nan
   plot, yaw, counts, xtitle='YAW',$
         ytitle='Counts in 1/4 NY Second',$
         title='Deflector Response for various Deflector DAC values',$
         xrange=[-1,1]*80.,/xstyle,charsize=1.4 ;,ylog=1,yrange=[1,5000]
   plots,yaw,counts,color = bytescale(def)
   defvals = [-50,-45,-40,-30,-20,-10,0,10,20,30,40,45,50]*1000L
   cols=bytescale(defvals)
   for i=0,n_elements(defvals)-1 do begin
      w = where( (def eq defvals[i]) and finite(counts) )
      y = yaw[w]
      c= counts[w]
      ;av=average_hist(y,c,std=std)
      cmax = max(c,bin)
      oplot,y,c,color=cols[i]
      xyouts,y[bin],cmax,strtrim(defvals[i],2),$
             align=.5,charsize=1.5 ;,color=cols[i]
      
   endfor
   makepng,'spani_cnts_vs_yaw',time=trange[0]
   
end




pro spp_swp_spi_cal_YAW_DEF_scan,trange=trange

  if n_elements(trange) ne 2 then ctime,trange
  hkp =spp_apdat('3be'x)
  hkps = hkp.array
  hkps_def = long(hkps.DACS[5])-long(hkps.DACS[6])
  store_data,hkp.tname+'DEF', hkps.time,  hkps_def
  
  rates = (spp_apdat('3bb'x)).array
  manips = (spp_apdat('7c3'x)).array
  w = where(rates.time gt trange[0] and rates.time le trange[1])
  rates=rates[w]
  def = interp(float(hkps_def),hkps.time,rates.time)
  yaw = interp(float(hkps_def),hkps.time,rates.time)
  counts = rates.valid_cnts[15]
  w = where(def ne 0)
  
  plot, def[w], counts[w], xtitle='DEF1-DEF2',$
        ytitle='Counts in 1/4 NY Second',$
        xrange=[-1,1]*2d^16,/xstyle,charsize=1.4
  makepng,'spani_cnts_vs_def',time=trange[0]

end








pro spp_swp_spi_cal_sweep_magnet,trange=trange,plotname=plotname,anode=anode




   IF n_elements(trange) ne 2 THEN ctime,trange
   IF ~keyword_set(plotname)  THEN plotname='~/Desktop/spi_swp_mag'
   IF ~keyword_set(anode)     THEN anode=0
   
   ;hkps   = (spp_apdat('3be'x)).array
   ;rates  = (spp_apdat('3bb'x)).array
   ;manips = (spp_apdat('7c3'x)).array
   aps5   = (spp_apdat('755'x)).array
   toff   = (spp_apdat('3ba'x)).array
   ;hkps_def = long(hkps.DACS[5])-long(hkps.DACS[6])
   ;hkps_def = hkps.dac_defl 


   ;w = where(rates.time GT trange[0] AND $
   ;          rates.time LE trange[1])

   ;get_data, 'spp_spi_tof_TOF', data=toff 
   spp_swp_spi_parameters, vals
   ;rates  = rates[w]
   ;def    = interp(hkps_def,hkps.time,rates.time)
   ;yaw    = interp(float(manips.yaw_pos),manips.time,rates.time)

   curr   = interp(aps5.p6i,aps5.time,toff.time)

   ;counts = rates.valid_cnts[anode]

   pp = where(toff.time GE trange[0] AND $
              toff.time LE trange[1],cc)


   ;; FLUX/DATA
   tof = reform(transpose(float(reform(toff[pp].tof))),cc*512)

   ;; X Axis
   curr = curr[pp]
   curs = reform(curr # replicate(1.,512),cc*512)

   ;; Y Axis
   tofs = reform(replicate(1.,cc) # vals.tof512,cc*512)

   ;xbinsize=0.01
   ;ybinsize=1.00
   
   fun = histbins2d(curs,tofs,flux=tof,$
                    xnbins=xnbins,xbinsize=xbinsize,$;xrange=[0.5,1.5],$
                    ynbins=ynbins,ybinsize=ybinsize);,yrange=[6,208])


   xx = (findgen(xnbins)*xbinsize + 0.6) # replicate(1.,ynbins)
   yy = replicate(1.,xnbins) # (findgen(ynbins)*ybinsize)
   
   
  ;popen, '~/Desktop/yaw_scan',/landscape
  ;!p.multi=[0,0,2]
   contour, fun, xx, yy, /fill, nlevel=20,/irr
  ;anode_s = string(anode,format='(I2)')
   stop





END















  
pro spp_swp_spi_cal_sweep_yaw,trange=trange,plotname=plotname,anode=anode

  IF n_elements(trange) ne 2 THEN ctime,trange
  IF ~keyword_set(plotname)  THEN plotname='~/Desktop/spi_swp_yaw'
  IF ~keyword_set(anode)     THEN anode=0

  hkps   = (spp_apdat('3be'x)).array
  rates  = (spp_apdat('3bb'x)).array
  manips = (spp_apdat('7c3'x)).array
  hkps_def = long(hkps.DACS[5])-long(hkps.DACS[6])
  hkps_def = hkps.dac_defl 

  w = where(rates.time GT trange[0] AND $
            rates.time LE trange[1])

  rates  = rates[w]
  def    = interp(hkps_def,hkps.time,rates.time)
  yaw    = interp(float(manips.yaw_pos),manips.time,rates.time)
  counts = rates.valid_cnts[anode]

  ;; Kludge: get rid of def=0
  pp = where(def NE 0)
  def = def[pp]
  yaw = yaw[pp]
  counts = counts[pp]


  ;; Kludge def
  ;def = fix((round(def/10.)*10.))

  ;un_def = (def[w])[uniq(def[w],sort(def[w]))]  
  un_def = (def)[uniq(def,sort(def))] 

  ybinsize=1
  xbinsize='500'x

  fun = histbins2d(def,yaw,flux=counts,$
                  xnbins=xnbins,xbinsize=xbinsize,xrange=[-'ffff'x,'ffff'x],$
                  ynbins=ynbins,ybinsize=ybinsize,yrange=[-75,75])


  xx = (findgen(xnbins)*xbinsize - 'ffff'x) # replicate(1.,ynbins)
  yy = replicate(1.,xnbins) # (findgen(ynbins)*ybinsize - 75)


  popen, '~/Desktop/yaw_scan',/landscape
  !p.multi=[0,0,2]
  contour, fun, xx, yy, /fill, nlevel=20,xr=[-'ffff'x,'ffff'x],xs=1
  anode_s = string(anode,format='(I2)')

  nn = n_elements(un_def)
  fits = fltarr(3,nn)
  ress = fltarr(4,nn)
  integ1 = fltarr(nn)
  integ2 = fltarr(nn)
  integ3 = fltarr(nn)
  FOR i=0, nn-1 DO BEGIN         

     ;deff = def[i]
     ;yaww = un_yaw[i]
     ;pp = where(round(yaw[w]) EQ yaww,cc)
     ;pp = where(def[w] EQ un_def AND def[w] NE 0,cc)
     pp = where(def EQ un_def[i] AND def NE 0,cc)
     IF cc GT 10 THEN BEGIN

        yaww = yaw[pp]
        countss = counts[pp]

        ;model = gaussfit(def[w[pp]], $
        ;                 counts[w[pp]], $
        ;                 aa,nterms=3)
        model = gaussfit(yaww, $
                         countss, $
                         aa,nterms=3)
        fits[*,i] = aa
        integ1[i] = sqrt(!PI*aa[2]^2*2)*aa[0]
        ;tmp1 = def[w[pp]]
        ;tmp2 = counts[w[pp]]
        tmp1 = yaww
        tmp2 = countss
        
        ss = sort(tmp1)
        tmp1 = tmp1[ss]
        tmp2 = tmp2[ss]

        unn = uniq(tmp1)
        tmp1 = tmp1[unn]
        tmp2 = tmp2[unn]
        integ2[i] = int_tabulated(tmp1,tmp2)
        integ2[i] = tsum(tmp1,tmp2)
        integ3[i] = total(tmp2)*260.
        ;oplot, [yaww,yaww],[aa[1]-aa[2], aa[1]+aa[2]],thick=2.4
        ;oplot, [yaww,yaww],[aa[1],aa[1]], color=250,$
        ;       psym=1,symsize=0.5,thick=2.4
        ress[*,i] = poly_fit(un_def, fits[1,*],3)
        ;oplot, [yaww,yaww],[aa[1]-aa[2], aa[1]+aa[2]],[yaww,yaww]
        ;oplot, [yaww,yaww],[aa[1],aa[1]],[yaww,yaww], color=250,psym=1
     ENDIF ;ELSE print, 'Bad', i, cc, un_def[i]
  ENDFOR

  ;;Polyfit
  res = poly_fit(un_def, fits[1,*],3)
  xx = findgen(120)-60
  oplot, xx, res[0]+res[1]*xx+res[2]*xx^2+res[3]*xx^3, linestyle=2,thick=4
  xyouts, 15, -5e4, $
          string(res[0],format='(F6.1)')+' + '+$
          string(res[1],format='(F6.1)')+'*def + '+$
          string(res[2],format='(F6.1)')+'*def^2'


  
  ;plot, un_def,integ1,psym=-1
  pp = where(integ2 NE 0)
  plot, un_def[pp],integ2[pp],psym=-1,$
        xtitle = 'Deflector [DAC]',xs=1,xr=[-'ffff'x,'ffff'x],$
        ytitle = 'Integral',ys=1,thick=4,yr=[0,6e3]

  ;oplot, un_def,integ3,psym=-1,color=50


  ;; Remove 0s from integral and plot
  pp = where(integ1 NE 0)
  oplot, un_def[pp],integ1[pp],psym=-1,color=250,thick=2

  xyouts, 10,1.7e6,'Trap. Integral'
  xyouts, 10,1.5e6,'Gaussian Integral',color=250
  ;pclose

  data = {anode:anode,$
          un_def:un_def,$
          poly_res:ress,$
          gauss_int:integ1,$
          fit_res:fits}


  save, filename='~/Desktop/yaw_scan_'+anode_s, data
  ;plot, def[w], counts[w], xtitle='DEF1-DEF2',$
  ;      ytitle='Counts in 1/4 NY Second',$
  ;      xrange=[-1,1]*2d^16,/xstyle,charsize=1.4
  ;makepng,'spani_cnts_vs_def',time=trange[0]
  
  !p.multi=0
  pclose


END




pro spp_swp_spi_cal_sweep_deflector,trange=trange,plotname=plotname,anode=anode

   
  IF n_elements(trange) ne 2 THEN ctime,trange
  IF ~keyword_set(plotname)  THEN plotname='~/Desktop/spi_def_swp_new'
  IF ~keyword_set(anode)     THEN anode=0

  hkps   = (spp_apdat('3be'x)).array
  rates  = (spp_apdat('3bb'x)).array
  manips = (spp_apdat('7c3'x)).array
  hkps_def = long(hkps.DACS[5])-long(hkps.DACS[6])
  hkps_def = hkps.dac_defl 

  ;store_data,hkp.tname+'DEF', hkps.time,  hkps_def
  
  w = where(rates.time GT trange[0] AND $
            rates.time LE trange[1])

  rates  = rates[w]
  def    = interp(float(hkps_def),hkps.time,rates.time)
  yaw    = interp(float(manips.yaw_pos),manips.time,rates.time)

  counts = rates.valid_cnts[anode]
  anode_s = string(anode,format='(I2)')

  w = where(def NE 0)
  
  popen, plotname,/landscape
  contour, counts[w],def[w], yaw[w], /irregular, /fill, nlevel=10,$
           title  = time_string(trange[0])+' - Anode '+anode_s+' - 480eV',$
           xtitle = 'Deflector [DAC]',$
           ytitle = 'Yaw [Degrees]',$
           yr = [-60,60],yst=1,$
           xr = [-1.*'ffff'x,'ffff'x],xst=1
  pclose

  ;; Cycle through yaws and fit gaussian
  ;window, 0, xsize=600,ysize=900
  popen, "~/Desktop/2017-03-14_anode_"+anode_s+"_def_scan"
  !P.multi=[0,0,2]
  plot, [0,1], [0,1],$
        xr = [-60,60],yst=1,$
        yr = [-1.*'ffff'x,'ffff'x],xst=1,$
        /nodata,$
        title = time_string(trange[0])+' - Anode '+anode_s+' - 480eV',$
        xtitle = 'Yaw [Degrees]',$
        ytitle = 'DAC'

  un_yaw = (round(yaw[w]))[uniq(round(yaw[w]),sort(round(yaw[w])))]  
  nn = n_elements(un_yaw)  
  fits = fltarr(3,nn)
  ress = fltarr(4,nn)
  integ1 = fltarr(nn)
  integ2 = fltarr(nn)
  integ3 = fltarr(nn)
  FOR i=0, nn-1 DO BEGIN         
     yaww = un_yaw[i]
     pp = where(round(yaw[w]) EQ yaww,cc)
     IF cc NE 0 THEN BEGIN

        ;; KLUDGE to include def=0
        ppp = where(rates.time GE min(rates[w[pp]].time) AND $
                    rates.time LE max(rates[w[pp]].time))
        deff = def[ppp]
        countss = counts[ppp]

        ;model = gaussfit(def[w[pp]], $
        ;                 counts[w[pp]], $
        ;                 aa,nterms=3)
        model = gaussfit(deff, $
                         countss, $
                         aa,nterms=3)
        fits[*,i] = aa
        integ1[i] = sqrt(!PI*aa[2]^2*2)*aa[0]
        ;tmp1 = def[w[pp]]
        ;tmp2 = counts[w[pp]]
        tmp1 = deff
        tmp2 = countss
        
        ss = sort(tmp1)
        tmp1 = tmp1[ss]
        tmp2 = tmp2[ss]

        unn = uniq(tmp1)
        tmp1 = tmp1[unn]
        tmp2 = tmp2[unn]
        integ2[i] = int_tabulated(tmp1,tmp2)
        integ2[i] = tsum(tmp1,tmp2)
        integ3[i] = total(tmp2)*260.
        oplot, [yaww,yaww],[aa[1]-aa[2], aa[1]+aa[2]],thick=2.4
        oplot, [yaww,yaww],[aa[1],aa[1]], color=250,$
               psym=1,symsize=0.5,thick=2.4
        ress[*,i] = poly_fit(un_yaw, fits[1,*],3)
        ;oplot, [yaww,yaww],[aa[1]-aa[2], aa[1]+aa[2]],[yaww,yaww]
        ;oplot, [yaww,yaww],[aa[1],aa[1]],[yaww,yaww], color=250,psym=1
     ENDIF ELSE stop
  ENDFOR

  ;;Polyfit
  res = poly_fit(un_yaw, fits[1,*],3)
  xx = findgen(120)-60
  oplot, xx, res[0]+res[1]*xx+res[2]*xx^2+res[3]*xx^3, linestyle=2,thick=4
  xyouts, 15, -5e4, $
          string(res[0],format='(F6.1)')+' + '+$
          string(res[1],format='(F6.1)')+'*yaw + '+$
          string(res[2],format='(F6.1)')+'*yaw^2'


  
  ;plot, un_yaw,integ1,psym=-1
  plot, un_yaw,integ2,psym=-1,$
        xtitle = 'Yaw [Degrees]',xs=1,$
        ytitle = 'Integral',ys=1,thick=4,yr=[0,6e6]

  ;oplot, un_yaw,integ3,psym=-1,color=50
  oplot, un_yaw,integ1,psym=-1,color=250,thick=4

  xyouts, 10,1.7e6,'Trap. Integral'
  xyouts, 10,1.5e6,'Gaussian Integral',color=250
  pclose

  data = {anode:anode,$
          un_yaw:un_yaw,$
          poly_res:ress,$
          gauss_int:integ1,$
          fit_res:fits}


  save, filename='~/Desktop/def_scan_'+anode_s, data
  ;plot, def[w], counts[w], xtitle='DEF1-DEF2',$
  ;      ytitle='Counts in 1/4 NY Second',$
  ;      xrange=[-1,1]*2d^16,/xstyle,charsize=1.4
  ;makepng,'spani_cnts_vs_def',time=trange[0]

END





PRO rest_plot_def

   popen, '~/Desktop/def_scan_all',/landscape
   !p.multi = [0,0,2]
   ;window, 1
   xx = findgen(121)-60
   plot, [0,1],[0,1],/nodata,xs=1,ys=1,yr=[-1*'ffff'x,'ffff'x],xr=minmax(xx)
   FOR i=0, 8 DO BEGIN 
      restore, '/Users/roberto/projects/sun/def_scan_'+string(i,format='(I1)')
      res = reform(data.poly_res)
      func = res[0]+res[1]*xx+res[2]*xx^2+res[3]*xx^3
      clr = data.anode/16.*230. + 20.
      oplot, xx, func, color=clr,psym=-1
      xyouts, -55, -2e4+1e4*data.anode, 'Anode '+string(data.anode,format='(I1)'), color=clr
   ENDFOR
   plot, [0,1],[0,1],/nodata,xs=1,ys=1,/noerase,yr=[0,4e6],xr=[-60,60]
   FOR i=0, 8 DO BEGIN 
      restore, '/Users/roberto/projects/sun/def_scan_'+string(i,format='(I1)')
      clr = data.anode/16.*230. + 20.
      oplot, data.un_yaw, data.gauss_int, color=clr,psym=-1
   ENDFOR
   !P.multi = 0
   pclose
   stop

END









PRO spp_swp_spi_thresh_scan, trange=trange


   ;; Setup
   loadct2, 34
   npoints = 200

   ;; --- Check keyword
   IF ~keyword_set(trange) THEN $
    stop, 'Error: Need trange.'

   ;; --- Get data
   rates  = (spp_apdat('3bb'x)).array
   manips = (spp_apdat('7c3'x)).array
   hkps   = (spp_apdat('3be'x)).array
   mons   = (spp_apdat('753'x)).array

   ;; --- Find time interval
   htime   = hkps.time
   rtime   = rates.time
   mtime   = mons.time
   rtt = where(rtime GE trange[0] AND $
               rtime LE trange[1],rcc)
   htt = where(htime GE trange[0] AND $
               htime LE trange[1],hcc)
   mtt = where(mtime GE trange[0] AND $
               mtime LE trange[1],mcc)
   IF rcc EQ 0  OR hcc EQ 0 OR mcc EQ 0 THEN $
    stop, 'Error: Time interval not loaded.'
   rates = temporary(rates[rtt])
   rtime = temporary(rtime[rtt])
   hkps  = temporary(hkps[htt])
   htime = temporary(htime[htt])
   mons  = temporary(mons[mtt])
   mtime = temporary(mtime[mtt])

   ;; --- Plot
   popen, '~/Desktop/2017-03-08_thresh_scan',/landscape
   plot, [0,1],[0,1],$
         xr=[10,60],   xs=1,xlog=1,xtitle='Threshold',$
         yr=[1e1,1e4],ys=1,ylog=1,ytitle='Binned and Average Counts',$
         Title=time_string(trange[0]),/nodata,thick=2

   ;; --- Define variables and interpolate to rates
   addr_hi = hkps.MRAM_ADDR_HI  AND '1F'x
   addr_lo = hkps.MRAM_ADDR_LOW AND 'FFFF'x
   anode   = round(interp(addr_hi,htime,rtime))

   ;; Kludge
   anode[where(anode EQ 1)] = 0
   anode[where(anode EQ 3)] = 2
   anode[where(anode EQ 5)] = 4
   anode[where(anode EQ 7)] = 6
   anode[where(anode EQ 9)] = 8

   thresh  = round(interp(addr_lo,htime,rtime)) AND '1FF'x
   mcp_dac = round(interp(reform(hkps.DACS[0,*]),htime,rtime))
   mcp_vvv =       interp(hkps.MON_MCP_V,htime,rtime)
   mcp_ccc =       interp(hkps.MON_MCP_C,htime,rtime)
   fill    = round(interp(mons.P6I*100.,mtime,rtime))

   ;; --- Find autozero
   autozero = ishft(addr_lo,-9) and  '11'b
   autozero =  round(interp(autozero,htime,rtime))

   ;; --- Find unique values for MCP, Anode, and Autozero
   un_auz = autozero[uniq(autozero,sort(autozero))]
   un_ano = anode[uniq(anode,sort(anode))]
   un_mcp = mcp_dac[uniq(mcp_dac,sort(mcp_dac))]
   un_fil = fill[uniq(fill,sort(fill))]
   nn_auz = n_elements(un_auz)
   nn_ano = n_elements(un_ano)
   nn_mcp = n_elements(un_mcp)
   nn_fil = n_elements(un_fil)

   ;; --- Structure
   thresh_data  = ptrarr(nn_fil,nn_mcp,nn_auz,nn_ano,/alloc)

   ;; --- Loop through unique MCPs, Anodes, and Autozeros

   ;; Filament Current
   FOR fil=0, nn_fil-1 DO BEGIN
      fil_val = un_fil[fil]

      ;; MCPs
      FOR mcp=0, nn_mcp-1 DO BEGIN
         mcp_val = un_mcp[mcp]

         ;; Autozero
         FOR auz=1, 1 DO BEGIN; nn_auz-1 DO BEGIN  ;nn_auz-1 DO BEGIN
            auz_val = un_auz[auz]

            ;; Anode
            FOR ano=0, nn_ano-1 DO BEGIN 
               ano_val = un_ano[ano]

               ;; Find values that match all unique values
               good = (anode    EQ ano_val) AND $
                      (mcp_dac  EQ mcp_val) AND $
                      (autozero EQ auz_val) AND $
                      (fill     EQ fil_val) AND $
                      (thresh   NE 0)
               pp = where(good EQ 1,cc)
               ;IF cc LT npoints THEN print,' BAD: '+string(fil,mcp,auz,ano,cc,format='(2F10.2,3I5)')
               IF cc GT npoints THEN BEGIN
                  IF ano_val LT '10'x THEN BEGIN
                     ;; ---------------- STARTS ------------------
                     ;; Setup counts
                     cnts = reform(rates[pp].STARTS_CNTS[ano_val])
                     ;; Bin according to threshold
                     cntsavg = average_hist(cnts,fix(thresh[pp]),$
                                            binsize=1,$
                                            xbins=cntsavg_bins)
                     ;; Derivative of threshold scan
                     dthavg = -deriv(cntsavg_bins,cntsavg)
                     ;; Exclude counts above 1e4
                     pp = where(cntsavg LT 1e4,cc)
                     IF cc NE 0 THEN BEGIN
                        cntsavg = temporary(cntsavg[pp])
                        cntsavg_bins = temporary(cntsavg_bins[pp])
                        dthavg  = temporary(dthavg[pp])
                        ;; Color and Plot
                        ;clr = round(ano_val/16.*250.)
                        clr = 0
                        oplot, cntsavg_bins, cntsavg, color=clr, thick=3,psym=-1
                     ENDIF
                  ENDIF ELSE BEGIN 
                     ;; ----------------- STOPS ------------------
                     ;; Setup counts
                     cnts = reform(rates[pp].STOPS_CNTS[ano_val-16])
                     ;; Bin according to threshold
                     cntsavg = average_hist(cnts,fix(thresh[pp]),$
                                            binsize=1,$
                                            xbins=cntsavg_bins)
                     ;; Derivative of threshold scan
                     dthavg = -deriv(cntsavg_bins,cntsavg)
                     ;; Exclude counts above 1e4
                     pp = where(cntsavg LT 1e4,cc)
                     IF cc NE 0 THEN BEGIN
                        cntsavg = temporary(cntsavg[pp])
                        cntsavg_bins = temporary(cntsavg_bins[pp])
                        dthavg  = temporary(dthavg[pp])
                        ;; Color and Plot
                        ;clr = round((ano_val-16.)/16.*250.)
                        IF ano_val LT '1a'x THEN clr = 250 ELSE clr=50
                        oplot, cntsavg_bins, cntsavg, color=clr, thick=3,psym=-1

                     ENDIF
                  ENDELSE

                  ;; Save data in structure
                  *(thresh_data[fil,mcp,auz,ano]) = $                
                   {az:           auz_val,$
                    mcp:          mcp_val,$
                    anode:        ano_val,$
                    fillament:    fil_val,$
                    ;mcp_v:        mcp_v,$
                    cnts:         cnts,$
                    thresh:       thresh,$
                    dthavg:       dthavg,$
                    cntsavg:      cntsavg,$
                    cntsavg_bins: cntsavg_bins}                     
               ENDIF
            ENDFOR
         ENDFOR
      ENDFOR
   ENDFOR

   pp = 0
   cc = 0
   FOR i=0, nn_fil*nn_mcp*nn_auz*nn_ano-1 DO $
    IF *(thresh_data[i]) NE !NULL THEN BEGIN
      pp = [pp,i]
      cc++
   ENDIF
   pp=[0:cc-1]
   data = reform(thresh_data[pp],nn_fil,nn_mcp,nn_auz,nn_ano)
   pclose
   ;spp_swp_spi_thresh_scan_plot,thresh_data
   stop
   
END






PRO spp_swp_spi_thresh_scan_plot, data

   IF ~keyword_set(data) THEN stop, 'Must provide data.'

   ;; --- Plot
   popen, '~/Desktop/2017-03-08_thresh_scan',/landscape
   plot, [0,1],[0,1],$
         xr=[10,60],   xs=1,xlog=1,xtitle='Threshold',$
         yr=[1e1,1e4],ys=1,ylog=1,ytitle='Binned and Average Counts',$
         Title='Threshold Scan',/nodata,thick=2

   nn_fil = (size(data))[1]
   nn_mcp = (size(data))[2]
   nn_auz = (size(data))[3]
   nn_ano = (size(data))[4]

   ;; Filament Current
   FOR fil=0, nn_fil-1 DO BEGIN
      fil_val = un_fil[fil]

      ;; MCPs
      FOR mcp=0, nn_mcp-1 DO BEGIN
         mcp_val = un_mcp[mcp]

         ;; Autozero
         FOR auz=0, nn_auz-1 DO BEGIN  ;nn_auz-1 DO BEGIN
            auz_val = un_auz[auz]

            ;; Anode
            FOR ano=0, nn_ano-1 DO BEGIN 
               ano_val = un_ano[ano]

               ;; Color and Plot
               clr = round((ano_val-16)/16*250+70)
               oplot, cntsavg_bins, cntsavg, color=clr, thick=3,psym=-2
               
               ;; Color and Plot
               clr = round(ano_val/16.*250.)
               oplot, cntsavg_bins, cntsavg, color=clr, thick=3,psym=-1
               
            ENDFOR
         ENDFOR
      ENDFOR
   ENDFOR

   pclose


END






PRO spp_swp_spi_yaw_scan_response, trange=trange

   ;; --- Constants
   time_offset=2.6
   anode = 'a'x

   ;; --- Get data
   rates  = (spp_apdat('3bb'x)).array
   manips = (spp_apdat('7c3'x)).array

   ;; --- Find correct times
   w=where(rates.time gt trange[0] and $
           rates.time lt trange[1],/null)

   ;; --- Filter times
   rates = temporary(rates[w])

   ;; --- Setup coordiantes and fit
   yaws  = interp(manips.yaw_pos,manips.time,rates.time+time_offset)
   model = gaussfit(yaws, rates.valid_cnts[anode], aa,nterms=3)

   popen, 'spani_yaw_scan',/landscape
   plot,  yaws, rates.valid_cnts[anode],$
          thick=1.2, charthick=1.2, charsize=1.2,$
          xtitle='Yaw [degrees]',$
          ytitle='Counts per 0.218 s'
   oplot, yaws, model, color=50, thick=3
   oplot, [aa[1],aa[1]],[0.1,1e4],linestyle=2, thick=3
   pclose
   stop

END







pro spp_swp_spi_rot_linyaw_response,trange=trange, verbose=verbose

   ;; --- Constants
   time_offset=0.0
   anode = 'a'x

   ;; --- Get data
   rates  = (spp_apdat('3bb'x)).array
   hkps   = (spp_apdat('3be'x)).array
   manips = (spp_apdat('7c3'x)).array

   ;; --- Verbose
   IF keyword_set(verbose) THEN BEGIN
      hkp.print
      manip.print
      rate.print
   ENDIF

   ;; --- Get times if necessary
   if ~keyword_set(trange) then ctime,trange

   ;; --- Find correct times
   w=where(rates.time gt trange[0] and $
           rates.time lt trange[1],/null)

   ;; --- Filter times
   rates = temporary(rates[w])

   ;; --- Interpolate variables relative to rates time
   ;anodes = interp(float(hkps.mram_addr_low),hkps.time,rates.time)
   yaws   = round(interp(manips.yaw_pos,manips.time,rates.time+time_offset))
   lins   = interp(manips.lin_pos,manips.time,rates.time+time_offset)
   c      = bytescale(indgen(20))


   ;; --- Sum and fit
   hh  = histogram(lins,binsize=0.01,reverse_indices=ri,loc=arrloc)
   arr = fltarr(n_elements(hh)) 
   FOR j=0l, n_elements(hh)-1 DO IF ri[j+1] GT ri[j] THEN $
    arr[j] = total(rates[ri[ri[j]:ri[j+1]-1]].valid_cnts[anode])
   model = gaussfit(arrloc, arr, aa,nterms=3)


   
   ;window, 1, xsize=600,ysize=900
   !p.multi=[0,0,2]
   ;; ------------ PLOTTING --------------------
   popen, '~/Desktop/spani_gun_map_3', /landscape
   plot,/nodata,yaws,total(rates.valid_cnts,1),$
        xtitle='Linear [cm]',$
        ytitle='Counts in 1/4 NYS (0.218 s)',$
        title='Anode 10 - Time: '+time_string(trange[0]),$
        xr = [4,14],$
        yr = [0,1e3], ys = 1,$
        charsize=1.2,charthick=1.5
   ;anodes = replicate(10,n_elements(anodes))
   ;FOR i=0,15 DO BEGIN
   xyouts, aa[1]-3.5, 900, 'Yaw',$
           charsize=1,charthick=2
   FOR j=-10, 10 DO BEGIN
      w = where(yaws EQ j,/null,cc)
      if keyword_set(w) AND cc GT 50 THEN BEGIN
         oplot,lins[w],rates[w].valid_cnts[anode],col = c[j]
         ;xyouts, aa[1]-2, 1000*(j+10)/20+500, 'Yaw '+string(j),$
         xyouts, aa[1]-3.5+(-1*j)/4., 800, string(j),$
                 col=c[j],charsize=1,charthick=2
      ENDIF
   ENDFOR
   oplot, [aa[1],aa[1]], [0.1, 1e4], thick=2, linestyle= 2
   contour, rates.VALID_CNTS[anode], lins, yaws, /irr, /fill,$
            nlevel=20,xtitle='Linear [cm]',ytitle='Yaw',$
            xr=[4,14],xs=1,charsize=1.2,charthick=1.5,ys=1,yr=[-8,8]

   pclose

   !p.multi=0


END














pro spp_swp_spi_rot_scan,trange=trange

   ;; Error Check 1
   IF size(trange,/type) EQ 7 THEN trange = time_double(temporary(trange))


   ;; Get Data
   rate   = (spp_apdat('3bb'x)).array
   hkp    = (spp_apdat('3be'x)).array
   manip  = (spp_apdat('7c3'x)).array
   events = (spp_apdat('3b9'x)).array

   ;; Error Check 2
   IF ~keyword_set(trange) THEN stop, 'Must set trange=trange as parameter.'

   ;; Find Times
   r_good = where(rate.time   GE trange[0] AND rate.time   LE trange[1],r_cc)
   h_good = where(hkp.time    GE trange[0] AND hkp.time    LE trange[1],h_cc)
   m_good = where(manip.time  GE trange[0] AND manip.time  LE trange[1],m_cc)
   e_good = where(events.time GE trange[0] AND events.time LE trange[1],e_cc)

   ;; Error Check 3
   IF r_cc EQ 0 OR h_cc EQ 0 OR m_cc EQ 0 OR e_cc EQ 0 THEN stop, 'No time sample.'

   ;; Interpolate to packets with highest rates (usually rates)
   starts       = rate[r_good].STARTS_CNTS
   start_nostop = rate[r_good].START_NOSTOP_CNTS
   stops        = rate[r_good].STOPS_CNTS
   stop_nostart = rate[r_good].STOP_NOSTART_CNTS
   valids       = rate[r_good].VALID_CNTS
   rtime        = rate[r_good].time

   rot    = interp(manip[m_good].rot_pos,manip[m_good].time, rtime)
   yaw    = interp(manip[m_good].yaw_pos,manip[m_good].time, rtime)
   lin    = interp(manip[m_good].lin_pos,manip[m_good].time, rtime)

   mcp_c = interp(hkp[h_good].MON_MCP_C,hkp[h_good].time,rtime)
   mcp_v = interp(hkp[h_good].MON_MCP_V,hkp[h_good].time,rtime)
   acc_c = interp(hkp[h_good].MON_ACC_C,hkp[h_good].time,rtime)
   acc_v = interp(hkp[h_good].MON_ACC_V,hkp[h_good].time,rtime)

   ;; Fit each distribution to 
   coeffs_str   = dblarr(3,16)
   coeffs_stp   = dblarr(3,16)
   coeffs_val   = dblarr(3,16)
   coeffs_tmp11   = dblarr(3,16)
   coeffs_tmp12   = dblarr(3,16)
   rot_str_cntr = dblarr(16)
   rot_stp_cntr = dblarr(16)
   rot_val_cntr = dblarr(16)

   FOR i=0,15 DO BEGIN
      tmp1 = gaussfit(rtime,reform(starts[i,*]),a1,nterms=3)
      tmp2 = gaussfit(rtime,reform(stops[i,*]), a2,nterms=3)
      tmp3 = gaussfit(rtime,reform(valids[i,*]),a3,nterms=3)

      coeffs_str[*,i] = a1
      coeffs_stp[*,i] = a2
      coeffs_val[*,i] = a3

      ;; Neighbouring Peaks
      ;mm   = where(tmp1 EQ (max(tmp1))[0])
      ;tmp11 = gaussfit(rtime[mm:*],((reform(starts[i,*])-tmp1)>0)[mm:*],coeffs_tmp11[*,i],nterms=3)
      ;tmp12 = gaussfit(rtime[0:mm],((reform(starts[i,*])-tmp1)>0)[0:mm],coeffs_tmp12[*,i],nterms=3)

      rot_str_cntr[i] = rot[where(tmp1 EQ (max(tmp1))[0])]
      rot_stp_cntr[i] = rot[where(tmp2 EQ (max(tmp2))[0])]
      rot_val_cntr[i] = rot[where(tmp3 EQ (max(tmp3))[0])]
   ENDFOR
   
   ;; Fit center values
   xx = [findgen(10)/2,indgen(6)+5]
   stp_fit = linfit(xx,rot_stp_cntr)
   str_fit = linfit(xx,rot_str_cntr)
   val_fit = linfit(xx,rot_val_cntr)


   ;; Sort events
   channel = events[e_good].channel 
   tof     = events[e_good].tof 
   etime   = events[e_good].time

   ;; Cycle through each anode
   thrsh=100
   indloc = fltarr(2,16)
   FOR i=0, 15 DO BEGIN

      pp = where(valids[i,*] GT 400,cc)
      tt = minmax(rtime[pp])
      ind = where(channel EQ i,cc)
      IF cc GT thrsh THEN BEGIN

         ;; Find peak counts
         ;; 80-120
         IF i EQ 0 THEN BEGIN
            pp      = where(etime[ind] GT tt[0] AND etime[ind] LT tt[1])
            tof_bin = histogram(tof[ind[pp]],loc=loc) 
            tof_bin = float(tof_bin)/max(tof_bin)
            xloc    = loc
            ;xind    = n_elements(loc)
            indloc[*,i] = [0,n_elements(loc)-1]
            pp      = where(loc GT 80 AND loc LT 110) ;; Hydrogen Peak
            param   = gaussfit(loc[pp],tof_bin[pp],a1,nterms=3)
            param   = a1
         ENDIF ELSE BEGIN 
            pp      = where(etime[ind] GT tt[0] AND etime[ind] LT tt[1])
            tmp = histogram(tof[ind[pp]],loc=loc)
            tmp = float(tmp) / max(tmp)
            tof_bin = [tof_bin, tmp]
            xloc = [xloc,loc]
            indloc[*,i] = [indloc[1,i-1]+1,n_elements(loc)+indloc[1,i-1]]
            ;xind = [xind,n_elements(loc)]
            pp      = where(loc GT 80 AND loc LT 110) ;; Hydrogen Peak
            par_tmp = gaussfit(loc[pp],tmp[pp],a1,nterms=3)
            param = [[param],[a1]]
         ENDELSE
      ENDIF

      ;; Number of corrective bins to be added to each tof channel.
      tof_corr = round(max(param[1,*]) - reform(param[1,*]))

   ENDFOR

   ;; PLOTTING
   ;!p.multi = [0,0,2]
   ns = 0.101725 ;* 1e-9
   popen, '~/Desktop/adjusted_normalized_tof',/landscape
   plot, [0,1],[0,1],$
         xr=[50,2048]*ns, /xlog, xs=1,$
         yr=[1e-4,1],     /ylog, ys=1,$
         /nodata,xtitle='[ns]',ytitle='Normalized Counts'
   FOR i=0, 15 DO BEGIN
      xx = xloc[indloc[0,i]:indloc[1,i]-1]; + tof_corr[i]
      yy = tof_bin[indloc[0,i]:indloc[1,i]-1]
      ;IF tof_corr[i] NE 0 THEN BEGIN
      ;   xx = xx+tof_corr[i]
      ;ENDIF
      oplot, xx*ns, yy, col=i/15.*250.
   ENDFOR
   pclose
   
   stop

END












PRO spp_swp_spi_k_sweep, trange=trange


   ;; Get Sweep DACs
   spp_swp_spi_tables, tables, config='01'x

   ;; Get SPAN-Ai HV DAC to Volts
   spp_swp_spi_parameters, vals 

   ;; Setup
   loadct2, 34
   npoints = 200

   ;; --- Check keyword
   IF ~keyword_set(trange) THEN $
    stop, 'Error: Need trange.'

   ;; --- Get data
   rates  = (spp_apdat('3bb'x)).array
   ;manips = (spp_apdat('7c3'x)).array
   hkps   = (spp_apdat('3be'x)).array
   mons   = (spp_apdat('761'x)).array
   f_p0m0 = (spp_apdat('398'x)).array
   t_p0m0 = (spp_apdat('3a4'x)).array

   ;; --- Find time interval
   htime   = hkps.time
   rtime   = rates.time
   mtime   = mons.time
   ftime   = f_p0m0.time
   ttime   = t_p0m0.time

   rtt = where(rtime GE trange[0] AND $
               rtime LE trange[1],rcc)
   htt = where(htime GE trange[0] AND $
               htime LE trange[1],hcc)
   mtt = where(mtime GE trange[0] AND $
               mtime LE trange[1],mcc)
   ftt = where(ftime GE trange[0] AND $
               ftime LE trange[1],fcc)
   ttt = where(ttime GE trange[0] AND $
               ttime LE trange[1],tcc)


   IF rcc EQ 0  OR hcc EQ 0 OR mcc EQ 0 THEN $
    stop, 'Error: Time interval not loaded.'

   rates  = temporary(rates[rtt])
   rtime  = temporary(rtime[rtt])
   hkps   = temporary(hkps[htt])
   htime  = temporary(htime[htt])
   mons   = temporary(mons[mtt])
   mtime  = temporary(mtime[mtt])
   f_p0m0 = temporary(f_p0m0[ftt])
   t_p0m0 = temporary(t_p0m0[ttt])
   ftime  = temporary(ftime[ftt])
   ttime  = temporary(ttime[ttt])
   
   ;; --- Plot
   ;popen, '~/Desktop/ch10_thresh_scan',/landscape
   ;plot, [0,1],[0,1],$
   ;      xr=[10,60],   xs=1,xlog=1,xtitle='Threshold',$
   ;      yr=[1e1,1e4],ys=1,ylog=1,ytitle='Binned and Average Counts',$
   ;      Title='Channel 10 Threshold Scan',/nodata,thick=2

   ;; --- Define variables and interpolate to rates
   addr_hi   = hkps.MRAM_ADDR_HI  AND '1F'x
   igun_volt = mons.volts
   anode     = round(interp(addr_hi,htime,rtime))
   igun      = round(interp(igun_volt,mtime,rtime))
   ;mcp_dac = round(interp(reform(hkps.DACS[0,*]),htime,rtime))
   nrgs = intarr(32,rcc)
   FOR i=0,31 DO nrgs[i,*] = interpol(f_p0m0.NRG_SPEC[i],ftime,rtime)


   ;; Cycle through all 16 anodes
   center = fltarr(16,32)
   FOR i=0, 15 DO BEGIN
      
      pp = where(anode EQ i,cc)
      str = rates[pp].STARTS_CNTS[i]
      stp = rates[pp].STOPS_CNTS[i]
      val = rates[pp].VALID_CNTS[i]
      volts = igun[pp]
      nrg  = nrgs[*,pp]

      IF cc GT 100 THEN BEGIN
         maxx = max(nrg,loc,dim=1)
         locc = array_indices(nrg,loc)
         FOR j=0, 31 DO BEGIN
            ;; Only Energy bins with max counts
            pp=where(locc[0,*] EQ j,cc)
            nrg2 = nrg[locc[0,pp],locc[1,pp]]
            IF max(nrg2) GT 10 AND cc GT 10 THEN BEGIN
               ;plot, volts[pp],nrg2,title=string(total(nrg2))+' '+ string(j)+' '+string(i)
               tmp = gaussfit(volts[pp],nrg2,a1,nterms=3)
               center[i,j] = a1[1]
               ;oplot, volts[pp], tmp, color=50
            ENDIF
         ENDFOR
      ENDIF
   ENDFOR
   plot, indgen(32), reform(center[0,*]), psym=-1
   FOR i=1., 15 DO oplot, indgen(32),reform(center[i,*]),color=i/16*250.,psym=-1
   tmp = reform((transpose(reform(tables.sweepv_dac[tables.fsindex[indgen(256)*4]],8,32)))[*,0])
   ;; DAC to Hemisphere Volts
   hemi_voltage = vals.hemi_fitt[0]+vals.hemi_fitt[1]*tmp
   ;; Go through anode by anode and find k factor
   kval = fltarr(16)
   FOR i=0, 15 DO BEGIN
      cntr = reform(center[i,*])
      pp = where(cntr GT 0,cc)
      IF cc LT 3 THEN stop
      cntr1 = cntr[pp]
      hv = hemi_voltage[pp]
      tmp = total(sqrt((ABS(hv)*14-cntr1)^2))
      FOR j=15., 20., 0.001 DO BEGIN
         
         tmp2 = total(sqrt((ABS(hv)*j-cntr1)^2))
         IF tmp2 gt tmp THEN BEGIN
            kval[i] = j         
            plot, cntr1
            oplot, abs(hv)*j,color=50
            BREAK
         ENDIF
         tmp = tmp2
      ENDFOR
      kval[i] = j
      print, 'KVAL', j
   ENDFOR
   stop
END





PRO spp_swp_spi_tof_boxcar, trange=trange, $
                            anode=anode,   $
                            normalized=normalized


   ;; Setup
   loadct2, 34

   ;; --- Check keyword
   IF ~keyword_set(trange) THEN BEGIN
      print, 'Error: Need trange.'
      ctime, trange
   ENDIF

   IF ~keyword_set(anode) THEN stop

   spp_swp_spi_parameters, vals

   ;; TOF
   get_data, 'spp_spi_tof_TOF', data=toff 

   ;; APS 5 - Agilent
   aps5 = (spp_apdat('755'x)).array


   ;; TOF
   e_toff = where(toff.x GE trange[0] AND $
                  toff.x LE trange[1],t_cc)

   c_toff = where(aps5.time GE trange[0] AND $
                  aps5.time LE trange[1],c_cc)

   tof      = toff.y[e_toff,*]
   tof_time = toff.x[e_toff]
   cur      = aps5[c_toff].p6i
   cur_time = aps5[c_toff].time

   ind = fltarr(t_cc)
   j = 0
   FOR i=0, t_cc-1 DO BEGIN 
      IF tof_time[i] LT cur_time[j] THEN BEGIN 
         ind[i] = j 
      ENDIF ELSE BEGIN 
         j=j+1
         ind[i] = j
      ENDELSE 
   ENDFOR

   cur=cur[ind]

   ind = reform(vals.tof512 ## replicate(1,t_cc),512.*t_cc)
   cur = rform(transpose(cur ## replicate(1,512)),512*t_cc)
   tof = reform(tof,512*t_cc)

   bin1 = 0.1
   min1 = min(ind)
   max1 = max(ind)

   bin2 = 0.01
   min2 = min(cur)
   max2 = max(cur)

   h2d =HIST_2D(tof, cur,$
                bin1=bin1,min1=min1,max1=max1,$
                bin2=bin2,min2=min2,max2=max2)
   
   contour, h2d, x,indgen(n_elements(h2d[0,*])),$
            /fill, nlevel=25,$
            xrange=[0,130],xs=1,$
            yrange=[0,170],ys=1.,$
            title=time_string(trange[0])+$
            ;' -  EM3 - Colutron 1keV eV, 50V ExB - Anode 11',$
            ' -  FM - Colutron 1keV eV, 50V ExB - Anode 11',$
            xtitle='Nanoseconds',ytitle='Magnet [mA]'
   stop
   ;skip:



   ;; ----------------- EVENTS
   e_good = where(events.time GE trange[0] AND $
                  events.time LE trange[1] AND $
                  events.channel EQ anode, e_cc)

   current = interp(float(aps5.p6i),aps5.time,events[e_good].time)

   h2d =HIST_2D(events[e_good].tof, current,$
                bin1=1,bin2=bin2,min2=min2,max2=max2)


   ;popen, '~/Desktop/201702022_spanai_tof_colutron_spec',/landscape
   contour, h2d[0:2047,*],indgen(2048)*0.101725,indgen(n_elements(h2d[0,*])),$
            /fill, nlevel=25,xrange=[0,130],yrange=[0,170],xs=1,ys=1.,$
            title=time_string(trange[0])+$
            ' -  EM3 - Colutron 480 eV, 50V ExB - Anode 11',$
            xtitle='Nanoseconds',ytitle='Magnet [mA]'
   ;pclose
   stop

   ;popen, '~/Desktop/201702022_spanai_tof_colutron_gas_mix',/landscape
   plot, indgen(2416)*0.101725,total(h2d,2), $
         /xlog, /ylog, xr=[6,200],yr=[10,1e4],xs=1,ys=1,$
         title=time_string(trange[0])+' -  EM3 - Colutron 1 keV, 35V ExB - Anode 11',$
         xtitle='Nanoseconds',ytitle='Counts'
   ;pclose

   stop

   FOR ii=binsize/2., e_cc-binsize/2., 100 DO BEGIN

      ind = e_good[ii-binsize/2.:ii+binsize/2.]
      ;; Histograms
      hh = histogram(events[ind].tof,min=0,max=2047,binsize=1)
      IF keyword_set(normalized) THEN hh = hh/max(hh)
      
      ;; Plot
      title = time_string(trange[0])+' '+$
              time_string(trange[1])
      title = title+' Anodes: '
      title = title + ' ' + string(anode, format='(I2)') 
      IF keyword_set(normalized) THEN BEGIN
         ytitle = 'Normalized Counts'
         yrange = [1e-4,1.]
      ENDIF ELSE BEGIN 
         ytitle = 'Counts per 1/4 NYS'
         yrange = [1,max(hh)*1.1]
         yrange = [1,100]
      ENDELSE
      
      xx = indgen(2048)*0.101725
      xtitle = 'ns'
      xrange = [5,max(xx)]
      xlog = 1
      ylog = 1

      ;plot, [1,1],[1,1],/nodata,$
      ;      ystyle=1,ytitle=ytitle,yrange=yrange,ylog=ylog,$
      ;      xstyle=1,xtitle=xtitle,xrange=xrange,xlog=xlog,$
      ;      title = title
      ;oplot, xx, smooth(hh,10), color=11/16.*250. 
      tmp = gaussfit(xx,smooth(hh,10),a1,nterms=3)
      ;tmp = gaussfit(volts[pp],nrg2,a1,nterms=3)
      ;oplot, xx, tmp, color=anode/16.*250.
      
      center[jj] = a1[1]
      jj=jj+1
   ENDFOR
   stop

END




PRO spp_swp_spi_plot_tof, trange=trange, $
                          anode=anode,   $
                          normalized=normalized


   ;; Setup
   loadct2, 34

   ;; --- Check keyword
   IF ~keyword_set(trange) THEN BEGIN
      print, 'Error: Need trange.'
      ctime, trange
   ENDIF

   
   IF ~keyword_set(anode) THEN $
    anode = indgen(16)
   nn_anode = n_elements(anode)

   ;; --- Get data
   events  = (spp_apdat('3b9'x)).array
   ;rates  = (spp_apdat('3bb'x)).array
   ;manips = (spp_apdat('7c3'x)).array
   ;hkps   = (spp_apdat('3be'x)).array
   ;mons   = (spp_apdat('761'x)).array
   ;f_p0m0 = (spp_apdat('398'x)).array
   ;t_p0m0 = (spp_apdat('3a4'x)).array


   ;; --- Find time interval
   etime   = events.time
   ;htime   = hkps.time
   ;rtime   = rates.time
   ;mtime   = mons.time
   ;ftime   = f_p0m0.time
   ;ttime   = t_p0m0.time

   e_good = where(events.time GE trange[0] AND $
                  events.time LE trange[1],e_cc)

   ;rtt = where(rtime GE trange[0] AND $
   ;            rtime LE trange[1],rcc)
   ;htt = where(htime GE trange[0] AND $
   ;            htime LE trange[1],hcc)
   ;mtt = where(mtime GE trange[0] AND $
   ;            mtime LE trange[1],mcc)
   ;ftt = where(ftime GE trange[0] AND $
   ;            ftime LE trange[1],fcc)
   ;ttt = where(ttime GE trange[0] AND $
   ;            ttime LE trange[1],tcc)
   
   ;; Histograms
   hh = fltarr(nn_anode,2048)
   FOR i=0, nn_anode-1 DO BEGIN
      ppan = where(events[e_good].channel EQ anode[i],cc_anode)
      hh[i,*] = histogram(events[e_good[ppan]].tof,min=0,max=2047,binsize=1)
      IF keyword_set(normalized) THEN hh[i,*] = hh[i,*]/max(hh[i,*])
   ENDFOR

   ;; Plot
   title = time_string(trange[0])+' '+$
           time_string(trange[1])
   title = title+' Anodes: '
   FOR i=0, nn_anode-1 DO $
    title = title + ' ' + string(anode[i], format='(I2)') 
   IF keyword_set(normalized) THEN BEGIN
      ytitle = 'Normalized Counts'
      yrange = [1e-4,1]
   ENDIF ELSE BEGIN 
      ytitle = 'Counts per 1/4 NYS'
      yrange = [1,max(hh)*1.1]
   ENDELSE

   xx = indgen(2048)*0.101725
   xtitle = 'ns'
   xrange = [5,max(xx)]
   xl = 1
   yl = 1

   plot, [1,1],[1,1],/nodata,$
         ystyle=1,ytitle=ytitle,yrange=yrange,ylog=yl,$
         xstyle=1,xtitle=xtitle,xrange=xrange,xlog=xl,$
         title = title
   
   FOR i=0, nn_anode-1 DO $
    oplot, xx, hh[i,*], color=i/16.*250. 

END




PRO spp_swp_tof_energy, trange=trange

   center_energy = 500.
   deltaEE = 0.2
   factor = deltaEE * center_energy
   minn = center_energy - factor
   maxx = center_energy + factor
   sweepv_dacv,hem_dac,def1_dac,def2_dac,spl_dac,k=16.7,rmax=11.0,vmax=4000,$
               nen=128,e0=minn,emax=maxx,spfac=0.,maxspen=500.

   spfac   = 0.
   nen = 128.
   spp_swp_sweepv_new_fslut, sweepv, $
                             defv1, $
                             defv2, $
                             spv, $
                             findex, $
                             nen = nen/4, $
                             spfac = spfac

   tmp=findex[indgen(1024/4)*4]
   nrg_bins=reform(hem_dac[(reform(tmp,8,32))[0,*]])
   for i = 0,255 do begin
      spp_swp_sweepv_new_tslut, sweepv, $
                                defv1, $
                                defv2, $
                                spv, $
                                fsindex_tmp, $
                                tsindex, $
                                nen = nen/4,$
                                spfac=spfac
      if i eq 0 then index = tsindex $
      else index = [index,tsindex]
   endfor
   tsindex=index

   events = (spp_apdat('3b9'x)).array
   rates  = (spp_apdat('3bb'x)).array
   hkp    = (spp_apdat('3be'x)).array
  
   peak_step = hkp.peak_Step

   e_good = where(events.time GE trange[0] AND $
                  events.time LE trange[1],e_cc)

   nn  = n_elements(rates.time)
   tmp  = indgen(nn,/long)*2

   step_time = indgen(nn*2*32,/long)/32. ;assuming 32 energy bins
   full_1 = replicate(1,nn*32)
   full_0 = intarr(nn*32)
   full   = reform(transpose(reform([full_1, full_0],32,nn,2),[0,2,1]),32*nn*2)
   targeted_1 = replicate(1,nn*32)
   targeted_0 = intarr(nn*32)
   targeted   = reform(transpose(reform([targeted_0, targeted_1],32,nn,2),[0,2,1]),32*nn*2)

   tim_int = interpol(rates.time, tmp, step_time)
   bin = value_locate(tim_int,events.time, /l64)
   
   targeted = temporary(targeted[bin])
   full     = temporary(full[bin])
   channel = 10
   ;pp_f = where(full NE 0 AND e_good AND events.channel EQ channel)
   ;pp_t = where(targeted NE 0 AND e_good AND events.channel EQ channel)
   pp_f = where(full NE 0 AND e_good)
   pp_t = where(targeted NE 0 AND e_good)

   ;; Plot Full and Targeted
   print, "Plotting ... "
   ;popen, "~/Desktop/events_spec",/landscape
   ;!p.multi=[0,0,2]
   energy_bins = (bin MOD 32)[pp_t] > 0
   ;energy_bins2 = nrg_bins[energy_bins]
   tof = events[pp_t].tof
   ;min2 = min(energy_bins2)
   ;max2 = max(energy_bins2)
   min2 = min(energy_bins)
   max2 = max(energy_bins)
   bin2 = 1
   print, 'bin2', bin2
   ;h2d_a =HIST_2D(tof, energy_bins2, bin1=1,bin2=bin2,min2=min2,max2=max2)
   h2d_a =HIST_2D(tof, energy_bins, bin1=1,bin2=bin2,min2=min2,max2=max2)
   m1 = floor((max2-min2)/bin2) + 1
   energies = indgen(m1)*bin2+min2

   xx_tof = indgen((size(h2d_a))[1])*0.101725
   m1p = where(xx_tof GT 8 AND xx_tof LT 12,cc)
   m2p = where(xx_tof GT 12 AND xx_tof LT 20,cc)

   !p.multi=[0,0,2]
   mass = m1p
   contour, alog(h2d_a[mass,1:m1-1]>1e-2),xx_tof[mass],nrg_bins[1:m1-1],$
            ;energies[0:m1-2],$
            ;yrange=[400,600],$
            /xlog,$
            ;xr=[5,150],$
            xs=1, $
            nlevel=100,/fill,ys=1,zr=[1.,10.2],$
            title='Full H+',xtitle='ns'

   mass = m2p
   contour, alog(h2d_a[mass,1:m1-1]>1e-2),xx_tof[mass],nrg_bins[1:m1-1],$
            ;energies[0:m1-2],$
            ;yrange=[400,600],$
            /xlog,$
            ;xr=[5,150],$
            xs=1, $
            nlevel=100,/fill,ys=1,zr=[1.,10.2],$
            title='Full H2+',xtitle='ns'
   !p.multi=0

   ;energy_bins = (bin MOD 32)[pp_f]
   ;tof = events[pp_f].tof
   ;h2d_b =HIST_2D(tof, energy_bins, bin1=1,bin2=1)
   ;contour,alog(h2d_b[*,1:31]>1e-4),$
   ;        indgen(2465)*0.101725, indgen(31),$
   ;        /xlog,xr=[5,150],xs=1,nlevel=100,$
   ;        /fill,ys=1,zr=[4.,10],$
   ;        title='Targeted',xtitle='ns'
   ;pclose
   stop


END








PRO spp_swp_spi_times

   message,'not to be run!'



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 0th Calibration   ;;;
;;;       2016-XX-XX          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;; ASK DAVIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 1st Calibration   ;;;
;;;       2016-10-24          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; First Rotation Scan
   trange = ['2016-10-24/05:31:00', '2016-10-24/06:38:00']  
   
   ;; First  Ion Beam Characterization LIN-YAW
   trange = ['2016-10-24/08:01:00', '2016-10-24/10:13:00']  
   
   ;; Second Ion Beam Characterization YAW-LIN
   trange = ['2016-10-24/15:03:00', '2016-10-24/17:22:00']  
   
   ;; Third  Ion Beam Characterization YAW-LIN
   trange = ['2016-10-25/04:00:00', '2016-10-25/06:20:00']  
   
   ;; Deflector-YAW scan
   trange = ['2016-10-26/04:00:00', '2016-10-26/06:00:00']    
   
   ;; YAW-Deflector scan
   trange = ['2016-10-26/23:21:30', '2016-10-27/01:06:30']  
   


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 2nd Calibration    ;;;
;;;         SNOUT2             ;;;
;;;       2016-12-03           ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; THRESHOLD SCANS

   ;; START 0- STOP 0  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/01:58:00','2016-12-04/02:30:00']
   ;; Channel 0- MCP 0xd000
   trange=['2016-12-04/02:30:00','2016-12-04/02:40:00']
   ;; STOP 1 - MCP 0xd400, 0xd800, 0xdC00, 0xe000- 
   trange=['2016-12-04/02:44:00','2016-12-04/03:04:00']
   ;; Channel 1- MCP 0xd000 
   trange=['2016-12-04/03:04:00','2016-12-04/03:15:00']
   ;; START 2- STOP 2  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/03:15:00','2016-12-04/03:52:00']
   ;; Channel 2 - MCP 0xd000
   ;; NEED MORE INTEGRATION TIME
   ;; STOP 3 - MCP 0xd400, 0xd800, 0xdC00, 0xe000- 
   trange=['2016-12-04/03:52:00','2016-12-04/04:10:00']
   ;; Channel 3- MCP 0xd000
   ;; NEED MORE INTEGRATION TIME
   ;; START 4- STOP 4  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/05:01:00','2016-12-05/05:38:00']
   ;; Channel 4- MCP 0xd000
   ;; NEED MORE INTEGRATION TIME
   ;; STOP 5  - MCP 0xd400, 0xd800, 0xdC00, 0xe000 - 
   trange=['2016-12-04/05:38:00','2016-12-04/05:58:00']
   ;; Channel 5- MCP 0xd000
   trange=['2016-12-04/05:58:00','2016-12-04/06:06:00']
   ;; START 6  - STOP 6  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/06:12:00','2016-12-04/06:46:00']
   ;; Channel 6- MCP 0xd000
   trange=['2016-12-04/06:46:00','2016-12-04/06:50:00']
   ;; STOP 7   - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/06:53:00','2016-12-04/07:10:00']
   ;; Channel 7- MCP 0xd000
   trange=['2016-12-04/07:10:00','2016-12-04/07:14:00']
   ;; START 8  - STOP 8  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/07:25:00','2016-12-04/08:16:00']
   ;; Channel 8- MCP 0xd000
   trange=['2016-12-04/08:16:00','2016-12-04/18:00:00']
   ;; STOP 9  -  MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/18:13:00','2016-12-04/18:40:00']
   ;; Channel 9- MCP 0xd000
   trange=['2016-12-04/18:40:00','2016-12-04/18:41:00']
   ;; START 10 - STOP 10  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/18:41:00','2016-12-04/19:34:00']
   ;; Channel 10- MCP 0xd000
   trange=['2016-12-04/19:34:00','2016-12-04/22:20:00']
   ;; START 11 - STOP 11  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/22:20:00','2016-12-04/23:15:00']
   ;; Channel 11- MCP 0xd000
   trange=['2016-12-04/23:15:00 - 2016-12-04/23:35:00']
   ;; START 12 - STOP 12  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-04/23:37:00','2016-12-05/00:28:00']
   ;; Channel 12- MCP 0xd000
   trange=['2016-12-04/00:28:00','2016-12-05/01:00:00']
   ;; START 13 - STOP 13  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-05/01:00:00','2016-12-05/01:51:00']
   ;; Channel 13- MCP 0xd000
   trange=['2016-12-05/01:51:00','2016-12-05/02:10:00']
   ;; START 14 - STOP 14  - MCP 0xd400, 0xd800, 0xdC00, 0xe000
   trange=['2016-12-05/02:12:00','2016-12-05/03:02:00']
   ;; Channel 14- MCP 0xd000 
   trange=['2016-12-05/03:02:00','2016-12-05/03:35:00']
   
   ;;... add the rest


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 3rd Calibration   ;;;
;;;      CAL Facility         ;;;
;;;       2016-12-12          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; First Rotation Scan
   trange=['2016-12-13/04:56:00','2016-12-13/06:25:00']




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 4th Calibration ;;;
;;;      CAL Facility       ;;;
;;;       2017-01-02        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   
   ;; Limited Performance Test
   trange = ['2017-01-02/18:10:00','2017-01-02/18:40:00']

   ;; Ramp MCP 0x0 - 0xD000, RAW 0xD000, ACC 0x0
   trange = ['2017-01-02/18:50:00', '2017-01-02/19:31:00']

   ;; RAW 0xD000, MCP 0xD000, ACC 0x0
   trange = ['2017-01-02/19:31:00', '2017-01-02/23:24:00']

   ;; Ramp ACC 0x0 - 0xFF00, RAW 0xD000, MCP 0x0
   trange = ['2017-01-02/23:34:00', '2017-01-03/01:36:00']

   ;; RAW 0xD000, MCP 0x0, ACC 0xFF00
   trange = ['2017-01-03/01:36:00', '2017-01-03/17:56:00']

   ;; Ramp MCP 0x0 - 0xD000
   ;; RAMP ACC 0x0 - 0xFF00
   ;; RAW 0xD000
   trange = ['2017-01-03/18:00:00', '2017-01-03/19:35:00']

   ;; Rotation Scan
   trange = ['2017-01-03/19:30:00' - '2017-01-03/22:00:00']
   
   ;; Threshold Scan of all STARTS and STOPS
   ;; RAW 0xD000, ACC 0xFF00, MCP-0xD000 - gun-0.75mA-480V
   ;; Thresh 60-5, AZ 0-3
   trange = ['2017-01-04/06:00:00' - '2017-01-04/16:00:00']

   ;; Long exposure on channel 15
   ;; RAW 0xD000, ACC 0xFF00, MCP-0xD000 - gun-0.75mA-480V
   trange=['2017-01-04/14:45:00','2017-01-04/19:50:00']

   
   ;; Threshold Scan of channel 12 (yellow)
   ;; RAW 0xD000, ACC 0xFF00 - gun 480V
   ;; MCP - 0xD000,0xD800,0xE000
   ;; Gun - 0.70A, 0.75A, 0.80A
   trange = ['2017-01-04/22:36:00', '2017-01-05/03:41:00']


   ;; Long exposure on channe; 12
   ;; RAW 0xD000, ACC 0xFF00, MCP-0xD000 - gun-0.75mA-480V
   trange = ['2017-01-05/03:41:00', '2017-01-05/06:20:00']


   ;; Gun Map (overnight 4th-5th)
   trange = []

   ;; Rotation Scan
   trange = ['2017-01-06/05:30:00', '2017-01-06/09:40:00']






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai 5th Calibration ;;;
;;;      CAL Facility       ;;;
;;;       2017-01-10        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;; First Rotation Scan
   ;; Gun at 0.728mA 480V
   trange = ['2017-01-13/18:20:00','2017-01-13/23:00:00']

   ;; Second Rotation Scan (After adjusting TOF offsets)
   ;; Gun at 0.800mA 480V with adjustments
   trange = ['2017-01-17/17:43:00','2017-01-17/23:45:00']

   ;; Gun Map (YAWLIN Scan)
   trange = ['2017-01-18/18:20:00','2017-01-18/20:30:00']

   ;; YAW Scan

   ;; WHEN???

   ;; Threshold Scan
   trange = ['2017-01-19/07:45:00','2017-01-19/16:00:00']

   ;; Threshold Scan channel 10 with varying mcps and gun filament
   trange = ['2017-01-20/06:32:00','2017-01-20/11:15:00']

   ;; K Sweep
   ;trange = ['2017-01-23/05:30:30','2017-01-23/12:36:30']
   trange = ['2017-01-23/04:30:30','2017-01-23/12:36:30']
   trange = time_double(trange)
   files = spp_file_retrieve(/cal,/spani,trange=trange)
   spp_ptp_file_read, files

   ;; Deflector Scan
   trange = ['2017-01-24/07:25:00','2017-01-24/19:00:00']
   trange = time_double(trange)
   files = spp_file_retrieve(/cal,/spani,trange=trange)
   spp_ptp_file_read, files


   ;; Energy-Yaw Scan
   trange = ['2017-02-01/20:41:30','2017-02-01/22:04:50']

   ;; Spoiler-Yaw Scan
   ;; Same day as Energy-Yaw Scan but in the eveninig
   trange = [0]
   



;; Dates only include availability on MAJA

;; NOTES ON DAY 17-02-15/17:00:00 -> 17-02-15/22:30:00
;; Between -55C and -30C
;; Incomplete actuation information in maja


;; NOTES ON DAY 17-02-16/02:00:00 -> 17-02-17/00:00:00
;; Hot Soak 04:00-12:00 Attenuator 07:45-08:00
;; Cold Soak 19:00-21:00 Attenuator 20:00-21:15


;; NOTES ON DAT 17-02-19/00:00 - 17-02-20/00:00:00
;; Instrument cooled down from Hot to room temperatures

;; NOTES ON DAT 17-02-20/00:00 - 17-02-21/00:00:00
;; Going Cold




;; Hot Cycle #1 - Actuation
trange = ['2017-02-15/11:00:00','2017-02-15/12:00:00']

;; Cold Cycle #1 - Actuation
trange = ['2017-02-16/12:00:00','2017-02-16/13:00:00']

;; Hot Cycle #2 - Actuation
trange = ['2017-02-16/18:00:00','2017-02-16/19:00:00']

;; Cold Cycle #2 - Actuation
;trange = 

;; Hot Cycle #3 - Actuation
trange = ['2017-02-17/13:00:00','2017-02-17/14:00:00']

;; Cold Cycle #3 - Actuation
;trange = 

;; Hot Cover Open

;; Hot Cycle #4 - Actuation
trange = ['2017-02-18/12:00:00','2017-02-18/13:00:00']

;; Cold Cycle #4 - Actuation
trange = ['2017-02-20/13:00:00','2017-02-20/14:00:00']

;; Hot Cycle #5 - Actuation
trange = ['2017-02-20/23:00:00','2017-02-21/00:00:00']

;; Cold Cycle #5 - Actuation
trange = ['2017-02-21/11:00:00','2017-02-21/12:00:00']



;; Hot Cycle #6 - Actuation
;trange = 

;; Cold Cycle #6 - Actuation
trange = ['2017-02-22/09:00:00','2017-02-22/09:00:00']






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; SPAN-Ai Thermal Vacuum  ;;;
;;;     Snout2 Facility     ;;;
;;;       2017-01-15        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   
   ;; -------------------------- CPT --------------------------
   ;; Delay Line Test
   trange = ['2017-02-15/20:50:00','2017-02-15/21:10']
   ;; Pulser Test
   trange = ['2017-02-15/21:14:10','2017-02-15/21:49:30']


   ;; ------------------------- CPT ---------------------------
   trange = ['2017-02-16/06:37:05','2017-02-16/07:43:35']

   ;; Delay Line Test
   trange = ['2017-02-16/06:39:30','2017-02-16/06:53:50']
   ;; Pulser Test
   trange = ['2017-02-16/06:53:50','2017-02-16/07:26:42']
   ;; Threshold Scan
   trange = ['2017-02-16/07:26:42','2017-02-16/07:43:00']


   ;; --------------------- Hot CPT ---------------------------
   ;trange = []

   ;; CPT HOT #3 with HV on
   trange = ['2017-02-17/19:07:00']


   ;; NOTE: Only turned on all products no

   ;; Delay Line Test
   trange = ['2017-02-17/19:09:14','2017-02-17/19:23:13']
   ;; Pulser Test
   trange = ['2017-02-17/19:23:13','']


   ;; ------------------------- CPT ---------------------------
   trange = ['2017-02-17/00:51:40','2017-02-17/02:07:20']
   

   











;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                SPAN-Ai Flight Calibration                    ;;;
;;;                       CAL Facility                           ;;;
;;;                        2017-03-07                            ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


   ;;---------------------------------------------------------------
   ;; Gun Map
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.80 [A]
   trange = ['2017-03-09/04:12:00','2017-03-09/22:36:00']

   ;; First Half
   tt_gunmap_11 = ['2017-03-09/04:25:10','2017-03-09/06:22:10']
   ;; Second Half
   tt_gunmap_12 = ['2017-03-09/20:25:20','2017-03-09/22:15:00']

   
   
   ;; Rotation Scan before TOF correction
   tt_rotscan_1 = ['2017-03-10/07:28:20','2017-03-10/08:44:40']
   ;; Rotation Scan after TOF correction
   ;rotscan2 = [
   
  
   ;;---------------------------------------------------------------
   ;; Threshold Scan
   ;;
   ;; INFO
   ;;   - CFD Threshold scan of all START and STOP channels.
   ;; CONFIG
   ;;   - AZ  = [0,1,2,3]
   ;;   - RAW = [0xD000]
   ;;   - MCP = [0xD000]
   ;;   - ACC = [0xFF00]
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_thresh_scan1 = ['2017-03-12/05:47:00','2017-03-12/19:00:00']
   
   
   ;;---------------------------------------------------------------
   ;; Rotation Scan
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_rotscan_2 = ['2017-03-13/07:12:35','2017-03-13/08:32:45']


   ;;---------------------------------------------------------------
   ;; Energy Angle Scan
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_eascan_1 = ['2017-03-13/18:21:00','2017-03-13/23:47:00']


   ;;---------------------------------------------------------------
   ;; Constant YAW, Sweeping Deflector - HIGH DETAIL - ANODE 0x0
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]
   tt_def_sweep_1 = ['2017-03-14/06:31:50','2017-03-14/10:04:30']


   ;;---------------------------------------------------------------
   ;; Constant YAW, Sweeping Deflector - COARSE - ALL ANODES
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.85 [A]

   ;; Anode 0x0 - 0x1
   tt_def_sweep_2 = ['2017-03-14/18:28:00','2017-03-14/22:30:00']

   ;; Anode 0x2 - 13 or 14 (check)
   tt_def_sweep_3 = ['2017-03-15/05:12:00','2017-03-15/22:02:00']






   
   ;;---------------------------------------------------------------
   ;; Constant YAW, Sweeping Deflector - Fine - anodes 9,10,11,12,13
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=500.,deltaEE=0.3'
   ;;   - Resiudal Gas Gun
   ;;     + Gun V = 480 [V]
   ;;     + Filament I = 0.80 [A]
   tt_def_sweep_4=['2017-03-21/07:38:30','2017-03-21/17:46:00']

   ;; Anode 0x9
   tt_def_sweep_5=['2017-03-21/07:36:50','2017-03-21/09:16:05']

   ;; Anode 0xA
   tt_def_sweep_6=['2017-03-21/09:41:50','2017-03-21/11:21:50']

   ;; Anode 0xB
   tt_def_sweep_7=['2017-03-21/11:47:00','2017-03-21/13:30:00']

   ;; Anode 0xC
   tt_def_sweep_8=['2017-03-21/13:51:30','2017-03-21/15:33:30']

   ;; Anode 0xD
   tt_def_sweep_9=['2017-03-21/15:57:00','2017-03-21/17:33:50']

   ;; Anode 0xE
   ;; Happened only partially, this is when linear stage of manipulator broke


   ;; Turned back on 05:55
   ;; Quick Rotation scan to get beam back to anode 0
   trange = ['2017-03-22/06:00:00', '2017-03-22/06:15:00']

 
   ;; Sweep YAW with constant deflector
   ;; Anode 0x0 and partially Anode 0x1
   trange = ['2017-03-22/06:16:20', '2017-03-22/11:49:40']

   ;; Anode 0x4 and partially Anode 0x5
   trange = ['2017-03-22/11:49:30', '2017-03-22/17:46:00']

   ;; Anode 0xA
   trange = ['2017-03-22/17:46:00', '2017-03-22/23:05:30']


   ;; Energy Scan (k-Factor and Mass Table)
   trange = ['2017-03-23/06:30:10', '2017-03-23/09:17:50']


   ;;---------------------------------------------------------------
   ;; Colutron
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=1000.,deltaEE=0.3'
   ;;   - Nitrogen Gas Gun
   ;;     + Gun V = 1000 [eV]
   ;;     + Filament I = 16.5 [A]
   ;;     + ExB - 50 [V] and varying current for magnet
   tt_mass_scan_1 = ['2017-03-24/17:00:00','2017-03-24/22:00:00']

   tt_mass_scan_h   = ['2017-03-24/21:03:30','2017-03-24/21:17:25']
   tt_mass_scan_h2  = ['2017-03-24/20:57:05','2017-03-24/21:02:40']
   tt_mass_scan_he  = ['2017-03-24/18:36:05','2017-03-24/18:48:45']
   tt_mass_scan_m4  = ['2017-03-24/19:01:15','2017-03-24/19:07:00']
   tt_mass_scan_m5  = ['2017-03-24/19:09:40','2017-03-24/19:13:20']
   tt_mass_scan_m6  = ['2017-03-24/19:22:20','2017-03-24/19:28:30']
   tt_mass_scan_m7  = ['2017-03-24/19:31:35','2017-03-24/19:36:20']
   tt_mass_scan_m8  = ['2017-03-24/19:39:00','2017-03-24/19:42:55']
   tt_mass_scan_m9  = ['2017-03-24/19:43:40','2017-03-24/19:50:25']
   tt_mass_scan_m10 = ['2017-03-24/19:52:40','2017-03-24/20:01:05']
   tt_mass_scan_m11 = ['2017-03-24/20:04:50','2017-03-24/20:12:35']
   tt_mass_scan_m12 = ['2017-03-24/20:15:15','2017-03-24/20:21:10']
   tt_mass_scan_m13 = ['2017-03-24/20:25:10','2017-03-24/20:39:25']  


   
   ;;---------------------------------------------------------------
   ;; Colutron
   ;;
   ;; INFO
   ;;   - ACC Scan
   ;; CONFIG
   ;;   - Table = 'spani_reduced_table,center_energy=1000.,deltaEE=0.3'
   ;;   - Gas Mix
   ;;     + Gun V = 1000 [eV]
   ;;     + Filament I = 16.5 [A]
   ;;     + ExB - 50 [V] and varying current for magnet
   tt_acc_scan = ['2017-03-24/22:00:00', '2017-03-25/01:00:00']

   tt_acc_scan_co2_1 = ['2017-03-24/22:22:29', '2017-03-24/22:41:19']
   tt_acc_scan_co2_2 = ['2017-03-24/23:32:10', '2017-03-24/23:47:19'] 

   tt_acc_scan_h_1 = ['2017-03-25/00:09:20', '2017-03-25/00:25:50']
   tt_acc_scan_h_2 = ['2017-03-25/00:25:50', '2017-03-25/00:45:40']



   ;; tt = '2017-03-25/06:00:00' - Not much going on, i.e. no counts.
   




   ;;---------------------------------------------------------------
   ;; Sweep YAW Constant Deflector 
   ;;
   ;; INFO
   ;;   - Davin Scan's
   ;;   - Residual Gas
   ;; CONFIG
   ;;   - Table = ???
   ;;   - Residual Gas
   ;;   - Gun energy = 700
   trange = ['2017-03-25/08:06:30', '2017-03-25/11:13:00']

   ;;   - Gun energy = 1000
   trange = ['2017-03-25/11:13:00', '2017-03-25/14:52:00']

   ;;   - Gun energy = 1500
   trange = ['2017-03-25/15:05:00', '2017-03-25/18:30:00']

   ;;   - Gun energy = 2000
   trange = ['2017-03-25/18:30:00', '2017-03-25/22:18:00']





   ;;---------------------------------------------------------------
   ;; Long term anode 11 with 2kV beam
   trange = ['2017-03-26/01:58:30', '2017-03-26/02:11:20']


   
   ;;---------------------------------------------------------------
   ;; Energy Scan using Davin's tables
   tt_e_scan_d1 = ['2017-03-26/01:58:30', '2017-03-26/02:11:20']
   tt_e_scan_d2 = ['2017-03-26/02:34:25', '2017-03-26/02:43:30']
   tt_e_scan_d3 = ['2017-03-26/03:13:20', '2017-03-26/03:23:00']
   tt_e_scan_d4 = ['2017-03-26/04:21:55', '2017-03-26/04:30:45']

   tt_e_scan_d_anodes = ['2017-03-26/08:41:10', '2017-03-26/10:36:20']

   tt_e_scan_d_an11_1 = ['2017-03-26/08:23:10', '2017-03-26/08:31:10']
   tt_e_scan_d_an11_2 = ['2017-03-26/08:31:10', '2017-03-26/08:39:20']

   tt_e_scan_d_an15 = ['2017-03-26/08:39:20', '2017-03-26/08:48:30']
   tt_e_scan_d_an14 = ['2017-03-26/08:48:30', '2017-03-26/08:55:50']
   tt_e_scan_d_an13 = ['2017-03-26/08:55:50', '2017-03-26/09:02:40']
   tt_e_scan_d_an12 = ['2017-03-26/09:02:40', '2017-03-26/09:10:10']
   tt_e_scan_d_an11 = ['2017-03-26/09:10:10', '2017-03-26/09:17:10']
   tt_e_scan_d_an10 = ['2017-03-26/09:17:10', '2017-03-26/09:24:10']
   tt_e_Scan_d_an09 = ['2017-03-26/09:24:10', '2017-03-26/09:31:20']
   tt_e_scan_d_an08 = ['2017-03-26/09:31:20', '2017-03-26/09:38:20']
   tt_e_scan_d_an07 = ['2017-03-26/09:38:20', '2017-03-26/09:45:20']
   tt_e_scan_d_an06 = ['2017-03-26/09:45:20', '2017-03-26/09:52:10']
   tt_e_scan_d_an05 = ['2017-03-26/09:52:10', '2017-03-26/09:59:10']
   tt_e_scan_d_an04 = ['2017-03-26/09:59:10', '2017-03-26/10:06:10']
   tt_e_scan_d_an03 = ['2017-03-26/10:06:10', '2017-03-26/10:13:20']
   tt_e_scan_d_an02 = ['2017-03-26/10:13:20', '2017-03-26/10:20:20']
   tt_e_scan_d_an01 = ['2017-03-26/10:20:20', '2017-03-26/10:27:10']
   tt_e_scan_d_an00 = ['2017-03-26/10:27:10', '2017-03-26/10:34:50']

   
   "That's it."
   
   

   
   ;; Load Selected Time Range
   files = spp_file_retrieve(/cal,/spani,trange=trange)
   files = spp_file_retrieve(/cal,/spani,trange=systime(1))
   files = spp_file_retrieve(/cal,/spani,recent=2/24.)
   spp_ptp_file_read, files
   spp_init_realtime,/cal,/spani,/exec,recent=.01
   spp_swp_tplot,/setlim
   spp_swp_tplot,'si'
   spp_swp_gse_pressure_file_read ; load chamber pressure






























;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;              SPAN-Ai Flight Post-Workmanship Vibe            ;;;
;;;                      Snout2 Facility                         ;;;
;;;                        2017-04-04                            ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



   ;;---------------------------------------------------------------
   ;; CPT
   ;;
   ;; INFO
   ;;   - 
   ;; CONFIG
   ;;   - 
   ;;   - 
   ;;     
   ;;     
   ;;     
   trange=['2017-04-05/02:33:21']



   ;; Another CPT, this time with Science products.
   trange = ['2017-04-07/05:07:18']




   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;              SPAN-Ai Flight Post-Workmanship Vibe            ;;;
;;;                      Snout2 Facility                         ;;;
;;;                        2017-04-04                            ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;Post EMC CPT
   trange = ['2017-04-17/20:35:00']

   ;;Post EMC Cover Open (April 21st) and CPT
   trange = ['2017-04-17']




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                      SPAN-Ai Flight EMC                      ;;;
;;;                       APL EMC Facility                       ;;;
;;;                          2017-04-27                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   
   trange = ['2017-04-27/22:38:00']

   ;; RS-03 Test (20V/m and 1V/m) from 100 MHz to 200 MHz
   trange = ['2017-04-28/20:40:00', '2017-04-28/21:35:00']


   ;; RS-03 20V/m Amplitude from 200 MHz to 1 GHz
   trange = ['2017-04-29/13:30:00', '2017-04-29/14:40:00']

   ;; RS-03 1V/m  Amplitude from 900 MHz to 1 GHz
   trange = ['2017-04-29/14:40:00', '2017-04-29/14:50:00']

   ;; RS-03 20V/m Amplitude 1 GHz to 4.2 GHz
   trange = ['2017-04-29/14:58:00', '2017-04-29/15:56:00']

   ;; RS-03 20V/m Amplitude 1 GHz to 1.3 GHz
   trange = ['2017-04-29/15:57:00', '2017-04-29/16:14:00']   

   ;; RS-03 20V/m Amplitude 4.2 GHz to 18 GHz
   trange = ['2017-04-29/18:05:00', '2017-04-29/19:12:00']

   ;; RS-03 20V/m Amplitude 8.33 GHz to 8.53 GHz, Vertical Polarization
   trange = ['2017-04-29/19:12:00', '2017-04-29/19:18:00']
   
   ;; RS-03 20V/m Amplitude 8.33 GHz to 8.53 GHz, Horizontal Polarization
   trange = ['2017-04-29/19:29:00', '2017-04-29/19:35:00']   

   ;; RS-03 40V/m Amplitude 4.5 GHz to 4.9 GHz
   trange = ['2017-04-29/19:36:00', '2017-04-29/19:53:30']

   ;; RS-03 66V/m Amplitude 5.76 GHz to 5.77 GHz
   trange = ['2017-04-29/19:54:00', '2017-04-29/19:57:30']

   ;; RS-03 26V/m Amplitude 9.38 GHz to 9.44 GHz
   trange = ['2017-04-29/19:57:30', '2017-04-29/20:00:30']

   ;; RS-03 26V/m Amplitude 2.2 GHz to 2.3 GHz
   trange = ['2017-04-29/20:01:00', '2017-04-29/20:07:30']

   ;; RS-03 31V/m Amplitude 2.86 GHz to 2.87 GHz
   trange = ['2017-04-29/20:08:30', '2017-04-29/20:13:30']
   
   ;; RS-03 20V/m Amplitude 14 kHz to 100 MHz (SPAN-A)
   trange = ['2017-04-29/20:26:00', '2017-04-29/21:11:00']

   ;; RS-03 20V/m Amplitude 14 kHz to 100 MHz (SPAN-B / SWEM)
   trange = ['2017-04-29/21:14:00','2017-04-29/22:02:00']

   ;; RS-03 1V/m  Amplitude 6 MHz to 100 MHz (SPAN-B / SWEM)
   trange = ['2017-04-29/22:22:00', '2017-04-29/22:39:00']

   ;; RS-03 20V/m Amplitude 6MHz - 100 MHz
   trange = ['2017-05-01/13:50:00', '2017-05-01/14:11:00']
   ;; Noise starting at 50MHz and ending at 100MHz

   ;; CPT
   trange = ['2017-05-01/16:10:00', '2017-05-01/17:40:00']

   ;; Cover open and Actuator Test
   trange = ['2017-05-02/13:31:00']









;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                      SPAN-Ai Flight CPT                      ;;;
;;;                       APL EMC Facility                       ;;;
;;;                          2017-06-29                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   trange = ['2017-06-29/18:25:00']

   
END

