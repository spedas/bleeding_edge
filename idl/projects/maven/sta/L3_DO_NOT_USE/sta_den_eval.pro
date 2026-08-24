;+
;Evaluate if there's a clear difference between STATIC densities derived using nb_4d and n_4d. Make some stat plots
;as functions of sc pot, etc, and compare with eg LPW Ne.
;
;Things to consider:
;Vsc
;Ion energy - pick up vs cold
;FOV flag
;Ion mass?
;Absolute Ni / Ne? Can we use this to find the fraction of protons? Will prob need to include NGIMS?
;
;Top routine - load in data.
;
;date: 'yyyy-mm-dd' string, date to load.
;
;Set /load to load L2 data. Otherwise routine assumes data are already loaded.
;
;Cold ion outflow data available: '2017-12-14', '2017-12-28'
;
;
;EGS:
;sta_den_eval_1, '2017-12-16'
;
;.r /Users/cmfowler/IDL/STATIC_routines/Density_routines/sta_den_eval.pro
;-
;

pro sta_den_eval_1, date, load=load

saveDIR1 = '/Users/cmfowler/IDL/STATIC_routines/Density_routines/SaveFiles/DenEval/'

get_data, 'mvn_sta_c6_E', data=ddc6
if size(ddc6,/type) ne 8 and not keyword_set(load) then begin
  print, ""
  print, "Warning: STATIC data not found in tplot. Do you need to set /load?"
  return
endif

if keyword_set(load) then begin
  timespan, date, 1.
  
  mvn_sta_l2_load, sta_apid=['c6']  ;make tplot vars for just c6
  mvn_sta_l2_tplot
  
  mvn_sta_l2_load, sta_apid=['d1', 'c8', 'ca']
  
  mvn_lpw_load_l2, ['lpnt'], /notplot
endif

get_data, 'mvn_sta_c6_E', data=ddc6

;tr = [1513424280.0000000d, 1513436400.0000000d]   ;user set time range (for testing)
tr = [min(ddc6.x, /nan), max(ddc6.x, /nan)]  ;full time range

;Get FOV flag:
mvn_sta_fov_snap, trange=tr, mrange=[0.5, 1.5], sta_apid='d1'
mvn_sta_fov_snap, trange=tr, mrange=[12., 20.], sta_apid='d1'
mvn_sta_fov_snap, trange=tr, mrange=[28., 36.], sta_apid='d1'
mvn_sta_fov_snap, trange=tr, mrange=[40., 48.], sta_apid='d1'

static_density_crib, trange=tr  ;gets densities for all species.

;PAIR WITH OTHER DATA:
;Pair the following to the density values for n_4d and nb_4d (these two should be at the same time cadence as they both
;use c6 data): ne, ni tot, vsc, fov for each mass, altitude, position, sza

;STATIC DATA:
get_data, 'mvn_sta_h+_c6_density2', data=dd_den_h
get_data, 'mvn_sta_h+_c6_density2_4d', data=dd_den_h_4d

get_data, 'mvn_sta_o+_c6_density2', data=dd_den_o
get_data, 'mvn_sta_o+_c6_density2_4d', data=dd_den_o_4d

get_data, 'mvn_sta_o2+_c6_density2', data=dd_den_o2
get_data, 'mvn_sta_o2+_c6_density2_4d', data=dd_den_o2_4d

get_data, 'mvn_sta_co2+_c6_density2', data=dd_den_co2
get_data, 'mvn_sta_co2+_c6_density2_4d', data=dd_den_co2_4d

get_data, 'diff_h+', data=dd_diff_h
get_data, 'diff_o+', data=dd_diff_o
get_data, 'diff_o2+', data=dd_diff_o2
get_data, 'diff_co2+', data=dd_diff_co2

get_data, 'mvn_sta_c6_density_total', data=dd_sta_tot
get_data, 'mvn_sta_c6_density_total_4d', data=dd_sta_tot_4d

;Get STATIC sc pot:
common mvn_c6, get_ind_c6, all_dat_c6   
midtimes = all_dat_c6.time+2.d  ;to search for data in tplot, need to use mid times of each point (CMF has checked this)
tr_c6 = [min(dd_den_h.x,/nan)-1.d, max(dd_den_h.x,/nan)+1.d]  ;min and max of actual times used
iKP = where(midtimes ge tr_c6[0] and midtimes le tr_c6[1], niKP)
if niKP eq 0. then stop  ;this shouldn't happen
scpotpaired = all_dat_c6.sc_pot[iKP]

;$$$ add other masses once working

;LPW:
get_data, 'mvn_lpw_lp_ne_l2', data=ddne
get_data, 'mvn_lpw_lp_vsc_l2', data=ddvsc
boomnum = floor(ddne.info/10.)  ;boom number
iboom = where(boomnum eq 1., niboom)

;EPHEMERIS:
mvn_lpw_anc_get_spice_kernels, dd_den_h.x, /notatlasp
mvn_lpw_anc_spacecraft, dd_den_h.x, /basic
mvn_lpw_anc_clear_spice_kernels

get_data, 'mvn_lpw_anc_mvn_alt_iau', data=ddalt
get_data, 'mvn_lpw_anc_mvn_pos_mso', data=ddpos

;PAIRING:
if niboom gt 10 then begin  ;LPW
    nepaired = pair_in_time(dd_den_h.x, ddne.x[iboom], ddne.y[iboom], maxT=10., /nan)
    vscpaired = pair_in_time(dd_den_h.x, ddvsc.x[iboom], ddvsc.y[iboom], maxT=10., /nan)
endif

;EPHEMERIS:
altpaired = pair_in_time(dd_den_h.x, ddalt.x, ddalt.y, maxT=10., /nan)
pospaired = pair_in_time(dd_den_h.x, ddpos.x, ddpos.y, maxT=10., /nan)
szapaired = make_sza(pospaired.dataout[*,0], pospaired.dataout[*,1], pospaired.dataout[*,2], /negY)

;FOV:
get_data, 'mvn_sta_FOV_flag_mr(0.5,1.5)_er(0.0,1000000.0)', data=ddfov_h
get_data, 'mvn_sta_FOV_flag_mr(12.0,20.0)_er(0.0,1000000.0)', data=ddfov_o
get_data, 'mvn_sta_FOV_flag_mr(28.0,36.0)_er(0.0,1000000.0)', data=ddfov_o2
get_data, 'mvn_sta_FOV_flag_mr(40.0,48.0)_er(0.0,1000000.0)', data=ddfov_co2

fovhpaired = pair_in_time(dd_den_h.x, ddfov_h.x, ddfov_h.y, maxT=10., /nan)
fovopaired = pair_in_time(dd_den_h.x, ddfov_o.x, ddfov_o.y, maxT=10., /nan)  ;can use same timesteps, dd_den_h here
fovo2paired = pair_in_time(dd_den_h.x, ddfov_o2.x, ddfov_o2.y, maxT=10., /nan)
fovco2paired = pair_in_time(dd_den_h.x, ddfov_co2.x, ddfov_co2.y, maxT=10., /nan)

;Compile into a file for saving:
DenData = create_struct('time'        ,         dd_den_h.x      , $
                        'den_h'       ,         dd_den_h.y      , $
                        'den_h_4d'    ,         dd_den_h_4d.y   , $
                        'den_o'       ,         dd_den_o.y      , $
                        'den_o_4d'    ,         dd_den_o_4d.y   , $
                        'den_o2'      ,         dd_den_o2.y      , $
                        'den_o2_4d'   ,         dd_den_o2_4d.y   , $
                        'den_co2'     ,         dd_den_co2.y     , $
                        'den_co2_4d'  ,         dd_den_co2_4d.y  , $
                        'diff_h'      ,         dd_diff_h.y        , $
                        'diff_o'      ,         dd_diff_o.y        , $
                        'diff_o2'     ,         dd_diff_o2.y       , $
                        'diff_co2'    ,         dd_diff_co2.y      , $
                        'sta_tot'     ,         dd_sta_tot.y       , $
                        'sta_tot_4d'  ,         dd_sta_tot_4d.y    , $
                        'FOV_h'       ,         fovhpaired.dataout  , $
                        'FOV_o'       ,         fovopaired.dataout  , $
                        'FOV_o2'      ,         fovo2paired.dataout  , $
                        'FOV_co2'     ,         fovco2paired.dataout , $
                        'alt'         ,         altpaired.dataout   , $
                        'pos'         ,         pospaired.dataout   , $
                        'sza'         ,         szapaired           , $
                        'ne_LPW'      ,         nepaired.dataout    , $
                        'vsc_LPW'     ,         vscpaired.dataout   , $
                        'vsc_STA'     ,         scpotpaired)

fn = 'STA_den_eval_'+date+'.sav'
save, DenData, filename=saveDIR1+fn
checkfilesave, saveDIR1+fn
stop

end

;==========
;==========

;+
;Start doing some analysis once data loaded.
;
;Things to consider:
;Vsc
;Ion energy - pick up vs cold
;FOV flag
;Ion mass?
;Absolute Ni / Ne? Can we use this to find the fraction of protons? Will prob need to include NGIMS?
;Day vs night side
;
;
;THOUGHTS:
;Hoe determine that STATIC is the correct density and at which altitude transition? 
; - Look at case study orbits comparing to LPW.
;
;To add as keywords:
;
;
;Save figs, for each set of keywords.
;
;KEYWORDS:
;Set /oneplot, etc, to make each plot. If not set, those plots aren't made, to speed up and keep tidy.
;
;Set /fov to only use data points that have a STA FOV flag of 0,1,2 (ignoring 3, where beam is likely at edge of FOV).
;
;minscp: min sc pot to use. Default is -25. if not set.
;maxscp: max sc pot to use. DEfault is +25. if not set.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Density_routines/sta_den_eval.pro
;-

pro sta_den_eval_2, oneplot=oneplot, twoplot=twoplot, threeplot=threeplot, fourplot=fourplot, fov=fov, minscp=minscp, maxscp=maxscp

@'qualcolors'

loadDIR1 = '/Users/cmfowler/IDL/STATIC_routines/Density_routines/SaveFiles/DenEval/'

if keyword_set(fov) then begin
    fovnum = 2
    fovstr = ', FOV'
endif else begin
    fovnum = 3
    fovstr = ''
endelse

if size(minscp,/type) eq 0 then minscp=-25.
if size(maxscp,/type) eq 0 then maxscp=25.
scpotSTR = ', '+strtrim(fix(minscp),2)+' < scpot [V]< '+strtrim(fix(maxscp),2)


file = file_search(loadDIR1+'STA_den_eval_*.sav', count=nfile)   ;$%$%$%$$% edit this once I have multiple files

if nfile eq 0 then begin
  print, ""
  print, "I didn't find any files to load."
  return
endif

restore, filename=file[0]

;=======
;ONE: H+
if keyword_set(oneplot) then begin
    ;Plot % diff vs altitude. % diff is 4d / nbc. Typically, nbc is greater at lower altitudes <~500 km, and 4d is greater above this.
    ;window, 10, xsize=600, ysize=800
    posT = [0.13, 0.55, 0.87, 0.95]
    posB = [0.13, 0.1, 0.87, 0.45]
    posCB1 = [0.95, 0.6, 0.975, 0.9]
    posCB2 = [0.95, 0.1, 0.975, 0.4]
    
    fs=1.7
    fs2=12.  ;plot functions
    
    ;plot, DenData.diff_h, DenData.alt, psym=3, charsize=fs, ytitle='Alt [km]', position=posT, yrange=[0, 7000], $
    ;        ysty=1
    ;plot, DenData.diff_h, DenData.alt, psym=3, charsize=fs, xtitle='H % diff (4d/nbc)', ytitle='Alt [km]', position=posB, yrange=[100., 1000.], ysty=1, /noerase
        
    ;Get indices for FOV flag:
    iKP = where(DenData.FOV_H le fovnum and DenData.vsc_STA ge minscp and DenData.vsc_STA le maxscp, niKP) ;routine assumes there will alays be points found
    if niKP eq 0 then stop  ;shouldn't happen for long enough data set
    nptsSTR = strtrim(string(niKP, format='(F12.0)'),2)
    
    ;Bin data and plot number of points in each bin:
    binnedh = bin_shit_2d(xdel=5., ydel=100., xmin=-100., xmax=100., ymin=100., ymax=6500., success=success, xdata=DenData.diff_h[iKP], ydata=DenData.alt[iKP])
    
    binnedh_log = alog10(binnedh.counts)
    
    win10 = window(dimensions=[700,800])
    
    ;ALL ALTS:
    ptitle='% diff H+, 4d/nbc, npts: '+nptsSTR+FOVstr
    
    plot10h = image(binnedh_log, binnedh.xaxis, binnedh.yaxis, position=posT, font_style=1, title=ptitle, aspect_ratio=0.02, $
                xrange=[-100., 100.], yrange=[0., 6500.], xsty=1, rgb_table=39, current=win10)
    
    xtv = [-100, -50, 0, 50, 100]
    ytv = [100, 1000, 2000, 3000, 4000, 5000, 6000]
    
    x1 = axis('X', location='bottom', tickvalues=xtv, target=plot10h, tickfont_style=1, title='% diff H+ (4d/nbc)')
    x2 = axis('X', location='top', tickformat='(A1)', tickvalues=xtv, target=plot10h, tickfont_style=1)
    y1 = axis('Y', location='left', tickvalues=ytv, target=plot10h, tickfont_style=1, title='Altitude [km]')
    y2 = axis('Y', location='right', tickformat='(A1)', tickvalues=ytv, target=plot10h, tickfont_style=1)
    
    
    cb2 = colorbar(range=[min(binnedh_log,/nan), max(binnedh_log,/nan)], orientation=1, position=posCB1, major=5, $  ;tickvalues=tickvaluesp, target=pIM,
      title='Log number of points', rgb_table=39, font_style=1, font_size=12)
    
    ;ZOOM ALTS:
    ptitle='zoom, npts: '+nptsSTR+FOVstr+scpoSTR
    
    plot10h = image(binnedh_log, binnedh.xaxis, binnedh.yaxis, position=posB, font_style=1, title=ptitle, aspect_ratio=0.16, $  ;aspect ratio changed with zoom y range
      xrange=[-100., 100.], yrange=[100., 800.], xsty=1, rgb_table=39, current=win10)
    
    xtv = [-100, -50, 0, 50, 100]
    ytv = [100, 200, 300, 400, 500, 600, 700, 800]  ;$%$%$ hard coded
    
    x1 = axis('X', location='bottom', tickvalues=xtv, target=plot10h, tickfont_style=1, title='% diff H+ (4d/nbc)')
    x2 = axis('X', location='top', tickformat='(A1)', tickvalues=xtv, target=plot10h, tickfont_style=1)
    y1 = axis('Y', location='left', tickvalues=ytv, target=plot10h, tickfont_style=1, title='Altitude [km]')
    y2 = axis('Y', location='right', tickformat='(A1)', tickvalues=ytv, target=plot10h, tickfont_style=1)
    
    
    cb2 = colorbar(range=[min(binnedh_log,/nan), max(binnedh_log,/nan)], orientation=1, position=posCB2, major=5, $  ;tickvalues=tickvaluesp, target=pIM,
      title='Log number of points', rgb_table=39, font_style=1, font_size=12)

endif  ;oneplot: % diff H+ vs alt   

;=======
;TWO: O+
if keyword_set(twoplot) then begin
  ;Plot % diff vs altitude. % diff is 4d / nbc. Typically, nbc is greater at lower altitudes <~500 km, and 4d is greater above this.
  posT = [0.13, 0.55, 0.87, 0.95]
  posB = [0.13, 0.1, 0.87, 0.45]
  posCB1 = [0.95, 0.6, 0.975, 0.9]
  posCB2 = [0.95, 0.1, 0.975, 0.4]

  fs=1.7
  fs2=12.  ;plot functions
  
  ;Get indices for FOV flag:
  iKP = where(DenData.FOV_O le fovnum and DenData.vsc_STA ge minscp and DenData.vsc_STA le maxscp, niKP) ;routine assumes there will alays be points found
  if niKP eq 0 then stop  ;shouldn't happen for long enough data set
  nptsSTR = strtrim(string(niKP, format='(F12.0)'),2)

  ;Bin data and plot number of points in each bin:
  binnedo = bin_shit_2d(xdel=5., ydel=100., xmin=-100., xmax=100., ymin=100., ymax=6500., success=success, xdata=DenData.diff_o[iKP], ydata=DenData.alt[iKP])

  binnedo_log = alog10(binnedo.counts)

  win11 = window(dimensions=[700,800])

  ;ALL ALTS:
  ptitle='% diff O+, 4d/nbc, npts: '+nptsSTR+FOVstr

  plot10o = image(binnedo_log, binnedo.xaxis, binnedo.yaxis, position=posT, font_style=1, title=ptitle, aspect_ratio=0.02, $
    xrange=[-100., 100.], yrange=[0., 6500.], xsty=1, rgb_table=39, current=win11)

  xtv = [-100, -50, 0, 50, 100]
  ytv = [100, 1000, 2000, 3000, 4000, 5000, 6000]

  x1 = axis('X', location='bottom', tickvalues=xtv, target=plot10o, tickfont_style=1, title='% diff O+ (4d/nbc)')
  x2 = axis('X', location='top', tickformat='(A1)', tickvalues=xtv, target=plot10o, tickfont_style=1)
  y1 = axis('Y', location='left', tickvalues=ytv, target=plot10o, tickfont_style=1, title='Altitude [km]')
  y2 = axis('Y', location='right', tickformat='(A1)', tickvalues=ytv, target=plot10o, tickfont_style=1)


  cb2 = colorbar(range=[min(binnedo_log,/nan), max(binnedo_log,/nan)], orientation=1, position=posCB1, major=5, $  ;tickvalues=tickvaluesp, target=pIM,
    title='Log number of points', rgb_table=39, font_style=1, font_size=12)

  ;ZOOM ALTS:
  ptitle='zoom, npts: '+nptsSTR+FOVstr+scpotSTR

  plot10o = image(binnedo_log, binnedo.xaxis, binnedo.yaxis, position=posB, font_style=1, title=ptitle, aspect_ratio=0.16, $  ;aspect ratio changed with zoom y range
    xrange=[-100., 100.], yrange=[100., 800.], xsty=1, rgb_table=39, current=win11)

  xtv = [-100, -50, 0, 50, 100]
  ytv = [100, 200, 300, 400, 500, 600, 700, 800]  ;$%$%$ hard coded

  x1 = axis('X', location='bottom', tickvalues=xtv, target=plot10o, tickfont_style=1, title='% diff O+ (4d/nbc)')
  x2 = axis('X', location='top', tickformat='(A1)', tickvalues=xtv, target=plot10o, tickfont_style=1)
  y1 = axis('Y', location='left', tickvalues=ytv, target=plot10o, tickfont_style=1, title='Altitude [km]')
  y2 = axis('Y', location='right', tickformat='(A1)', tickvalues=ytv, target=plot10o, tickfont_style=1)

  cb2 = colorbar(range=[min(binnedo_log,/nan), max(binnedo_log,/nan)], orientation=1, position=posCB2, major=5, $  ;tickvalues=tickvaluesp, target=pIM,
    title='Log number of points', rgb_table=39, font_style=1, font_size=12)

endif  ;twoplot: % diff O+ vs alt

;==========
;THREE: O2+
if keyword_set(threeplot) then begin
  ;Plot % diff vs altitude. % diff is 4d / nbc. Typically, nbc is greater at lower altitudes <~500 km, and 4d is greater above this.
  posT = [0.13, 0.55, 0.87, 0.95]
  posB = [0.13, 0.1, 0.87, 0.45]
  posCB1 = [0.95, 0.6, 0.975, 0.9]
  posCB2 = [0.95, 0.1, 0.975, 0.4]

  fs=1.7
  fs2=12.  ;plot functions

  ;Get indices for FOV flag:
  iKP = where(DenData.FOV_O2 le fovnum and DenData.vsc_STA ge minscp and DenData.vsc_STA le maxscp, niKP) ;routine assumes there will alays be points found
  if niKP eq 0 then stop  ;shouldn't happen for long enough data set
  nptsSTR = strtrim(string(niKP, format='(F12.0)'),2)
  
  ;Bin data and plot number of points in each bin:
  binnedo2 = bin_shit_2d(xdel=5., ydel=100., xmin=-100., xmax=100., ymin=100., ymax=6500., success=success, xdata=DenData.diff_o2[iKP], ydata=DenData.alt[iKP])

  binnedo2_log = alog10(binnedo2.counts)

  win12 = window(dimensions=[700,800])

  ;ALL ALTS:
  ptitle='% diff O2+, 4d/nbc, npts: '+nptsSTR+FOVstr

  plot10o2 = image(binnedo2_log, binnedo2.xaxis, binnedo2.yaxis, position=posT, font_style=1, title=ptitle, aspect_ratio=0.02, $
    xrange=[-100., 100.], yrange=[0., 6500.], xsty=1, rgb_table=39, current=win12)

  xtv = [-100, -50, 0, 50, 100]
  ytv = [100, 1000, 2000, 3000, 4000, 5000, 6000]

  x1 = axis('X', location='bottom', tickvalues=xtv, target=plot10o2, tickfont_style=1, title='% diff O2+ (4d/nbc)')
  x2 = axis('X', location='top', tickformat='(A1)', tickvalues=xtv, target=plot10o2, tickfont_style=1)
  y1 = axis('Y', location='left', tickvalues=ytv, target=plot10o2, tickfont_style=1, title='Altitude [km]')
  y2 = axis('Y', location='right', tickformat='(A1)', tickvalues=ytv, target=plot10o2, tickfont_style=1)


  cb2 = colorbar(range=[min(binnedo2_log,/nan), max(binnedo2_log,/nan)], orientation=1, position=posCB1, major=5, $  ;tickvalues=tickvaluesp, target=pIM,
    title='Log number of points', rgb_table=39, font_style=1, font_size=12)

  ;ZOOM ALTS:
  ptitle='zoom, npts: '+nptsSTR+FOVstr+scpotSTR

  plot10o2 = image(binnedo2_log, binnedo2.xaxis, binnedo2.yaxis, position=posB, font_style=1, title=ptitle, aspect_ratio=0.16, $  ;aspect ratio changed with zoom y range
    xrange=[-100., 100.], yrange=[100., 800.], xsty=1, rgb_table=39, current=win12)

  xtv = [-100, -50, 0, 50, 100]
  ytv = [100, 200, 300, 400, 500, 600, 700, 800]  ;$%$%$ hard coded

  x1 = axis('X', location='bottom', tickvalues=xtv, target=plot10o2, tickfont_style=1, title='% diff O2+ (4d/nbc)')
  x2 = axis('X', location='top', tickformat='(A1)', tickvalues=xtv, target=plot10o2, tickfont_style=1)
  y1 = axis('Y', location='left', tickvalues=ytv, target=plot10o2, tickfont_style=1, title='Altitude [km]')
  y2 = axis('Y', location='right', tickformat='(A1)', tickvalues=ytv, target=plot10o2, tickfont_style=1)

  cb2 = colorbar(range=[min(binnedo2_log,/nan), max(binnedo2_log,/nan)], orientation=1, position=posCB2, major=5, $  ;tickvalues=tickvaluesp, target=pIM,
    title='Log number of points', rgb_table=39, font_style=1, font_size=12)

endif  ;threeplot: % diff O2+ vs alt

;=======
;FOUR: CO2+
if keyword_set(fourplot) then begin
  ;Plot % diff vs altitude. % diff is 4d / nbc. Typically, nbc is greater at lower altitudes <~500 km, and 4d is greater above this.
  posT = [0.13, 0.55, 0.87, 0.95]
  posB = [0.13, 0.1, 0.87, 0.45]
  posCB1 = [0.95, 0.6, 0.975, 0.9]
  posCB2 = [0.95, 0.1, 0.975, 0.4]

  fs=1.7
  fs2=12.  ;plot functions

  ;Get indices for FOV flag:
  iKP = where(DenData.FOV_CO2 le fovnum and DenData.vsc_STA ge minscp and DenData.vsc_STA le maxscp, niKP) ;routine assumes there will alays be points found
  if niKP eq 0 then stop  ;shouldn't happen for long enough data set
  nptsSTR = strtrim(string(niKP, format='(F12.0)'),2)
  
  ;Bin data and plot number of points in each bin:
  binnedco2 = bin_shit_2d(xdel=5., ydel=100., xmin=-100., xmax=100., ymin=100., ymax=6500., success=success, xdata=DenData.diff_co2[iKP], ydata=DenData.alt[iKP])

  binnedco2_log = alog10(binnedco2.counts)

  win13 = window(dimensions=[700,800])

  ;ALL ALTS:
  ptitle='% diff CO2+, 4d/nbc, npts: '+nptsSTR+FOVstr

  plot10co2 = image(binnedco2_log, binnedco2.xaxis, binnedco2.yaxis, position=posT, font_style=1, title=ptitle, aspect_ratio=0.02, $
    xrange=[-100., 100.], yrange=[0., 6500.], xsty=1, rgb_table=39, current=win13)

  xtv = [-100, -50, 0, 50, 100]
  ytv = [100, 1000, 2000, 3000, 4000, 5000, 6000]

  x1 = axis('X', location='bottom', tickvalues=xtv, target=plot10co2, tickfont_style=1, title='% diff CO2+ (4d/nbc)')
  x2 = axis('X', location='top', tickformat='(A1)', tickvalues=xtv, target=plot10co2, tickfont_style=1)
  y1 = axis('Y', location='left', tickvalues=ytv, target=plot10co2, tickfont_style=1, title='Altitude [km]')
  y2 = axis('Y', location='right', tickformat='(A1)', tickvalues=ytv, target=plot10co2, tickfont_style=1)


  cb2 = colorbar(range=[min(binnedco2_log,/nan), max(binnedco2_log,/nan)], orientation=1, position=posCB1, major=5, $  ;tickvalues=tickvaluesp, target=pIM,
    title='Log number of points', rgb_table=39, font_style=1, font_size=12)

  ;ZOOM ALTS:
  ptitle='zoom, npts: '+nptsSTR+FOVstr+scpotSTR

  plot10co2 = image(binnedco2_log, binnedco2.xaxis, binnedco2.yaxis, position=posB, font_style=1, title=ptitle, aspect_ratio=0.16, $  ;aspect ratio changed with zoom y range
    xrange=[-100., 100.], yrange=[100., 800.], xsty=1, rgb_table=39, current=win13)

  xtv = [-100, -50, 0, 50, 100]
  ytv = [100, 200, 300, 400, 500, 600, 700, 800]  ;$%$%$ hard coded

  x1 = axis('X', location='bottom', tickvalues=xtv, target=plot10co2, tickfont_style=1, title='% diff CO2+ (4d/nbc)')
  x2 = axis('X', location='top', tickformat='(A1)', tickvalues=xtv, target=plot10co2, tickfont_style=1)
  y1 = axis('Y', location='left', tickvalues=ytv, target=plot10co2, tickfont_style=1, title='Altitude [km]')
  y2 = axis('Y', location='right', tickformat='(A1)', tickvalues=ytv, target=plot10co2, tickfont_style=1)

  cb2 = colorbar(range=[min(binnedco2_log,/nan), max(binnedco2_log,/nan)], orientation=1, position=posCB2, major=5, $  ;tickvalues=tickvaluesp, target=pIM,
    title='Log number of points', rgb_table=39, font_style=1, font_size=12)

endif  ;twoplot: % diff O+ vs alt



end

;=========
;=========

;+
;Load in L2 tplot variables, to compare derived STATIC densities vs LPW. LPW is reasonable at higher altitudes.
;
;Set /load to load data from L2.
;
;sta_apid: STATIC product to use to derive density. Default is 'c6' if not set. This routine also loads d1 and ca data needed
;          for density derivation.
;
;EGS:
;sta_den_eval_3, '2017-12-16', sta_apid='c6', /load
;
;
;.r /Users/cmfowler/IDL/STATIC_routines/Density_routines/sta_den_eval.pro
;-

pro sta_den_eval_3, date, load=load, sta_apid=sta_apid

@'qualcolors'

get_data, 'mvn_sta_c6_E', data=ddc6
if size(ddc6,/type) ne 8 and not keyword_set(load) then begin
  print, ""
  print, "Warning: STATIC data not found in tplot. Do you need to set /load?"
  return
endif

if keyword_set(load) then begin
  timespan, date, 1.

  mvn_sta_l2_load, sta_apid=[sta_apid]  ;make tplot vars for just c6
  mvn_sta_l2_load, sta_apid=['ca', 'd1', 'c8']
  mvn_sta_l2_tplot

  mvn_lpw_load_l2, ['lpnt'], /notplot
endif

get_data, 'mvn_sta_c6_E', data=ddc6

;tr = [1513424280.0000000d, 1513436400.0000000d]   ;user set time range (for testing)
tr = [min(ddc6.x, /nan), max(ddc6.x, /nan)]  ;full time range

;Get FOV flag:
mvn_sta_fov_snap, trange=tr, mrange=[0.5, 1.5], sta_apid='d1'
mvn_sta_fov_snap, trange=tr, mrange=[12., 20.], sta_apid='d1'
mvn_sta_fov_snap, trange=tr, mrange=[28., 36.], sta_apid='d1'
mvn_sta_fov_snap, trange=tr, mrange=[40., 48.], sta_apid='d1'

static_density_crib, trange=tr, sta_apid=sta_apid  ;gets densities for all species.

;Combine LPW and STA tot:
get_data, 'mvn_lpw_lp_ne_l2', data=ddne
boomnum = floor(ddne.info/10.)
iKP = where(boomnum eq 1)
store_data, 'LPW_ne_B1', data={x: ddne.x[iKP], y: ddne.y[iKP]}

store_data, 'TOT_den_compare_'+sta_apid, data=['mvn_sta_'+sta_apid+'_density_total', 'mvn_sta_'+sta_apid+'_density_total_4d', 'LPW_ne_B1']
  options, 'TOT_den_compare_'+sta_apid, colors=[qualcolors.black, qualcolors.blue, qualcolors.green]
  options, 'TOT_den_compare_'+sta_apid, labels=['STA nbc', 'STA 4d', 'LPW']
  options, 'TOT_den_compare_'+sta_apid, labflag=1
  options, 'TOT_den_compare_'+sta_apid, psym=1
  ylim, 'TOT_den_compare_'+sta_apid, 1, 5E5

tvars=['mvn_sta_c6_E', 'mvn_sta_c6_M', 'TOT_den_compare_'+sta_apid]
tplot, tvars

end







