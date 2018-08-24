; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-08-23 08:59:38 -0700 (Thu, 23 Aug 2018) $
; $LastChangedRevision: 25689 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spane_thresh_analysis.pro $

;; WORK IN PROGRESS

pro spp_swp_spane_thresh_analysis,sensor,no_stim,anode,mcp,sigma,goddard = goddard,separate = separate, trangefull=trangeFull,data=data,plotname=plotname

  if not keyword_set(sensor) then begin
    print, 'No sensor selected; defaulting to SPAN-Ae'
    sensor = 1
  endif
  if sensor eq 1 then begin
    tplotString = 'spp_spa_'
    plotString = 'SPANA_'
  endif
  if sensor eq 2 then begin
    tplotString = 'spp_spb_'
    plotString = 'SPANB_'
  endif
  if not keyword_set(mcp) then mcp = 0
  if ~keyword_set(no_stim) then no_stim = 0




; list conditions
; need to run tlimit outputting trangeFull as boundaries (first of anode, then of whole test as this script get more sophisticated)
  if not keyword_set(separate) then separate = 0
  if not keyword_set(trangefull) then ctime,trangeFull,npo=2
  
  

  timebar,trangeFull
  
  ;;Attempting to improve fits / derivatives by smoothing Anode spectra;;
  tsmooth2, '*spb*AF0*ANODE*SPEC', 10, newname = 'spp_spb_AF0_ANODE_SPEC_smooth10'
  ;;Sample the relevant data;;
  specAnode = tsample(tplotString + 'AF0_ANODE_SPEC', trangeFull, time = timeSpecAnode)
  specAnodeSmooth = tsample(tplotString + 'AF0_ANODE_SPEC_smooth10', trangeFull)
  threshAnode = tsample(tplotString + 'hkp_MRAM_WR_ADDR', trangeFull, time = timeThreshAnode)
  mcpDACanode = tsample(tplotString + 'hkp_MCP_DAC', trangeFull)
  anodeNumber = tsample(tplotString + 'hkp_MRAM_WR_ADDR_HI', trangeFull)
  mcpVanode = tsample(tplotString + 'hkp_ADC_VMON_MCP', trangeFull)
  
  threshIntAnode = interpol(threshAnode, timeThreshAnode, timeSpecAnode)
  mcpDACintAnode = interpol(mcpDACanode, timeThreshAnode, timeSpecAnode)
  anodeNumberInt = interpol(anodeNumber, timeThreshAnode, timeSpecAnode)
  mcpVintAnode = interpol(mcpVanode, timeThreshAnode, timeSpecAnode)
  
  ;;; Do a separate analysis if there are no counts present ;;;
  ;;; This section was written using a dataset where MCPS are no, but no electrons used as stimuli;;;
  if no_stim then begin
    threshes = []
    anodeNumberArr = []
    countsAnodeArr = []
    printdat, countsAnode
    ;!p.multi = [0,4,4]
    

    good2 = 1
    good2 = good2 and (threshIntAnode gt 100)
    for i = 0, 15 do begin
      good = 1
      good = good and (threshIntAnode ne 0) ; only times when the threshold test is running
      good = good and (anodeNumberInt eq i)
      goodall = good or good2
      itrThreshAnode = threshIntAnode[where(goodall)]
      itrCountsAnode = specAnode[where(goodall), i]
      wi, 1
      arrNum = n_elements(itrThreshAnode)
      anodeNumberArr = [anodeNumberArr, make_array(arrNum, /integer, value = i)]
      countsAnodeArr = [countsAnodeArr, itrCountsAnode]
      threshes = [threshes,itrThreshAnode]
      printdat, goodall
      plot, threshes[where(anodeNumberArr eq i)], countsAnodeArr[where(anodeNumberArr eq i)], yrange = [0.1, 10], xrange = [70,110], title = tplotString + ' ' + "Anode " + strtrim(i,2), ytitle = "Counts", xtitle = "Threshold DAC Level"
      print, 'nothing'
    endfor
  endif
  
  
  
;  ;;;Begin Old Code;;; ;
  
   ;;;Snag TPLOT Variables:DEPRECATED;;;
;  specAnode = tsample(tplotString + 'AF0_ANODE_SPEC', trangeFull, time = timeSpecAnode)
;  threshAnode = tsample(tplotString + 'hkp_MRAM_WR_ADDR', trangeFull, time = timeThreshAnode)
;  mcpDACanode = tsample(tplotString + 'hkp_MCP_DAC', trangeFull)
;  anodeNumber = tsample(tplotString + 'hkp_MRAM_WR_ADDR_HI', trangeFull)
;  mcpVanode = tsample(tplotString + 'hkp_ADC_VMON_MCP', trangeFull)
;  ;;;Create Interpolated Housekeeping Values:DEPRECATED;;;
;  threshIntAnode = interpol(threshAnode, timeThreshAnode, timeSpecAnode)
;  mcpDACintAnode = interpol(mcpDACanode, timeThreshAnode, timeSpecAnode)
;  anodeNumberInt = interpol(anodeNumber, timeThreshAnode, timeSpecAnode)
;  mcpVintAnode = interpol(mcpVanode, timeThreshAnode, timeSpecAnode)
  

  
  ;;;Combined MCP-Threshold Test Calcs;;;
  if mcp eq 1 then begin
    if ~keyword_set(anode) then begin
      print, 'No Anode keyword set: default to 0!'
      anode = 0
    endif
    if ~keyword_set(sigma) then begin
      print, 'No sigma defined: default to 100!'
      sigma = 100
    endif
    ; Select valid counts with boolean filter ; 
    good = 1
    good = good and (threshIntAnode gt 80) 
    good = good and (threshIntAnode ne 0)
    good = good and (threshIntAnode lt 260); cut out counts from when threshold is below noise.
    good = good and (specAnode[*,anode] lt 1000) ; average max real counts is ~ couple hundred
    ;good = good and (anodeNumber ne '1f'x) ; set anode equal to 0x1f when not active or when rotating.
    
    hkp = create_struct('time',timeThreshAnode, 'thresh', threshAnode, 'mcpdac', mcpDACanode, 'mcpv', mcpVanode, 'anode', anodeNumber)
    
    preFilter = create_struct('time', timeSpecAnode, 'thresh', threshIntAnode, 'mcpdac', mcpDACintAnode, 'mcpv', mcpVintAnode, $
                              'anode', anodeNumberInt, 'counts', specAnode, 'smoothcounts', specAnodeSmooth)
  
    condition = where(good)
    filterDat = create_struct('time', preFilter.time[condition], 'thresh', preFilter.thresh[condition], 'mcpdac', preFilter.mcpdac[condition], $
                              'mcpv', preFilter.mcpv, 'anode', preFilter.anode[condition], 'counts', preFilter.counts[condition,*], 'smoothcounts', preFilter.smoothcounts[condition,*])
    
                              
    uniqueMCP = filterDat.mcpdac[uniq(filterDat.mcpdac)]
    ; define a better green.
    tvlct, 53, 156, 83, 100
    colorArray = [6, 100, 2, 1, 0] ; r, g, b, m, k
    ;colorArray = [250,300,350,400,450]
    ;indexArray = [4,3,2,1,0]        
                              
    for i = 0,n_elements(uniqueMCP)-1 do begin
      ;sort by mcp value.
      mcpCriteria = 1
      print, 'iteration # ' + strtrim(i)
      mcpCriteria = mcpCriteria and (filterDat.mcpdac eq uniqueMCP[i])
      mcpCondition = where(mcpCriteria)
      counts = filterDat.counts[mcpCondition, anode]
      smoothcounts = filterDat.smoothcounts[mcpCondition, anode] ;; for diagnostic
      threshDACs = filterDat.thresh[mcpCondition]
      mcpVs = filterDat.mcpv[mcpCondition]
      mcpVavg = mean(mcpVs)
      wi, (anode + 2), wsize = [600,600]
      yrange = [0,220]
      !p.multi = [0,1,2]
      if i eq 0 then begin
        plot,threshDACs,counts,psym=4, yrange = yrange,xtitle='Threshold DAC level',ytitle='Counts', title = 'SPAN-B Flight Anode ' + strtrim(anode,2)
        p1 = !P & x1 = !X & y1 = !Y ; holds plot values
      endif else begin
        !p = p1 & !x = x1 & !y = y1
      endelse
      oplot, threshDACs, counts, psym = 4, color = colorArray[i]
      sigmaCounts = stddev(counts)
      meanCounts = mean(counts)
      sigmaCounts = stddev(counts)
      printdat, sigmaCounts
      ;--------------------------------------
      ;eliminate values more than 3sigma away
      ;this will be replaced by something more statistically rigid.
      sigmaCriteria = 1
      sigmaCriteria = sigmaCriteria and (counts lt (meanCounts + (sigma * sigmaCounts))) and (counts gt (meanCounts - (sigma * sigmaCounts)))
      sigmaCondition = where(sigmaCriteria)
      countsValid = counts[sigmaCondition]
      threshDACsValid = threshDACs[sigmaCondition]
      ;--------------------------------------
      ;calculate fit
      range = [min(threshDACs),max(threshDACs)]
      xp = dgen(4,range=range)
      printdat, xp
      yp = xp*0+300
      xv = dgen()
      printdat, yp
      printdat, xv
      yv = spline_fit3(xv,xp,yp,param=p,/ylog)
      weights = 1.0/countsValid
      fit, threshDACsValid, countsValid, weight = weights, param=p
      fitThresh = func(xv, param = p) 
      derivfunction = -deriv(xv,fitThresh);func(xv,param=p))
      candidateThresh = xv[where(derivfunction eq min(derivfunction[0:50]))] ;; kludge to get threshold that isn't artificially high
      oplot, xv, fitThresh
      plt1 = get_plot_state()
      ver, candidateThresh, color = fsc_color('green')
      altYrange = [0,3.]
      if i eq 0 then begin
        plot,xv,derivfunction,xtitle='Threshold DAC level, Thresh = ' + strtrim(candidateThresh, 2),ytitle='PHD', yrange = altYrange
        
        p2 = !P & x2 = !X & y2 = !Y
      endif else begin
        !p = p2 & !x = x2 & !y = y2
      endelse
      oplot,xv,derivfunction, color = colorArray[i] ;oplot
      plt2 = get_plot_state()
      ver, candidateThresh, color = fsc_color('green')
      ; if separate flag set then also plot these on individual plots
      if separate eq 1 then begin
        wi, (anode + i + 10), wsize = [600,600]
        plot,threshDACs,counts,psym=4, yrange = yrange,xtitle='Threshold DAC level',ytitle='Counts', title = 'SPAN-B Flight Anode ' + strtrim(anode,2) + 'MCP = ' + strtrim(mcpVavg,2)
        oplot,threshDACs,counts,psym=4, color = colorArray[i]
        pf, p, /over;color = colorArray[i], /over
        plot,xv,derivfunction,xtitle='Threshold DAC level',ytitle='PHD'
        oplot,xv,derivfunction, color = colorArray[i]
        makepng, plotString + 'Anode' + strtrim(anode,2) + '_MCPV' + strtrim(round(mcpVavg),2) + '_timestamp' + strtrim(time_string(filterDat.time[0], tformat = 'YYYYMMDDhhmmss'),2)
      endif
      wi, (anode + 2)
      makepng, plotString + 'Anode' + strtrim(anode,2) + '_all_timestamp' + strtrim(time_string(filterDat.time[0], tformat = 'YYYYMMDDhhmmss'), 2)
      !p.multi = 0
      
;      ;;; ------------------------------------------ ;;;
;      ;;; repeat the whole thing for smoothed counts ;;;
;      ;;; ------------------------------------------ ;;;
;      
;      wi, (anode + 12), wsize = [600,600]
;      yrange = [0,220]
;      !p.multi = [0,1,2]
;      if i eq 0 then begin
;        plot,threshDACs,smoothcounts,psym=4, yrange = yrange,xtitle='Threshold DAC level',ytitle='SmoothCounts', title = 'SPAN-B Flight Anode ' + strtrim(anode,2)
;        p1 = !P & x1 = !X & y1 = !Y ; holds plot values
;      endif else begin
;        !p = p1 & !x = x1 & !y = y1
;      endelse
;      oplot, threshDACs, smoothcounts, psym = 4, color = colorArray[i]
;      sigmaCounts = stddev(smoothcounts)
;      meanCounts = mean(smoothcounts)
;      printdat, sigmaCounts
;      ;--------------------------------------
;      ;eliminate values more than 3sigma away
;      ;this will be replaced by something more statistically rigid.
;      sigmaCriteria = 1
;      sigmaCriteria = sigmaCriteria and (smoothcounts lt (meanCounts + (sigma * sigmaCounts))) and (smoothcounts gt (meanCounts - (sigma * sigmaCounts)))
;      sigmaCondition = where(sigmaCriteria)
;      countsValid = smoothcounts[sigmaCondition]
;      threshDACsValid = threshDACs[sigmaCondition]
;      ;--------------------------------------
;      ;calculate fit
;      range = [min(threshDACs),max(threshDACs)]
;      xp = dgen(5,range=range)
;      printdat, xp
;      yp = xp*0+300
;      xv = dgen()
;      printdat, yp
;      printdat, xv
;      yv = spline_fit3(xv,xp,yp,param=p,/ylog)
;      fit,threshDACsValid,countsValid,param=p
;      derivfunction = -deriv(xv,func(xv,param=p))
;      plt1 = get_plot_state()
;      altYrange = [0,3.]
;      if i eq 0 then begin
;        plot,xv,-deriv(xv,func(xv,param=p)),xtitle='Threshold DAC level',ytitle='PHD', yrange = altYrange
;        p2 = !P & x2 = !X & y2 = !Y
;      endif else begin
;        !p = p2 & !x = x2 & !y = y2
;      endelse
;      oplot,xv,derivfunction, color = colorArray[i] ;oplot
;      plt2 = get_plot_state()
;      ; if separate flag set then also plot these on individual plots
;      if separate eq 1 then begin
;        wi, (anode + i + 10), wsize = [600,600]
;        plot,threshDACs,smoothcounts,psym=4, yrange = yrange,xtitle='Threshold DAC level',ytitle='SmoothCounts', title = 'SPAN-B Flight Anode ' + strtrim(anode,2) + 'MCP = ' + strtrim(mcpVavg,2)
;        oplot,threshDACs,smoothcounts,psym=4, color = colorArray[i]
;        pf, p, /over;color = colorArray[i], /over
;        plot,xv,derivfunction,xtitle='Threshold DAC level',ytitle='PHD'
;        oplot,xv,derivfunction, color = colorArray[i]
;        makepng, plotString + 'Anode' + strtrim(anode,2) + '_MCPV' + strtrim(round(mcpVavg),2) + '_timestamp' + strtrim(time_string(filterDat.time[0], tformat = 'YYYYMMDDhhmmss'),2)
;      endif
;      wi, (anode + 2)
;      makepng, plotString + 'Anode' + strtrim(anode,2) + '_all_timestamp' + strtrim(time_string(filterDat.time[0], tformat = 'YYYYMMDDhhmmss'), 2)
;      !p.multi = 0
    endfor
  endif
end
  