;+
;NAME:
; mvn_sep_overplot
;PURPOSE:
; MAVEN PFP SEP Quicklook Plot
;CALLING SEQUENCE:
; mvn_sep_overplot, date = date, time_range = time_range, $
;      makepng=makepng, device = device, directory = pdir, $
;      l0_input_file = l0_input_file, , noload_data = noload_data, $
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
;           'mvn_sep_qlook_seprt_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; noload_data = if set, don't load data
;HISTORY:
; Hacked from mvn_sep_gen_ql, 2013-06-14, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-04-08 16:52:37 -0700 (Wed, 08 Apr 2015) $
; $LastChangedRevision: 17256 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_sep_overplot.pro $
Pro mvn_sep_overplot, date = date, time_range = time_range, $
                      makepng = makepng, device = device, directory = directory, $
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
;mvn_sep_gen_ql needs a time range
;   If(keyword_set(time_range)) Then trange = time_range Else Begin
;      p1  = strsplit(file_basename(filex), '_',/extract)
;      date = p1[4]
;      d0 = time_double(strmid(date,0,4)+'-'+strmid(date,4,2)+'-'+strmid(date,6,2))
;      trange = d0+[0.0, 86400.0]
;   Endelse
;   timespan, trange0
;   mvn_sep_gen_ql, trange=trange, /load
   mvn_pfp_l0_file_read,file=filex,/sep
   orbdata = mvn_orbit_num()
   store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
               dlimit={ytitle:'Orbit'}
Endif

varlist = tnames('mvn_sep*') ;just to get a time range
varlist = mvn_qlook_vcheck(varlist, tr = tr)
If(varlist[0] Eq '') Then Begin
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
tplot_options, 'title', 'MAVEN SEP Quicklook '+date

mvn_sep_tplot,'SUM'
If(keyword_set(multipngplot)) Then makepng = 1b
If(keyword_set(makepng)) Then Begin
   If(keyword_set(directory)) Then pdir = directory Else pdir = './'
    fname = pdir+mvn_qlook_filename('sep', tr, _extra = _extra)
    If(keyword_set(multipngplot)) Then mvn_gen_multipngplot, fname, directory = pdir $
    Else makepng, fname
Endif

Return
End
