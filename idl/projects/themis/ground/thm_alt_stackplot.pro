;+
; NAME:
;       thm_alt_stackplot.pro
;
; PURPOSE:
;       To create 3 PNG files displaying the H,D and Z components of the magnetic field
;	from multiple GBO stations out of GMAG data that is stored in CDF file.
;
; CALLING SEQUENCE:
;       thm_alt_stackplot, date, duration, stack_shift=stack_shift, no_expose=no_expose, make_png=make_png
;
; INPUTS:
;       date: The start of the time interval to be plotted. (Format:
;       'YYYY-MM-DD/hh:mm:ss')
;	duration: The length of the interval being plotted. (Floating
;	point number of days -> 12hr=0.5), default=1
;	stack_shift: Space between stations on the y-axis (units are
;	nanotesla), default=50
;	no_expose: Set this keyword to prevent the plot from being
;	printed to the screen. 
;       make_png: Set this keyword to make the 3 PNG files. (OPTION
;	NOT IMPLEMENTED
;	max_deviation:  Large spikes in the data (probably gliches)
;	can screw up the y-axis scales.  This keyword allows you to
;	set the maximum deviation the data can go from the median;
;	points that exceed this value are omitted. default value is
;	plus or minus 1500 nT
;	no_data_load:  This keyword prevents new data from being
;	loaded; the routine will try to plot existing data if it exists.
; OUTPUTS:
;       Plots...
;; PROCEDURE:
;       Read in data from CDF files; plot the data using tplot.pro routines;
;       make PNG files with makegif.pro routine
; EXAMPLE:
;       thm_alt_stackplot, '2006-11-11',1,/make_png, max_deviation=1500, stack_shift=200.
; MODIFICATION HISTORY:
;       Written by:       Matt Davis
;       October 23, 2006     Initial version
;       Added dydt_spike_test, 7-apr-2008, jmm, jimm@ssl.berkeley.edu
;       Hacked from thm_gmag_stackplot, this version makes no
;       distinction between lo and hi lat's, just plots 8 per page,
;       jmm, 31-aug-2009
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-09 09:54:03 -0800 (Mon, 09 Jan 2012) $
; $LastChangedRevision: 9515 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_alt_stackplot.pro $
;-

Pro thm_alt_stackplot, date, duration, stack_shift=stack_shift, $
                       make_png = make_png, max_deviation = max_deviation, $
                       no_data_load = no_data_load, n_per_page = n_per_page, $
                       plot_dir = plot_dir, _extra = _extra
;________________________________________________________________________________________________
;find all gmag CDF files on given date and put data into tplot variables
;________________________________________________________________________________________________
  if not keyword_set(date) then begin
    dprint,  'You must specify a date.  (Format : YYYY-MM-DD/HH:MM:SS)'
    return
  endif

  if not keyword_set(duration) then duration = 1.

  start_time = time_double(date)
  end_time = start_time+86400.*duration

  timespan, date, duration
  if not keyword_set(no_data_load) then thm_load_gmag, site = '????'
;________________________________________________________________________________________________
;check that there is some valid data
;________________________________________________________________________________________________
  tplotvars = tnames('thg_mag_????')
  if tplotvars(0) eq '' then begin
    dprint,  'Appropriate tplot variables could not be found!'
    dprint,  'Searched for "thg_mag_????"'
    dprint,  'Stackplot program was aborted.'
    return
  endif
;________________________________________________________________________________________________
;this section is in place to make sure that we are only looking at data in the time range specified,
;previously loaded gmag data from different time range is ignored
;also use this loop to despike the data
;________________________________________________________________________________________________
  stations = ['filler']
  for i = 0, n_elements(tplotvars)-1 do begin
    get_data, tplotvars[i], data = dd
    index_time = where(dd.x ge start_time and dd.x le end_time)
    if index_time[0] ne -1 then begin
      stations = [stations, strmid(tplotvars[i], 8, 4)]
;      bad_flag0 = dydt_spike_test(dd.x, dd.y[*, 0], dydt_lim = 100.0, $
;                                  degap_dt = 1.0, degap_margin = 1.0)
;      bad_flag1 = dydt_spike_test(dd.x, dd.y[*, 1], dydt_lim = 100.0, $
;                                  degap_dt = 1.0, degap_margin = 1.0)
;      bad_flag2 = dydt_spike_test(dd.x, dd.y[*, 2], dydt_lim = 100.0, $
;                                  degap_dt = 1.0, degap_margin = 1.0)
;      bad = where(bad_flag0+bad_flag1+bad_flag2 Gt 0, nbad)
;      if(nbad gt 0) then begin
;        dd.y[bad, *] = !values.f_nan
;        store_data, tplotvars[i], data = dd
;      endif
    endif
  endfor
  stations = stations[1:*]
;________________________________________________________________________________________________
;sort stations by longitude
;________________________________________________________________________________________________
  lats = fltarr(n_elements(stations))
  lons = fltarr(n_elements(stations))
  nstations = n_elements(stations)
  for i = 0, nstations-1 do begin
    get_data, 'thg_mag_'+stations[i], dlimits = dl
    lats[i] = float(dl.cdf.vatt.station_latitude)
    lons[i] = float(dl.cdf.vatt.station_longitude)
  endfor
  lat_index = reverse(sort(lats))
  stations = stations[lat_index]
;________________________________________________________________________________________________
;manipulate data into tplot variables for "relative" stack plots
;________________________________________________________________________________________________
  if not keyword_set(stack_shift) then set_default_shift = 1 $
  else set_default_shift = 0
  If(keyword_set(n_per_page)) Then npp = n_per_page $
  Else npp = 3
  nx = ceil(nstations/float(npp)) ;this will be the number of plots
  stations0 = stations          ;hold full array here
  for w = 0, nx-1 do begin
    wch = strcompress(/remove_all, string(w))
    x0 = w*npp
    x1 = (x0+npp-1) < (nstations-1)
    stations = stations0[x0:x1]
;create tplot variables of components
    num_elements = n_elements(stations)
    h_axis_range = dblarr(2)
    d_axis_range = dblarr(2)
    z_axis_range = dblarr(2)
    if set_default_shift eq 1 then stack_shift = 500.
    if keyword_set(max_deviation) then begin ;changed the clipping parameters, 9-oct-2007, jmm
      if(n_elements(max_deviation) Eq 1) then begin
        max_dev = [-max_deviation, max_deviation]
      endif else max_dev = max_deviation
    endif else max_dev = [-1500., 1500.]
    max_dev = [min(max_dev), max(max_dev)]
    for i = 0, num_elements-1 do begin
      get_data, 'thg_mag_'+stations[i], data = dd
      index_time = where(dd.x ge start_time and dd.x le end_time)
      themedian = strcompress(string(median(dd.y(index_time, 0), /even), format = '(f10.1)'), /remove_all)
      hdata = dd.y(index_time, 0)-median(dd.y(index_time, 0), /even)
      xclip, max_dev[0], max_dev[1], hdata, /clip_adjacent
      hdata = hdata+stack_shift*i
      store_data, 'thg_mag_'+stations[i]+'_h_rel_0', data = {x:dd.x(index_time), y:hdata}, $
        limits = {labels:[strupcase(stations[i])+'='+string(themedian)]}
      clean_spikes, 'thg_mag_'+stations[i]+'_h_rel_0', new_name = 'thg_mag_'+stations[i]+'_h_rel', thresh = 3.0, nsmooth = 601
      store_data, 'thg_mag_'+stations[i]+'_h_rel_0', /delete
      themedian = strcompress(string(median(dd.y(index_time, 1), /even), format = '(f10.1)'), /remove_all)
      ddata = dd.y(index_time, 1)-median(dd.y(index_time, 1), /even)
      xclip, max_dev[0], max_dev[1], ddata, /clip_adjacent
      ddata = ddata+stack_shift*i
      store_data, 'thg_mag_'+stations[i]+'_d_rel_0', data = {x:dd.x(index_time), y:ddata}, $
        limits = {labels:[strupcase(stations[i])+'='+string(themedian)]}
      clean_spikes, 'thg_mag_'+stations[i]+'_d_rel_0', new_name = 'thg_mag_'+stations[i]+'_d_rel', thresh = 3.0, nsmooth = 601
      store_data, 'thg_mag_'+stations[i]+'_d_rel_0', /delete
      themedian = strcompress(string(median(dd.y(index_time, 2), /even), format = '(f10.1)'), /remove_all)
      zdata = dd.y(index_time, 2)-median(dd.y(index_time, 2), /even)
      xclip, max_dev[0], max_dev[1], zdata, /clip_adjacent
      zdata = zdata+stack_shift*i
      store_data, 'thg_mag_'+stations[i]+'_z_rel_0', data = {x:dd.x(index_time), y:zdata}, $
        limits = {labels:[strupcase(stations[i])+'='+string(themedian)]}
      clean_spikes, 'thg_mag_'+stations[i]+'_z_rel_0', new_name = 'thg_mag_'+stations[i]+'_z_rel', thresh = 3.0, nsmooth = 601
      store_data, 'thg_mag_'+stations[i]+'_z_rel_0', /delete
      if max(hdata) gt h_axis_range[1] then h_axis_range[1] = max(hdata)
      if max(ddata) gt d_axis_range[1] then d_axis_range[1] = max(ddata)
      if max(zdata) gt z_axis_range[1] then z_axis_range[1] = max(zdata)
      if min(hdata) lt h_axis_range[0] then h_axis_range[0] = min(hdata)
      if min(ddata) lt d_axis_range[0] then d_axis_range[0] = min(ddata)
      if min(zdata) lt z_axis_range[0] then z_axis_range[0] = min(zdata)
    endfor
;________________________________________________________________________________________________
;create buffer tplot variables
;the purpose of these buffers is to 'trick' the plot routines into formatting the stackplots
;the way we want, it can be more reliable (as in doing what we want rather than what we tell it)
;than explicitly setting the plot format
;it also allows for the easy placement of the 'Median (nT)' label
;________________________________________________________________________________________________
    bth = dd.y(index_time, 0)
    bbh = dd.y(index_time, 0)
    btd = dd.y(index_time, 1)
    bbd = dd.y(index_time, 1)
    btz = dd.y(index_time, 2)
    bbz = dd.y(index_time, 2)
    bth[*] = h_axis_range[1]+stack_shift
    bbh[*] = h_axis_range[0]-stack_shift
    btd[*] = d_axis_range[1]+stack_shift
    bbd[*] = d_axis_range[0]-stack_shift
    btz[*] = z_axis_range[1]+stack_shift
    bbz[*] = z_axis_range[0]-stack_shift
    store_data, 'BUFFER_TOP_H', data = {x:dd.x(index_time), y:bth}
    store_data, 'BUFFER_BOT_H', data = {x:dd.x(index_time), y:bbh}
    store_data, 'BUFFER_TOP_D', data = {x:dd.x(index_time), y:btd}
    store_data, 'BUFFER_BOT_D', data = {x:dd.x(index_time), y:bbd}
    store_data, 'BUFFER_TOP_Z', data = {x:dd.x(index_time), y:btz}
    store_data, 'BUFFER_BOT_Z', data = {x:dd.x(index_time), y:bbz}
    options, 'BUFFER_TOP_H', 'ytitle', ''
    options, 'BUFFER_BOT_H', 'ytitle', ''
    options, 'BUFFER_TOP_D', 'ytitle', ''
    options, 'BUFFER_BOT_D', 'ytitle', ''
    options, 'BUFFER_TOP_Z', 'ytitle', ''
    options, 'BUFFER_BOT_Z', 'ytitle', ''
    options, 'BUFFER_TOP_H', 'labels', ['Median (nT)']
    options, 'BUFFER_TOP_D', 'labels', ['Median (nT)']
    options, 'BUFFER_TOP_Z', 'labels', ['Median (nT)']
;________________________________________________________________________________________________
;Set various plotting options
;________________________________________________________________________________________________
    tplotvars_h = ['filler']
    tplotvars_d = ['filler']
    tplotvars_z = ['filler']
    for i = 0, n_elements(stations)-1 do begin
      tplotvars_h = [tplotvars_h, tnames('thg_mag_'+stations[i]+'_h_rel')]
      tplotvars_d = [tplotvars_d, tnames('thg_mag_'+stations[i]+'_d_rel')]
      tplotvars_z = [tplotvars_z, tnames('thg_mag_'+stations[i]+'_z_rel')]
    endfor
    store_data, 'BH', data = [tplotvars_h(1:*), 'BUFFER_TOP_H', 'BUFFER_BOT_H']
    store_data, 'BD', data = [tplotvars_d(1:*), 'BUFFER_TOP_D', 'BUFFER_BOT_D']
    store_data, 'BZ', data = [tplotvars_z(1:*), 'BUFFER_TOP_Z', 'BUFFER_BOT_Z']
    options, 'BH', 'ytickformat', '(a1)' ; this gets rid of the y-axis numbering
    options, 'BD', 'ytickformat', '(a1)' ; this gets rid of the y-axis numbering
    options, 'BZ', 'ytickformat', '(a1)' ; this gets rid of the y-axis numbering
    num_hticks = (h_axis_range[1]+stack_shift)/100. - (h_axis_range[0]-stack_shift)/100.
    h_factor = (byte(num_hticks/30.)+1)
    num_hticks = byte(num_hticks/h_factor)-1
    num_dticks = (d_axis_range[1]+stack_shift)/100. - (d_axis_range[0]-stack_shift)/100.
    d_factor = (byte(num_dticks/30.)+1)
    num_dticks = byte(num_dticks/d_factor)-1
    num_zticks = (z_axis_range[1]+stack_shift)/100. - (z_axis_range[0]-stack_shift)/100.
    z_factor = (byte(num_zticks/30.)+1)
    num_zticks = byte(num_zticks/z_factor)-1
    options, 'BH', 'yticks', num_hticks
    options, 'BD', 'yticks', num_dticks
    options, 'BZ', 'yticks', num_zticks
    hy_pos_ticks = findgen(byte( (h_axis_range[1]+stack_shift)/(100.*h_factor) +1.))*100.*h_factor
    dy_pos_ticks = findgen(byte( (d_axis_range[1]+stack_shift)/(100.*d_factor) +1.))*100.*d_factor
    zy_pos_ticks = findgen(byte( (z_axis_range[1]+stack_shift)/(100.*z_factor) +1.))*100.*z_factor
    hy_neg_ticks = -100.*h_factor*reverse(findgen(byte( abs(h_axis_range[0]-stack_shift)/(100.*h_factor) +1.)))
    dy_neg_ticks = -100.*d_factor*reverse(findgen(byte( abs(d_axis_range[0]-stack_shift)/(100.*d_factor) +1.)))
    zy_neg_ticks = -100.*z_factor*reverse(findgen(byte( abs(z_axis_range[0]-stack_shift)/(100.*z_factor) +1.)))
    if n_elements(hy_pos_ticks) gt 1 then hy_tickvalues = [hy_neg_ticks, hy_pos_ticks(1:*)] else hy_tickvalues = [hy_neg_ticks]
    if n_elements(dy_pos_ticks) gt 1 then dy_tickvalues = [dy_neg_ticks, dy_pos_ticks(1:*)] else dy_tickvalues = [dy_neg_ticks]
    if n_elements(zy_pos_ticks) gt 1 then zy_tickvalues = [zy_neg_ticks, zy_pos_ticks(1:*)] else zy_tickvalues = [zy_neg_ticks]
    options, 'BH', 'ytickv', hy_tickvalues
    options, 'BD', 'ytickv', dy_tickvalues
    options, 'BZ', 'ytickv', zy_tickvalues
    options, 'BH', 'yminor', 10
    options, 'BD', 'yminor', 10
    options, 'BZ', 'yminor', 10
    options, 'BH', 'ytitle', 'Scale='+strcompress(string(100*h_factor, format = '(f10.0)'))+$
      'nT/major, '+strcompress(string(10*h_factor, format = '(f10.0)'))+'nT/minor tickmark'
    options, 'BD', 'ytitle', 'Scale='+strcompress(string(100*d_factor, format = '(f10.0)'))+$
      'nT/major, '+strcompress(string(10*d_factor, format = '(f10.0)'))+'nT/minor tickmark'
    options, 'BZ', 'ytitle', 'Scale='+strcompress(string(100*z_factor, format = '(f10.0)'))+$
      'nT/major, '+strcompress(string(10*z_factor, format = '(f10.0)'))+'nT/minor tickmark'
;________________________________________________________________________________________________
;make plots
;________________________________________________________________________________________________
    original_device = !d.name   ;save to reset
    p_multi = !p.multi
    If keyword_set(make_png) Then Begin
      set_plot, 'z'
      device, set_resolution = [800, 800]
    Endif Else Begin
      osf = strupcase(!version.os_family)
      If(osf Eq 'WINDOWS') Then set_plot, 'win' Else set_plot, 'x'
      screen_size = get_screen_size()
      xss = screen_size/3.0
      xss = 100.0*fix(xss[0]/100)
      window, 0, xsize = xss, ysize = 600, xpos = 0, ypos = 0
      window, 1, xsize = xss, ysize = 600, xpos = xss+10, ypos = 0
      window, 2, xsize = xss, ysize = 600, xpos = 2*xss+20, ypos = 0
    Endelse
    tplot_options, 'region', [0.00, 0.00, 0.95, 1.]
    !p.color = 0
    !p.background = 255
    !p.charsize = 1.0
    time_stamp, /off
    date_compress = strcompress(strmid(date, 0, 4)+strmid(date, 5, 2)+strmid(date, 8, 2), /remove_all)
    timespan, date, duration
;--------------------------
    if(keyword_set(plot_dir)) then pdir = plot_dir else pdir = './'
    thetitle = 'H Component, Sample: '+wch
    get_data, 'BH', data = xxx
    dprint,  'PLOTTING:', xxx[0:n_elements(xxx)-3]
    if keyword_set(make_png) then begin
      tplot, 'BH', title = thetitle
      makepng, pdir+'thg_l2_mag_alt_'+string(date_compress)+'_'+wch, /no_expose
    endif else begin
      tplot, 'BH', title = thetitle, window = 0
    endelse
    thetitle = 'D Component, Sample: '+wch
    get_data, 'BD', data = xxx
    dprint,  'PLOTTING:', xxx[0:n_elements(xxx)-3]
    if keyword_set(make_png) then begin
      tplot, 'BD', title = thetitle
      makepng, pdir+'thg_l2_mag_alt_'+string(date_compress)+'_'+wch, /no_expose
    endif else begin
      tplot, 'BD', title = thetitle, window = 1
    endelse
    thetitle = 'Z Component, Sample: '+wch
    get_data, 'BZ', data = xxx
    dprint,  'PLOTTING:', xxx[0:n_elements(xxx)-3]
    if keyword_set(make_png) then begin
      tplot, 'BZ', title = thetitle
      makepng, pdir+'thg_l2_mag_zhla_'+string(date_compress)+'_'+wch, /no_expose
    endif else begin
      tplot, 'BZ', title = thetitle, window = 2
    endelse
    wshow, 0 & wshow, 1 & wshow, 2
    dprint,  'Hit Enter to Continue:'
    xxx = strarr(1)
    read, xxx
  endfor                        ; w
  set_plot, original_device

end

