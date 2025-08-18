;+
;Fitting function used by Amoeba. Fits a gaussian.
;
;
;-

function defl_fit_gaussian, params

  common fit_gaussian_common, XX, YY, weights

  A0 = params[0]
  A1 = params[1]
  A2 = params[2]
  A3 = params[3]

  z = (XX - A1)/A2

  fxx = (A0 * exp((-1.)*z*z/2.)) + A3

  diff = 10.*total(abs(fxx - YY)*weights*(YY gt 0.),/nan)/ (n_elements(XX) * max(YY,/nan))   ;normalize size by max(YY)

  return, diff

end

;==========
;==========

;+
;Routine that determines if the beam is in the FOV, using amoeba to fit a gaussian to the beam in STATIC. This is NOT the top level
;function - it is recommended that you keep scrolling down to mvn_sta_defl_fov_run!
;
;INPUTS:
;dataY: 1D fltarr array containing energy flux at a single timestamp from the STATIC c8-P2-D data product.
;dataV: 1D fltarr array containing the deflector angles at a single timestamp, from the STATIC c8-P2-D data product.
;
;tpwin: window number that the tplot data are in. This is needed to ensure wset works correctly.
;wnum: window number to plot the deflector distribution into (not needed if /fplot is NOT set).
;
;output: a structure containing all the outputs from the routine, for storing into tplot.
;
;Set /fplot to plot the gaussian fit. Slows down the routine on long loops. Default is setting is to NOT plot this.
;
;Set /qc to load qualcolors.
;
;Set /no_off so that the y axis offset is not a fitting variable. In this case, the lowest real eflux value in the Y data
;   is used as the offset value, and cannot be varied by the fitting routine.
;
;Set /zeros to that any zeros in the data have zero weight and do not contribute to the fit. This is useful to "remove" NaNs, and missing
;   data, without changing the size of the arrays.
;
;NOTES:
;To calculate the STATIC FOV flag value for multiple timesteps, use the routine mvn_sta_defl_fov_run. See this routine
;for caveats as well.
;
;The code will search for and remove NaNs, and set them to zero. If /zeros is set, any zero values are given zero weighting and
;will not influence the fit.
;
;EGS:
;mvn_sta_defl_fov_amoebafit, dataY, dataV, tpwin=0, wnum=1
;
;It is recommended that you use mvn_sta_defl_fov_run instead, which will calculate the FOV flag value over multiple time steps.
;
;-
;

pro mvn_sta_fov_defl_amoebafit, dataY, dataV, tpwin=tpwin, wnum=wnum, output=output, fplot=fplot, qc=qc, no_off=no_off, zeros=zeros

  if keyword_set(qc) then begin
    @'qualcolors'  ;user specific color tables
  endif

  common fit_gaussian_common, angle, log_eflux, weights

  if not keyword_set(fplot) then fplot = 0
  if not keyword_set(tpwin) then tpwin=0
  if not keyword_set(wnum) then wnum=1

  iFI = where(finite(dataY) eq 0, niFI)  ;remove NaNs, keep real numbers only

  eflux = dataY
  angle = dataV

  if niFI gt 0 then eflux[iFI] = 0.  ;set NaNS to zeros

  log_eflux = alog10(eflux) ;this might add some inf to the array... but they'll have zero weighting, so I think this will be ok.

  ;For nterms=4, terms are: [peak of gaussian, center, width, offset]
  max1 = max(log_eflux, imax, /nan)

  if keyword_set(no_off) then begin
    ;Take lowest three real values of eflux, and use average as the min:
    iKP = where(log_eflux gt 0., niKP)
    if niKP gt 3 then isort = (sort(log_eflux[iKP])) else isort=[0,1,2]  ;if all NaNs, just use first three
    EFinit = mean(log_eflux[iKP[isort[0:2]]])  ;take mean of first three points

    init = [max1, angle[imax], 11., EFinit]
    scale=[1., 2., 1., 0.]
  endif else begin
    init = [max1, angle[imax], 11., min(log_eflux, /nan)]
    scale=[1., 2., 1., 1.]
  endelse

  ;Weights:
  if keyword_set(weights) then begin
    weights = log_eflux  ;proportional to logged value
    weights = ((log_eflux/min(log_eflux,/nan)) -1.)^2.  ;smallest eflux has zero weight. 
  endif else weights = fltarr(n_elements(dataY))+1.  ;flat weights by default

  if keyword_set(zeros) then begin
    iZE = where(eflux eq 0., niZE)
    if niZE gt 0. then weights[iZE] = 0.  ;zero weighting
  endif

  result = amoeba(1E-2, function_name='defl_fit_gaussian', P0=init, scale=scale)

  ;Check amoeba converged:
  if n_elements(result) eq 4 then begin
    ;Interpolate fitted gaussian to finer angle resolution:
    delA = 1.  ;angular resolution, degrees
    minA = float(round(min(angle,/nan)))
    maxA = float(round(max(angle,/nan)))

    neleA = floor((maxA - minA)/delA)+1.
    angleARR = (findgen(neleA)*delA)+minA

    zz = (angleARR - result[1])/result[2]
    efluxMODEL2 = result[0] * exp((-1.)*zz*zz/2.) + result[3]  ;model2 is the finer angle resolution plot

    ;Remake fitted gaussian at just 16 data points for deflector:
    zz_MODEL1 = (angle - result[1])/result[2]
    efluxMODEL1 = result[0] * exp((-1.)*zz_MODEL1*zz_MODEL1/2.) + result[3]   ;model1 is at 16 angle bins resolution

    ;Remove Y offset to make calculating area easier:
    efluxMODEL2_noY = (efluxMODEL2 - result[3]) > 0.  ;fitted gaussian
    log_efluxDATA_noY = log_eflux - result[3]  ;measured data
    efluxMODEL1_noY = efluxMODEL1 - result[3]  ;fitted gaussian with 16 data points

    ;Estimate what fraction of the gaussian area lies outside the FOV. First, use the analytical expression for the integral of a gaussian
    ;to work out what the area under the gaussian is in total: this is params[0]* sqrt(pi*2*params[2]*params[2])
    areaG = result[0]*sqrt(!pi*2.*result[2]*result[2])   ;this is the area of the fitted full gaussian, assuming no Y offset - checked correct by CMF

    ;This is the area of the remodelled Gaussisn, just in the FOV.
    ;Because I have removed the Y offset, and angle array is at 1 degree resolution, the area under the curve
    ;is just the sum of the eflux array.
    areaM = total(efluxMODEL2_noY,/nan)

    fracG = 100.*areaM/areaG  ;the % of the curve that lies within the FOV.

    ;ERROR ESTIMATE:
    ;Sum abs() of diff between fit and data in log space, but only for values when the fit is above the zero offset. This should reduce
    ;the influence from edge effects, which can unfairly skew the error value higher.
    ;I don't know if doing this diff in linear space would be better or not.
    ;Diff has background value subtracted:
    diff = 100.* total(abs((efluxMODEL1_noY - log_efluxDATA_noY) * (log_efluxDATA_noY gt 0.) * weights),/nan) / (n_elements(angle)*max(log_eflux,/nan))   ;normalize by number of angles incase this changes, and by max eflux
    ;Diff1 does not have background value subtracted, comes out to similar values as diff:
    diff1 = 100.* total(abs((efluxMODEL1 - log_eflux) * (log_eflux gt 0.) * weights),/nan) / (n_elements(angle)*max(log_eflux,/nan))   ;normalize by number of angles incase this changes, and by max eflux
    
    ;Second error estimate: only calculate difference between the peak and data, and ignore points at the "background" level, as these
    ;can skew good fits. This is actually the same as diff and diff1, but for diff2, I also weight as 2^weight, so that the peak carries
    ;more weight.
    bckg = min(efluxMODEL1,/nan)  ;assume background level is the min value of the fit
    ibckg = where(efluxMODEL1 gt 1.01*bckg, nibckg)  ;find all points above the background.
    
    if nibckg ge 5. then begin ;need at least 5 points above background to do this.
        ;Factor in front just brings difference value to values of order 1.
        diff2 = 10000.*total(abs((efluxMODEL1[ibckg] - log_eflux[ibckg]) * (log_eflux[ibckg] gt 0.) * weights[ibckg]),/nan) / (n_elements(angle[ibckg])*max(log_eflux[ibckg],/nan))   ;normalize by number of angles incase this changes, and by max eflux
    endif else diff2 = !values.f_nan
    
    ;OTHER FLAGS:
    maxEF = max(log_eflux, /nan)

    if fplot eq 1 then begin
      wset, wnum
      plot, angle, log_eflux_noY, xtitle='Deflector angle', ytitle='Log eflux', charsize=1.7, yrange=[0., 1.1*max(efluxARR,/nan)], ysty=1
      if keyword_set(qc) then colblue = qualcolors.blue else colblue=150l ;im guessing at 150.
      oplot, angleARR, efluxARR_noY, color=colblue

      xyouts, 0.2, 0.85, "Area in FOV [%]: "+strtrim(fix(fracG),2), charsize=1.7, /normal
      xyouts, 0.2, 0.8, "|fit - data|: "+strtrim((diff),2), charsize=1.7, /normal
      xyouts, 0.2, 0.75, "Adj. max eflux: "+strtrim((maxEF),2), charsize=1.7, /normal
    endif

    success=1

  endif else begin
    
    maxEF = !values.f_nan
    fracG = !values.f_nan
    diff = !values.f_nan
    diff1 = !values.f_nan
    diff2 = !values.f_nan
    log_efluxDATA_noY = !values.f_nan
    angleARR = !values.f_nan
    efluxMODEL2 = !values.f_nan
    efluxMODEL2_noY = !values.f_nan
    success=0
  endelse

  output = create_struct('maxEF'    ,     maxEF   , $
                         'area'     ,     fracG   , $
                         'diff'     ,     diff    , $
                         'diff1'    ,     diff1   , $
                         'diff2'    ,     diff2   , $
                         'success'  ,     success , $
                         'xdata'    ,     angle   , $
                         'ydata_log',     log_eflux, $   ;input data, logged (nans removed)
                         'ydata_log_ny'    ,     log_efluxDATA_noY , $  ;input data, logged, with offset removed
                         'xmodel'   ,     angleARR , $
                         'ymodel2'  ,     efluxMODEL2 , $  ;modeled data, logged
                         'ymodel2_ny'  ,     efluxMODEL2_noY)  ;ymodel2 is at finer angle resolution

end

;==============
;==============

;+
;Input a 4x16 array. Rescale it to a larger set of pixels, for plotting using tv.
;
;arrayin: data array to be up scaled [4x16]
;factor: the scaling factor by which to multiply arrayin. Must be an integer. Eg, factor=2 will give an output array of 8x32, where
;        each 2x2 square is equivalent to a 1x1 square in the original array.   
;        If you set xfact and yfact below, you do not need to set factor.
;
; xfact, yfact: scaling factors for x and y dimensions independently. Same as above, but apply to X and Y dimensions separately.
;               Setting these will overwrite factor. If you set one, both must be set, as factor will be ignored.
;
;output: the upscaled array.
;
;
;-

pro scale_array, arrayin, factor, output=output, success=success, xfact=xfact, yfact=yfact

if size(xfact,/type) ne 0 and size(yfact,/type) ne 0 then begin
    xscale = round(xfact)
    yscale = round(yfact)
endif else begin
    if size(factor,/type) eq 0 then begin
      print, ""
      print, "Set factor, or xfact and yfact."
      success=0
      return
    endif
    xscale = round(factor)
    yscale = round(factor)
endelse

if xscale lt 1 or yscale lt 1 then begin
  print, ""
  print, "Scaling factor must be >1, I can only upscale."
  success=0
  return
endif

neleX = n_elements(arrayin[*,0])
neleY = n_elements(arrayin[0,*])

nXnew = (neleX*xscale)
nYnew = (neleY*yscale)

output = fltarr(nXnew, nYnew)

xi = (findgen(neleX)*xscale)  ;indices at start of each block in new array
yi = (findgen(neleY)*yscale)

;Cycle through and populate array:
for xx = 0l, neleX-1l do begin
  
  x1 = xi[xx]
  x2 = x1+(xscale)-1l
  xinds=[x1:x2]
  
  for yy = 0l, neleY-1l do begin
      val0 = arrayin[xx,yy]  ;original value
      
      y1 = yi[yy]
      y2 = yi[yy]+(yscale)-1l
      yinds=[y1:y2]
          
      ;Cycle through each of the "new" rows, as IDL won't fill in a block of points at once:
      for yyy = 0l, (yscale)-1l do output[xinds, yinds[yyy]] = val0
      
  endfor
  
endfor

success=1

end

;==============
;==============

;+
;Routine to histogram plot where all bins are evenly sized in x. Using psym=10 in IDL produces the end bins at half the size of the
;other bins.
;
;This routine will simply oplot data (using the oplot routine), so make sure it is in the right place in your code.
;
;Xdata, Ydata: fltarrs, etc. Ydata will have one less element than Xdata, because Xdata must bound each side of each bin.
;
;Set /vert to plot as a vertical plot. The defualt is horizontal.
;
;EG: to plot data for 16A, ydata is [16] in size, and contains the eflux for each anode. xdata will be 17 in size, where
;    xdata = findgen(17).
;
;    cmf_sta_hist_plot, Xdata, Ydata
;     
;     
;-
;

pro cmf_sta_hist_plot, Xdata, Ydata, color=color, thick=thick, linestyle=linestyle, vert=vert

  nelePP = n_elements(Ydata)

  for pp = 0l, nelePP-1l do begin
    
    if keyword_set(vert) then begin
        ;Vertical plot:
                
        ;horizontal bar:
        oplot, [Ydata[pp], Ydata[pp]], [Xdata[0+pp], Xdata[1+pp]], color=color, thick=thick, linestyle=linestyle
        ;LHS vertical:
        if pp gt 0 then oplot, [Ydata[pp-1], Ydata[pp]], [Xdata[0+pp], Xdata[0+pp]], color=color, thick=thick, linestyle=linestyle
        ;RHS vertical:
        if pp lt nelePP-1l then oplot, [Ydata[pp+1], Ydata[pp]], [Xdata[pp+1], Xdata[pp+1]], color=color, thick=thick, linestyle=linestyle

    endif else begin
        ;Horizontal plot:
             
        ;horizontal bar:
        oplot, [Xdata[0+pp], Xdata[1+pp]], [Ydata[pp], Ydata[pp]], color=color, thick=thick, linestyle=linestyle
        ;LHS vertical:
        if pp gt 0 then oplot, [Xdata[0+pp], Xdata[0+pp]], [Ydata[pp-1], Ydata[pp]], color=color, thick=thick, linestyle=linestyle
        ;RHS vertical:
        if pp lt nelePP-1l then oplot, [Xdata[pp+1], Xdata[pp+1]], [Ydata[pp+1], Ydata[pp]], color=color, thick=thick, linestyle=linestyle
    
    endelse
    
  endfor

end


;==============
;==============

;+
;Create the STATIC FOV flag, using inputs from mvn_sta_fov_snap.
;
;INPUTS:
;FOVoutput: IDL data structure FOVoutput, from mvn_sta_d0d1c8_fov_crib.
;
;OUTPUTS:
;flagVAL: ;0 means FOV ok, 1+2 mean possible problems, 3 means not ok. Default is 3
;
;-


function mvn_sta_fov_create_flag, FOVoutput

  ;Create a FOV flag based on results:
  ;#### CAUTION!!! #### This is preliminary, has not been tested much, and is definitely not correct in all cases. It is
  ;designed as a first layer of defence against FOV problems, but users should absolutely check the FOV using
  ;the snap routine for case studies, and run some tests and checks, when running statistical studies. AT THEIR OWN RISK,
  ;users can create their own flag routines, using the tplot variables created above, based on the algorithm below.

  flagVAL = fltarr(n_elements(FOVoutput.sc_flag))+3.  ;0 means FOV ok, 1+2 mean possible problems, 3 means not ok. Default is 3

  ;This is the simplest case: >70% of the eflux lies within the found beam, with no sc blockage, and the beam peak lies in one of 
  ;the center two anodes.
  inds0 = where((FOVoutput.sc_flag eq 0) and (FOVoutput.fov_flag eq 0) and (FOVoutput.BeamEflux ge 70.), ninds0) 
    if ninds0 gt 0 then flagVAL[inds0] = 0.   ;NOTE this 70 is tied to fov finding as well

  ;Slightly more difficult case: 50-70% of eflux lies within center two deflector anodes, and c8 data appear to be a good
  ;(which is somewhat risky, as c8 doesn't have mass resolution):
  inds1 = where((FOVoutput.sc_flag eq 0) and (FOVoutput.fov_flag eq 0) and (FOVoutput.BeamEflux lt 70.) and (FOVoutput.BeamEflux ge 50.) and $
    (FOVoutput.Gaussian_fit.diff2 lt 3.) and (FOVoutput.Gaussian_fit.frac ge 75.), ninds1) 
    if ninds1 gt 0 then flagVAL[inds1] = 1.
  
  ;In this case, the "beam" lies at the edge of the FOV, meaning that we could be missing some of it, but the c8 data show
  ;that the peak lies within the FOV. This is still risky, as c8 doesn't have mass resolution. This still requires at least 50%
  ;of the eflux to lie within the "beam", which helps flag cases when there are multiple peaks.
  inds2 = where((FOVoutput.sc_flag eq 0) and (FOVoutput.fov_flag eq 1) and (FOVoutput.BeamEflux ge 50.) and $
    (FOVoutput.Gaussian_fit.diff2 lt 3.) and (FOVoutput.Gaussian_fit.frac ge 75.), ninds2)
    if ninds2 gt 0 then flagVAL[inds2] = 2.
  
  return, flagVAL

end



;==============
;==============

;+
;Crib to get FOV and spacecraft blockage flags using d0/d1 and c8 data. Plan is to use d0 data to get 16A x 4D map. Find peak
;eflux or counts. Is there spacecraft bloackage in an adjacent bin? Not sure how to handle deflector fov, as with only 4D, peak
;can easily lie in outside bin, but peak can still easily be within FOV. Can use c8 data to help at times. Check if
;>X% of eflux or counts lie within a certain anode. If this is the case, assume that the c8 data (which is 16D x 1A) is 
;representative of that anode. Can check deflector dimension for this peak.
;
;Add in mass and energy dependence via d0 and d1 data. How does this affect c8 data? => if peak lies in same 4 bins in c8,
;that it lies in within d0, assume it's the same peak? If not, not sure?
;
;trange: double precision UNIX time: 
;        two element array [a,b]: calculate FOV details between these two times.
;        single time: a: calculate FOV details for this time.
;
;wnum: window number into which the FOV results are plotted. Dedfault if not set is 2. The plotting occurs when looking at a single
;      timesptamp. Plotting will not occur by default when a time range is entered, to save time. Use the /forceplot keyword
;      to overcome this.
;
;erange: [a, b]: floats: energy range in eV between which to look at. STATIC energies typically range between 0.01 and ~5E4 eV, 
;                depending on observation mode.
;
;mrange: [a, b]: floats: mass range in AMU between which to look at. d0 and d1 data products have 8 mass bins.
;
;forceplot: set /forceplot to force the routine to plot the FOV results each timestep, into window wnum. Default is to only do this
;           plotting when trange is a single timestep.
;           
;tpnum: the window number with tplot variables in. This is only required when using this function as part of ctime, to plot the FOV
;       results as you drag the cursor. The default is tpnum=0 if not set.
;
;ctimeflag: set to 1 if using the routine with ctime, to plot FOV results while moving the cursor over a tplot window. Set to
;           0 if this is not the case (you are entering a specific time or time range). The user should not have to set this 
;           keyword, it should set automatically based on your input to mvn_sta_fov_snap.
;
;sta_apid: lowercase string: user can set which STATIC data products to use by hand if wanted. Options are 'ce', 'cf', 'd0', 'd1', 
;          as no other STATIC products contain the necessary information.
;
;Set /qc to load qualcolors (Mike Chaffins colorbars). Uses default IDL colors it not set.
;
;top_c, bottom_c: top and bottom color table indices that IDL should used when plotting. Defaults if not set are either 0 and 255,
;                 or those set by qualcolors, if /qc is set. 
;
;zrange: [a,b] float array, where a and b are the min and max energy flux values for the colorbar. Useful if you want all plots to
;        keep the same plot range. If not set, the code uses default variable zranges based on the energy flux present at each timestep.
;        a and b are real numbers - they will become alog10(a), alog10(b) within the code.
;
;
;OUTPUTS:
;success: 0 means the code did not run (eg no data found). 1 means code ran. See FOVoutput for success codes on each timestamp
;         analyzed.
;
;NOTES:
;The d0 / d1 display may have different colors to the c8 panel. This is because c8 does not have mass descrimination, and thus if
;you set mrange, this will filter out some data from the d0/d1 products, which is still included in the c8 product.
;
;EGS:
;Run before to load in data:
;timespan, '2018-07-08', 1.
;mvn_sta_l2_load, sta_apid=['d1', 'c8'], /tplot_vars_create   ;note: tplot variables /tplot-vars-create are not needed.
;
;tt0=1530859000.0000000d  ;testing  - pick up ions
;
;mvn_sta_d0d1c8_fov_crib, trange=[a,b]   ;calculate between a time range [a,b].
;mvn_sta_d0d1c8_fov_crib, trange=a    ;calculate at just one time, a.
;
;.r /Users/cmfowler/IDL/STATIC_routines/FOV_routines/mvn_sta_fov_defl.pro
;.r /Users/cmfowler/IDL/STATIC_routines/FOV_routines/mvn_sta_fov_snap.pro
;
;-
;

pro mvn_sta_d0d1c8_fov_crib, trange=trange, success=success, erange=erange, mrange=mrange, m_int=m_int, wnum=wnum, tpnum=tpnum, $
                          forceplot=forceplot, ctimeflag=ctimeflag, FOVoutput=FOVoutput, sta_apid=sta_apid, qc=qc, $
                          top_c=top_c, bottom_c=bottom_c, zrange=zrange, searchvector=searchvector, coneangle=coneangle, lookvector=lookvector

if keyword_set(qc) then begin
  @'qualcolors'
  topc = qualcolors.top_c
  bottomc = qualcolors.bottom_c
  col_white = qualcolors.white
  col_blue = qualcolors.blue
  col_green = qualcolors.green
  col_brown = qualcolors.brown
endif else begin
  ;There is probably a better way to code colors for default tables. Figure this out.
  topc = 254l
  bottomc = 0l
  col_white=0l
  col_blue = 125l ;guesses for now
  col_green = 175l
  col_brown = 50l
endelse

;Overwrite top and bottom color table indices if set by hand. If these keywords aren't set, they are set top 'na',
;thus the check for size eq 7
if not keyword_set(qc) and keyword_set(top_c) then begin    
      if size(top_c,/type) ne 7 then topc = top_c else topc=255
endif

if not keyword_set(qc) and keyword_set(bottom_c) then begin
      if size(bottom_c,/type) ne 7 then bottomc = bottom_c else bottom_c=0
endif

if not keyword_set(erange) then erange=[0., 1e6]  ;use all energies
if not keyword_set(mrange) then mrange=[0., 100.]   ;use all masses
if not keyword_set(wnum) then wnum=2  ;plot contour in, for testing only.
if not keyword_set(tpnum) then tpnum=0

mstr = '['+strtrim(string(mrange[0], format='(f12.1)'),2)+','+strtrim(string(mrange[1], format='(f12.1)'),2)+']'
estr = '['+strtrim(string(erange[0], format='(f12.1)'),2)+','+strtrim(string(erange[1], format='(f12.1)'),2)+']'

common mvn_cf, get_ind_cf, all_dat_cf   ;only present during ~2015
common mvn_ce, get_inds_ce, all_dat_ce  ;only present during ~2015
common mvn_d1, get_ind1, all_dat1
common mvn_d0, get_ind0, all_dat0        ;should always be present from ~2016 onwards
common mvn_c8, get_indc8, all_datc8
common mvn_sta_fov_common, plotct, all_dat, dtype   ;plotct is used when /ctimeflag is set, to create wnum on the first pass.

;CHECKS:
if size(all_dat_cf,/type) eq 0. and size(all_dat_ce,/type) eq 0. and size(all_dat0,/type) eq 0. and size(all_dat1,/type) eq 1 then begin
  print, ""
  print, "I couldn't find any ce, ce, d0 or d1 data. Load using mvn_sta_l2_load, sta_apid=['ce', 'cf', 'd0', 'd1']."
  success=0
  return
endif
if size(all_datc8,/type) eq 0. then begin
  print, ""
  print, "I couldn't find any c8 data. Load using mvn_sta_l2_load, sta_apid=['c8']."
  success=0
  return
endif

;#$#$#$#$#$#$#
;Complicated bit: in 2015, data could be in ce, cf, d0 or d1 products. After 2015, data purely in d0 or d1.
;The code needs to be able to pick out the correct product at each timestep.
;One option: take all products in common blocks (up to user to load them all). Put times into one array in time order. Have matching array
;that tags which product is at each timestep. As I go through time array, cna pick out closest matching product. Caveat: if burst is 
;available, use that, even if ce, d0 is slightly closer, as this is still averaged over much longer time.



;It takes ~3s for IDL to copy the d0 or d1 arrays here, as they are large. This is ok when running for a set trange, but
;makes using the ctime cursor function unusable. On the first time through a ctime cursor call, store the data into a common block
;so the routine only has to copy this the first time.
if keyword_set(ctimeflag) then begin
    if plotct eq 0 then begin  ;only set d0 or d1 data on the first pass. plotct is reset on every new call to the ctime cursor mode.
        
        if keyword_set(sta_apid) then begin  ;user selected STATIC mode
            dtype=sta_apid
            case dtype of
                'ce' : all_dat = all_dat_ce
                'cf' : all_dat = all_dat_cf
                'd0' : all_dat = all_dat0
                'd1' : all_dat = all_dat1
                else : begin
                          print, ""
                          print, "sta_apid must be set to ce, cf, d0 or d1."
                          success=0
                          return
                       end
            endcase
            
        endif else begin
        
            if size(all_dat1,/type) eq 8 then begin  ;default use burst if available
              dtype = 'd1'
              all_dat=all_dat1
            endif else begin
              dtype = 'd0'
              all_dat=all_dat0
            endelse
        
        endelse
        ;all_dat and dtype are now stored in the mvn_sta_fov_common common block.
    endif
endif else begin
    if keyword_set(sta_apid) then begin  ;user selected STATIC mode
    dtype=sta_apid
    case dtype of
        'ce' : all_dat = all_dat_ce
        'cf' : all_dat = all_dat_cf
        'd0' : all_dat = all_dat0
        'd1' : all_dat = all_dat1
        else : begin
                  print, ""
                  print, "sta_apid must be set to ce, cf, d0 or d1."
                  success=0
                  return
               end
    endcase

  endif else begin
        
      if size(all_dat1,/type) eq 8 then begin  ;default use burst if available
        dtype = 'd1' 
        all_dat=all_dat1
      endif else begin
        dtype = 'd0'
        all_dat=all_dat0
      endelse
  
  endelse
  
endelse

neleT = n_elements(all_dat.time)

;SORT TIME RANGE: 
neleTR = n_elements(trange)
if neleTR eq 0 or neleTR gt 2 then begin
    print, ""
    print, "trange must be a single time, or [a,b] time range."
    success=0
    return
endif

;Get correct time range:
if neleTR eq 2 then begin
  ;Range of times:
  iKP = where(all_dat.time ge trange[0] and all_dat.end_time le trange[1], niKP)  ;iKP are used to retrieve STA data from common blocks
  
  if niKP eq 0 then begin
      print, ""
      print, "I couldn't find any data between the requested time range."
      success=0
      return
  endif
  
  forceplot2=0.
  
endif else begin
  ;Single timestep:
  iKP = where(all_dat.time ge trange[0], niKP)
  
  if niKP eq 0 then begin
    print, ""
    print, "I couldn't find data for the requested time."
    success=0
    return
  endif
  
  niKP = 1. ;a single point only
  iKP = iKP[0]  ;use the data point immediately after the requested time
  
  forceplot2=1
endelse

if keyword_set(forceplot) then forceplot2=1

;ARRAYS:
Tdiff_c8 = dblarr(niKP)  ;time difference in secs, between c8 and d0/d1 data.
diffALL = fltarr(niKP)  ;gaussian fit result
diffALL2 = fltarr(niKP) ;gaussian fit result
maxALL = fltarr(niKP)   ;gaussian fit result
fracALL = fltarr(niKP)  ;gaussian fit result
successGF = fltarr(niKP)
FOVflagALL = fltarr(niKP) 
SCflagALL = fltarr(niKP) 
EFtypeALL = fltarr(niKP)
EFpkALL = fltarr(niKP)  ;Eflux % in peak anode
EF_d_bm_ratio_ALL = fltarr(niKP)  ;% of EF in d deflectors that contain the peak
successD01 = fltarr(niKP)  ;did code get FOV details using do or d1 data
timeALL = dblarr(niKP)+!values.f_nan  ;timestamps

;PARAMS:
wsx=1200.
wsy=650.
if forceplot2 eq 1 then begin
  if keyword_set(ctimeflag) then begin
      if plotct eq 0 then window, wnum, xsize=wsx, ysize=wsy else wset, wnum  ;make a window on the first pass of ctime loop, or set window if not
  endif
  
  if not keyword_set(ctimeflag) then window, wnum, xsize=wsx, ysize=wsy  ;make a window if it's just a single call 
endif


for tt = 0l, niKP-1l do begin
    ind = iKP[tt]  ;index in common block
    res = execute("dat=mvn_sta_get_"+dtype+"(index=ind)")  ;retrieve using index in the common block

    if res eq 1 then begin
        mvn_sta_convert_units, dat, 'eflux'
        dat_cp = dat ;copy for later 
        data2 = dat.data
        midtime = mean([dat.time, dat.end_time], /nan)  ;mid time of this data
        timeALL[tt] = dat.time  ;use start time of STATIC
        
        ;##### SELECT ENERGY AND MASS RANGES: can this be moved outside of the loop - do these bins change with d0/d1?
        iRM = where((dat.energy lt erange[0] or dat.energy gt erange[1]) or $  ;use OR here to get energy and mass in one
                    (dat.mass_arr lt mrange[0] or dat.mass_arr gt mrange[1]), niRM)
       
        if niRM gt 0 then begin
            data2[iRM] = 0.  ;remove data outside of mass and energy ranges.
        endif
        
        ;Compress data in energy and mass dimensions:
        data3 = total(data2, 1, /nan) ;energy
        data4 = total(data3, 2, /nan) ;mass        
        data5 = transpose(reform(data4, 4, 16))   ;break to 16Ax4D. CMF checked and confirmed that this is the correct order to reform
        
        iCH = where(finite(data5) eq 0, niCH)  ;remove NaNS, set to 0s.
        if niCH gt 0. then data5[iCH] = 0.
        
        bins_sc = transpose(reform(dat.bins_sc, 4, 16))  ;sc blockage array, 1=ok, 0=not good
        
        ;==============
        ;PLOTTING CODE:
        if forceplot2 eq 1 then begin
            plotct+=1l  ;update plot counter
            erase  ;erase current plot window
            ;Upscale data5 so I can plot using tv (which only works in units of pixels):   
            scfac = 32.  ;scaling factor, (scfac*4) needs to be divisible by 16 for later plotting stuff
            scale_array, data5, scfac, output=data5b
            scale_array, bins_sc, scfac, output=bins_scb
    
            ;PLOT ANODE AND DEFLECTOR IMAGE:
            xp0 = 300. ;plot position (pixels) for tvscl
            yp0 = 225.
            nX = n_elements(data5b[*,0])  ;length in pixels of data5b
            nY = n_elements(data5b[0,*])
            
            data5b_log = alog10(data5b)
            maxval = max(data5b_log,/nan)
            minval = min(data5b_log,/nan)
              if minval eq maxval then minval = maxval-1.  ;this happens sometimes, when only one bin has data, at RAM periapsis
            
            ;Reset minval and maxval, if set by user:
            if keyword_set(zrange) then begin
                maxval = alog10(zrange[1])
                minval = alog10(zrange[0])
            endif        
              
            ;data5b_log_byt = bytscl(data5b_log, min=minval, max=maxval, top=topc, /nan)
            data5b_log_byt = mvn_sta_bytscl2(data5b_log, min=minval, max=maxval, top=topc, bottom=bottomc)  ;use bottom_c
            
            ;NOTE: tv switches the rows, so that the last row in the array plots on the top row in the figure.
            tv, reverse(data5b_log_byt, 2), xp0, yp0  ;note the reverse keyword as above
            xyouts, xp0, yp0+nY+5., dtype+' A-D, eflux', /device, charsize=1.7, charthick=1.7
            
            ;Plot summation of eflux across A and then D:
            efluxA = total(data5,2)
            efluxD = total(reverse(data5,2),1)  ;note the reverse in the D direction
            
            ;Convert any zeros to NaNs, so that y axis scaling doesn't screw up:
            iCHtmp = where(efluxA eq 0., niCHtmp)
            if niCHtmp gt 0 then efluxA[iCHtmp] = !values.f_nan
            iCHtmp = where(efluxD eq 0., niCHtmp)
            if niCHtmp gt 0 then efluxD[iCHtmp] = !values.f_nan
            
            pw = 150./wsy ;width in y
            p1 = xp0/wsx   ;x1
            p2 = (xp0+nX)/wsx   ;x2
            p4 = (yp0/wsy) - 0.025  ;y2
            p3 = p4 - pw  ;y1
                    
            ;ANODES:
            nA = n_elements(efluxA)  ;number of anodes
            plot, efluxA, charsize=1.7, charthick=1.7, xtitle=dtype+' anode #', ytitle='Eflux', position=[p1,p3,p2,p4], /noerase, $
                    psym=10, /nodata, /ylog, yrange=[0.8*min(efluxA,/nan)>1E4, 1.25*max(efluxA,/nan)>1E7], ysty=1, xrange=[0,nA], xsty=1
            cmf_sta_hist_plot, findgen(nA+1l), efluxA
            
            ;DEFLECTORS:
            dw = 0.175  ;width of def panel as fraction
            p5 = p1 - dw - 0.025  ;x1
            p6 = p5 + dw   ;x2
            p7 = yp0/wsy   ;y1
            p8 = (yp0+nY)/wsy   ;y2
            
            nD = n_elements(efluxD)
                        
            plot, efluxD, charsize=1.7, charthick=1.7, xtitle='Eflux', ytitle='Deflector #', position=[p5,p7,p6,p8], /noerase, $
                    psym=10, /nodata, /xlog, xrange=[0.8*min(efluxD,/nan)>1E4, 1.25*max(efluxD,/nan)>1E7], xsty=1, yrange=[0,nD], ysty=1, $
                      title=dtype+' def #'
            cmf_sta_hist_plot, findgen(nD+1l), efluxD, /vert
            
            ;SC blockage:
            xp1 = xp0 ;plot position (pixels) for tvscl
            yp1 = yp0+nY + 100.  ;pixels
            ;Default in bins_scb is 1=ok, 0=bad. Reverse this to get better colors.
            bins_scb2 = fltarr(nX,nY) + 1  ;set array to all 1s
            iCH = where(bins_scb eq 1, niCH)
            if niCH gt 0 then bins_scb2[iCH] = 0.  ;change ok FOV points to zeroes, so that ok FOV bins are plotted black.
            
            tvscl, reverse(bins_scb2,2), xp1, yp1, /nan  ;note the reverse in D direction
            xyouts, xp1, yp1+nY+5., dtype+' A-D, sc blockage', /device, charsize=1.7, charthick=1.7
            xyouts, xp1+(nX/2.), yp1+nY+25., time_string(dat.time), /device, charsize=1.7, charthick=1.7
            xyouts, xp1+(nX/2.), yp1+nY+5., "=> "+time_string(dat.end_time), /device, charsize=1.7, charthick=1.7            
        endif  ;forceplot2=1

        ;#### FIND c8 deflector data:
        dat_c8 = mvn_sta_get_c8(midtime)
        midtime_c8 = mean([dat_c8.time, dat_c8.end_time], /nan)
        Tdiff_c8[tt] = abs(midtime - midtime_c8)  ;time diff in secs between c8 and d data.
        
        ;c8 deflector data is plotted down below after converting to correct units etc.
        
        ;####Find peak eflux in d data:
        ;mvn_sta_fov_findpeak, data5, pts=pts, rowI=rowI, colI=colI, peakinfo=peakinfo   ;old version
        mvn_sta_fov_d0d1_findpeak, data5, peakinfo=peakinfo
        colI = peakinfo.xPK ;copy variables to make easier
        rowI = peakinfo.yPK 
        
        xPK = peakinfo.xPK
        yPK = peakinfo.yPK
        yPK2 = peakinfo.pts[1,*]  ;y indices for all points in the beam
        
        ;Find flux in d deflectors that contain the beam:
        ;For now, do this whether a peak is found or not.
        if (peakinfo.EFsuccess eq 1) or (peakinfo.EFsuccess eq 0) then begin
            efluxD2 = total(data5,1, /nan)  ;redo do this, as earlier I add nans to avoid screwing y axis ranges
            sortYPK = sort(yPK2)  ;sort y indices - use all points in beam, not just peak point
            yPK_sort = yPK2[sortYPK]  ;ascending indices
            uniqYPK = yPK_sort[uniq(yPK_sort)]  ;the uniq yPK indices i efluxD for the peak.
            nUNIQ = n_elements(uniqYPK)
            EF_d_tot=0.
            for uniy = 0l, nUNIQ-1l do EF_d_tot += efluxD2[uniqYPK[uniy]]  ;get total eflux in the d deflector bins, in the peak.
            EF_d_bm_ratio = 100.*EF_d_tot / total(efluxD2,/nan)  ;% of flux in the d deflectors that contain the beam. d data have mass resolution, so this can be different to c8 deflector data
        endif else begin
            EF_d_bm_ratio = !values.f_nan
        endelse
        
        npts = peakinfo.EFsize   ;n_elements(pts[0,*])  ;using EFsize means no plots when there's no eflux at all.
        npk = n_elements(xPK)
                 
        ;==============
        ;MORE PLOTTING:
        if forceplot2 eq 1 then begin
            ;Overplot squares onto blockage plane, showing which anodes/deflectors are being checked for blockage:
            
            ;Overplot an empty figure on top of the blockage panel, so I can overplot the squares onto this.
            sqp1 = xp1/wsx  ;as fractions
            sqp2 = (xp1+nX)/wsx
            sqp3 = yp1/wsy
            sqp4 = (yp1+nY)/wsy
            plot, [0], [0], /noerase, /nodata, xrange=[0,16], yrange=[0,4], xsty=1, ysty=1, position=[sqp1, sqp3, sqp2, sqp4], $
                    charsize=1.7, charthick=1.7
            
            if peakinfo.EFsuccess eq 1 then begin ;only plot white boxes if code was able to find a peak
                for sq = 0l, npts-1l do begin  ;loop over each square
                    xsq1 = peakinfo.pts[0,sq]
                    xsq2 = xsq1+1l
                    ysq1 = peakinfo.pts[1,sq]
                    ysq2 = ysq1+1l
                    
                    ;Reverse Y coords, to match plotting by tv:
                    ysq1b = dat.ndef - ysq2
                    ysq2b = dat.ndef - ysq1 
                    
                    oplot, [xsq1, xsq2], [ysq1b, ysq1b], color=col_white, thick=2
                    oplot, [xsq1, xsq2], [ysq2b, ysq2b], color=col_white, thick=2
                    oplot, [xsq1, xsq1], [ysq1b, ysq2b], color=col_white, thick=2
                    oplot, [xsq2, xsq2], [ysq1b, ysq2b], color=col_white, thick=2      
                     
                endfor
            endif
            
            ;Overplot square(s) the routine determined were the main peak, in the d0/d1 panel:
            ;Overplot an empty figure on top of the blockage panel, so I can overplot the squares onto this.
            sqp5 = xp0/wsx  ;as fractions
            sqp6 = (xp1+nX)/wsx
            sqp7 = yp0/wsy
            sqp8 = (yp0+nY)/wsy
            plot, [0], [0], /noerase, /nodata, xrange=[0,16], yrange=[0,4], xsty=1, ysty=1, position=[sqp5, sqp7, sqp6, sqp8], $
              charsize=1.7, charthick=1.7, xtickformat='(A1)', ytickformat='(A1)', xminor=1, yminor=1
            
            if peakinfo.EFsuccess eq 1 then begin  ;Plot specific colors if code found a peak vs it didn't.
                ;Found a peak:
                col1 = col_blue  ;main peak
                col2 = col_green  ;all surrounding bins
            endif else begin
                ;Couldn't find a peak, mark all as brown:
                col1 = col_blue  ;main peak
                col2 = col_brown  ;all surrounding bins
            endelse
            ;OVERPLOT BINS:
            for sq = 0l, npts-1l do begin  ;loop over each square; used to be npk for old code
                xsq1 = peakinfo.pts[0,sq]
                xsq2 = xsq1+1l
                ysq1 = peakinfo.pts[1,sq]
                ysq2 = ysq1+1l
                
                ;Reverse Y coords, to match plotting by tv:
                ysq1b = dat.ndef - ysq2
                ysq2b = dat.ndef - ysq1
                
                ;The last square plotted will be the peak bin, so plot in a different color
                if sq eq npts-1l then col = col1 else col = col2
                
                oplot, [xsq1, xsq2], [ysq1b, ysq1b], color=col, thick=2   ;use green as white is in eflux colorbar
                oplot, [xsq1, xsq2], [ysq2b, ysq2b], color=col, thick=2
                oplot, [xsq1, xsq1], [ysq1b, ysq2b], color=col, thick=2
                oplot, [xsq2, xsq2], [ysq1b, ysq2b], color=col, thick=2   
                            
            endfor
            
            ;If requested, overplot the specified look vector input into the snap routine:           
            if lookvector eq 1 then begin
                result = mvn_sta_find_bin_directions(dat_cp, sta_apid=sta_apid, success=binsuccess, searchvector=searchvector, coneangle=coneangle)
                
                ;If this worked, oplot the results:
                if binsuccess eq 1 then begin
                    ;Look direction depends on energy. Use selected mrange, and lowest erange (largest theta range) values to determine which bins to show.
                    ;The lowest erange has indice dat.nenergy-1
                    diff = abs(dat_cp.mass_arr[0,0,*] - m_int)  ;use min distance to m_int to find mass bin
                    m1 = min(diff, imin, /nan)
                    result2 = (result[dat_cp.nenergy-1l, *, imin])
                    theta_vals_tmp1 = dat_cp.theta[dat_cp.nenergy-1l, *, imin]  ;get theta and phi values for checks
                    phi_vals_tmp1 = dat_cp.phi[dat_cp.nenergy-1l, *, imin]
                    
                    result3 = transpose(reform(result2, 4, 16))  ;same as code above where I checked this gives 16Ax4D
                    theta_vals_tmp2 = transpose(reform(theta_vals_tmp1, 4, 16))
                    phi_vals_tmp2 = transpose(reform(phi_vals_tmp1, 4, 16))
                    
                    isv = where(result3 eq 1, nisv)  ;find bins that fall within searchvector
                    if nisv gt 0 then begin
                      for ni = 0l, nisv-1l do begin
                          ;isv referenced to full array, so use mod to find column-row indices:
                          rowI = floor(isv[ni]/dat_cp.nanode)
                          colI = isv[ni] mod dat_cp.nanode
                          
                          ;Reverse Y coord to match TV plotting:
                          rowIb = dat.ndef - rowI -1l  ;extra -1l needed
                          
                          ;Overplot searchvector in dashed blue:
                          oplot, [colI, colI+1l], [rowIb, rowIb], linestyle=2, color=col_white, thick=2
                          oplot, [colI+1l, colI+1l], [rowIb, rowIb+1l], linestyle=2, color=col_white, thick=2
                          oplot, [colI+1l, colI], [rowIb+1l, rowIb+1l], linestyle=2, color=col_white, thick=2
                          oplot, [colI, colI], [rowIb+1l, rowIb], linestyle=2, color=col_white, thick=2
                         
                      endfor
                    endif
                                           
                endif
                
            endif           
            
        endif  ;forceplot2=1
                    
        ;GET sc blockage values:
        scvals = 0
        for vv = 0l, npts-1l do scvals+= bins_sc[peakinfo.pts[0,vv], peakinfo.pts[1,vv]]  ;if this = 9 then no blockage (probably).
        if scvals ne npts then scflag = 1 else scflag = 0
        
        ;#### Simple FOV check - does peak lie in middle two deflectors, or outside ones? Just because it lies in the outside,
        ;doesn't mean it's outside the FOV. We need c8 to say for sure, which can be used next if the beam is in one anode.
        if min(yPK,/nan) eq 0 or max(yPK,/nan) eq 3 then fovflag1 = 1 else fovflag1 = 0
        
        mvn_sta_convert_units, dat_c8, 'eflux' 
        data_c8_1 = dat_c8.data
        
        ;Sum over energy range:
        iRMc8 = where(dat_c8.energy lt erange[0] and dat_c8.energy gt erange[1], niRMc8)
        if niRMc8 gt 0l then data_c8_1[iRMc8] = 0.
        
        ;Remove empty mass dimension:
        data_c8_1 = reform(dat_c8.data, 32, 16)
        
        ;Sum over energy:
        data_c8_2 = total(data_c8_1, 1)
        
        ;Derive theta angles: theta are functions of energy. Take all bins that lie in the energy range requested, and use
        ;the largest theta angles (which correspond to the highest energy):
        iTH = where(dat_c8.energy[*,0,0] ge erange[0] and dat_c8.energy[*,0,0] le erange[1], niTH)
        
        ;if the c8 energy range requested is too narrow, choose a single energy bin closest to the midpoint requested
        if niTH eq 0 then begin  
            midE = mean(erange,/nan)
            diff = abs(midE - dat_c8.energy[*,0,0])
            m1 = min(diff, imin, /nan)
            eind_c8 = imin  ;indice to use
                       
        endif else eind_c8 = iTH
        
        ;If multiple rows were found, use the highest energy row:
        if niTH gt 1 then iTH2 = eind_c8[niTH-1l] else iTH2 = eind_c8[0]
        
        
        ;Get theta and data values to fit to later:
        Ytmp = data_c8_2
        Vtmp = reform(dat_c8.theta[iTH2,*,0], 16)  ;16D theta angles

        ;=======================
        ;PLOT c8 DEFLECTOR DATA:
        if forceplot2 eq 1 then begin
            ;Convert to [1x16] array to plot using tv:
            data_c8_3 = transpose(data_c8_2)
            
            scfac2 = floor(nY/16.)  ;have to rescale the 16 D to fit into nY.
            
            scale_array, data_c8_3, output=data_c8_3b, xfact=scfac2*3., yfact=scfac2
            
            xp2 = xp0 + nX + 15 ;plot position (pixels) for tvscl
            yp2 = yp0
            
            data_c8_3b_log = alog10(data_c8_3b)
            ;data_c8_3b_log_byt = bytscl(data_c8_3b_log, min=minval, max=maxval, /nan, top=topc)  ;bytscl with same range as main panel to use same cbar
            data_c8_3b_log_byt = mvn_sta_bytscl2(data_c8_3b_log, min=minval, max=maxval, top=topc, bottom=bottomc)  ;use bottom_c
            
            tv, reverse(data_c8_3b_log_byt,2), xp2, yp2   ;note reverse in D dimensions  ;this plots the mini vertical colorbar for c8
            xyouts, xp2-40., yp0+nY+5., 'c8 D, eflux', /device, charsize=1.7, charthick=1.7             
            
            ;PLOT SUM OF EFLUX FOR c8:
            dw2 = dw  ;width
            p9 = (xp2+115l)/wsx  ;x1
            p10 = p9 + dw2   ;x2
            p11 = p7  ;y1
            p12 = p8  ;y2
            
            Vtmp2 = findgen(17)  ;deflector array for c8. Can't plot wrt angle in degrees, as bins are not uniform in degree space.
            
            ;Y range based on data with real fluxes:
            iY = where(Ytmp gt 0)
            
            ;Note: reverse() not needed below:
            plot, reverse(Ytmp), charsize=1.7, charthick=1.7, xtitle='Eflux', position=[p9,p11,p10,p12], /noerase, $
              psym=10, /nodata, /xlog, xrange=[0.8*min(Ytmp[iY],/nan)>1E4, 1.25*max(Ytmp[iY],/nan)>1E7], xsty=1, $
                yrange=[min(Vtmp2,/nan), max(Vtmp2,/nan)], ysty=1, title='c8 def #', ytitle='Deflector #'
            cmf_sta_hist_plot, Vtmp2, reverse(Ytmp), /vert 
            
            ;PLOT COLORBAR FOR EFLUX:
            cbp1 = xp0/wsx  ;x1
            cbp2 = (xp0+nX)/wsx  ;x2
            cbp3 = (yp0+nY+45)/wsy  ;y1
            cbp4 = cbp3 + (20/wsy)  ;y2
            
            ;Create ticknames:
            nticks=6.  ;number of ticks
            ndiv=nticks-1.
            
            delt = (maxval-minval)/ndiv
            tickvals = (findgen(nticks)*delt)+minval
            tickvals2 = strtrim( string(tickvals, format='(F5.2)') ,2)
            
            if finite(minval) eq 1 and finite(maxval) eq 1 then $
            mvn_sta_colorbar, position=[cbp1, cbp3, cbp2, cbp4], minrange=minval, maxrange=maxval, divisions=ndiv, topind=topc, $
                            bottom=bottomc, title='Log eflux', charsize=1.5, ticknames=tickvals2
            
        endif  ;forceplot                
        
        ;#### If X% of total EF lies in one anode, use c8 data to look at distribution in 16D => is it in FOV?
        ;EFcol = total(data5[peakinfo.colI,*], /nan)  ;sum over deflectors
        ;EFtot = total(data5, /nan)  ;total EF

        ;Use amoeba to fit to c8 D data, if most of the eflux lies in one anode: reminder, that Ytmp has zeros instead of NaNs, which
        ;may screw up fitting if not taking into account:
        mvn_sta_fov_defl_amoebafit, Ytmp, Vtmp, output=output, fplot=0, /no_off, /zeros
        
        ;=====================
        ;Plot fit into window:
        if forceplot2 eq 1 then begin
            pp1 = p9
            pp2 = p10
            pp3 = yp1/wsy
            pp4 = (yp1+nY)/wsy
            plot, [0], [0], charsize=1.7, charthick=1.7, xtitle='Eflux', ytitle='Deflector [degrees]', thick=2, /xlog, $
                   position=[pp1, pp3, pp2, pp4], /nodata, /noerase, yrange=[(-1.)*1.2*max(output.xdata), (+1.)*1.2*max(output.xdata)], $  ;note yrange=[-ve, +ve] to get ordering correct     
                      xrange=[0.8*min(Ytmp[iY],/nan)>1E4, 1.25*max(Ytmp[iY],/nan)>1E7], xsty=1, ysty=1, title='c8 deflector fit'
            delxd = abs(output.xdata[0] - output.xdata[1])  ;delta angle
           
            cmf_sta_hist_plot, ([output.xdata[0]+delxd, output.xdata]), 10.^([output.yDATA_log]), /vert   ;reverse y order to plot in right order    
            oplot, 10.^(output.ymodel2), (output.xmodel)+(delxd/2.), thick=2., color=col_blue  ;fine res model fit
    
            ;PRINT RESULTS TO PLOT:
            if finite(EF_d_bm_ratio,/nan) eq 1 then EF_d_bm_ratio2 = 0 else EF_d_bm_ratio2 = EF_d_bm_ratio
            xyouts, (fix(p5*wsx))/3., wsy-40., "Beam size: "+strtrim(round(peakinfo.EFsize),2), /device, charsize=1.7, charthick=1.7 
            xyouts, (fix(p5*wsx))/3., wsy-70., "Eflux in beam [%]: "+strtrim(round(peakinfo.beamflux),2), /device, charsize=1.7, charthick=1.7
            xyouts, (fix(p5*wsx))/3., wsy-100., "Eflux in all defl (beam) [%]: "+strtrim(round(EF_d_bm_ratio2),2), /device, charsize=1.7, charthick=1.7
            xyouts, (fix(p5*wsx))/3., wsy-130., "Eflux in peak [%]: "+strtrim(fix(peakinfo.peakflux),2), /device, charsize=1.7, charthick=1.7

            ;Flag outputs:
            xyouts, (fix(p5*wsx))/3., 120., "FOV flag: "+strtrim(fix(fovflag1),2), /device, charsize=1.7, charthick=1.7
            xyouts, (fix(p5*wsx))/3., 90., "SC blockage flag: "+strtrim(fix(scflag),2), /device, charsize=1.7, charthick=1.7
             
            ;Print gaussian fit outputs:
            xyouts, (fix(p5*wsx))/3., wsy-190., "Gaussian fit % in FOV: "+strtrim(fix(round(output.area)),2), /device, charsize=1.7, charthick=1.7
            xyouts, (fix(p5*wsx))/3., wsy-220., "Gaussian fit error: "+strtrim(string(output.diff2, format='(F10.1)'),2), /device, charsize=1.7, charthick=1.7  ;### which diff value to use here?

            ;Print energy and mass ranges requested:
            xyouts, (p9*wsx)-80., (p11*wsy)-100., "Mass range [AMU]: "+mstr, /device, charsize=1.7, charthick=1.7
            xyouts, (p9*wsx)-80., (p11*wsy)-150., "Energy range [eV]: "+estr, /device, charsize=1.7, charthick=1.7
            
        endif  ;forceplot2 eq 1
         
        ;Output results:
        ;Gaussian fit results:
        diffALL[tt] = output.diff
        diffALL2[tt] = output.diff2
        maxALL[tt] = output.maxEF
        fracALL[tt] = output.area
        successGF[tt] = output.success  
        
        ;Other flag results:
        FOVflagALL[tt] = fovflag1
        SCflagALL[tt] = scflag
        EFtypeALL[tt] = peakinfo.EFsize
        EFpkALL[tt] = round(peakinfo.beamflux)
        EF_d_bm_ratio_ALL[tt] = EF_d_bm_ratio
          if peakinfo.EFsuccess eq 1 then d01s = 1 else d01s = 0
        successD01[tt] = d01s  ;did code succesfully use d0/1 data to get a FOV flag? EFsuccess must = 1 for this to be true.

    endif else begin  ;res=1
 
    endelse

endfor  ;tt

;Put outputs into one structure:
GFoutput = create_struct('diff'   ,     diffALL , $
                         'diff2'  ,     diffALL2, $
                         'max'    ,     maxALL  , $
                         'frac'   ,     fracALL , $
                         'success',     successGF )

FOVoutput = create_struct('Gaussian_fit'      ,     GFoutput  , $
                          'FOV_flag'          ,     FOVflagALL, $
                          'SC_flag'           ,     SCflagALL , $
                          'Beam_size'         ,     EFtypeALL , $   ;number of bins in the beam
                          'BeamEflux'         ,     EFpkALL   , $    ;eflux % in the found beam
                          'BeamEflux_in_d'    ,     EF_d_bm_ratio_ALL, $  ;eflux % in the deflectors only
                          'success'           ,     successD01, $  ;did it find a beam?
                          'time'              ,     timeALL   , $
                          'EFsuccess'         ,     peakinfo.EFsuccess)  ;1=code found the beam; 0= it didn't

;Finally, add on flag value calculated, and add this to FOVoutput structure:
flagVAL = mvn_sta_fov_create_flag(FOVoutput)

str_element, FOVoutput, 'fovflag', flagval, /add  ;Add flag to output structure

if forceplot2 eq 1 then xyouts, (fix(p5*wsx))/3., 60., "FOV flag value: "+strtrim(fix(flagVAL),2), /device, charsize=1.7, charthick=1.7

if keyword_set(ctimeflag) then wset, tpnum  ;reset to tplot window on exit if needed

success=1  ;code ran through and should have made some outputs

end


;=============
;=============

;+
;This is the top most routine that users should run. This routine will call upon those above.
;
;INPUTS:
;
;trange: optional: set as:
;        single UNIX time: calculate FOV results for this time. Results are plotted into the window wnum.
;        time range [a,b]: calculate FOV results between these two times. Results are not plotted in this mode to save time,
;                          but setting /forceplot will overwrite this.
;        don't set: use the ctime cursor in your tplot window, and the FOV results will plot as you move the cursor. Set wnum and
;                   tpnum.
;
;wnum: IDL window number into which FOV results are plotted. Default is 2 if not set.
;tpnum: IDL window number that your tplot is in. Default is 0 if not set.
;
;success: 1 if routine was able to generate FOV flags, 0 if it wasn't (ie no data available).
;         I'm not sure this will work when using in the tplot cursor mode.
;
;mrange: AMU mass range to look. Right now doesn't work - looks at all masses.
;
;erange: energy range in eV to look at - right now doesn't work - looks at all energies.
;
;sta_apid: lowercase string: user can set which STATIC data products to use by hand if wanted. Options are 'ce', 'cf', 'd0', 'd1',
;          as no other STATIC products contain the necessary information.
;
;Set /forceplot to force the routine to plot the FOV results, even when running over multiple timesteps.
;
;Set /qc to use Mike Chaffins qualcolors color tables. If not set, default IDL colors are used.
;
;Set /allvars to create the full set of tplot variables associated with determining the STATIC FOV flag. These are mostly
;   for testing purposes. If not set, only one variable will be created, mvn_sta_FOV_flag, which contains the final flag information.
;
;top_c, bottom_c: top and bottom color table indices that IDL should used when plotting. Defaults if not set are either 0 and 255,
;                 or those set by qualcolors, if /qc is set.
;
;zrange: [a,b] float array, where a and b are the min and max energy flux values for the colorbar. Useful if you want all plots to
;        keep the same plot range. If not set, the code uses default variable zranges based on the energy flux present at each timestep.
;        a and b are real numbers - they will become alog10(a), alog10(b) within the code.
;
;species: there are several ions with pre-set mass parameters; enter the following strings (case independent):
;         'H', 'He', 'O', 'O2' or 'CO2'. If set, you don't need to set mrange or m_int - these are set for you. The species input overwrites
;         the mrange and m_int keywords.
;
;mrange: [a,b]: use this keyword to specify the mass range for which flow velocities are calculated for.
;       Each mass range will have its own tplot variable created. If not set, all masses are used.
;
;       Some additional notes:
;       STATIC d0 and d1 data have 8 mass bins centered on the following AMU values. The following options are allowed for the
;       mass keyword:
;       mass  = 1.09 AMU
;             = 2.23 AMU
;             = 4.67 AMU
;             = 9.42 AMU
;             = 17.14 AMU
;             = 30.57 AMU
;             = 42.42 AMU
;             = 62.53 AMU
;
;       STATIC ce and cf data have 16 mass bins (more mass resolution), but are only available in ~2015. After ~2015, at least d0
;       data should be available all of time (and d1 data should be available most of the time).
;
;searchvector: [a,b,c]: vector in the MSO coordinate system. If set, the routine will mark which STATIC anode-deflector bins fall within
;                       coneangle of this vector.
;
;coneangle: float: STATIC bins that lie within this angle of searchvector are plotted. Units of degrees. Default is 35 degrees if not set.
;
;
;OUTPUTS:
; flagout: If trange is set as a single timestamp, or two element array of start and stop times, the keyword flagout will contain the
; STA FOV flag variables for the user specified mass and energy ranges. The default value of flagout is NaN, if not flag value
; was calculated (success=0).
; 
; If trange is set as a two element array as a time range, the tplot variable mvn_sta_FOV_flag_mrA_B_erC_D will
; be produced, where A and B are the AMU mass range, and C and D are the energy range, specified by the user. This tplot
; variable contains the FOV flag for those ions. 
; The flag values are below. Data with flag=0 data can be used with confidence. Data with flag=1 and
; flag=2 may have FOV issues, and if used, should be used with caution. Data with flag=3 has FOV issues and should not be used.
;   0 : FOV should be ok - ok to use data.
;   1 : Possible FOV issues - this is based on data without mass resolution. Use with caution.
;   2 : Possible FOV issues: the beam lies at the edge of the FOV. Finer resolution data show the beam to be within the FOV,
;       but these data don't resolve mass. Use with caution.
;   3 : FOV issues: the beam is at the edge of the FOV, and / or the spacecraft is blocking part of the beam. Don't use.
;   
;   
;EGS:
;You must first load STATIC d0 or d1 data, and c8 data:
;timespan, '2018-07-06', 1.
;mvn_sta_l2_load, sta_apid=['d1', 'c8'], /tplot_vars_create   
;
;window, 0
;tplot, [some variables]
;
;ctime, t0  ;select a single time, or a range of times.
;mvn_sta_fov_snap, trange=t0, tpnum=0, sta_apid='d1', species='o'     ;this will plot the results for a single click, or output them for a range.
;
;mvn_sta_fov_snap, tpnum=0, sta_apid='d1', erange=[1000., 30000.]  ;this will allow the user to move the cursor across the tplot window and set the results at each timestep.
;
;mvn_sta_fov_snap, sta_apid='d1', zrange=[1e6, 1e10], top_c=240  ;set colorbar range, and restrict color indices IDL can use when plotting.
;
;
;
;.r /Users/cmfowler/IDL/STATIC_routines/FOV_routines/mvn_sta_fov_snap.pro
;-

pro mvn_sta_fov_snap, trange=trange, wnum=wnum, tpnum=tpnum, forceplot=forceplot, success=success, mrange=mrange, erange=erange, $
                        sta_apid=sta_apid, qc=qc, allvars=allvars, flagout=flagout, top_c=top_c, bottom_c=bottom_c, $
                          zrange=zrange, species=species, searchvector=searchvector, coneangle=coneangle

if not keyword_set(sta_apid) then begin
  print, ""
  print, "Currently, you must specify sta_apid; routine is not clever enough to figure this out yet. For most cases you can use sta_apid='d1'"
  success=0
  return
endif

if not keyword_set(coneangle) then coneangle = 35. ;degrees

flagout = !values.f_nan

;If keyword species set, go with this:
if size(species, /type) eq 7 then begin
  mranges = mvn_sta_get_mrange()

  species=strupcase(species)
  case species of
    'H' : begin
                mrange = mranges.H
                m_int=1.
          end
    'HE' : begin
                mrange = mranges.He
                m_int=2.
          end
    'O' : begin
                mrange = mranges.O
                m_int=16.
          end
    'O2' : begin
                mrange = mranges.O2
                m_int=32.
          end
    'CO2' : begin
                mrange = mranges.CO2
                m_int=44.
          end
    else : begin
              mrange=[0., 60.]
              m_int=32.
           end
  endcase
endif

if size(trange,/type) ne 0 then begin
    ;trange is set:
    neleTR = n_elements(trange)
    
    common mvn_sta_fov_common, plotct, all_dat, dtype ;this is needed here to set plotct=0
    plotct=0l
    if keyword_set(searchvector) then lookvector=1 else lookvector=0
    mvn_sta_d0d1c8_fov_crib, trange=trange, success=success, erange=erange, mrange=mrange, m_int=m_int, wnum=wnum, tpnum=tpnum, $
                          forceplot=forceplot, ctimeflag=ctimeflag, FOVoutput=FOVoutput, sta_apid=sta_apid, qc=qc, $
                          top_c=top_c, bottom_c=bottom_c, zrange=zrange, searchvector=searchvector, coneangle=coneangle, lookvector=lookvector

    if success eq 1 then begin
        ;Store outputs as tplot variables: mrange and erange are in routine above, if user does not set them:
        mstr = '('+strtrim(string(mrange[0], format='(f12.1)'),2)+','+strtrim(string(mrange[1], format='(f12.1)'),2)+')'
        estr = '('+strtrim(string(erange[0], format='(f12.1)'),2)+','+strtrim(string(erange[1], format='(f12.1)'),2)+')'        
        nameext = '_mr'+mstr+'_er'+estr  ;add this to the end of each variable.
        
        if keyword_set(allvars) then begin
            if neleTR eq 2 then begin
                store_data, 'mvn_sta_fov_defl_flag'+nameext, data={x: FOVoutput.time, y: FOVoutput.fov_flag}
                  ylim, 'mvn_sta_fov_defl_flag'+nameext, -1, 2
                  options, 'mvn_sta_fov_defl_flag'+nameext, ytitle='D flag'
                    
                store_data, 'mvn_sta_fov_sc_flag'+nameext, data={x: FOVoutput.time, y: FOVoutput.sc_flag}
                  ylim, 'mvn_sta_fov_sc_flag'+nameext, -1, 2 
                  options, 'mvn_sta_fov_sc_flag'+nameext, ytitle='SC flag'
            
                store_data, 'mvn_sta_fov_peak_type'+nameext, data={x: FOVoutput.time, y: FOVoutput.peak_type}
                  ylim, 'mvn_sta_fov_peak_type'+nameext, 0, 5
                  options, 'mvn_sta_fov_peak_type'+nameext, ytitle='Beam type'
            
                store_data, 'mvn_sta_fov_peak_fr'+nameext, data={x: FOVoutput.time, y: FOVoutput.peak_fr}
                  ylim, 'mvn_sta_fov_peak_fr'+nameext, 0, 100
                  options, 'mvn_sta_fov_peak_fr'+nameext, ytitle='Beam frac'
                
                store_data, 'mvn_sta_fov_peak_dfr'+nameext, data={x: FOVoutput.time, y: FOVoutput.peak_fr_d}
                  ylim, 'mvn_sta_fov_peak_dfr'+nameext, 0, 100
                  options, 'mvn_sta_fov_peak_dfr'+nameext, ytitle='Beam frac!Cd def'
              
                store_data, 'mvn_sta_fov_gauss_fov'+nameext, data={x: FOVoutput.time, y: FOVoutput.Gaussian_fit.frac}
                  ylim, 'mvn_sta_fov_gauss_fov'+nameext, 0, 100
                  options, 'mvn_sta_fov_gauss_fov'+nameext, ytitle='GF frac'
            
                store_data, 'mvn_sta_fov_gauss_diff'+nameext, data={x: FOVoutput.time, y: FOVoutput.Gaussian_fit.diff2}  ;#### which diff value to use here?
                  ylim, 'mvn_sta_fov_gauss_diff'+nameext, 0, 40
                  options, 'mvn_sta_fov_gauss_diff'+nameext, ytitle='GF diff'
            
                store_data, 'mvn_sta_fov_gauss_max'+nameext, data={x: FOVoutput.time, y: FOVoutput.Gaussian_fit.max}
                  ylim, 'mvn_sta_fov_gauss_max'+nameext, 4, 12
                  options, 'mvn_sta_fov_gauss_max'+nameext, ytitle='GF max EF'
            endif  ;neleTR=2
        endif ;allvars
        
        ;FOV tplot variable:
        ;Always make this variable:
        if neleTR eq 2 then begin
            store_data, 'mvn_sta_FOV_flag'+nameext, data={x: FOVoutput.time, y: FOVoutput.fovflag}
              ylim, 'mvn_sta_FOV_flag'+nameext, -1, 4
              options, 'mvn_sta_FOV_flag'+nameext, ytitle='STA FOV!Cflag'
        endif
        
        flagout = FOVoutput.fovflag
        
    endif  ;success=1
          
endif else begin
    ;trange is not set, use cursor with ctime:
    common mvn_sta_fov_common, plotct, all_dat, dtype ;this is needed here to set plotct=0
    plotct = 0l  ;counter so that routine knows on first plot, to create the window wnum
    
    if keyword_set(wnum) then wstr = strtrim(fix(wnum),2) else wstr='0'
    if keyword_set(tpnum) then tstr = strtrim(fix(tpnum),2) else tstr='0'
    if keyword_set(mrange) then mstr = '['+strtrim(mrange[0],2)+','+strtrim(mrange[1],2)+']' else mstr='0'
    if keyword_set(erange) then estr = '['+strtrim(erange[0],2)+','+strtrim(erange[1],2)+']' else estr='0'
    if keyword_set(zrange) then zstr = '['+strtrim(zrange[0],2)+','+strtrim(zrange[1],2)+']' else zstr='0'
    if keyword_set(sta_apid) then sta_apid_str = sta_apid else sta_apid_str='0'
    if keyword_set(qc) then qc_str = '1' else qc_str='0'
    if keyword_set(top_c) then top_c_str = strtrim(fix(top_c),2) else top_c_str='"na"'
    if keyword_set(bottom_c) then bottom_c_str = strtrim(fix(bottom_c),2) else bottom_c_str='"na"'
    if keyword_set(coneangle) then coneangle_str = strtrim(string(coneangle, format='(F7.2)'),2) else coneangle_str='0'
    if keyword_set(searchvector) then begin
          searchvector_str = '['+strtrim(string(searchvector[0],format='(F10.2)'),2)+','+strtrim(string(searchvector[1],format='(F10.2)'),2)+','+strtrim(string(searchvector[2],format='(F10.2)'),2)+']'
          lookvector_str='1'
    endif else begin
        searchvector_str='0'
        lookvector_str='0'
    endelse
    m_int_str = strtrim(string(m_int, format='(F7.2)'),2)

    mvn_sta_ctime, trange, routine_name='mvn_sta_d0d1c8_fov_crib, trange=t, wnum='+wstr+', tpnum='+tstr+', mrange='+mstr+', erange='+estr+', zrange='+zstr+', qc='+qc_str+', ctimeflag=1, sta_apid="'+sta_apid_str+'", top_c='+top_c_str+', bottom_c='+bottom_c_str+', coneangle='+coneangle_str+', searchvector='+searchvector_str+', lookvector='+lookvector_str+', m_int='+m_int_str               
    
endelse

if keyword_set(tpnum) then wset, tpnum  ;reset tplot window to active one

;To do:
;output data for plotting?

end





