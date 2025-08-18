;+
;PROCEDURE:   swe_make_hires
;PURPOSE:
;  Loads L0 data containing hires SWEA data (LUT = 7,8,9) and 32-Hz MAG data,
;  creates hires PAD and SPEC data, and makes tplot variables with merged hires
;  and normal resolution data.  SWEA and tplot save files are created.
;
;USAGE:
;  swe_make_hires, date
;
;INPUTS:
;       date:      Date to process, in any format accepted by time_double().
;                  Only the date (YYYY-MM-DD) is used; HH:MM:SS are ignored.
;
;KEYWORDS:
;       TPLOT:     If set, create a time series plot of the data.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-06-23 10:37:01 -0700 (Mon, 23 Jun 2025) $
; $LastChangedRevision: 33409 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_make_hires.pro $
;
;CREATED BY:    David L. Mitchell
;FILE: swe_make_hires.pro
;-
pro swe_make_hires, date, tplot=tplot

; Generate filenames based on date

  if (size(date,/type) eq 0) then begin
    print,"You must supply a date."
    return
  endif

  t0 = systime(/utc,/sec)

  date = time_string(time_double(date), prec=-3)

  yyyymmdd = strmid(date,0,4) + strmid(date,5,2) + strmid(date,8,2)
  path = root_data_dir() + 'maven/data/sci/swe/l3/hires/'
  fname = path + 'swe_hires_' + yyyymmdd

; Load 32-Hz MAG data

  timespan, date
  mvn_mag_load, 'L2_FULL', sclk=sclk  ; get kernel used to produce MAG data
  get_data,'mvn_B_full',alim=lim
  maglev = strupcase(lim.level)
  mvn_swe_spice_init, sclk=sclk       ; same kernel used to produce MAG data
  maven_orbit_tplot, /load
  eph = maven_orbit_eph()
  mvn_mag_geom, var='mvn_B_full'
  mvn_mag_tplot, 'mvn_B_full_maven_mso'
  options,'mvn_mag_l1_bamp','ytitle','|B| (nT)!c' + maglev
  options,'mvn_mag_l1_bamp','ysubtitle',''
  options,'mvn_B_full_maven_mso','ytitle','B (nT)!c' + maglev + ' MSO'
  options,'mvn_B_full_maven_mso','ysubtitle',''

; Load SWEA data

  mvn_swe_load_l0
  mvn_swe_getlut, /flux, /tplot
  get_data, 'TABNUM', data=tab  ; table number vs time
  indx = where(tab.y gt 6, count)
  if (count eq 0L) then begin
    print,"No hires data.  Nothing to do."
    return
  endif
  mvn_swe_makespec, lut=tab.y
  mvn_swe_sumplot, /lut, /loadonly
  mvn_scpot, /loadonly
  mvn_attitude_bar

; Load SWIA data and estimate error bars

  mvn_swe_addswi
  get_data, 'mvn_swics_en_counts', data=swicnt, index=i
  if (i gt 0) then begin
    rerr = (1./sqrt(swicnt.y)) > 0.01  ; digitization noise limits rerr
    get_data, 'mvn_swics_en_eflux', data=swiflx
    str_element, swiflx, 'dy', rerr*swiflx.y, /add
    store_data, 'mvn_swics_en_eflux', data=swiflx
    undefine, swicnt, swiflx, rerr
  endif else print,"Variable not found:  mvn_swics_en_counts"
  ylim,'mvn_swics_en_eflux',25,25000,1
  options, 'mvn_swics_en_eflux', 'ztitle', 'EFLUX'

; Get high resolution PAD data and make tplot variables
;   This step takes time because of the pitch angle sorting and resampling

  mvn_swe_makefpad, pans=padpans, /tplot, merge=1

; Get high resolution SPEC data
;   ** Note: SPEC data are recorded in high resolution mode.  For each energy
;      step (0.03 sec) the deflectors sweep up and down, but the energy stays
;      the same for subsequent steps.  Thus, a full SPEC at one energy is 
;      generated every 0.03 sec (64 times per measurement cycle).  The normal
;      units conversion will not work for these data, since it assumes the 
;      normal energy sweep and variation of the calibration with energy.  So,
;      we have to start with units of CRATE and convert to EFLUX manually.

  mvn_swe_makespec, units='crate', lut=tab.y, /tplot

  j = (where(tab.y eq 5))[0]
  spec = mvn_swe_getspec(tab.x[j], units='crate')  ; first normal SPEC

  mvn_swe_convert_units, spec, 'eflux', scale=scale
  i = nn2(spec.energy, 50)
  scale_50 = scale[i]  ; CRATE -> EFLUX at 50 eV
  i = nn2(spec.energy, 125)
  scale_125 = scale[i] ; CRATE -> EFLUX at 125 eV
  i = nn2(spec.energy, 200)
  scale_200 = scale[i] ; CRATE -> EFLUX at 200 eV
  spec = 0

  swe_engy_timing, /cal
  get_data,'edat_svy',data=dat                               ; hires SPEC timing
  lut = reform(replicate(1B,64) # tab.y, n_elements(dat.x))  ; expand LUT to hires sampling

  indx = where(lut eq 7B, count7)
  if (count7 gt 0L) then begin
    store_data,'flux_200',data={x:dat.x[indx], y:dat.y[indx]*scale_200, dy:dat.dy[indx]*scale_200}
    indx = where((lut eq 7B) and (dat.y gt 0.))
    yrange = minmax(dat.y[indx])
    ymin = 10.^floor(alog10(yrange[0]))
    ymax = 10.^ceil(alog10(yrange[1]))
    ylim,'flux_200',ymin,ymax,1
    units = 'EFLUX'
    options,'flux_200','ytitle',units + '!c200 eV'
    options,'flux_200','datagap',1D
    options,'flux_200','psym',0
  endif

  indx = where(lut eq 8B, count8)
  if (count8 gt 0L) then begin
    store_data,'flux_50',data={x:dat.x[indx], y:dat.y[indx]*scale_50, dy:dat.dy[indx]*scale_50}
    indx = where((lut eq 8B) and (dat.y gt 0.))
    yrange = minmax(dat.y[indx])
    ymin = 10.^floor(alog10(yrange[0]))
    ymax = 10.^ceil(alog10(yrange[1]))
    ylim,'flux_50',ymin,ymax,1
    units = 'EFLUX'
    options,'flux_50','ytitle',units + '!c50 eV'
    options,'flux_50','datagap',1D
    options,'flux_50','psym',0
  endif

  indx = where(lut eq 9B, count9)
  if (count9 gt 0L) then begin
    store_data,'flux_125',data={x:dat.x[indx], y:dat.y[indx]*scale_125, dy:dat.dy[indx]*scale_125}
    indx = where((lut eq 9B) and (dat.y gt 0.))
    yrange = minmax(dat.y[indx])
    ymin = 10.^floor(alog10(yrange[0]))
    ymax = 10.^ceil(alog10(yrange[1]))
    ylim,'flux_50',ymin,ymax,1
    units = 'EFLUX'
    options,'flux_125','ytitle',units + '!c125 eV'
    options,'flux_125','datagap',1D
    options,'flux_125','psym',0
  endif

; Merge high and normal resolution SPEC data (now with EFLUX units)

  mvn_swe_makespec, units='eflux', lut=tab.y, /tplot

  get_data,'swe_a4',data=dat
  indx = where(tab.y ne 5)
  dat.y[indx,*] = !values.f_nan
  dat.dy[indx,*] = !values.f_nan
  store_data,'swe_a4',data=dat
  padpans = ['']
  morepadpans = padpans

  if (count7 gt 0L) then begin
    de = min(abs(dat.v - 200.),j)
    indx = where(dat.y[*,j] le 0., count)
    if (count gt 0L) then dat.y[indx,j] = !values.f_nan
    store_data,'flux_200n',data={x:dat.x, y:dat.y[*,j], dy:dat.dy[*,j]}
    options,'flux_200n','psym',4

    store_data,'flux_200a',data=['flux_200','flux_200n']
    ylim,'flux_200a',3e4,3e7,1

    padpans = [padpans, 'swe_pad_resample_200eV_merge', 'flux_200a']
    morepadpans = [morepadpans, 'flux_200', 'flux_200n']
  endif

  if (count8 gt 0L) then begin
    de = min(abs(dat.v - 50.),j)
    indx = where(dat.y[*,j] le 0., count)
    if (count gt 0L) then dat.y[indx,j] = !values.f_nan
    store_data,'flux_50n',data={x:dat.x, y:dat.y[*,j], dy:dat.dy[*,j]}
    options,'flux_50n','psym',4

    store_data,'flux_50a',data=['flux_50','flux_50n']
    ylim,'flux_50a',3e5,3e8,1

    padpans = [padpans, 'swe_pad_resample_50eV_merge', 'flux_50a']
    morepadpans = [morepadpans, 'flux_50', 'flux_50n']
  endif

  if (count9 gt 0L) then begin
    de = min(abs(dat.v - 125.),j)
    indx = where(dat.y[*,j] le 0., count)
    if (count gt 0L) then dat.y[indx,j] = !values.f_nan
    store_data,'flux_125n',data={x:dat.x, y:dat.y[*,j], dy:dat.dy[*,j]}
    options,'flux_125n','psym',4

    store_data,'flux_125a',data=['flux_125','flux_125n']
    ylim,'flux_125a',3e5,3e8,1

    padpans = [padpans, 'swe_pad_resample_125eV_merge', 'flux_125a']
    morepadpans = [morepadpans, 'flux_125', 'flux_125n']
  endif

  padpans = padpans[1:*]
  morepadpans = morepadpans[1:*]

; Plot the data

  if keyword_set(tplot) then begin
    device, window_state=wstate
    tplot_options, get=topt
    str_element, topt, 'window', Twin, success=ok
    if (not ok) then if (!d.window ge 0) then Twin = !d.window else Twin = 0
    if (wstate[Twin]) then wset,Twin else win,Twin,/f

    pans = ['mvn_swics_en_eflux','mvn_mag_l1_bamp','mvn_B_full_maven_mso','mvn_sun_bar',$
           'mvn_att_bar','swe_a3_bar',padpans,'TABNUM','swe_a4']
    tplot, pans
  endif

; Make save files

  mvn_swe_save, filename=(fname + '.sav')

  allpans = ['mvn_swics_en_eflux','mvn_mag_l1_bamp','mvn_B_full_maven_mso',$
             'mvn_sun_bar','mvn_att_bar','swe_a3_bar',padpans,morepadpans,'TABNUM','swe_a4','swe_quality']

  tplot_save, allpans, file=fname

  t1 = systime(/utc,/sec)
  print, (t1 - t0)/60D, format='(/"Time to process: ",f5.2," min",/)'

end
