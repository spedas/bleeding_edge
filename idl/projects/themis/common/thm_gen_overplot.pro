;+
;NAME:
;   thm_gen_overplot
;
;PURPOSE:
;   To make mission overview plots of all instruments
;   This can be called either from SPEDAS GUI or from a server script to create png images
;
;CALLING SEQUENCE:
;   thm_gen_overplot
;
;INPUT:
;   none
;
;KEYWORDS:
;   PROBES: spacecraft ('a','b','c','d','e')
;   DATE: the date string or seconds since 1970 ('2007-03-23')
;   DUR: duration (default units are days)
;   DAYS: redundant keyword to set the units of duration (but its comforting to have)
;   HOURS: keyword to make the duration be in units of hours
;   DEVICE: sets the device (x or z) (default is x)
;   MAKEPNG: keyword to generate 5 png files
;   DIRECTORY: sets the directory where the above pngs are placed (default is './')
;   FEARLESS: keyword that prevents program from quitting when it fears its in an infinite loop
;     (infinite loop is feared when catch statement has been call 1000 times)
;   DONT_DELETE_DATA:  keyword to not delete all existing tplot variables before loading data in for
;      the overview plot (sometimes old variables can interfere with overview plot)
;   gui_plot: 1 for gui plot, 0 for server plot
;   no_draw: flag passed to tplot_gui for gui overview plots
;   error: 0 if it run to the end
;     
;OUTPUT:
;   A set of png files or a set of plots for the GUI
;
;EXAMPLES:
;   thm_gen_overplot,probe='a',date='2007-03-23',dur=1
;     The above example will produce the overview plots for a full day in the X window.
;   thm_gen_overplot, probes='a', date='2008-03-23',dur=1, makepng=1, device='z', directory='c:\tmp'
;     The above example will produce a set of 17 plots in c:\temp
;   thm_gen_overplot, probes='a', date='2009-03-23', dur = 1, makepng = 0, fearless = 0, dont_delete_data = 1, error=error, gui_plot = 1  
;     The above example calls this function from the SPEDAS GUI
;
;HISTORY:
;  This has replaced the older spd_ui_overplot.pro which was written specifically for GUI overview plots.
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2025-05-19 11:45:05 -0700 (Mon, 19 May 2025) $
;$LastChangedRevision: 33318 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_gen_overplot.pro $
;-----------------------------------------------------------------------------------

pro thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = probes
  if (gui_plot eq 1) then return ; run this only for server plots
  severity='2' ;error severity level
  CALDAT,SYSTIME(/julian), month0, day0, year0, hour0, minute0
  datetime0 = time_double(strtrim(string(year0),2) + "-" + strtrim(string(FORMAT='(I02)', month0),2) + "-" + strtrim(string(FORMAT='(I02)', day0),2) + "/" + strtrim(string(FORMAT='(I02)', hour0),2) + ":" + strtrim(string(FORMAT='(I02)', minute0),2))
  datetime1 = time_double(date)
  if abs(datetime0 - datetime1) le 172800.0D then begin ; if less than 48 hours, no error is printed
    ;print, 'Got Error Message' ; Enabling this creates an error log for the current day as well
    str_message = "Message: " + "--- Current date=" + time_string(datetime0) + ", summary plot date=" + time_string(datetime1) + ", probes=" + probes[0]
    print, str_message
  endif else begin    
    print, 'Got Error Message' ; this triggers the error reporting later on
    str_message = str_message + "--- Current date=" + time_string(datetime0) + ", summary plot date=" + time_string(datetime1) + ", probes=" + probes[0]
    thm_thmsoc_dblog, server_run=1, process_name='thm_gen_overplot', severity=severity, str_message=str_message
  endelse
end


pro thm_gen_overplot, probes = probes, date = date, dur = dur, $
                      days = days, hours = hours, device = device, $
                      directory = directory, makepng = makepng, $
                      fearless = fearless, dont_delete_data = dont_delete_data, $
                      no_draw=no_draw, gui_plot = gui_plot, error=error, $
                      _extra=_extra

compile_opt idl2, hidden

;catch errors and fail gracefully
;-------------------------------------------------------
common overplot_position, load_position, error_count
heap_gc
quiet=0
error_count=0
load_position = 'init'
                    
if (keyword_set(gui_plot)) then gui_plot=1 else gui_plot=0

if ~keyword_set(directory) then cd,current = directory

; set the suffix to identify different calls to overplot
; osuffix = ('_op' + strcompress(string(*oplot_calls + 1), /remove_all))[0]

;catch statement to allow program to recover from errors
;-------------------------------------------------------

catch,error_status

if error_status ne 0 then begin

   error_count++
   if error_count ge 1000. and not keyword_set(fearless) then begin
     str_message = 'The program is quitting because it fears its in an infinite loop.'
     dprint,  ' '
     dprint, str_message
     dprint,  'To eliminate this fear add the keyword /fearless to the call.'
     thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = ' '
     error=1
     return
   endif

   dprint,  '***********Catch error**************'
   help, /last_message, output = err_msg
   For j = 0, n_elements(err_msg)-1 Do print, err_msg[j]
   print, 'load_position: ' , load_position

   case load_position of
        'init'          : goto, SKIP_DAY
   	'fgm'		: goto, SKIP_FGM_LOAD
   	'fbk'		: goto, SKIP_FBK_LOAD
   	'sst'		: goto, SKIP_SST_LOAD
   	'esa'		: goto, SKIP_ESA_LOAD
   	'gmag'		: goto, SKIP_GMAG_LOAD
   	'asi'		: goto, SKIP_ASI_LOAD
   	'pos'		: goto, SKIP_POS_LOAD
   	'mode'		: goto, SKIP_SURVEY_MODE
   	'bound'		: goto, SKIP_BOUNDS
   	else		: goto, SKIP_DAY

  endcase

endif

;check some inputs
;-------------------------------------------------------
if keyword_set(probes) then sc = strlowcase(probes) ; quick change of variable name

vsc = ['a','b','c','d','e']
if not keyword_set(sc) then begin
  str_message = 'You did not enter a spacecraft into the program call.'
  dprint, str_message
  dprint,  "Valid inputs are: 'a','b','c','d','e'  (ie, sc='b')"
  thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = ' '
  error=1
  return
endif
if total(strmatch(vsc,strtrim(strlowcase(sc)))) gt 1 then begin
  str_message = 'This program is only designed to accept a single spacecraft as input.'
  dprint, str_message
  dprint,  "Valid inputs are: 'a','b','c','d','e'  (ie, sc='b')"
  thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = sc
  error=1
  return
endif
if total(strmatch(vsc,strtrim(strlowcase(sc)))) eq 0 then begin
  str_message = "The input sc= '" + strtrim(sc) + "' is not a valid input."
  dprint, str_message
  dprint,  "Valid inputs are: 'a','b','c','d','e'  (ie, sc='b')" 
  thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = sc
  error=1
  return
endif

if ~keyword_set(dur) then begin
  dprint, 'duration not input, setting dur = 1'
  dur = 1
endif
if (dur Lt 0) then begin
  dprint, 'Invalid duration, setting dur = 1'
  dur = 1
endif

if keyword_set(hours) then dur=dur/24.

if not keyword_set(date) then begin
  str_message = 'You did not enter a date into the program call.'
  dprint, str_message
  dprint, "Example: thm_gen_overplot,sc='b',date='2007-03-23'"
  thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = sc
  error=1
  return
endif else begin
  
  ; Expand start time (-1 hour) and duration (+2 hours)
  ; so that there are no gaps due to packets missing 
  ; at the beginning or the end of the time span 
  date_ext=time_string(time_double(date)-60*60D)
  dur_ext = dur + 2.0/24.0
  ;t0_ext = time_double(date_ext)  
 ; t1_ext = time_double(t0_ext + dur_ext*60D*60D*24D)
 
  t0 = time_double(date)
  t1 = t0+dur*60D*60D*24D
  
  if t1 lt time_double('2007-02-17/00:00:00') then begin
    str_message = 'Invalid time entered: '+ time_string(date)
    dprint, str_message
    thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = sc
    error=1
    return
  endif else if (t0 Gt systime(/seconds)) then begin
    str_message = 'Invalid time entered: '+ time_string(date)
    dprint, str_message
    thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = sc
    error=1
    return
  endif
endelse


valid_devices = ['cgm','hp','metafile','null','pcl','printer','ps','regis','tek','win','x','z']

if ~keyword_set(device) then begin
  help,/device,output=plot_device
  plot_device=strtrim(strlowcase(strmid(plot_device[1],24)),2)
  if plot_device eq 'z' then device, set_resolution = [750, 800]
endif else begin

  if ~in_set(strlowcase(device),valid_devices) then begin
    str_message = 'Device keyword has invalid value. Returning'
    dprint, str_message
    thm_gen_overplot_print, date = date, str_message=str_message, gui_plot=gui_plot, probes = sc
    error=1
    return
  endif  

  set_plot,device
  help,/device,output=plot_device
  plot_device=strtrim(strlowcase(strmid(plot_device[1],24)),2)
  if plot_device eq 'z' then device, set_resolution = [750, 800]
endelse

thx = 'th'+sc[0]                ;need a scalar for this

date=time_string(date)

if not keyword_set(dont_delete_data) then begin
  del_data, '*'                 ; give ourselves a clean slate
  clear_esa_common_blocks
  common data_cache_com, dcache
  dcache = ''
endif

timespan,date_ext,dur_ext

;load magnetic field fit data
;-----------------------------

load_position='fgm'

thm_load_state,probe=sc,/get_support
thm_load_fit,lev=1,probe=sc,/get_support

SKIP_FGM_LOAD:

;kluge to prevent missing data from crashing things
index_fit=where(thx+'_fgs' eq tnames())
index_state=where(thx+'_state_spinras' eq tnames())
if (index_fit[0] eq -1 or index_state[0] eq -1) then begin
  filler=fltarr(2,3)
  filler[*,*]=float('NaN')
  store_data,thx+'_fgs_gse',data={x:time_double(date_ext)+findgen(2),y:filler}
  ylim,thx+'_fgs_gse',-100,100,0
endif else begin
  thm_cotrans,thx+'_fgs',out_suf='_gse', in_c='dsl', out_c='gse'
;for recent FGS data, if there is an estimated Bz, put the Bz curve
;behind Bx and By. jmm, 2024-12-12
  If(sc[0] Eq 'e' And time_double(date) Ge time_double('2024-05-25')) Then Begin
     options, thx+'_fgs_gse', 'indices', [2,0,1]
;check for l1b data, if there is none yet, set Bz to NaN 
     If(~is_string(thm_l1b_check(date, sc[0]))) Then Begin
        get_data, thx+'_fgs_gse', data = btmp
        btmp.y[*, 2] = !values.f_nan
        store_data, thx+'_fgs_gse', data = btmp
     Endif
  Endif
endelse

;clip data
tclip, thx+'_fgs_gse', -100.0, 100.0, /overwrite
name = thx+'_fgs_gse'
options, name, 'ytitle', 'B FIT!CGSE!C[nT]'
options, name, 'labels', ['Bx', 'By', 'Bz']
options, name, 'labflag', 1
options, name, 'colors', [2, 4, 6]


;load FBK and FFT data, skip this if probe = 'a' and date past
;26-feb-2025, jmm, 19-May-2025, as EFI and SCM are turned off
;--------------

load_position='fbk'
If(sc Eq 'a') Then Begin
   If(time_double(date) Lt time_double('2025-02-26')) Then Begin
      thm_load_fbk,lev=1,probe=sc
      thm_load_fft,lev=1,probe=sc
   Endif
Endif Else Begin
   thm_load_fbk,lev=1,probe=sc
   thm_load_fft,lev=1,probe=sc
Endelse   

SKIP_FBK_LOAD:

del_data,thx+'_fb_h*'  ; del thx_fb_hff as it is not used and gets in the way later
fbk_tvars=tnames(thx+'_fb_*') ; this should give us two tplot variables (but sometimes more)
fft_tvars=tnames(thx+'_fff_*')

If(n_elements(fbk_tvars) Eq 1) Then fbk_tvars=[fbk_tvars,'filler']

For i=0,n_elements(fbk_tvars)-1 Do Begin
  ;kluge to prevent missing data from crashing things
  get_data,fbk_tvars[i],data=dd
  If(size(dd,/type) Ne 8) Then Begin
    filler = fltarr(2, 6)
    filler[*, *] = float('NaN')
    name = thx+'_fb_'+strcompress(string(i+1), /remove_all)
    store_data, name, data = {x:time_double(date_ext)+findgen(2), y:filler, v:findgen(6)}
    options, name, 'spec', 1
    ylim, name, 1, 1000, 1
    zlim, name, 0, 0, 1
  Endif Else Begin
    fbk_tmp = strsplit(fbk_tvars[i], '_', /extract)
    fbk_tmp = fbk_tmp[2] ;'edc12' or 'scm2' for example
    fbk_inst = strmid(fbk_tmp, 0, 3) ;'edc' or 'scm'
    store_data, fbk_tvars[i], data = {x:dd.x, y:dd.y, v:[2048., 512., 128., 32., 8., 2.]}
    options, fbk_tvars[i], 'spec', 1
    options, fbk_tvars[i], 'zlog', 1
    ylim, fbk_tvars[i], 2.0, 2048.0, 1
    thm_spec_lim4overplot, fbk_tvars[i], ylog = 1, zlog = 1, /overwrite
    options, fbk_tvars[i], 'ytitle', 'FBK!C'+strmid(fbk_tvars[i], 7) +'!C[Hz]'
;for ztitle, we need to figure out which type of data is there
;      for V channels, <|V|>.
;      for E channels, <|mV/m|>.
;      for SCM channels, <|nT|>.
    x1 = strpos(fbk_tvars[i], 'scm')
    If(x1[0] Ne -1) Then Begin
      options, fbk_tvars[i], 'ztitle', '<|nT|>'
;reset the upper value of zlimit to 2.0, jmm, 30-nov-2007
      get_data, fbk_tvars[i], data = d
      If(is_struct(d)) Then zlim,  fbk_tvars[i], min(d.y), 2.0, 1
    Endif
    xv = strpos(fbk_tvars[i], 'v')
    If(xv[0] Ne -1) Then Begin
       options, fbk_tvars[i], 'ztitle', '<|V|>'
    Endif
    xe = strpos(fbk_tvars[i], 'e')
    If(xe[0] Ne -1) Then Begin
      options, fbk_tvars[i], 'ztitle', '<|mV/m|>'
;reset the upper value of zlimit to 2.0, jmm, 30-nov-2007
      get_data, fbk_tvars[i], data = d
      If(is_struct(d)) Then zlim,  fbk_tvars[i], min(d.y), 2.0, 1
    Endif
  Endelse
;degap, jmm, 2017-02-13
  tdegap, fbk_tvars[i], /overwrite, dt = 600.0
;Replace FBK with FFF data, if possible, for THD since 1-jan-2023
;only for edc or scm data
  If(sc[0] Eq 'd' And time_double(date) Ge time_double('2023-01-01')) Then Begin
     fft_use = ''
     If(is_string(fft_tvars)) Then Begin
        match0 = where(strmatch(fft_tvars, '*'+fbk_tmp))
        If(match0[0] Ne -1) Then fft_use = fft_tvars[match0[0]] Else Begin
;try for a match for a different axis, e.g., 'scm2' rather than 'scm1'
           match1 = where(strmatch(fft_tvars, '*'+fbk_inst+'*'))
           If(match1[0] Ne -1) Then Begin
              If(fbk_inst Eq 'edc') Then Begin
                 fft_use = fft_tvars[match1[0]]
              Endif Else If(fbk_inst Eq 'scm') Then Begin ;use scm3 preferentially
                 match2 = where(strmatch(fft_tvars, '*scm3'))
                 If(match2[0] Ne -1) Then fft_use = fft_tvars[match2[0]] $
                 Else fft_use = fft_tvars[match1[0]]
              Endif
           Endif ;if no match to 'edc' or 'scm', then do nothing
        Endelse
     Endif
     If(is_string(fft_use)) Then Begin
        If(fbk_inst Eq 'edc') Then scale = 100 Else scale = 0
        fbk_tvars[i] = thm_ffffbk_composite(fft_use, fbk_tvars[i], scale = scale)
;replace zero values with NaN
        get_data, fbk_tvars[i], data = dd
        zv = where(dd.y Eq 0, nzv)
        If(nzv Gt 0) Then dd.y[zv] = !values.f_nan
        store_data, fbk_tvars[i], data = temporary(dd)
;Set limits after setting zero values to NaN
        thm_spec_lim4overplot, fbk_tvars[i], ylog = 1, zlog = 1, /overwrite
        zlim,  fbk_tvars[i], 2.0e-4, 2.0, 1
        get_data, fbk_tvars[i], data = d
        options, fbk_tvars[i], 'spec', 1
        options, fbk_tvars[i], 'zlog', 1
        options, fbk_tvars[i], 'ytitle', 'FBK-FFF!C[Hz]'
        x1 = strpos(fbk_tvars[i], 'scm')
        If(x1[0] Ne -1) Then options, fbk_tvars[i], 'ztitle', 'FBK-|nT|!C!CFFF-|nT|'
        xe = strpos(fbk_tvars[i], 'e')
        If(xe[0] Ne -1) Then options, fbk_tvars[i], 'ztitle', 'FBK-|mV/m|!C!CFFF-100|mV/m|'
     Endif
     ylim, fbk_tvars[i], 9.0, 4096.0, 1
  Endif
Endfor

;load SST spectrograms
;----------------------

load_position='sst'
thm_load_sst, probe = sc, level = 'l2'
;If Level 2 data didn't show up, check for L1
index_sst_e = where(thx+'_psef_en_eflux' eq tnames())
index_sst_i = where(thx+'_psif_en_eflux' eq tnames())
if(index_sst_e[0] eq -1 Or index_sst_i[0] Eq -1) then begin
  thm_load_sst2, probe = sc, level = 'l1'
  thm_part_moments, probe = sc, instrument = ['psif', 'psef'], $
    moments = ['density', 'velocity', 't3'], method_clean='automatic'
endif

SKIP_SST_LOAD:
;kluge to prevent missing data from crashing things
index_sst=where(thx+'_psif_en_eflux' eq tnames())
if index_sst eq -1 then begin
  filler = fltarr(2, 16)
  filler[*,*]=float('NaN')
  store_data, thx+'_psif_en_eflux', $
    data = {x:time_double(date_ext)+findgen(2)*86400., y:filler, v:findgen(16)}
  name = thx+'_psif_en_eflux'
  options, name, 'spec', 1
  ylim, name, 1, 1000, 1
  zlim, name, 1d1, 5d2, 1
  options, name, 'ytitle', 'SST!Cions!C[eV]'
  options, name, 'ysubtitle', ''
;  options, name, 'ztitle', 'Eflux !C eV/cm!U2!N!C-s-sr-eV'
  options, name, 'ztitle', 'Eflux, EFU'
endif else begin
;SST ion panel
  name = thx+'_psif_en_eflux'
  tdegap, name, /overwrite, dt = 600.0
  options, name, 'spec', 1
  options, name, 'ytitle', 'SST!Cions!C[eV]'
  options, name, 'ysubtitle', ''
;  options, name, 'ztitle', 'Eflux !C eV/cm!U2!N!C-s-sr-eV'
  options, name, 'ztitle', 'Eflux, EFU'
  options, name, 'y_no_interp', 1
  options, name, 'x_no_interp', 1
  zlim, name, 1d1, 5d2, 1
endelse
index_sst = where(thx+'_psef_en_eflux' eq tnames())
if index_sst eq -1 then begin
  filler = fltarr(2, 16)
  filler[*, *] = float('NaN')
  store_data, thx+'_psef_en_eflux', $
    data = {x:time_double(date_ext)+findgen(2), y:filler, v:findgen(16)}
  name = thx+'_psef_en_eflux'
  options, name, 'spec', 1
  ylim, name, 1, 1000, 1
  zlim, name, 1d1, 5d2, 1
  options, name, 'ytitle', 'SST!Celec!C[eV]'
  options, name, 'ysubtitle', ''
;  options, name, 'ztitle', 'Eflux !C eV/cm!U2!N!C-s-sr-eV'
  options, name, 'ztitle', 'Eflux, EFU'
endif else begin
;SST electron panel
  name = thx+'_psef_en_eflux'
  tdegap, name, /overwrite, dt = 600.0
  options, name, 'spec', 1
  options, name, 'ytitle', 'SST!Celec!C[eV]'
  options, name, 'ysubtitle', ''
;  options, name, 'ztitle', 'Eflux !C eV/cm!U2!N!C-s-sr-eV'
  options, name, 'ztitle', 'Eflux, EFU'
  options, name, 'y_no_interp', 1
  options, name, 'x_no_interp', 1
  zlim, name, 1d1, 5d2, 1
endelse

;load ESA spectrograms and moments
;----------------------------------
load_position='esa'
;load both full and reduced data:
mtyp = ['f', 'r']
ok_esai_flux = bytarr(2)
ok_esae_flux = bytarr(2)
ok_esai_moms = bytarr(2)
ok_esae_moms = bytarr(2)
For j = 0, 1 Do Begin
  thm_load_esa, probe = sc, datatype = 'pe?'+mtyp[j]+'*', level = 'l2'
  itest = thx+'_pei'+mtyp[j]
  etest = thx+'_pee'+mtyp[j]
;If Level 2 data didn't show up, check for L1
  index_esa_e_en = where(etest+'_en_eflux' eq tnames())
  index_esa_e_d = where(etest+'_density' eq tnames())
  index_esa_e_v = where(etest+'_velocity_dsl' eq tnames())
  index_esa_e_t = where(etest+'_t3' eq tnames())

  index_esa_i_en = where(itest+'_en_eflux' eq tnames())
  index_esa_i_d = where(itest+'_density' eq tnames())
  index_esa_i_v = where(itest+'_velocity_dsl' eq tnames())
  index_esa_i_t = where(itest+'_t3' eq tnames())

  if(index_esa_e_en[0] eq -1 Or index_esa_i_en[0] Eq -1) then begin
    thm_load_esa_pkt, probe = sc
    thm_load_esa_pot, probe = sc
    instr_all = ['pei'+mtyp[j], 'pee'+mtyp[j]]
    for k = 0, 1 do begin
      test_index = where(thx+'_'+instr_all[k]+'_en_counts' eq tnames())
      If(test_index[0] Ne -1) Then Begin
        thm_part_moments, probe = sc, instrument = instr_all[k], $
          moments = '*'
        copy_data, thx+'_'+instr_all[k]+'_velocity', $
          thx+'_'+instr_all[k]+'_velocity_dsl'
     Endif
    endfor
    index_esa_e_en = where(etest+'_en_eflux' eq tnames())
    index_esa_e_d = where(etest+'_density' eq tnames())
    index_esa_e_v = where(etest+'_velocity_dsl' eq tnames())
    index_esa_e_t = where(etest+'_t3' eq tnames())
    
    index_esa_i_en = where(itest+'_en_eflux' eq tnames())
    index_esa_i_d = where(itest+'_density' eq tnames())
    index_esa_i_v = where(itest+'_velocity_dsl' eq tnames())
    index_esa_i_t = where(itest+'_t3' eq tnames())
  endif
  if index_esa_i_en[0] eq -1 then begin
    filler = fltarr(2, 32)
    filler[*, *] = float('Nan')
    name1 = itest+'_en_eflux'
    store_data, name1, data = {x:time_double(date_ext)+findgen(2), y:filler, v:findgen(32)}
    zlim, name1, 1d3, 7.5d8, 1
    ylim, name1, 3., 40000., 1
;    options, name1, 'ztitle', 'Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
    options, name1, 'ztitle', 'Eflux, EFU'
    options, name1, 'ytitle', 'ESA!Cions!C[eV]'
    options, name1, 'ysubtitle', ''
    options, name1, 'spec', 1
  endif else begin
    name1 = itest+'_en_eflux'
    tdegap, name1, /overwrite, dt = 600.0
    zlim, name1, 1d3, 7.5d8, 1
    ylim, name1, 3., 40000., 1
;    options, name1, 'ztitle', 'Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
    options, name1, 'ztitle', 'Eflux, EFU'
    options, name1, 'ytitle', 'ESA!Cions!C[eV]'
    options, name1, 'ysubtitle', ''
    options, name1, 'spec', 1
    options, name1, 'x_no_interp', 1
    options, name1, 'y_no_interp', 1
    ok_esai_flux[j] = 1
  endelse

  if index_esa_i_d[0] eq -1 then begin
    filler = fltarr(2)
    filler[*] = float('Nan')
    store_data, itest+'_density', data = {x:time_double(date_ext)+findgen(2), y:filler}
;    options, itest+'_density', 'ytitle', 'Ni '+thx+'!C!C1/cm!U3'
    options, itest+'_density', 'ytitle', 'Ni'
  endif else begin
    name1 = itest+'_density'
    tdegap, name1, /overwrite, dt = 600.0
    options, name1, 'ytitle', 'Ni'
    ok_esai_moms[j] = 1
  endelse

  if index_esa_i_v[0] eq -1 then begin
    filler = fltarr(2, 3)
    filler[*, *] = float('Nan')
    store_data, itest+'_velocity_dsl', data = {x:time_double(date_ext)+findgen(2), y:filler}
    options, itest+'_velocity_dsl', 'ytitle', 'VI!C[km/s]'
    options, itest+'_velocity_dsl', 'ysubtitle', ''
  endif else begin
    name1 = itest+'_velocity_dsl'
    tdegap, name1, /overwrite, dt = 600.0
    itstrg=[t0,t1]
    get_ylimits, name1, itslimits, itstrg
    minmaxvals=itslimits.yrange
    maxvel=max(abs(minmaxvals))
    maxlim=min([maxvel,2000.])
    minlim=0.-maxlim
    if maxvel le 100. then ylim, name1, -50,50,0 else ylim, name1, minlim, maxlim, 0
    options, name1, 'colors', [2, 4, 6]
    options, name1, 'labflag', 1
    options, name1, 'ytitle', 'VI!C[km/s]'
    options, name1, 'ysubtitle', ''
;;    options, name1, labels = ['Vi!dx!n', 'Vi!dy!n', 'Vi!dz!n'], constant = 0.
    options, name1, labels = ['VIx', 'VIy', 'VIz'], constant = 0.
  endelse

  if index_esa_i_t[0] eq -1 then begin
    filler = fltarr(2, 3)
    filler[*, *] = float('Nan')
    store_data, itest+'_t3', data = {x:time_double(date_ext)+findgen(2), y:filler}

    name1 = itest+'_t3'
    tdegap, name1, /overwrite, dt = 600.0
    ylim, name1, .1, 9999, 1
    options, name1, 'colors', [2, 4, 6, 0]
    options, name1, 'ytitle', 'Ti!C[eV]'
    options, name1, 'ysubtitle', ''

  endif else begin
    name1 = itest+'_t3'
    tdegap, name1, /overwrite, dt = 600.0
    ylim, name1, .1, 9999, 1
    options, name1, 'colors', [2, 4, 6, 0]
    options, name1, 'ytitle', 'Ti!C[eV]'
    options, name1, 'ysubtitle', ''
  endelse
  
  index_esa_e_en = where(etest+'_en_eflux' eq tnames())
  if index_esa_e_en[0] eq -1 then begin
    filler = fltarr(2, 32)
    filler[*, *] = float('Nan')
    name1 = etest+'_en_eflux'
    store_data, name1, data = {x:time_double(date_ext)+findgen(2), y:filler, v:findgen(32)}
    zlim, name1, 1d4, 7.5d8, 1
    ylim, name1, 3., 40000., 1
;    options, name1, 'ztitle', 'Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
    options, name1, 'ztitle', 'Eflux, EFU'
    options, name1, 'ytitle', 'ESA!Celec!C[eV]'
    options, name1, 'ysubtitle', ''
    options, name1, 'spec', 1
  endif else begin 
    name1 = etest+'_en_eflux'
    tdegap, name1, /overwrite, dt = 600.0
    zlim, name1, 1d4, 7.5d8, 1
    ylim, name1, 3., 40000., 1
;    options, name1, 'ztitle', 'Eflux !C!C eV/cm!U2!N!C-s-sr-eV'
    options, name1, 'ztitle', 'Eflux, EFU'
    options, name1, 'ytitle', 'ESA!Celec!C[eV]'
    options, name1, 'ysubtitle', ''
    options, name1, 'spec', 1
    options, name1, 'x_no_interp', 1
    options, name1, 'y_no_interp', 1
    ok_esae_flux[j] = 1
  endelse

  if index_esa_e_d[0] eq -1 then begin
    filler = fltarr(2)
    filler[*] = float('Nan')
    store_data, etest+'_density', data = {x:time_double(date_ext)+findgen(2), y:filler}
;    options, etest+'_density', 'ytitle', 'Ne '+thx+'!C!C1/cm!U3'
    options, etest+'_density', 'ytitle', 'Ne!C[1/cc]'
    options, etest+'_density', 'ysubtitle', ''
no_npot:
    filler = fltarr(2)
    filler[*] = float('Nan')
    store_data, etest+'_density_npot', data = {x:time_double(date_ext)+findgen(2), y:filler}
    options, etest+'_density_npot', 'ytitle', 'Ne!C[1/cc]'
    options, etest+'_density_npot', 'ysubtitle', ''
  endif else begin 
    name1 = etest+'_density'
;    options, name1, 'ytitle', 'Ne '+thx+'!C!C1/cm!U3'
    options, name1, 'ytitle', 'Ne!C[1/cc]'
    options, name1, 'ysubtitle', ''
    ok_esae_moms[j] = 1
;For THE, post 2022-09-22, calculate calculate n_opt using 'peem'
;data, and EESa data
    IF(sc Eq 'e' AND time_double(date) Gt time_double('2022-09-22')) THEN BEGIN
       thm_scpot2dens_opt_n, probe = sc, datatype_esa = 'peem'
    ENDIF ELSE BEGIN
;Npot calculation, 2009-10-12, jmm
       thm_scpot2dens_opt_n, probe = sc, /no_data_load, datatype_esa = 'pee'+mtyp[j]
    ENDELSE
;degap after npot calculation
    tdegap, name1, /overwrite, dt = 600.0
    name1x = tnames(etest+'_density_npot')
    get_data, name1x, data = npot_test
    If(is_struct(temporary(npot_test)) Eq 0) Then Goto, no_npot
    tdegap, name1x, /overwrite, dt = 600.0
    options, name1x, 'ytitle', 'Ne!C[1/cc]'
    options, name1x, 'ysubtitle', ''
  endelse

  if index_esa_e_v[0] eq -1 then begin
    filler = fltarr(2, 3)
    filler[*, *] = float('Nan')
    store_data, etest+'_velocity_dsl', data = {x:time_double(date_ext)+findgen(2), y:filler}
;    options, etest+'_velocity_dsl', 'ytitle', 'Ve '+thx+'!C!Ckm/s'
    options, etest+'_velocity_dsl', 'ytitle', 'VE!C[km/s]'
    options, etest+'_velocity_dsl', 'ysubtitle', ''
  endif else begin
    name1 = etest+'_velocity_dsl'
    tdegap, name1, /overwrite, dt = 600.0
    ylim, name1, -500, 200., 0
;    options, name1, 'ytitle', 'Ve '+thx+'!C!Ckm/s'
    options, name1, 'ytitle', 'VE!C[km/s]'
    options, name1, 'ysubtitle', ''
  endelse

  if index_esa_e_t[0] eq -1 then begin
    filler = fltarr(2, 3)
    filler[*, *] = float('Nan')
    store_data, etest+'_t3', data = {x:time_double(date_ext)+findgen(2), y:filler}
    options, etest+'_t3', 'ytitle', 'Te!C[eV]'
    options, etest+'_t3', 'ysubtitle', ''
  endif else begin
  ;options,name1,'colors',[cols.blue,cols.green,cols.red]
;    options, name1, labels = ['V!dex!n', 'V!dey!n', 'V!dez!n'], constant = 0.
    name1 = etest+'_t3'
    tdegap, name1, /overwrite, dt = 600.0
    options, name1, labels = ['TEx', 'TEy', 'TEz'], constant = 0.
    ylim, name1, 10, 10000., 1
    options, name1, 'colors', [2, 4, 6]
    options, name1, 'ytitle', 'TE!C[eV]'
    options, name1, 'ysubtitle', ''
  endelse

; plot quantities (manipulating the plot quantities for the sake of plot aesthetics)
; kluge for labeling the density, added Npot, 2009-10-12, jmm
  get_data, etest+'_density', data = d
  get_data, etest+'_density_npot', data = d1
  Ne_kluge_name = 'Ne_'+etest+'_kluge'
  If(n_elements(d1.x) Eq n_elements(d.x)) Then Begin
    dummy = fltarr(n_elements(d.y), 3)
    dummy[*, 0] = d1.y
    dummy[*, 1] = d.y
    dummy[*, 2] = d.y
    dummy = dummy > 0.001       ;electrons
    store_data, Ne_kluge_name, data = {x:d.x, y:dummy}
    options, Ne_kluge_name, labels = ['Npot', 'Ni', 'Ne']
    options, Ne_kluge_name, colors = [2, 0, 6]
    options, Ne_kluge_name, 'labflag', 1
  Endif Else Begin
    dummy = fltarr(n_elements(d.y), 2)
    dummy[*, 0] = d.y
    dummy[*, 1] = d.y
    dummy = dummy > 0.001       ;electrons
    store_data, Ne_kluge_name, data = {x:d.x, y:dummy}
    options, Ne_kluge_name, labels = ['Ni', 'Ne']
    options, Ne_kluge_name, colors = [0, 6]
    options, Ne_kluge_name, 'labflag', 1
  Endelse
; Set plot limits here, 2018-03-06, jmm
;  get_data, itest+'_density', data=di0 ;ions
;  if is_struct(di0) then begin
;     nmaxi = max(di0.y, /nan) < 1.0e8
;     undefine, di0
;     ylim, itest+'_density', 0.001, nmax, 1
;  endif else nmaxi = -1.0
;Set plot limit max to 1.0e2
;  nmaxe = max(dummy, /nan) < 1.0e8
;  nmax = max([nmaxi, nmaxe])
  nmax = 1.0e2
  options, Ne_kluge_name, 'yrange', [0.001, nmax]
  options, Ne_kluge_name, 'ylog', 1
  store_data, thx+'_Nie'+mtyp[j], data = [itest+'_density', Ne_kluge_name]
;  options, thx+'_Nie'+mtyp[j], 'ytitle', 'Ni,e '+thx+'!C1/cm!U3'
;  options, thx+'_Nie'+mtyp[j], 'ytitle', 'Ni,e '+thx
  options, thx+'_Nie'+mtyp[j], 'ytitle', 'Ni!Celec!C[1/cc]'
  options, thx+'_Nie'+mtyp[j], 'ysubtitle', ''
  options, thx+'_Nie'+mtyp[j], 'yrange', [0.001, nmax]
  options, thx+'_Nie'+mtyp[j], 'ystyle', 1
  options, thx+'_Nie'+mtyp[j], 'ylog', 1
  
;
  nameti=itest+'_t3'
  namete=etest+'_t3'
  store_data, thx+'_Tie'+mtyp[j], data = [nameti,namete]
  options, thx+'_Tie'+mtyp[j], 'ytitle', 'Ti!Celec!C[eV]'
  options, thx+'_Tie'+mtyp[j], 'ysubtitle', ''
  ylim, thx+'_Tie'+mtyp[j], .1, 9999, 1

  If(gui_plot eq 1) Then Begin
     options,nameti,'labels',['Ti prp',' ', 'Ti ||'] ;fix for GUI, fixing compound variable does not work
     options,namete,'labels',['Te prp',' ', 'Te ||']
     options,nameti, 'colors', [2, 2, 4]
     options,namete, 'colors', [6, 6, 0]
  Endif Else Begin
     options,nameti,'labels',['Ti!9'+string(120B)+'!X',' ','Ti!9'+string(35B)+'!X']
     options,namete,'labels',['Te!9'+string(120B)+'!X',' ','Te!9'+string(35B)+'!X']
     options,nameti, 'colors', [2, 2, 4]
     options,namete, 'colors', [6, 6, 0]
  Endelse
  options, thx+'_Tie'+mtyp[j], 'labflag', 1
Endfor
SKIP_ESA_LOAD:

; load gmag data
;----------------

load_position='gmag'


SKIP_GMAG_LOAD:

; load ASK data and plot 3 specific ones (can be changed)
;---------------------------------------------------------

load_position='asi'

thm_load_ask, /verbose

SKIP_ASI_LOAD:

asi_sites = tnames('*ask*')
filler = fltarr(2, 10)          ; (10 chosen arbitrarily)
filler[*, *] = float('NaN')
;2020-03-24, FSIM, FSMI, RANK, SNKQ checked in that order
test_sites = tnames('thg_ask_'+['fsim', 'fsmi', 'rank', 'snkq'])
other_sites = ssl_set_complement(test_sites, asi_sites)
If(~is_string(other_sites)) Then other_sites = '' ;protect against low-probability
asi_sites = [test_sites, other_sites]
;check sites for good data in order
have_keogram = 0b
If(is_string(asi_sites)) Then Begin
   For ksite = 0, n_elements(asi_sites)-1 Do Begin
      If(~have_keogram) Then Begin
         get_data, asi_sites[ksite], data = askd
         If(is_struct(askd)) Then Begin
            copy_data, asi_sites[ksite], 'Keogram'
            ask_site = strmid(asi_sites[ksite], 8)
            options, 'Keogram', 'ytitle', 'Keogram'
            options, 'Keogram', 'ysubtitle', ask_site
            have_keogram= 1b
            undefine, askd
            break               ;out of loop
         Endif
      Endif
   Endfor
Endif
If(~have_keogram) Then Begin ;for no data at any site
   store_data, 'Keogram', data = {x:time_double(date_ext)+findgen(2), y:filler, v:findgen(10)}
   options, 'Keogram', 'ytitle', 'Keogram'
   options, 'Keogram', 'ysubtitle', ''
   have_keogram = 0b
Endif
;remove all time steps for which all y values are fill= 65335, then degap
if have_keogram then begin
   get_data, 'Keogram', data = kd
   nkd = n_elements(kd.x)
   nyd = n_elements(kd.y[0, *])
   drop_kd = bytarr(nkd)
   for j = 0, nkd-1 do begin
      jkd_test = where(kd.y[j, *] eq 65535, njkd_test)
      if njkd_test eq nyd then drop_kd[j] = 1b
   endfor
   keep_data = where(drop_kd eq 0, nkeep_data)
   if nkeep_data gt 0 then begin
      store_data, 'Keogram', data = {x:kd.x[keep_data], y:float(kd.y[keep_data,*])}
      tdegap, 'Keogram', dt = 120.0, /twonanpergap, /overwrite
   endif else begin
      store_data, 'Keogram', data = {x:time_double(date_ext)+findgen(2), y:filler, v:findgen(10)}
   endelse
endif   

; Get position info
;---------------------------------------------------------

load_position='mode'

thm_cotrans,thx+'_state_pos',out_suf='_gse',out_coord='gse'
get_data, thx+'_state_pos_gse',data=tmp

if is_struct(tmp) then begin
  store_data,thx+'_state_pos_gse_x',data={x:tmp.x,y:tmp.y[*,0]/6371.2}
	  options,thx+'_state_pos_gse_x','ytitle','X-GSE'
  store_data,thx+'_state_pos_gse_y',data={x:tmp.x,y:tmp.y[*,1]/6371.2}
	  options,thx+'_state_pos_gse_y','ytitle','Y-GSE'
  store_data,thx+'_state_pos_gse_z',data={x:tmp.x,y:tmp.y[*,2]/6371.2}
  	options,thx+'_state_pos_gse_z','ytitle','Z-GSE'
endif else begin
  dprint,'No state gse data found'
;  store_data,thx+'_state_pos_gse_x',data={x:time_double(date)+dindgen(2), y:replicate(!values.d_nan,2)}
;  store_data,thx+'_state_pos_gse_y',data={x:time_double(date)+dindgen(2), y:replicate(!values.d_nan,2)}
;  store_data,thx+'_state_pos_gse_z',data={x:time_double(date)+dindgen(2), y:replicate(!values.d_nan,2)}
endelse
 
SKIP_POS_LOAD:

load_position='mode'

; make tplot variable tracking the sample rate (0=SS,1=FS,2=PB,3=WB)
;-------------------------------------------------------------------
sample_rate_var = thm_sample_rate_bar(date, dur, sc, /outline)
options, sample_rate_var,'ytitle',''
If(gui_plot) Then Begin ;try degapping wave and particle burst bars
  tdegap, 'particle_burst_bar_'+sc, /overwrite, dt = 30.0, /twonan
  tdegap, 'particle_burst_sym_'+sc, /overwrite, dt = 30.0, /twonan
  tdegap, 'wave_burst_bar_'+sc, /overwrite, dt = 10.0, /twonan
  tdegap, 'wave_burst_sym_'+sc, /overwrite, dt = 10.0, /twonan
Endif 


SKIP_SURVEY_MODE:
load_position='bound'

; final tplot preparations
;--------------------------

load_position='plot'

;set the low limit of the ESA en_eflux variables to be the lower limit
;of either the ion or electron energies
esa_instr = ['f', 'r']
For j = 0, 1 Do Begin
   ivar = thx+'_pei'+esa_instr[j]+'_en_eflux'
   evar = thx+'_pee'+esa_instr[j]+'_en_eflux'
   thm_esa_lim4overplot, ivar, [t0, t1], zlog = 1, ylog = 1, /overwrite
   thm_esa_lim4overplot, evar, [t0, t1], zlog = 1, ylog = 1, /overwrite
;thm_esa_lim4overplot overrides any z-axis min/max with
;the min/max of the data if zeros are found, so reset zlimits
   zlim, ivar, 1d3, 7.5d8, 1
   zlim, evar, 1d4, 7.5d8, 1
Endfor

ssti_name=thx+'_psif_en_eflux'
sste_name=thx+'_psef_en_eflux'
thm_spec_lim4overplot, ssti_name, zlog = 1, ylog = 1, /overwrite
thm_spec_lim4overplot, sste_name, zlog = 1, ylog = 1, /overwrite
zlim, ssti_name, 1d0, 5d7, 1
zlim, sste_name, 1d0, 5d7, 1

SKIP_BOUNDS:

tplot_options, 'lazy_ytitle', 0 ; prevent auto formatting on ytitle (namely having carrage returns at underscores)


roi_bar = thm_roi_bar(thx+'_state_roi')

!p.background=255.
!p.color=0.
time_stamp,/off
loadct2,43
!p.charsize=0.6

probes_title = ['P5',  'P1',  'P2',  'P3', 'P4']
scv = strcompress(strlowcase(sc[0]),/remove_all)
pindex = where(vsc Eq scv) ;this is always true for one probe by the time we are here
tplot_options,'ygap',0.0D

;For esa data we would like to plot full mode if possible, but reduced
;mode if no full mode is available, Also do scpot_overlay here, jmm,
;2013-09-10
esa_peif_overlay = thx+'_peif_en_eflux'
esa_peir_overlay = thx+'_peir_en_eflux'
esa_peef_overlay = scpot_overlay(thx+'_peef_sc_pot', thx+'_peef_en_eflux', sc_line_thick=2.0, /use_yrange)
esa_peer_overlay = scpot_overlay(thx+'_peer_sc_pot', thx+'_peer_en_eflux', sc_line_thick=2.0, /use_yrange)

;use either peif or peir data, depending on which has better coverage,
;jmm, 2016-06-09
If(ok_esai_flux[0] Eq 1 And ok_esai_flux[1] Eq 0) Then Begin
   esaif_flux_name = esa_peif_overlay
Endif Else If(ok_esai_flux[0] Eq 0 And ok_esai_flux[1] Eq 1) Then Begin
   esaif_flux_name = esa_peir_overlay
Endif Else If(ok_esai_flux[0] Eq 1 And ok_esai_flux[1] Eq 1) Then Begin
   ;choose the longer time range for plot variable
   get_data, thx+'_peif_en_eflux', data = df
   get_data, thx+'_peir_en_eflux', data = dr
   dtf = max(df.x)-min(df.x)
   dtr = max(dr.x)-min(dr.x)
   If(dtf ge dtr) Then esaif_flux_name = esa_peif_overlay $
   Else esaif_flux_name = esa_peir_overlay
   undefine, df, dr
Endif Else Begin
   ;No data for either, so use peif dummy
   esaif_flux_name = esa_peif_overlay
Endelse
;electrons
If(ok_esae_flux[0] Eq 1 And ok_esae_flux[1] Eq 0) Then Begin
   esaef_flux_name = esa_peef_overlay
Endif Else If(ok_esae_flux[0] Eq 0 And ok_esae_flux[1] Eq 1) Then Begin
   esaef_flux_name = esa_peer_overlay
Endif Else If(ok_esae_flux[0] Eq 1 And ok_esae_flux[1] Eq 1) Then Begin
   ;choose the longer time range for plot variable
   get_data, thx+'_peef_en_eflux', data = df
   get_data, thx+'_peer_en_eflux', data = dr
   dtf = max(df.x)-min(df.x)
   dtr = max(dr.x)-min(dr.x)
   If(dtf ge dtr) Then esaef_flux_name = esa_peef_overlay $
   Else esaef_flux_name = esa_peer_overlay
   undefine, df, dr
Endif Else Begin
   ;No data for either, so use peef dummy
   esaef_flux_name = esa_peef_overlay
Endelse
   
esaif_v_name = thx+'_peif_velocity_dsl'
If(ok_esai_moms[0] Eq 0) Then Begin
  If(ok_esai_moms[1]) Then esaif_v_name = thx+'_peir_velocity_dsl'
Endif

esaef_v_name = thx+'_peef_velocity_dsl'
If(ok_esae_moms[0] Eq 0) Then Begin
  If(ok_esae_moms[1]) Then esaef_v_name = thx+'_peer_velocity_dsl'
Endif
esaf_t_name = thx+'_Tief'       ;T and N are done for ions, electrons together
esaf_n_name = thx+'_Nief'
If(ok_esai_moms[0] Eq 0) Then Begin
  If(ok_esai_moms[1]) Then Begin
    esaf_t_name = thx+'_Tier'
    esaf_n_name = thx+'_Nier'
  Endif
Endif

;; Panel 1: Kyoto and THEMIS AE
spd_gen_overplot_ae_panel

vars_full = ['kyoto_thm_combined_ae', roi_bar, 'Keogram', thx+'_fgs_gse', $
             esaf_n_name, esaif_v_name, esaf_t_name, sample_rate_var, $
             ssti_name, esaif_flux_name, sste_name,  $
             esaef_flux_name, fbk_tvars[0], fbk_tvars[1], thx+'_pos_gse_z']

if (gui_plot eq 1) then begin ; for GUI plots we have some differences 
    title = probes_title[pindex[0]] + ' (TH-'+strupcase(sc)+')'
    tplot_options, 'title', title
    tplot_options, 'ymargin', [3,5]
    
;parallel and perpendicular components: select simple label to avoid
;font problems, does not work, jmm, 2018-10-09
    
;    options, esaf_t_name, labels=  ['Ti ||', 'Ti per', 'Te ||', 'Te per']
;    options, esaf_t_name, 'colors', [4, 2, 0, 6]
    
    ; For GUI panels, panel arrangement and height is determined by rows,
    ;   for example: panel_settings->setProperty, row=current_row, rSpan=2
    ;   for this to work we have to delete the 'panel_size' variable
    get_data,sample_rate_var,limit=l
    str_element,l,'panel_size',/delete ;panel sizing handled using different method in gui overview plots
    store_data,sample_rate_var,limit=l
   
    get_data,roi_bar,data=ppp,limit=l ;the ROI bar has to be transormed
    If(is_struct(ppp)) Then Begin
        bits2,ppp.y,new_bar ;the extracts the bit values into a bytarr of 16xntimes
        nbv=n_elements(new_bar[*,0])
        nxv=n_elements(ppp.x)
        new_bar=rebin(1+bindgen(nbv), nbv, nxv)*new_bar ;this assigns each non-zero bit the value equal to its bit number
        new_bar=float(new_bar)  ;to allow for NaN's to plot correctly
        zerov=where(new_bar Eq 0,nzerov)
        If(nzerov Gt 0) Then new_bar[zerov]=!values.f_nan
        str_element,ppp,'y',transpose(new_bar),/add_replace ;need transpose to make it ntimesX16
        str_element,l,'panel_size', /delete  ;panel sizing handled using different method in gui overview plots
        store_data,roi_bar,data=ppp,limit=l
        options,roi_bar,tplot_routine='mplot' ;reset this for testing
    Endif Else Begin
        filler=fltarr(2,16)
        filler[*,*]=float('NaN')
        store_data,thx+'_roi_bar',data={x:time_double(date_ext)+findgen(2),y:filler}
        roi_bar=thx+'_roi_bar'
    Endelse
    
    timespan,date,dur
    tplot_gui,vars_full,trange=[t0,t1],/no_verify,/no_update,/add_panel,no_draw=keyword_set(no_draw), $
      var_label = [thx+'_state_pos_gse_x', thx+'_state_pos_gse_y', thx+'_state_pos_gse_z']

endif else begin
  ;for server plots
   timespan,date,dur
   tplot_options, 'xmargin', [14,16]
   tplot, vars_full,trange=[t0,t1], title = probes_title[pindex[0]]+' (TH-'+strupcase(sc)+')', $
    var_label = [thx+'_state_pos_gse_z', thx+'_state_pos_gse_y', thx+'_state_pos_gse_x']
endelse

; make pngs
;-----------
;there are three different types of png plots, the 24hr will include
;full mode, the 6hr and 2hr plots will contain reduced mode, if there
;is reduced data.
if keyword_set(makepng) then begin
  esair_flux_name = esa_peir_overlay
  If(ok_esai_flux[1] Eq 0) Then Begin
    If(ok_esai_flux[0]) Then esair_flux_name = esa_peif_overlay
  Endif
  esair_v_name = thx+'_peir_velocity_dsl'
  If(ok_esai_moms[1] Eq 0) Then Begin
    If(ok_esai_moms[0]) Then esair_v_name = thx+'_peif_velocity_dsl'
  Endif
  esaer_flux_name = esa_peer_overlay
  If(ok_esae_flux[1] Eq 0) Then Begin
    If(ok_esae_flux[0]) Then esaer_flux_name = esa_peef_overlay
  Endif
  esaer_v_name = thx+'_peer_velocity_dsl'
  If(ok_esae_moms[1] Eq 0) Then Begin
    If(ok_esae_moms[0]) Then esaer_v_name = thx+'_peef_velocity_dsl'
  Endif
  esar_t_name = thx+'_Tier' ;T and N are done for ions, electrons together
  esar_n_name = thx+'_Nier'
  If(ok_esai_moms[1] Eq 0) Then Begin
    If(ok_esai_moms[0]) Then Begin
      esar_t_name = thx+'_Tief'
      esar_n_name = thx+'_Nief'
    Endif
  Endif
  vars06 = ['kyoto_thm_combined_ae', roi_bar, 'Keogram', thx+'_fgs_gse', $
             esar_n_name, esair_v_name, esar_t_name, 'sample_rate_'+sc, $
             ssti_name, esair_flux_name, sste_name,  $
             esaer_flux_name, fbk_tvars[0], fbk_tvars[1], thx+'_pos_gse_z']
  vars02 = ['kyoto_thm_combined_ae', roi_bar, 'Keogram', thx+'_fgs_gse', $
             esar_n_name, esair_v_name, esar_t_name, 'sample_rate_'+sc, $
             ssti_name, esair_flux_name, sste_name,  $
             esaer_flux_name, fbk_tvars[0], fbk_tvars[1], thx+'_pos_gse_z']
  dprint, '24: ',vars_full
  options,vars_full,ysubtitle=''
  options,vars_full,ysubtitle='',/def
  dprint, '06: ',vars06
  dprint, '02: ',vars02
  dprint, 'Dir: ',directory

  thm_gen_multipngplot, thx+'_l2_overview', date, directory = directory, $
    vars24 = vars_full, vars06 = vars06, vars02 = vars02
endif ; makepng

; turn off the variable labels
tplot_options,var_label=''

SKIP_DAY:
message, /info, 'Returning:'
help, /memory
error=0
Return

end
