;+
;NAME:
; thm_sample_rate_bar_helper
;PURPOSE:
; Expands rate start/end intervals into "rate on" flags with a fixed cadence for the 'on' periods
;CALLING SEQUENCE:
; thm_sample_rate_bar_helper,in_name=in_name,out_name=out_name,dt=dt
;KEYWORDS:
; in_name =  a tplot variable with scmode data
; dt = time (in seconds) between points with sample rate "on"
; out_name = name of the output tplot variable
;
;HISTORY:
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-08-30 22:37:14 -0700 (Sun, 30 Aug 2026) $
; $LastChangedRevision: 34844 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_sample_rate_bar.pro $
;-

pro thm_sample_rate_bar_helper,in_name=in_name, dt=dt, out_name=out_name

   a=tnames(in_name)
   if a[0] eq '' then begin
    message,'Input variable ' + in_name + 'does not exist.'
   endif
   
   if n_elements(dt) eq 0 then dt = 0.25
   
   if n_elements(out_name) eq 0 then out_name=in_name + '_expanded'
   
   get_data,in_name,data=d
   
   inp_times = d.x
   tr = minmax(inp_times)
   tstart = tr[0]
   tspan = tr[1] - tr[0]
   tcount = long(tspan/dt)
   tgrid=[tstart+dindgen(tcount)*dt,tr[1]]
   tinterpol_mxn,in_name,tgrid,out=d_exp,/nearest_neighbor
   idx = where(d_exp.y gt 0, c)
   if c eq 0 then begin
    ; No 'on' periods, just return a single NaN at the start time
    store_data,out_name,data={x:tr[0],y:[float("NaN")]}
   endif else begin
    out_times = tgrid[idx]
    out_dat = d_exp.y[idx]
    store_data,out_name,data={x:out_times, y: out_dat}
   endelse     
end

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
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-08-30 22:37:14 -0700 (Sun, 30 Aug 2026) $
; $LastChangedRevision: 34844 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_sample_rate_bar.pro $
;-
Function thm_sample_rate_bar, date, duration, probe,outline=outline, _extra = _extra

  compile_opt idl2
  p = ''
  timespan, date, duration
  sc = strlowcase(strcompress(probe[0], /remove_all))

  ; Delete stale variables in case this call does not load data
  del_data,'th'+sc+'_scmode_*'
  ; Load L1 SCMODE data. The variables contain all the OFF-ON or ON-OFF transitions. 0=OFF, 1=ON
  thm_load_scmode, probe=sc
  get_data, strjoin('th'+sc+'_scmode_pb'), data = dpb,dlimit=dl
  get_data, strjoin('th'+sc+'_scmode_wb'), data = dwb,dlimit=dl
  get_data, strjoin('th'+sc+'_scmode_ufs'), data = dufs,dlimit=dl
  get_data, strjoin('th'+sc+'_scmode_fs'), data = dfs,dlimit=dl
  ; default is slow survey, yellow bar
  get_data, strjoin('th'+sc+'_scmode_ss'), data = dss,dlimit=dl
  
  if  ~(is_struct(dpb) && is_struct(dwb) && is_struct(dufs) && is_struct(dfs) && is_struct(dss)) then begin
    dprint,'Warning: some scmode variables were not successfully loaded for probe '+sc+', date '+date+', duration '+str(duration)
  endif
  
  ; PB and WB intervals are depicted by symbols plotted above and below the colored bar.
  ; For this type of plot, we don't want to mark just the transitions, but have a set of times within each interval
  ; so the plotted symbols form a continuous bar.  thm_sample_rate_bar_helper converts the start/stop times to sets of
  ; points at the given cadence 'dt'.
  
  pb_name = 'th'+sc+'_scmode_pb'
  if tnames(pb_name) ne '' then thm_sample_rate_bar_helper, in_name=pb_name, dt=0.25, out_name=pb_name+'_expanded'
  wb_name = 'th'+sc+'_scmode_wb'
  if tnames(wb_name) ne '' then thm_sample_rate_bar_helper, in_name=wb_name, dt=0.25, out_name=wb_name+'_expanded'

  ; If any of the SCMODE variables are missing, set up some variables representing "all off" for that mode.
  ;   
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
    fs_time = [float('NaN')]
    fs_data = [float('NaN')] 
  endif else begin
    ind_fs = where(dfs.y eq 1)
    fs_time = float(dfs.x)
    fs_data = float(dfs.y)
    fs_data[*] = float('NaN')
    if (ind_fs[0] ne -1) then fs_data[ind_fs] = 0.0
  endelse

  if (size(dss,/type) ne 8) then begin
    ss_time = [float('NaN')]
    ss_data = [float('NaN')]
  endif else begin
    ind_ss = where(dss.y eq 1)
    ss_time = float(dss.x)
    ss_data = float(dss.y)
    ss_data[*] = float('NaN')
    if (ind_ss[0] ne -1) then ss_data[ind_ss] = 0.0
  endelse

  if (size(dpb,/type) ne 8) then begin
    pb_time = [float('NaN')]
    pb_data = [float('NaN')]
  endif else begin
    ind_pb = where(dpb.y eq 1)
    pb_time = float(dpb.x)
    pb_data = float(dpb.y)
    pb_data[*] = float('NaN')
    if (ind_pb[0] ne -1) then pb_data[ind_pb] = 0.0
  endelse

  if (size(dwb,/type) ne 8) then begin
    wb_time = [float('NaN')]
    wb_data = [float('NaN')]
  endif else begin
    ind_wb = where(dwb.y eq 1)
    wb_time = float(dwb.x)
    wb_data = float(dwb.y)
    wb_data[*] = float('NaN')
    if (ind_wb[0] ne -1) then wb_data[ind_wb] = 0.0
  endelse
    
  str_element,dl,'labels',/delete
  str_element,dl,'ysubtitle',/delete
  str_element,dl,'colors',/delete   
  str_element,dl,'labflag',/delete
  str_element,dl,'ytitle',/delete
  store_data, 'slow_survey_bar_'+sc, data = {x:ss_time, y:ss_data},dlimit=dl
  store_data, 'fast_survey_bar_'+sc, data = {x:fs_time, y:fs_data},dlimit=dl
  store_data, 'ultrafast_survey_bar_'+sc, data = {x:ufs_time, y:ufs_data},dlimit=dl
  store_data, 'particle_burst_bar_'+sc, data = {x:pb_time, y:pb_data},dlimit=dl
  store_data, 'wave_burst_bar_bar_'+sc, data = {x:wb_time, y:wb_data},dlimit=dl
  store_data, 'aesthetic_bar_'+sc, data = {x:[time_double(date)], y:[float('NaN')]},dlimit=dl
  
  ; Particle burst markers: one marker per timestamp when the mode is 'on'  
  tn = tnames('th'+sc+'_scmode_pb_expanded')
  if tn[0] eq '' then begin     ;no data
    store_data, 'particle_burst_bar_'+sc, data = {x:[time_double(date)], y:[float('NaN')]}
    store_data, 'particle_burst_sym_'+sc, data = {x:[time_double(date)], y:[float('NaN')]}
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
      store_data, 'particle_burst_bar_'+sc, data = {x:[time_double(date)], y:[float('NaN')]}
      store_data, 'particle_burst_sym_'+sc, data = {x:[time_double(date)], y:[float('NaN')]}
    Endelse
  endelse

  ; Wave burst markers: one marker per timestamp when the mode is 'on'  
  tn = tnames('th'+sc+'_scmode_wb_expanded')
  if tn[0] eq '' then begin
    store_data, 'wave_burst_bar_'+sc, data = {x:[time_double(date)], y:[float('NaN')]}
    store_data, 'wave_burst_sym_'+sc, data = {x:[time_double(date)], y:[float('NaN')]}
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
      store_data, 'wave_burst_bar_'+sc, data = {x:[time_double(date)], y:[float('NaN')]}
      store_data, 'wave_burst_sym_'+sc, data = {x:[time_double(date)], y:[float('NaN')]}
    Endelse
  endelse

  ; Set some plot options for the online and SPEDAS GUI summary plots
  
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

