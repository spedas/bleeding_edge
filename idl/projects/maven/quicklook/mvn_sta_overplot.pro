;+
;NAME:
; mvn_sta_overplot
;PURPOSE:
; MAVEN PFP STA Quicklook Plot
;CALLING SEQUENCE:
; mvn_sta_overplot, date = date, time_range = time_range, $
;      makepng=makepng, device = device, directory = pdir, $
;      l0_input_file = l0_input_file, noload_data = noload_data, $
;      _extra=_extra
;INPUT:
; No explicit input, everthing is via keyword.
;OUTPUT:
; Plots, on the screen or in a png file
;KEYWORDS:
; date = If set, a plot for the input date.
; time_range = If set, plot this time range, note that this supercedes
;              the date keyword, if both are set, the time range is
;              attempted.
; l0_input_file = A filename for an input file, if this is set, the
;                 date and time_range keywords are ignored.
; makepng = If set, make a png file, with filename
;           'mvn_sta_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; noload_data = if set, don't load data
;HISTORY:
; Hacked from mvn_sta_gen_ql, 2013-06-14, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2025-05-14 16:15:46 -0700 (Wed, 14 May 2025) $
; $LastChangedRevision: 33309 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_sta_overplot.pro $
Pro mvn_sta_overplot, date = date, time_range = time_range, $
                      makepng=makepng, device = device, directory = directory, $
                      l0_input_file = l0_input_file, $
                      noload_data = noload_data, multipngplot = multipngplot, $
                      _extra=_extra

mvn_qlook_init, device = device

;First load the data
If(keyword_set(l0_input_file)) Then Begin
   filex = l0_input_file[0]
Endif Else Begin
   filex = mvn_l0_db2file(date, l0_file_type = 'all')
Endelse
If(~keyword_set(noload_data)) Then Begin
;I need a timespan here
    p1  = strsplit(file_basename(filex), '_',/extract)
    d0 = time_double(time_string(p1[4]))
    timespan, d0, 1
    mvn_sta_gen_ql, file = filex;, pathname=file_dirname(filex), file=file_basename(filex)
    orbdata = mvn_orbit_num()
    store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
                dlimit={ytitle:'Orbit'}
Endif Else Begin
;Add D1 bar
   If(~keyword_set(date)) Then Begin
      p1  = strsplit(file_basename(filex), '_',/extract)
      date = time_double(time_string(p1[4]))
      d0 = date
   Endif Else d0 = time_double(date)
Endelse
d1p = mvn_qlook_static_d1_bar(d0, 1, /outline)
varlist = ['mvn_sta_mode','mvn_sta_C0_att'$
           ,'mvn_sta_density'$
           ,'mvn_sta_C0_P1A_tot','mvn_sta_C0_P1A_E','mvn_sta_C6_P1D_M','mvn_sta_A','mvn_sta_D'$
           ,'mvn_sta_D8_R1_diag','mvn_d1_arcflag'$
          ]

;You need a time range for the data, Assuming that everything comes
;from one kind of packet, you should be ok, but check all variables
;just in case

varlist = mvn_qlook_vcheck(varlist, tr = tr)
If(varlist[0] Eq '') Then Begin
    dprint, 'No data, Returning'
    Return
Endif

;Get the date
p1  = strsplit(file_basename(filex), '_',/extract)
date = p1[4]
d0 = time_double(time_string(date))
tr = tr > d0
title = 'MAVEN STATIC Quicklook '+date

;Remove gap between plot panels
tplot_options, 'ygap', 0.0d0

;plot the data
tplot, varlist, title = title, var_label = 'mvn_orbnum'

If(keyword_set(multipngplot)) Then makepng = 1b
If(keyword_set(makepng)) Then Begin
    If(keyword_set(directory)) Then pdir = directory Else pdir = './'
    fname = pdir+mvn_qlook_filename('sta', tr, _extra=_extra)
    If(keyword_set(multipngplot)) Then mvn_gen_multipngplot, fname, directory = pdir $
    Else makepng, fname
Endif

Return
End
