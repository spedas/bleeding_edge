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
;           'mvn_gen_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a png is created, this is the output directory, the
;             default is the current working directory.
; multipngplot = if set, then make multiple plots of 2 and 6 hour
;               duration, in addition to the regular png plot
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; CHanged to use thara's mvn_pl_pfp_tplot.pro, 2015-04-14, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2016-05-23 14:35:24 -0700 (Mon, 23 May 2016) $
; $LastChangedRevision: 21178 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_pfpl2_overplot.pro $
;-
Pro mvn_pfpl2_overplot, orbit_number = orbit_number, $
                        date = date, time_range = time_range, $
                        makepng=makepng, device = device, $
                        directory = directory, $
                        multipngplot = multipngplot, $
                        _extra=_extra

  mvn_qlook_init, device = device

;First load the data
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

  mvn_ql_pfp_tplot2, tr0, bcrust=1, /tplot, bvec = bvec

;Re-init here
  mvn_qlook_init, device = device

;Get a burst_data_bar
  mvn_bb = mvn_qlook_burst_bar(tr0[0], (tr0[1]-tr0[0])/86400.0d0, /outline, /from_l2)
  varlist = ['mvn_sep1_B-O_Eflux_Energy', 'mvn_sep2_B-O_Eflux_Energy', $
             'mvn_sta_c0_e', 'mvn_sta_c6_m', 'mvn_swis_en_eflux', $
             'mvn_swe_etspec', 'mvn_lpw_iv', 'mvn_mag_bamp', bvec, 'alt2', $
             mvn_bb]

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
