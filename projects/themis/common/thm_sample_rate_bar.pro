;+
;NAME:
; thm_sample_rate_bar
;PURPOSE:
; creates the sample rate bar for overview plots
;CALLING SEQUENCE:
; p = thm_sample_rate_bar(date,duration,probe)
;INPUT:
; date =  the date for the start of the timespan, 
; duration = the duration of your bar in days
; probe = THEMIS probe Id
;
;KEYWORDS:
; outline: set this to 1 to generate a sample rate panel with
;          a black outline rather than no outline
;OUTPUT:
; p = the variable name of the sample_rate_bar, set to '' if not
;     sccessful
;HISTORY:
; 20-nov-2007, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-02-17 10:47:06 -0800 (Wed, 17 Feb 2016) $
; $LastChangedRevision: 20029 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_sample_rate_bar.pro $
;-
Function thm_sample_rate_bar, date, duration, probe,outline=outline, _extra = _extra

  compile_opt idl2
  p = ''
  timespan, date, duration
  sc = strlowcase(strcompress(probe[0], /remove_all))

; make tplot variable tracking the sample rate (0=SS,1=FS,2=PB,3=WB)
;------------------------------------------------------------------

  thm_load_scmode, probe=sc
  ; default is slow survey, yellow bar
  get_data, strjoin('th'+sc+'_scmode_ufs'), data = dufs,dlimit=dl
  get_data, strjoin('th'+sc+'_scmode_fs'), data = dfs,dlimit=dl
  get_data, strjoin('th'+sc+'_scmode_ss'), data = dss,dlimit=dl
  
  if tnames('th'+sc+'_scmode_ufs') eq '' then begin
    ufs_time = [float('NaN')]
    ufs_data = [float('NaN')]
  endif else begin
    ind_ufs = where(dufs.y eq 1) 
    ufs_time = float(dufs.x)
    ufs_data = float(dufs.y)
    ufs_data[*] = float('NaN')
    if (ind_ufs[0] ne -1) then ufs_data[ind_ufs] = 0.0
  endelse

  if (size(dfs,/type) ne 8) then begin
    fs_time = float('NaN')
    fs_data = float('NaN')
    fs_data[*] = float('NaN')   
  endif else begin
    ind_fs = where(dfs.y eq 1)
    fs_time = float(dfs.x)
    fs_data = float(dfs.y)
    fs_data[*] = float('NaN')
    if (ind_fs[0] ne -1) then fs_data[ind_fs] = 0.0
  endelse

  if (size(dss,/type) ne 8) then begin
    ss_time = float('NaN')
    ss_data = float('NaN')
    ss_data[*] = float('NaN')   
  endif else begin
    ind_ss = where(dss.y eq 1)
    ss_time = float(dss.x)
    ss_data = float(dss.y)
    ss_data[*] = float('NaN')
    if (ind_ss[0] ne -1) then ss_data[ind_ss] = 0.0
  endelse
    
  str_element,dl,'labels',/delete
  str_element,dl,'ysubtitle',/delete
  str_element,dl,'colors',/delete   
  str_element,dl,'labflag',/delete
  str_element,dl,'ytitle',/delete
  store_data, 'slow_survey_bar_'+sc, data = {x:ss_time, y:ss_data},dlimit=dl
  store_data, 'fast_survey_bar_'+sc, data = {x:fs_time, y:fs_data},dlimit=dl
  store_data, 'ultrafast_survey_bar_'+sc, data = {x:ufs_time, y:ufs_data},dlimit=dl
  store_data, 'aesthetic_bar_'+sc, data = {x:time_double(date), y:float('NaN')},dlimit=dl
;get particle burst data from fgh level 2 data, jmm, 27-aug-2007
  thm_load_fgm, probe = sc[0], level = 'l2', datatype = 'fgh'
;if L2 data is not there, look for L1 data, jmm, 24-apr-2008
  tn = tnames('th'+sc+'*fgh*')
  If(tn[0] eq '') then begin
    tns = tnames('th'+sc+'*state_spin*')
    If(tns[0] eq '') then thm_load_state, probe = sc[0], /get_support_data
    thm_load_fgm, probe = sc[0], level = 'l1', datatype = 'fgh'
  Endif
  tn = tnames('th'+sc+'*fgh*')
  if tn[0] eq '' then begin     ;no data
    store_data, 'particle_burst_bar_'+sc, data = {x:time_double(date), y:float('NaN')}
    store_data, 'particle_burst_sym_'+sc, data = {x:time_double(date), y:float('NaN')}
  endif else begin
    tn = tn[0]       ;assuming that all fgh's have the same time range
    get_data, tn, data = d,dlimit=dl
    If(size(d, /type) Eq 8) Then Begin ;on the off chance
      test_y = d.x
      pb_data = float(test_y)
      index_pb_fill = where(finite(test_y) Eq 0)
      index_pb = where(finite(test_y))
      if (index_pb_fill[0] ne -1) then pb_data[index_pb_fill] = float('NaN')
      if (index_pb[0] ne -1) then pb_data[index_pb] = 0.0
      pb_data2 = pb_data        ; pb_data2 is for symbols below bar
      if (index_pb[0] ne -1) then pb_data2[index_pb] = -1.0
      str_element,dl,'labels',/delete
      str_element,dl,'ysubtitle',/delete
      str_element,dl,'colors',/delete   
      str_element,dl,'labflag',/delete
      str_element,dl,'ytitle',/delete
      store_data, 'particle_burst_bar_'+sc, data = {x:d.x, y:pb_data},dlimit=dl
      store_data, 'particle_burst_sym_'+sc, data = {x:d.x, y:pb_data2},dlimit=dl
    Endif Else Begin
      store_data, 'particle_burst_bar_'+sc, data = {x:time_double(date), y:float('NaN')}
      store_data, 'particle_burst_sym_'+sc, data = {x:time_double(date), y:float('NaN')}
    Endelse
  endelse

;wave bursts from level 1 ffw data
  thm_load_fft, probe = sc[0], level = 'l1', varformat = 'th'+sc+'*ffw*'
  tn = tnames('th'+sc+'*ffw*')
  if tn[0] eq '' then begin
    store_data, 'wave_burst_bar_'+sc, data = {x:time_double(date), y:float('NaN')}
    store_data, 'wave_burst_sym_'+sc, data = {x:time_double(date), y:float('NaN')}
  endif else begin
    tn = tn[0] ;making the assumption that all ffws will have the same time range?
    get_data, tn, data = d,dlimit=dl
    test_y = d.x                ;use the times here
    If(size(d, /type) Eq 8) Then Begin ;on the off chance
      wb_data = float(test_y)
      index_wb_fill = where(finite(test_y) Eq 0)
      index_wb = where(finite(test_y))
      if (index_wb_fill[0] ne -1) then wb_data[index_wb_fill] = float('NaN')
      if (index_wb[0] ne -1) then wb_data[index_wb] = 0.0
      wb_data2 = wb_data        ; wb_data2 is for symbols above bar
      if (index_wb[0] ne -1) then wb_data2[index_wb] = 1.0
      str_element,dl,'spec',/delete
      str_element,dl,'ysubtitle',/delete
      str_element,dl,'log',/delete
      store_data, 'wave_burst_bar_'+sc, data = {x:d.x, y:wb_data},dlimit=dl
      store_data, 'wave_burst_sym_'+sc, data = {x:d.x, y:wb_data2},dlimit=dl
    Endif Else Begin
      store_data, 'wave_burst_bar_'+sc, data = {x:time_double(date), y:float('NaN')}
      store_data, 'wave_burst_sym_'+sc, data = {x:time_double(date), y:float('NaN')}
    Endelse
  endelse

  options, 'aesthetic_bar_'+sc, 'color', 255
  options, 'slow_survey_bar_'+sc, 'color', 5 
  options, 'fast_survey_bar_'+sc, 'color', 6 ;red
  options, 'ultrafast_survey_bar_'+sc, 'color', 3 ;cyan
  options, 'particle_burst_bar_'+sc, 'color', 3
  options, 'particle_burst_sym_'+sc, 'color', 0
  options, 'wave_burst_bar_'+sc, 'color', 0
  options, 'wave_burst_sym_'+sc, 'color', 0
  
  options, 'slow_survey_bar_'+sc, 'thick', 5
  options, 'fast_survey_bar_'+sc, 'thick', 5
  options, 'ultrafast_survey_bar_'+sc, 'thick', 3
  options, 'particle_burst_bar_'+sc, 'psym', 6
  options, 'particle_burst_bar_'+sc, 'symsize', 0.1
  options, 'particle_burst_sym_'+sc, 'psym', 6
  options, 'particle_burst_sym_'+sc, 'symsize', 0.2
  options, 'wave_burst_bar_'+sc, 'psym', 6
  options, 'wave_burst_bar_'+sc, 'symsize', 0.1
  options, 'wave_burst_sym_'+sc, 'psym', 6
  options, 'wave_burst_sym_'+sc, 'symsize', 0.2
  
  if keyword_set(outline) then begin

     options,'aesthetic_bar_'+sc,color=0,ticklen=0,$
             yticks=1,ytickname=[' ',' ']
  endif

  store_data, 'sample_rate_'+sc, data = ['aesthetic_bar_'+sc, 'slow_survey_bar_'+sc, 'fast_survey_bar_'+sc, 'ultrafast_survey_bar_'+sc, 'particle_burst_sym_'+sc, 'wave_burst_sym_'+sc]

  ylim, 'sample_rate_'+sc, -1.1, 1.1, 0
  options, 'sample_rate_'+sc, 'panel_size', 0.2
  options,'sample_rate_'+sc, ytitle=''
  

;end mode bar code block
;--------------->
  p = 'sample_rate_'+sc
  Return, p
End

