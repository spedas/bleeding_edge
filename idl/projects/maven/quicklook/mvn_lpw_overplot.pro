;+
;NAME:
; mvn_lpw_overplot
;PURPOSE:
; MAVEN PFP LPW Quicklook Plot
;CALLING SEQUENCE:
; mvn_lpw_overplot, date = date, time_range = time_range, $
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
;           'mvn_lpw_qlook_start_time_end_time.png'
; device = a device for set_plot, the default is to use the current
;          setting, for cron jobs, device = 'z' is recommended. Note
;          that this does not reset the device at the end of the
;          program.
; directory = If a png is created, this is the output directory, the
;             default is the current working directory.
; noload_data = if set, don't load data
; noplot = if set, don't plot the data
;HISTORY:
; Hacked from thm_over_shell, 2013-05-12, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2020-04-30 12:45:05 -0700 (Thu, 30 Apr 2020) $
; $LastChangedRevision: 28651 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_lpw_overplot.pro $
Pro mvn_lpw_overplot, date = date, time_range = time_range, $
                      makepng=makepng, device = device, directory = directory, $
                      l0_input_file = l0_input_file, $
                      noload_data = noload_data, $
                      multipngplot = multipngplot, $
                      noplot = noplot, $
                      _extra=_extra

mvn_qlook_init, device = device

;First load the data
If(keyword_set(l0_input_file)) Then Begin
   filex = l0_input_file[0]
Endif Else Begin
   filex = mvn_l0_db2file(date, l0_file_type = 'all')
Endelse

;Here you have a filename, some of these inputs require a time span or
;date, extract the date from the filename
If(is_string(filex)) Then Begin
   p1  = strsplit(file_basename(filex), '_',/extract)
   date = p1[4]
Endif Else Begin
   dprint, 'Missing Input File, Returning'
   Return
Endelse
yyyy = strmid(date, 0, 4)
mm = strmid(date, 4, 2)
dd = strmid(date, 6, 2)
date_str = yyyy+'-'+mm+'-'+dd
If(~keyword_set(noload_data)) Then Begin
   del_data, '*'
   mvn_lpw_load, date_str, tplot_var='all', packet='nohsbm', /notatlasp, /noserver
   mvn_lpw_ql_instr_page
   orbdata = mvn_orbit_num()
   store_data,'mvn_orbnum',orbdata.peri_time,orbdata.num,dlimit={ytitle:'Orbit'}
Endif

varlist = ['mvn_lpw_euv','mvn_lpw_euv_temp_C','mvn_lpw_hsk_temp',$
           'modes','mvn_lpw_spec_hf_pas','mvn_lpw_spec_mf_pas',$
           'mvn_lpw_spec_lf_pas', 'E12','SC_pot','mvn_lpw_swp1_IV_log',$
           'mvn_lpw_swp2_IV_log','htime']

varlist0 = varlist
;You need a time range for the data, Assuming that everything comes
;from one kind of packet, you should be ok, but check all variables
;just in case
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
;plot the data
If(~keyword_set(noplot)) Then Begin
   tplot, varlist, title = 'MAVEN LPW Quicklook '+date, var_label = 'mvn_orbnum'

   If(keyword_set(multipngplot)) Then makepng = 1b
   If(keyword_set(makepng)) Then Begin
      If(keyword_set(directory)) Then pdir = directory Else pdir = './'
      fname = pdir+mvn_qlook_filename('lpw', tr, _extra=_extra)
      If(keyword_set(multipngplot)) Then mvn_gen_multipngplot, fname, directory = pdir $
      Else makepng, fname
   Endif
Endif
;store LPW tplot variable for PFP L2 plotting
get_data, 'mvn_lpw_swp1_IV_log', data=d, dl=dl, lim=lim
If(is_struct(d)) Then Begin
   extract_tags, nlim, lim, tags=['yrange', 'ylog', 'zlog', 'spec', 'no_interp', 'ystyle']
   store_data, 'mvn_lpw_iv', data=d, dl=dl, lim=nlim
   undefine, d, dl, lim, nlim
   options, 'mvn_lpw_iv', 'zrange', [-10, -4]
   options, 'mvn_lpw_iv', ytitle='LPW-L0 (IV)', ysubtitle='[V]', ztitle='Log(IV)', $
            xsubtitle='', zsubtitle=''
   lpw_vars = 'mvn_lpw_iv'
;This needs hard-coding, because the L0 script uses a different
;directory keyword...
   pdir1 = '/disks/data/maven/data/sci/lpw/tplot/'+yyyy+'/'
   If(~is_string(file_search(pdir1))) Then Begin
      file_mkdir, pdir1
      file_chmod, pdir1, '775'o
   Endif
   tplot_save, lpw_vars, filename = pdir1+'mvn_lpw_iv_'+yyyy+mm+dd
   file_chmod, pdir1+'mvn_lpw_iv_'+yyyy+mm+dd+'.tplot', '664'o
Endif 

Return
End
