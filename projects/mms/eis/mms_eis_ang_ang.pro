;+
; mms_eis_ang_ang.pro
;
; PURPOSE: Generate angle-angle (polar versus azimuthal) plots for EIS data with overlaid pitch angle contours
;
; KEYWORDS:
;         probe:              value for MMS SC #
;         trange:             time range of interest (string, ex. ['yyyy-mm-dd','yyyy-mm-dd'])
;         datatype:           'extof', 'phxtof', or 'electronenergy'
;         species:            depends on datatype: 
;                               - ExTOF: 'proton', 'oxygen', 'helium' (formerly 'alpha')
;                               - PHxTOF: 'proton'
;                               - electronenergy: 'electron' (this will be set automatically if you specify 'electronenergy' as the datatype)
;         level:               data level ['l1a','l1b','l2pre','l2' (default)]
;         data_units:         'flux' or 'cps'
;         data_rate:          instrument data rates ['brst', 'srvy' (default)]
;         energy_chan:        array of four energy channels (numeric, ex. [1,2,3,4])
;         avgdata:            set to 1 to average values between the images when time range forces the resolution to greater than 1 (default = 0)
;         i_print:            set to 1 to print to PS file (default = 0)
;         p_filename:         string array defining filename for output .ps file
;         png:                string defining filename for output of .png file
;         no_plot:            set =1 to not plot data (default = 0)
;         cdf_version:        (optional) desired CDF version of EIS data to load
;         n_azbins:           number of azimuthal bins (if not set, will be automatically defined by data_rate)
;
;
; CREATED BY: J. Westlake, 2015-09-18
;
; REVISION HISTORY:
;       + 2015-09-21, I. Cohen      : changed name from mms_ang_ang_crib to eis_ang_ang; added trange to keywords; added documentation; set plot window size; 
;                                   : moved loadct out of for loop; added flat field array for each probe; added trange to get_data calls
;       + 2015-09-22, I. Cohen      : added /time_clip to mms_load_eis call to make trange work correctly; added res keyword for plotting time resolution; 
;                                   : replaced i with correct index for timedata when plotting; change y positions in cgimage position to lower first row from top of window
;                                   : replaced color keyword in cgcontour with c_color to get white contours; added datatype keyword; added energy_chan keyword
;       + 2015-09-23, I. Cohen      : changed colortable for plot from 33 to 1; changed "default" color table at the end from 13 to 39; commented out get_data for sector and midtai
;                                   : added capability for electrons by using datatype in get_data calls
;       + 2015-09-30, J. Westlake   : changed polar binning from [-90,90] to [–80,80]; fixed issue with PA contours, replaced non-data 0's with NaN
;       + 2015-10-15, J. Westlake   : changed azimuth range from [0,360] to [-180,180] (0 sunward, GSE)
;       + 2015-10-23, I. Cohen      : added i_print switch for printing to PS
;       + 2015-11-02, J. Westlake   : changed definition of polar angle from !RADEG*acos(d.y[*,2])-90 to 90-!RADEG*acos(d.y[*,2]) to correct sign of polar angle
;       + 2016-01-11, I. Cohen      : added data_rate and data_units keywords
;       + 2016-01-12, J. Westlake   ; removed res keyword; fixed scaling issue in plotting; fixed timing (nspins & spininds) to force start and stop at first & last complete spins
;                                   ; changed charsize to 1.5; changed number of rows to n_elements in energy_chan instead of forcing 4
;       + 2016-01-20, J. Westlake   ; fixed some bugs related to the number of plots on the screen and the automatic resolution selection. Cleaned up a bit around the edges
;                                   ; Also implemented selectable number of energy bins - as in if you only put in two energy bins in the call then you only get two in the plots
;                                   ; Also they don't have to be energy bins that are next to each other. And I put in some stuff to make the plots a bit more informative, made the axes 
;                                   ; go to values that we care about and added titles for the lines. Updated the flat fielding. I added the keyword avgdata to allow for averaging between
;                                   ; data points or decimating the data. Also added colorbars.
;       + 2016-03-02, I. Cohen      : added level keyword and defined pvalue to handle L2 data
;       + 2016-03-15, I. Cohen      : added p_filename keyword for general printing; added prefix definition to enable handling of burst data; removed flat fielding                     
;       + 2016-03-23, E. Grimes     : removed dependencies on cgtext, cgimage, cgconlevels, cgcontour, cgcolorbar
;                                   : updated the date/time format to prevent overlap with the next plot
;                                   : added png keyword, for saving output to a PNG file
;       + 2016-03-24, E. Grimes     : fixed issues with postscript output caused by my changes yesterday
;                                   : set the default data_rate to 'srvy' (if not specified); request the time range (if not specified)
;                                   : commented out !p.multi call in postscript output, so that all energy channels are included in the PS file
;       + 2016-03-31, E. Grimes     : removed flat fielding 
;       + 2016-09-19, E. Grimes     : updated to support v3 L1b files, as well as integer probes
;       + 2016-10-26, E. Grimes     : fixed bug for burst mode data; n_azi=32 (burst), n_azi=8 (srvy)
;       + 2016-11-08, E. Grimes     : now programmatically getting number of azimuths from the sector variable; setting species='electron' when datatype='electronenergy';
;                                   : also now checking that data exists before trying to access the data                            
;       + 2017-05-05, I. Cohen      : added ability to use "helium" as species; altered EIS varformat to include look direction and magnetic field;
;                                   : added print command to inform if data is unavailable
;       + 2020-07-02, S. Bingham    : added no_plot, cdf_version, and n_azbins keywords; added output of ang-ang data to tplot variable; changed procedure name to 'mms_eis_ang_ang.pro'
;       + 2020-12-11, I. Cohen      : changed "undefined" to "undefined" in initialization of some keywords
;       + 2021-02-09, I. Cohen      : added helium to species in header under KEYWORD section and removed PHxTOF oxygen; added loadct call for species='helium'
;       + 2021-04-08, I. Cohen      : updated prefix definition to handle new L2 variable names
;                        
;$LastChangedBy: egrimes $
;$LastChangedDate: 2021-08-06 09:27:09 -0700 (Fri, 06 Aug 2021) $
;$LastChangedRevision: 30179 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_ang_ang.pro $
;-

pro mms_eis_ang_ang, probe=probe, trange = trange, species = species, datatype = datatype, level = level, data_units = data_units, data_rate = data_rate, $
  energy_chan = energy_chan, avgdata=avgdata, i_print = i_print, p_filename = p_filename, png = png, no_plot = no_plot, cdf_version = cdf_version, n_azbins = n_azbins
  
  ; set defaults
  if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
  if undefined(species) then species = 'proton'
  if undefined(datatype) then datatype = 'extof'
  if undefined(data_units) then data_units = 'flux'
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(level) then level = 'l2'
  if undefined(energy_chan) then energy_chan = [1,2,3,4]
  if undefined(i_print) then i_print = 0
  if undefined(avgdata) then avgdata = 0
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then trange = timerange(trange) $
    else trange = timerange()
  if undefined(no_plot) then no_plot = 0
  
  ; species should always be 'electron' for 'electronenergy' datatypes
  if datatype eq 'electronenergy' then species = 'electron'
;  if species eq 'helium' then species = 'alpha'
  
  date_dir = strmid(trange(0),0,10)
  date_filename = strmid(trange(0),0,4)+strmid(trange(0),5,2)+strmid(trange(0),8,2)
  start_time_filename = strmid(trange(0),11,2)+strmid(trange(0),14,2)
  end_time_filename = strmid(trange(1),11,2)+strmid(trange(1),14,2)
  
  nenergies = n_elements(energy_chan)
  
  prefix = 'mms'+probe+'_epd_eis_'+data_rate+'_'+level+'_'
  
  ; load EIS data:
  mms_load_eis, probes=probe, cdf_version = cdf_version, trange=trange, datatype=datatype, level = level, data_rate = data_rate, data_units=data_units, $
    /time_clip, varformat = ['*'+species+'_P*_'+data_units+'_t*','*spin*','*sector*','*pitch_angle*','*look*','*_b','*'+species+'*energy*']
  
  get_data, prefix+datatype+'_look_t0', data = d
  ;stop
  ; check if there's valid data before continuing
  if ~is_struct(d) then begin
    print,'No valid data found'
    return
  endif
  
  azi = dblarr(6,n_elements(d.x))
  pol = dblarr(6,n_elements(d.x))
  pa = dblarr(6,n_elements(d.x))
  cps = dblarr(6,nenergies,n_elements(d.x))
  
  ; use wild cards to figure out what this variable name should be for telescope 0
  this_variable = tnames(prefix + datatype + '_' + species + '*_' + data_units + '_t0')
  if level eq 'l2' || level eq 'l1b' then begin
    ; get the P# value from the name of telescope 0:
    pvalue = (strsplit(this_variable, '_', /extract))[7]
    if pvalue ne data_units then pvalue = pvalue + '_' else pvalue = ''
  endif else begin
    pvalue = ''
  endelse
  
  for t=0, 5 do begin
    get_data, prefix+datatype+'_look_t'+STRTRIM(t, 1), data = d
    azi[t,*] = !RADEG*atan(d.y[*,1],d.y[*,0])             ;; Domain [-180,180], 0 = sunward (GSE)
    pol[t,*] = 90-!RADEG*acos(d.y[*,2])                ;; Domain [-90,90], Positive is look direction northward
    get_data, prefix+datatype+'_pitch_angle_t'+STRTRIM(t, 1), data = d
    pa[t,*] = d.y
    get_data, prefix+datatype+'_'+species+'_'+pvalue+data_units+'_t'+STRTRIM(t, 1), data = d
    for i=0, nenergies-1 do cps[t,i,*] = d.y[*,energy_chan(i)-1]
  endfor
  
  get_data, prefix+datatype+'_b', data = magfield
  get_data, prefix+datatype+'_spin', data = spin
  get_data, prefix+datatype+'_sector', data = sector
  
  spininds = uniq(spin.y)
  spin_test = where(spin.y eq spin.y[spininds[0]],count)            ;; Check to see if we have a complete first spin
  if count ne 8 then spininds = spininds[1:n_elements(spininds)-1]  ;; If not then go to the second spin
  spin_test = where(spin.y eq spin.y[spininds[n_elements(spininds)-1]],count)   ;; Check to see if the last one is complete
  if count ne 8 then spininds = spininds[0:n_elements(spininds)-2]  ;; If not then go to the second spin
  nspins = n_elements(spininds)
  n_pol = 6
  min_pol_edges = -80 + 160*findgen(n_pol)/n_pol      ;;Minus 80 plus
  max_pol_edges = -80 + 160*(findgen(n_pol)+1)/n_pol
  
  ;if data_rate eq 'brst' then n_azi = 32 else n_azi = 8
  IF KEYWORD_SET(n_azbins) THEN n_azi = n_azbins ELSE n_azi = n_elements(uniq(sector.Y, sort(sector.Y)))
  
  min_azi_edges = -180 + 360*findgen(n_azi)/n_azi
  max_azi_edges = -180 + 360*(findgen(n_azi)+1)/n_azi
  angangdata = dblarr(n_azi,n_pol,nspins,nenergies)
  padata = fltarr(n_azi,n_pol,nspins)
  ind = where(padata eq 0.0)
  padata[ind] = !VALUES.F_NAN     ;; Start the array with NAN
  timedata = strarr(nspins)
  
  polarangs = -80+findgen(160)
  aziangs = findgen(360)
  ;stop
  for i=0, nspins-1 do begin
      thisSpin = spin.y[spininds[i]]
      timeinds = where(spin.y eq thisSpin)
  ;    timedata[i] = time_string(spin.x[spininds[i]], tformat='YYYY-MM-DD!Chh:mm:ss')
      timedata[i] = time_string(spin.x[timeinds[0]], tformat='YYYY-MM-DD!Chh:mm:ss')
  
      for j=0, n_elements(timeinds)-1 do begin
        for t=0, 5 do begin
          thisAzi = where((azi[t,timeinds[j]] gt min_azi_edges) and (azi[t,timeinds[j]] lt max_azi_edges)) 
          thisPol = where((pol[t,timeinds[j]] gt min_pol_edges) and (pol[t,timeinds[j]] lt max_pol_edges))
          for k=0, nenergies-1 do angangdata[thisAzi,thisPol,i,k] = cps[t,k,timeinds[j]]          
          padata[thisAzi,thisPol,i] = pa[t,timeinds[j]]
       endfor
      endfor
  
  endfor
  
  ;; set color table specific to each species
  if species eq 'proton' then loadct,1
  if (species eq 'alpha') or (species eq 'helium') then loadct,8
  if species eq 'oxygen' then loadct,3
  if species eq 'electron' then loadct,7
  
  ;; set number of columns in plot
  !p.multi=0
  if nspins le 16 then begin
    res=1.
    !p.multi = [0,nspins,nenergies]
    nplots = nspins
  endif else begin
    res = fix(nspins/16)
    !p.multi=[0,16,nenergies]
    nplots = 16
  endelse
  
  ;; Scale the plots for the maximum size that the screen can handle
  scsize = get_screen_size()
  nxsize = nplots*150
  nysize = nenergies*200
  if nxsize gt scsize[0] then nxsize=scsize[0]
  if nysize gt scsize[1] then nysize=scsize[1]
  
  ; store angang data as tplot
  timedata_dbl = TIME_DOUBLE(strmid(timedata,0,10)+'/'+strmid(timedata,12,8))
  store_data,prefix+datatype+'_'+species+'_'+data_units+'_angangdata',data={x:timedata_dbl,y:angangdata,v1:min_azi_edges + 180./n_azi,v2:min_pol_edges + 90./n_pol,v3:d.v(energy_chan-1)}
  
  IF (no_plot NE 1) THEN BEGIN
    window, 0, xsize=nxsize, ysize=nysize
    !X.OMargin = [3,12]
    !Y.OMargin = [2,5]
    ;; Reformat axes
    axis_format = {XTicks:3, YTicks:4}

    ;; plot     
    for j=0,nenergies-1 do begin
      angangdata_bytscl = bytscl(alog10(angangdata[*,*,*,j]),min=0.01)
      for i=0,nplots-1 do begin
        if i eq nplots-1 then xyouts, 10, (nysize-10)-(nysize/nenergies-8)*j, species+', Energy Bin Number: '+strcompress(string(energy_chan(j))),/device, color=0
        thisind = i*res
        if (res gt 1) and (avgdata eq 1) and (i gt 0) then thisangangdata = total(angangdata_bytscl[*,*,(thisind-res):thisind],3)/res $
          else thisangangdata = angangdata_bytscl[*,*,thisind]
        
        ; setup the plot with margins and axes
        contour, padata[*,*,thisind], min_azi_edges + 180./n_azi, min_pol_edges + 90./n_pol,$
            YSTYLE=1, xstyle=1, XRANGE=[-180, 180], YRANGE=[-80, 80], xmargin=2, ymargin=[7, 2], charsize=1.5, $
            title=timedata[thisind], yticks=4, xticks=3
        
        ; setup the contour levels
        num_levels = 6
        contourLevels = 180*indgen(num_levels+1)/num_levels
        c_levels_str = strcompress(string(contourLevels), /rem)
        
        ; add the data
        tvimage, thisangangdata, /axes, margin=0.33,xrange=[-180,180],yrange=[-80,80],$
          background=255,Position= [0.1, 0.2, 0.98, 0.88] , title=timedata[thisind],charsize=1.5,$
          AXKEYWORDS=axis_format, xstyle=1, ystyle=1, /overplot, /nointerpolation
        
        ; draw the contours
        contour, padata[*,*,thisind], min_azi_edges + 180./n_azi, min_pol_edges + 90./n_pol, $
          Levels=contourLevels,C_Colors=255, /overplot, c_labels=c_levels_str
        IF max(angangdata[*,*,*,j]) NE 0 THEN range_max = max(angangdata[*,*,*,j]) ELSE range_max = 10.
        if i eq nplots-1 then draw_color_scale, range=[0.01, range_max], charsize=2.0, /log
      endfor
    endfor
    
    if keyword_set(png) then makepng, png
    
    ;; print copy of plot to file if i_print keyword set to 1
    if (i_print eq 1) then begin
      
      !p.charsize=0.6
      popen,p_filename,land=1
      if species eq 'proton' then loadct,1
      if (species eq 'alpha') OR (species eq 'helium') then loadct,8
      if species eq 'oxygen' then loadct,3
      if species eq 'electron' then loadct,7

      for j=0,nenergies-1 do begin
        angangdata_bytscl = bytscl(alog10(angangdata[*,*,*,j]),min=0.01)
        for i=0,nplots-1 do begin
          if i eq nplots-1 then xyouts, 0.025, 1.-(float(j)/nenergies)+0.004*j, species+', Energy Bin Number: '+strcompress(string(energy_chan(j))),/normal, color=0
          thisind = i*res ;800 + i*res
          if (res gt 1) and (avgdata eq 1) and (i gt 0) then thisangangdata = total(angangdata_bytscl[*,*,(thisind-res):thisind],3)/res $
          else thisangangdata = angangdata_bytscl[*,*,thisind]
    
          ; setup the plot with margins and axes
          contour, padata[*,*,thisind], min_azi_edges + 180./n_azi, min_pol_edges + 90./n_pol,$
              YSTYLE=1, xstyle=1, XRANGE=[-180, 180], YRANGE=[-80, 80], xmargin=2, ymargin=[7, 2], $
              title=timedata[thisind], yticks=4, xticks=3, c_charsize=0.4
          
          ; setup the contour levels
          num_levels = 6
          contourLevels = 180*indgen(num_levels+1)/num_levels
          c_levels_str = strcompress(string(contourLevels), /rem)
          
          ; add the data
          tvimage, thisangangdata, /axes, margin=0.33,xrange=[-180,180],yrange=[-80,80],$
            background=255,Position= [0.1, 0.2, 0.98, 0.88] , title=timedata[thisind],$
            AXKEYWORDS=axis_format, xstyle=1, ystyle=1, /overplot, /nointerpolation
          
          ; draw the contours
          contour, padata[*,*,thisind], min_azi_edges + 180./n_azi, min_pol_edges + 90./n_pol, $
            Levels=contourLevels,C_Colors=255, /overplot, c_labels=c_levels_str, c_charsize=0.4
          
          ; draw the colorbar
          if i eq nplots-1 then draw_color_scale, range=[0.01, max(angangdata[*,*,*,j])], charsize=1.2, /log
        endfor
      endfor
      pclose
    endif
  ENDIF 
  loadct,39
  !p.multi=0

end