;+
;NAME:
; mvn_swe_overplot
;PURPOSE:
; MAVEN PFP SWE Quicklook Plot
;CALLING SEQUENCE:
; mvn_swe_overplot, date = date, time_range = time_range, $
;      makepng=makepng, device = device, directory = pdir, $
;      l0_input_file = l0_input_file, noload_data=noload_data, $
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
;           'mvn_swe_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a png is created, this is the output directory, the
;             default is the current working directory.
; noload_data = if set, don't load data
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-03-19 13:42:44 -0700 (Thu, 19 Mar 2015) $
; $LastChangedRevision: 17150 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_swe_overplot.pro $
Pro mvn_swe_overplot, date = date, time_range = time_range, $
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
;It looks like this will now require a time range, too
   If(is_string(filex)) Then Begin
      p1  = strsplit(file_basename(filex), '_',/extract)
      date = p1[4]
      d0 = time_double(strmid(date,0,4)+'-'+strmid(date,4,2)+'-'+strmid(date,6,2))
      time_range = d0+[0.0, 86400.0]
   Endif Else If(n_elements(date) Gt 0) Then Begin
      d0 = time_double(date[0])
      time_range = d0+[0.0, 86400.0]
   Endif Else time_range = [0.0d0, 0.0d0]
   mvn_swe_load_l0, time_range, filename = filex
   orbdata = mvn_orbit_num()
   store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
               dlimit={ytitle:'Orbit'}
Endif
mvn_swe_sumplot, tplot_vars_out = varlist

;You need a time range for the data, Assuming that everything comes
;from one kind of packet, you should be ok, but check all variables
;just in case

varlist = mvn_qlook_vcheck(varlist, tr = tr)
If(varlist[0] Eq '')  Then Begin
    dprint, 'No data, Returning'
    Return
Endif

;Remove gap between plot panels
tplot_options, 'ygap', 0.0d0

;Get the date
p1  = strsplit(file_basename(filex), '_',/extract)
date = p1[4]
d0 = time_double(time_string(date))
tr = tr > d0
;plot the data
tplot, varlist, title = 'MAVEN SWE Quicklook '+date, var_label = 'mvn_orbnum'

If(keyword_set(multipngplot)) Then makepng = 1b
If(keyword_set(makepng)) Then Begin
    If(keyword_set(directory)) Then pdir = directory Else pdir = './'
    fname = pdir+mvn_qlook_filename('swe', tr, _extra=_extra)
    If(keyword_set(multipngplot)) Then mvn_gen_multipngplot, fname, directory = pdir $
    Else makepng, fname
Endif

Return
End
