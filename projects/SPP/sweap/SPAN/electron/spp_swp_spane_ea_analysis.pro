pro spp_swp_spane_ea_analysis, anode, sensor, plotMaxima, trangeFull

    
  if not keyword_set(trangefull) then ctime,trangeFull
  if not keyword_set(plotMaxima) then plotMaxima = 0
  if not keyword_set(sensor) then begin
    print, 'No sensor selected; defaulting to SPAN-Ae'
    sensor = 1
  endif
  if sensor eq 1 then tplotString = 'spp_spa_'
  if sensor eq 2 then tplotString = 'spp_spb_'


  

  timebar,trangeFull
  
  
  dacArray1k = [2355., 2347., 2340., 2332., 2325., 2317., 2310., 2303., 2295., $
    2288., 2281., 2273., 2266., 2259., 2252., 2244., 2237., 2230., $
    2223., 2216., 2209., 2202., 2195., 2188., 2181., 2174., 2167., $
    2160., 2153., 2146., 2139., 2133.]
    
    


  anodeArray = tsample(tplotString + 'hkp_MRAM_WR_ADDR_HI', trangeFull, time = timeHKP)
  countsArray = tsample(tplotString + 'AF1_CNTS', trangeFull, time = timeData)
  specArray = tsample(tplotString + 'AF1_NRG_SPEC', trangeFull, time = timeDataSpec)
  ;timeManip = timeManip + 2.6
  trangeFull = trangeFull + 2.6
  yawArray = tsample('manip_YAW_POS', trangeFull, time = timeManip)
  yawInterp = interpol(yawArray, timeManip, timeData)
  yawDegrees = indgen(15) - 7
  counter = 0
  wi, 4
  Device, Decomposed=0
  foreach element, yawDegrees, index do begin
  ; find nearest values in the array where the interpolated yaw value is closest to a whole degree
    degVal = element
    yawCritIndex = where(yawInterp lt (degVal + 0.3) and yawInterp gt (degVal - 0.3)) ;indices of all values near degVal
    yawClose = yawInterp[yawCritIndex]
    printdat, yawClose
    startArray = [yawCritIndex[0]]
    endArray = []
    ; find the difference in indices so you can slice up yaw angles
    for i = 1, n_elements(yawCritIndex) - 1 do begin
      printdat, yawCritIndex[i]
      printdat, yawCritIndex[i - 1]
      indexTestCrit = yawCritIndex[i] - yawCritIndex[i - 1]
      printdat, indexTestCrit
      if indexTestCrit ne 1 then begin
        startArray = [startArray, yawCritIndex[i]]
        endArray = [endArray, yawCritIndex[i - 1]]
      endif
    endfor
    endArray = [endArray, yawCritIndex[-1]]
    printdat, endArray
    printdat, startArray
    ; find the closest one in each.
    maximaLoc = []
    for i = 0, n_elements(endArray) - 1 do begin
      differenceArray = yawInterp[startArray[i]:endArray[i]]
      printdat, differenceArray
        difference = differenceArray - degVal
        printdat, difference
        min_diff = min(abs(difference))
        indexPos = where(abs(difference) eq min_diff)
        indexEval = size(indexPos)
        printdat, yawInterp[startArray[i]+indexPos]
        printdat, startArray[i]+indexPos
        print, 'the above should equal the minimum angle value'
      if indexEval[0] ne 1 then indexPos = indexPos[0]
      maximaLoc = [maximaLoc, indexPos + startArray[i]]
    endfor
    averageCountsSpec = mean(specArray[maximaLoc,*], dimension = 1)
    yrange = [0,30]
    ;code to determine what anode is being sampled
    anodeVar = tsample(tplotString + 'hkp*MRAM*WR*ADDR*HI*', trangeFull, time = timeAnodeVar)
    anodeInterp = interpol(anodeVar, timeAnodeVar, timeData)
    anodeVal = round(mean(anodeInterp))
    if counter eq 0 then begin
      plot, dacArray1k, averageCountsSpec, xstyle = 1, ystyle = 1, yrange = yrange, xrange = [min(dacArray1k),max(dacArray1k)], xtitle = 'DAC Value', ytitle = '# of counts', title = tplotString + ' Anode ' + strtrim(anodeVal,2)
    endif 
    oplot, dacArray1k, averageCountsSpec, color = (248. / 15 * index) + 7 
    counter = counter + 1
  endforeach
  smoothCounts = smooth(countsArray, 60, /edge_truncate)
 
  wi,1, wsize = [600,400]
  ;plot, countsArray
  ;oplot, smoothCounts, color = 6
  
  ; apply time shift of 2.6 seconds,
  ;timeHKP = timeHKP + 2.6
  ;timeData = timeData + 2.6

  
dacArray1p1k = [2590., 2582., 2574., 2565., 2557., 2549., 2541., 2533., 2525., $
                2517., 2509., 2501., 2493., 2485., 2477., 2469., 2461., 2453., $
                2445., 2438., 2430., 2422., 2414., 2407., 2399., 2391., 2384., $
                2376., 2369., 2361., 2353., 2346.]
                
             
  
  nrgSmooth = smooth(specArray,[32,0], /edge_truncate)
  
  options,lim,xmargin=[10,10],xtitle='Yaw angle (degrees)',ytitle='HEM ADC value', title = 'This is a Title'
  specplot, yawInterp, dacArray1p1k, nrgSmooth, no_interp = 1,limits=lim
  
  printdat, max(nrgSmooth)

  ;rotAngles = 
  
  print, 'pause'
  
  if plotMaxima eq 1 then begin
    ; Find the local maxima by taking the derivative & smoothing it
    ; then use signum to make positive values = 1, negative = -1, and zeros = 0
    ; for local maxima, value[i] - value[i + 1] == 2
    derivCounts = deriv(timeData, smoothCounts)
    derivSmooth = smooth(derivCounts, 20, /edge_truncate)
    wi, 2, wsize = [600,400]
    plot, timeData, smoothCounts
    oplot, timeData, derivCounts, color = 6
    oplot, timeData, derivSmooth,  color = 2
    wi, 3, wsize = [600,400]
    plot, timeData, derivSmooth
    oplot, timeData, derivSmooth,  color = 2
    polarity = signum(derivSmooth)
    oplot, timeData, polarity, color = 1
    polarityLen = n_elements(polarity)
    validMaxs = [!NULL]
    for i = 0,polarityLen - 2 do begin
      if (polarity[i] - polarity[i + 1]) eq 2 then validMaxs = [validMaxs, i]
    endfor
  
  
    print, 'valid Maxima indices', validMaxs


    ;yawInterp = interpol(yawArray, timeManip, timeData)
    ;yawVal = yawInterp[validMaxs]
    ;yawValValid = yawVal[where(yawVal gt 0)] ; replace with something more generic later, involving absolute value and degrees away from mean
    ;printdat, anode
    ;printdat, yawValValid
    ;meanValidYaw = mean(yawValValid)
    ;printdat, meanValidYaw
    ;varValidYaw = variance(yawValValid)
    ;printdat, varValidYaw

    ;wi, 4, wsize = [600,400]
    ;plot, yawInterp, countsArray
    ;avgYaw = mean([yawVal1, yawVal2, yawVal3, yawVal4])
    ;printdat, avgYaw
  endif

end