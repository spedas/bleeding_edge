;+
;NAME:
; mvn_mag_overplot
;PURPOSE:
; MAVEN PFP MAG Quicklook Plot
;CALLING SEQUENCE:
; mvn_mag_overplot, date = date, time_range = time_range, $
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
;           'mvn_mag_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; noload_data = if set, don't load data
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; Changed to call mvn_mag_ql_tsmaker2, 2014-03-21, may switch back
; next week
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-03-19 13:42:44 -0700 (Thu, 19 Mar 2015) $
; $LastChangedRevision: 17150 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_mag_overplot.pro $
Pro mvn_mag_overplot, date = date, time_range = time_range, $
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
    mvn_pfp_l0_file_read, file = filex, /mag
    magvar0 = ['mvn_mag1_svy_BAVG', 'mvn_mag2_svy_BAVG']
    magvar1 = ['mvn_ql_mag1', 'mvn_ql_mag2']
    For j = 0, 1 Do Begin
       get_data, magvar0[j], data = dj
       If(is_struct(dj)) Then Begin
          copy_data, magvar0[j], magvar1[j]
;units and coordinate system?
          data_att = {units:'nT', coord_sys:'Sensor'}
          dlimits = {spec:0, log:0, colors:[2, 4, 6], labels: ['x', 'y', 'z'],  $
                     labflag:1, color_table:39, data_att:data_att}
          store_data, magvar1[j], dlimits = dlimits
       Endif
    Endfor
;orbit number
    orbdata = mvn_orbit_num()
    store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
                dlimit={ytitle:'Orbit'}
    varlist = ['mvn_ql_mag1', 'mvn_ql_mag2']
;You need a time range for the data, Assuming that everything comes
;from one kind of packet, you should be ok, but check all variables
;just in case
    varlist = mvn_qlook_vcheck(varlist, tr = tr)
    If(varlist[0] Eq '') Then Begin
        dprint, 'No data, Returning'
        Return
    Endif
 ;Here I am going to despike the data, using simple_despike_1d.pro
    nvars = n_elements(varlist)
    For j = 0, nvars-1 Do Begin
        get_data, varlist[j], data = dj
        For k = 0, n_elements(dj.y[0, *])-1 Do Begin
            djyk = simple_despike_1d(dj.y[*, k], width = 10)
            dj.y[*, k] = djyk
        Endfor
        store_data, varlist[j], data = dj
    Endfor
 Endif Else Begin
    varlist = ['mvn_ql_mag1', 'mvn_ql_mag2']
    varlist = mvn_qlook_vcheck(varlist, tr = tr)
    If(varlist[0] Eq '') Then Begin
        dprint, 'No data, Returning'
        Return
    Endif
 Endelse
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
;plot the data
tplot, varlist, title = 'MAVEN MAG Quicklook '+date, var_label = 'mvn_orbnum'

If(keyword_set(multipngplot)) Then makepng = 1b
If(keyword_set(makepng)) Then Begin
    If(keyword_set(directory)) Then pdir = directory Else pdir = './'
    fname = pdir+mvn_qlook_filename('mag', tr, _extra=_extra)
    If(keyword_set(multipngplot)) Then mvn_gen_multipngplot, fname, directory = pdir $
    Else makepng, fname
Endif

Return
End
