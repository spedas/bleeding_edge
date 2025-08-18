;+
;NAME:
; mvn_pfpl2_overplot
;PURPOSE:
; MAVEN PFP GEN Quicklook Plot
;CALLING SEQUENCE:
; mvn_pfpl2_overplot, date = date, time_range = time_range, $
;      makepng=makepng, device = device, directory = pdir, $
;      multipngplot = multipngplot
;INPUT:
; No explicit input, everthing is via keyword.
;OUTPUT:
; Plots, on the screen or in a png file
;KEYWORDS:
; date = If set, a plot for the input date.
; time_range = If set, plot this time range, note that this supercedes
;              the date keyword, if both are set, the time range is
;              attempted.
; makepng = If set, make a png file, with filename
;           'mvn_pfp_l2_date.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a png is created, this is the output directory, the
;             default is the current working directory.
; multipngplot = if set, then make multiple plots for each orbit
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; CHanged to use thara's mvn_pl_pfp_tplot.pro, 2015-04-14, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2024-04-03 14:29:06 -0700 (Wed, 03 Apr 2024) $
; $LastChangedRevision: 32518 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_pfpl2_overplot.pro $
;-
Pro mvn_pfpl2_overplot, orbit_number = orbit_number, $
                        date = date, time_range = time_range, $
                        makepng=makepng, device = device, $
                        directory = directory, $
                        multipngplot = multipngplot, $
                        no_bcrust = no_bcrust, $
                        _extra=_extra

  mvn_qlook_init, device = device

;First load the data
  del_data, '*'
;Orbit number
  orbdata = mvn_orbit_num()
  norbits = n_elements(orbdata.num)
  If(keyword_set(orbit_number)) Then Begin
     orb_range = minmax(orbit_number)
     If(n_elements(orbit_number) Eq 1) Then orb_range[1]=orb_range[1]+1
     tr0 = interpol(orbdata.apo_time, orbdata.num, orb_range)
     tr0x = tr0
  Endif Else If(keyword_set(time_range)) Then Begin
     tr0 = time_double(time_range) & tr0x = tr0
  Endif Else If(keyword_set(date)) Then Begin
     tr0 = time_double(date)+[0.0d0, 86400.0d0] & tr0x = tr0
;reset time range to start and end of orbits, note we are making the
;assumption that the orbit data is always ahead of the time processed.
    If(tr0[0] Ge orbdata[0].apo_time And $
        tr0[1] Le orbdata[norbits-1].apo_time) Then Begin
        o1 = max(where(orbdata.apo_time Le tr0[0]))
        o2 = min(where(orbdata.apo_time ge tr0[1]))
        tr0 = orbdata[[o1, o2]].apo_time
        print, 'Orbit start and end:', orbdata[[o1, o2]].num
     Endif
  Endif Else Begin
     dprint, 'Need orbit_number, date or time_range input keywords set'
     Return
  Endelse
; No plots prior to 2014-10-14, as all of the data may not exist
  If(time_double(tr0[0]) Lt time_double('2014-10-12T12:00:00')) Then Begin
     dprint, 'Date too early: '+time_string(tr0[0])
     Return
  Endif
; run mvn_lpw_overplot for this date, to insure the presence of the lpw_iv
; tplot save file, only if the date keyword is used, as in
; mvn_call_pfpl2plot.pro. This piles up spice kernels, so clear out
; spice kernels after use, they'll have to be reloaded, 
; jmm, 2020-05-11
  If(keyword_set(date)) Then Begin
     mvn_lpw_overplot, date = date, /noplot
     mvn_spc_clear_spice_kernels
     del_data, '*'
  Endif
;The ql_pfp_tplots can not be trusted to always load spice kernels
  mvn_spice_load, trange = [-7.0*86400.0d0,7.0*86400.0d0]+tr0
; Load SEP from a different program, 2019-02-20
  If(keyword_set(no_bcrust)) Then Begin
     mvn_ql_pfp_tplot2, tr0, bcrust=0, sep = 0, /tplot, bvec = bvec
  Endif Else Begin
     mvn_ql_pfp_tplot2, tr0, bcrust=1, sep = 0, /tplot, bvec = bvec
  Endelse
;reset colors for B field
  get_data, 'mvn_mag_bang_1sec', dlimits = dl
  If(is_struct(dl)) Then Begin
     str_element, dl, 'colors', [6, 0], /add_replace         ;red, black
     If(tag_exist(dl, 'axis') && tag_exist(dl.axis, 'color')) Then dl.axis.color = 6
     store_data, 'mvn_mag_bang_1sec', dlimits = dl
  Endif

;Re-init here
  mvn_qlook_init, device = device
  mvn_spice_load, trange = [-7.0*86400.0d0,7.0*86400.0d0]+tr0
;Get a burst_data_bar
  mvn_bb = mvn_qlook_burst_bar(tr0[0], (tr0[1]-tr0[0])/86400.0d0, $
                               /outline, /from_l2)
  options, mvn_bb, 'panel_size', 0.05 ;smaller panel
  options, mvn_bb, 'ytitle', 'ATT!CBST'
;Get an attitude bar
  mvn_attitude_bar
  options, 'mvn_att_bar', 'xstyle', 0
  options, 'mvn_att_bar', 'ystyle', 0
  options, 'mvn_att_bar', 'labels', ['ATT',''], /default
  
;Use mvn_sep_average.pro to get ion and electron fluxes
  mvn_sep_average, trange = tr0, /load
  options, 'mvn_L2_sep_mean_ion_eflux', 'ytitle', 'SEP Ions, !C keV'
  options, 'mvn_L2_sep_mean_electron_eflux', 'ytitle', 'SEP Electrons, !C keV'
  options, 'mvn_L2_sep_mean_ion_eflux', 'ztitle', 'EFLUX'
  options, 'mvn_L2_sep_mean_electron_eflux', 'ztitle', 'EFLUX'
  options, 'mvn_L2_sep?attenuator_state', 'psym', 1
  options, 'mvn_L2_sep1attenuator_state', 'labels', 'ATN1-red=in'
  options, 'mvn_L2_sep2attenuator_state', 'labels', 'ATN2-red=in'

;swap out 0 values in attenuators
  get_data, 'mvn_L2_sep1attenuator_state', data = d1
  If(is_struct(d1)) Then Begin
     Ok = where(d1.x Gt 0 And d1.y Gt 0, nok)
     d1y_dummy = float(d1.y) & d1y_dummy[*] = 1.0 ;to not split attenuator states
     If(nok gt 0) Then store_data, 'mvn_L2_sep1attenuator_state', $
                                   data = {x:d1.x[ok], y:d1y_dummy[ok]}
     Ok2 = where(d1.x Gt 0 And d1.y Eq 2, nok2);use this to overplot
     oplot_att_in1 = 0b
     If(nok2 gt 0) Then Begin
        oplot_att_in1 = 1b
        store_data, 'SEP1_ATT_IN', $
                    data = {x:d1.x[ok2], y:d1y_dummy[ok2]}
        options, 'SEP1_ATT_IN', 'psym', 1
        options, 'SEP1_ATT_IN', 'color', 6
        options, 'SEP1_ATT_IN', 'yrange', [0.9,1.1]
        store_data, 'SEP_V1', data =['mvn_L2_sep1attenuator_state', $
                                     'SEP1_ATT_IN']
     Endif Else copy_data, 'mvn_L2_sep1attenuator_state', 'SEP_V1'
  Endif
  get_data, 'mvn_L2_sep2attenuator_state', data = d2
  If(is_struct(d2)) Then Begin
     Ok = where(d2.x Gt 0 And d2.y Gt 0, nok)
     d2y_dummy = float(d2.y) & d2y_dummy[*] = 1.0 ;to not split attenuator states
     If(nok gt 0) Then store_data, 'mvn_L2_sep2attenuator_state', $
                                   data = {x:d2.x[ok], y:d2y_dummy[ok]}
     Ok2 = where(d2.x Gt 0 And d2.y Eq 2, nok2) ;use this to overplot
     oplot_att_in2 = 0b
     If(nok2 gt 0) Then Begin
        oplot_att_in2 = 1b
        store_data, 'SEP2_ATT_IN', $
                    data = {x:d2.x[ok2], y:d2y_dummy[ok2]}
        options, 'SEP2_ATT_IN', 'psym', 1
        options, 'SEP2_ATT_IN', 'color', 6
        options, 'SEP2_ATT_IN', 'yrange', [0.9,1.1]
        store_data, 'SEP_V2', data =['mvn_L2_sep2attenuator_state', $
                                     'SEP2_ATT_IN']
     Endif Else copy_data, 'mvn_L2_sep2attenuator_state', 'SEP_V2'
  Endif
  options, 'SEP_V?', 'yrange', [0.9,1.1]
  options, 'SEP_V?', 'ystyle', 4
  options, 'SEP_V?', 'panel_size', 0.15

;try log plot for altitude,
  ylim, 'alt2', 60.0, 10000.0, 1
;Change ztitle for mvn_sta_c6_m_twt
  options, 'mvn_sta_c6_m_twt', 'ztitle', 'EFLUX/TOFBIN'
  options, 'mvn_sta_c6_m_twt', 'zrange', [1.0e3, 1.0e8]
  attitude_label = 'Attitude: orange = Sun point; blue = Earth point; green = Fly-Y; red = Fly-Z; purple = Fly+Z.'
  options, 'mvn_att_bar', 'title', attitude_label
  options, 'mvn_att_bar', 'charsize', 0.5
;Add EMM aurora data, maybe only to the short term plots
  emissions = ['O I 130.4 triplet', 'O I 135.6 doublet']
;this routine grabs the files from the SSL network and loads the
;relevant information into a structure called "disk"
  emm_emus_examine_disk, tr0, emission = emissions, /l2b, disk = disk
  If(is_Struct(disk)) Then Begin
; this routine takes the "disk" structure as input and creates the tplot variables
     emm_emus_image_bar, trange = tr0, disk = disk
;Something bad happens to overall setup here,
     If(keyword_set(device)) Then mvn_qlook_init, device = device
;Tweak color table for the EMM variable
;Set up varlist
     options, 'emus_O_1304', 'color_table', 8
     options, 'emus_O_1304', 'zrange', [2.0, 30.0]
     varlist = ['mvn_L2_sep_mean_ion_eflux', 'mvn_L2_sep_mean_electron_eflux', $
                'SEP_V1', 'SEP_V2', $
                'mvn_sta_c0_e', 'mvn_sta_c6_m_twt', 'mvn_swis_en_eflux', $
                'mvn_swe_etspec', 'mvn_lpw_iv', 'mvn_mag_bamp', $ 
                'mvn_mag_bang_1sec', 'emus_O_1304', 'alt2', 'mvn_att_bar', mvn_bb]
  Endif Else Begin;no EMM panel
     varlist = ['mvn_L2_sep_mean_ion_eflux', 'mvn_L2_sep_mean_electron_eflux', $
                'SEP_V1', 'SEP_V2', $
                'mvn_sta_c0_e', 'mvn_sta_c6_m_twt', 'mvn_swis_en_eflux', $
                'mvn_swe_etspec', 'mvn_lpw_iv', 'mvn_mag_bamp', $ 
                'mvn_mag_bang_1sec', 'alt2', 'mvn_att_bar', mvn_bb]
  Endelse
  varlist = mvn_qlook_vcheck(varlist, tr = tr, /blankp)
  If(varlist[0] Eq '')  Then Begin
     dprint, 'No data, Returning'
     Return
  Endif

;load orbit data into tplot variables
  store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
              dlimit={ytitle:'Orbit'}
  store_data, 'mvn_orbnum1', orbdata.apo_time, orbdata.num, $
              dlimit={ytitle:'Orbit-APO'}
;Remove gap between plot panels
  tplot_options, 'ygap', 0.0d0

;Get the date-time range
  d0 = time_string(tr0x[0])
  d1 = time_string(tr0x[1])

;plot the data
  tplot, varlist, title = 'MAVEN PFP L2 '+d0+'-'+d1, var_label = 'mvn_orbnum'
  tlimit, tr0x[0], tr0x[1]
;add the attitude label

  If(keyword_set(multipngplot) && keyword_set(date)) Then makepng = 1b
  If(keyword_set(makepng)) Then Begin
     If(keyword_set(directory)) Then pdir = directory Else pdir = './'
     fname = pdir+mvn_qlook_filename('l2', tr0x, _extra=_extra)
     If(keyword_set(multipngplot) && keyword_set(date)) Then Begin
        mvn_gen_multipngplot, fname, directory = pdir
     Endif Else makepng, fname
  Endif

  Return
End
