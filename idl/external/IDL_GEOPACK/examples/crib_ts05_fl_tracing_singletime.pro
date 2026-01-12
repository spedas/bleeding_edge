; Crib sheet and regression test for field line tracing
; 
; This crib sheet is derived from a bug report submitted by Yoshi Miyoshi and the ERG team in late 2024.  They had noticed that when
; they did a field line trace from the ERG spacecraft position to the northern ionosphere, then took that foot point and traced backward to the
; southern ionosphere, the start position of the reverse trace was offset from the intended start location, and the traces didn't line up as expected.
; 
; The issue turned out to be an inconsistency in the times used to perform the GSE<->GSW coordinate transforms in trace2iono and trace2equator
; (which only occur if /geopack_2008 is specified).
; 
; The purpose of this crib is to perform several field line traces, starting each trace from the previous foot point or spacecraft position, and 
; demonstrate that there are no more offsets in the start positions, and that the traces for a given timestamp all lie on top of each other, as one
; would expect.  Two spacecraft positions are chosen, near the start and end of the time interval, to show that the correction is effective throughout the
; interval.
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-01-09 12:21:54 -0800 (Fri, 09 Jan 2026) $
; $LastChangedRevision: 33984 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/examples/crib_ts05_fl_tracing_singletime.pro $


function ns_trace_draw, m
  get_data, 'fline_erg_to_np', data=n
  get_data, 'fline_np_to_sp', data=s
  get_data, 'foot_n', data=fn
  get_data, 'foot_s', data=fs
  get_data, 'erg_orb_l2_pos_gsm_avg_tclip', data=erg
  get_data, 'fline_sp_to_np',data=revtrace
  get_data, 'retrace_foot_n',data=f_retrace

  n_trace = n.y[m, *, *]
  n_trace_ref = reform(n_trace)
  n_trace_mag = sqrt(total(n_trace_ref^2,2))
  s_trace  = s.y[m, *, *]
  s_trace_ref = reform(s_trace)
  s_trace_mag =  sqrt(total(s_trace_ref^2,2))
  fn_i = fn.y[m, *]
  fs_i = fs.y[m, *]
  erg_i = erg.y[m, *]
  revtrace_i = revtrace.y[m,*,*]
  revtrace_i_ref = reform(revtrace_i)
  fretrace_i = f_retrace.y[m,*]
  t=time_string(erg.x[m], prec=3)
  print, t

  erg_trace_count = n_elements(n_trace_ref)/3
  store_data, 'erg_trace_xy', data={x: replicate(n.x[0],erg_trace_count), y: n_trace_ref}
  sp_trace_count = n_elements(s_trace_ref)/3
  store_data, 'sp_trace_xy',  data={x: replicate(s.x[0], sp_trace_count),  y: s_trace_ref}
  store_data, 'fn_xy', data={x: fn.x[m], y: fn_i}
  store_data, 'fs_xy', data={x: fs.x[m], y: fs_i}
  store_data, 'erg_xy', data={x: erg.x[m], y: erg_i}
  store_data,'fn_i',data={x:fn.x[m], y: fn.y[m,*]}
  revtrace_count = n_elements(revtrace_i_ref)/3
  store_data, 'rev_i',data={x:replicate(revtrace.x[0],revtrace_count), y: revtrace_i_ref}

  print,'Time: ', erg.x[m], ' ',time_string(erg.x[m])
  print,'S/C pos: ', erg_i
  print,'Trace point count, s/c to NP: ', erg_trace_count
  print,'First s/c to NP trace point: ', n_trace_ref[0,*]
  print,'Last s/c to NP trace point: ', n_trace_ref[erg_trace_count-1,*]
  print,'NP foot point: ',fn_i[*]
  

  print,'Trace point count, NP to SP: ', sp_trace_count
  print,'First NP to SP trace point: ', s_trace_ref[0,*]
  print,'Last NP to SP trace point: ', s_trace_ref[sp_trace_count-1,*]
  print,'SP foot point: ',fs_i[*]

  print,'Trace point count, SP to NP: ', revtrace_count
  print,'First SP to NP trace point: ', revtrace_i_ref[0,*]
  print,'Last SP to NP trace point: ', revtrace_i_ref[revtrace_count-1,*]
  print,'Retrace NP foot point: ',fretrace_i[*]

  xran = [-4, 8] & yran = [-4, 8] & vs = 'xy'
  window, 0 & wset, 0
  tplotxy, 'erg_trace_xy', versus=vs, xran=xran, yran=yran, color=spd_get_color('orange'), thick=6, title=t
  tplotxy, 'sp_trace_xy', versus=vs, color=spd_get_color('blue'), thick=2, /over
  tplotxy, 'rev_i', versus=vs, pstart=1, pstop=2,color=spd_get_color('magenta'), thick=3, /over
  tplotxy, 'fn_xy', versus=vs, color=spd_get_color('purple'), thick=4, pstart=1, /over, symsize=2
  tplotxy, 'fs_xy', versus=vs, color=spd_get_color('green'), thick=5, pstart=2, /over, symsize=2
  tplotxy, 'erg_xy', versus=vs, color=spd_get_color('black'), thick=5, pstart=4, /over, symsize=2

  window, 1 & wset,1
  xran = [0, 2] & yran = [4, 6] & vs = 'xy'
  tplotxy, 'erg_trace_xy', versus=vs, xran=xran, yran=yran, color=spd_get_color('orange'), thick=6, title=t
  tplotxy, 'sp_trace_xy', versus=vs, color=spd_get_color('blue'), thick=2, /over
  tplotxy, 'rev_i', versus=vs, pstart=1, pstop=2,color=spd_get_color('magenta'), thick=3, /over
  tplotxy, 'fn_xy', versus=vs, color=spd_get_color('purple'), thick=4, pstart=1, /over, symsize=2
  tplotxy, 'fs_xy', versus=vs, color=spd_get_color('green'), thick=5, pstart=2, /over, symsize=2
  tplotxy, 'erg_xy', versus=vs, color=spd_get_color('black'), thick=5, pstart=4, /over, symsize=2

  window, 2 & wset, 2
  xran = [-0.5, 1.0] & yran = [0.0, 0.75] & vs = 'xy'
  tplotxy, 'erg_trace_xy', versus=vs, xran=xran, yran=yran, psym=1,color=spd_get_color('orange'),thick=3, pstart=1, pstop=2,/xstyle, /ystyle
  tplotxy, 'sp_trace_xy', pstart=1,pstop=2,versus=vs, /over
  tplotxy, 'sp_trace_xy', versus=vs, color=spd_get_color('blue'), thick=2, /over
  tplotxy,'fn_i',pstart=1,pstop=2,versus=vs,color=spd_get_color('red'),/over
  tplotxy, 'rev_i', versus=vs, color=spd_get_color('magenta'), /over
  
  return, t
end 

pro crib_ts05_fl_tracing_singletime, standard_mapping=standard_mapping, geopack_2008=geopack_2008,timestamp=timestamp
  compile_opt idl2
  ; default to settings that reproduce the tracing bug
  
  if n_elements(standard_mapping) eq 0 then begin
    standard_mapping = 0
  endif
  if n_elements(geopack_2008) eq 0 then begin
    geopack_2008 = 1
  endif
  if n_elements(timestamp) eq 0 then begin
    trange = ['2022-11-23/01:00:29.5', '2022-11-23/01:00:30.5']
  endif else begin
    tdbl = time_double(timestamp)
    tstart = tdbl - 0.5
    tend = tdbl + 0.5
    trange = [time_string(tstart), time_string(tend)]
  endelse
  
  print, 'Trange: ', trange
  del_data, '*'
  timespan, '2022-11-22', 2
  ;;load omni data
  omni_hro_load, /res5min
  store_data, 'omni_imf', data=['OMNI_HRO_5min_BY_GSM', 'OMNI_HRO_5min_BZ_GSM']
  ;;make tsyganenko parameter set
  get_tsy_params, 'OMNI_HRO_5min_SYM_H', 'omni_imf', 'OMNI_HRO_5min_proton_density',  'OMNI_HRO_5min_flow_speed', 'T04s', /speed, /imf_yz
  ;;Load erg orbit data
  timespan, '2022-11-23', 1, /day
  erg_load_orb, /no_download
  avg_data, 'erg_orb_l2_pos_gsm' ;; boxcar-averaging with a 1-min window
  time_clip, 'erg_orb_l2_pos_gsm_avg', trange[0], trange[1]
  get_data,'erg_orb_l2_pos_gsm_avg_tclip', data=d
  n_times=n_elements(d.x)
  ;; FL-tracing from satellite positions to their
  ;; footprints on the northen i'sphere

  ;; FL-tracing from ERG spacecraft position to northern ionosphere  
  ttrace2iono, 'erg_orb_l2_pos_gsm_avg_tclip', newname='foot_n', in_coord='gsm', out_coord='gsm', external_model='t04s', par='t04s_par', trace='fline_erg_to_np',geopack_2008=geopack_2008,standard_mapping=standard_mapping
  ;; FL-tracing from northern foot point all the way to southern ionosphere
  ttrace2iono, 'foot_n', newname='foot_s', in_coord='gsm', out_coord='gsm', external='t04s',  par='t04s_par', /south, trace='fline_np_to_sp',geopack_2008=geopack_2008, standard_mapping=standard_mapping
  ;; Reverse FL-tracing, from southern foot point back to the northern ionosphere.
  ttrace2iono, 'foot_s', newname='retrace_foot_n', in_coord='gsm', out_coord='gsm', external='t04s',  par='t04s_par', trace='fline_sp_to_np',geopack_2008=geopack_2008, standard_mapping=standard_mapping

  get_data,'foot_n',data=f_n
  get_data,'foot_s',data=f_s
  get_data,'retrace_foot_n',data=f_r
  print,'North:',f_n.y, 'r (km) =', sqrt(total(f_n.y*f_n.y)) * 6371.2D
  print,'South:',f_s.y,'r (km) =', sqrt(total(f_s.y*f_s.y)) * 6371.2D
  print,'Retrace:',f_r.y, 'r (km) =', sqrt(total(f_r.y*f_r.y)) * 6371.2D
  print,'Diff north-retrace:', f_n.y - f_r.y, 'r (km) =', sqrt(total((f_n.y - f_r.y)*(f_n.y - f_r.y))) * 6371.2D
  ; Plot the traces
  ptime=ns_trace_draw(0)
  print,'Field line traces from the ERG spacecraft position at the start of the time interval.'
  print, 'Orange: trace from ERG position to northern ionosphere'
  print, 'Blue: trace from northern foot point to southern ionosphere'
  print, 'Magenta: trace from southern foot point back to northern ionosphere'
  print, ''
  print,'Plot window 0: zoomed out view.'
  print,'Window 1: Zoomed in on ERG s/c position (indicated with a diamond marker)'
  print,'Window 2: Zoomed in on ionosphere'
  print,''
  print,'All traces should be plotted on top of each other, with no offsets between traces at the northern or southern foot points (where the trace direction is reversed from the previous endpoint).'
  print,'In plot 1, the traces should all pass directly through the ERG s/c position'

end
