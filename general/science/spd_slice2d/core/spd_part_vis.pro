;+
;Procedure:
;  spd_part_vis
;
;Purpose:
;  View data from 3D distribution structures in 3 dimensions.
;  This is primarily a diagnostic tool.
;
;Calling Sequence:
;  spd_part_vis, input [,trange=trange] [,samples=samples] 
;                      [,time=time [,window=window [,/center_time]]
;                      [/zeros]
;
;Input:
;  input:  Structure array or scalar pointer to structure array
;  samples:  Specify # of distributions to plot (default=1)
;  trange:  Plot distribution(s) within this time range
;  time:  Plot distribution(s) closest to this time
;  window:  Use a time range of this width (sec) from TIME
;  center_time:  TIME is the center of the window instead of the start
;  zeros:  Flag to plot zeros instead of nonzero data
;
;Output:
;  fail:  Returns message in case of error
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-12-09 18:11:14 -0800 (Wed, 09 Dec 2015) $
;$LastChangedRevision: 19562 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_part_vis.pro $
;-

pro spd_part_vis, input, $
                  time=time, $
                  window=window, $
                  center_time=center_time, $
                  trange=trange, $
                  samples=samples, $
                  zeros=zeros, $
                  fail=fail

    compile_opt idl2


;allow pointer or struct
if is_struct(input) then begin
  ds = ptr_new(input)
endif else begin
  if ptr_valid(input) then begin
    ds = input
  endif else begin
    fail = 'Invalid pointer'
    dprint, dlevel=0, fail
    return
  endelse
endelse

if ~is_struct((*ds[0])) then begin
  fail = 'Invalid data structure within pointer'
  dprint, dlevel=0, fail
  return
endif

if undefined(samples) then samples=1

;get time range
if ~undefined(trange) then begin
  tr = minmax(time_double(trange))
endif

;get time range from time/window
if undefined(tr) && ~undefined(time) && ~undefined(window) then begin
  if keyword_set(center_time) then begin
    tr = time_double(time) + window*[-.5,.5]
  endif else begin
    tr = time_double(time) + window*[0,1]
  endelse
endif

;get time range from time/samples 
if undefined(tr) && ~undefined(time) && ~undefined(samples) then begin
  tr = spd_slice2d_nearest(ds[0], time, samples)
endif

;use distributions in time range if requested, otherwise use up to SAMPLES
if ~undefined(tr) then begin
  idx = spd_slice2d_intrange(ds[0], trange, n=nt)
  if nt gt 0 then begin
    da = (*ds[0])[idx[0:samples-1]]
  endif else begin
    fail = 'No times in requested range.'
    dprint, dlevel=0, fail
    return
  endelse
endif else begin
  da = (*ds[0])[0:(samples < n_elements(*ds[0]))-1]
endelse

;loop over distributions
for i=0, n_elements(da)-1 do begin

  ;assume new energies/look directions for each dist
  undefine, r, p, t

  ;get coords
  spd_slice2d_get_sphere, da[i], rad=r, phi=p, theta=t, energy=energy

  ;cartesian conversion could be skipped, but it's probably a better
  ;diagnostic to replicate the process
  spd_slice2d_s2c, r, t, p, v_xyz
  
  vec = array_concat(v_xyz,vec)
  dat = array_concat(da[i].data,dat)

endfor


;find where data is non-zero
idx = where(dat ne 0, n, comp=idx0, ncomp=n0)
rg = [-max(vec),max(vec)]

;plot nonzero data
if n gt 0 then begin
  iplot, vec[idx,0], vec[idx,1], vec[idx,2], $
         linestyle=6, sym_index=6, $
         xrange = rg, yrange=rg, zrange=rg, $
         rgb_table=13, vert_colors=bytscl(alog10(dat[idx])), $
         window_title=time_string(da[0].time,/msec)+' - '+ $
                      strmid(time_string(da[i-1].end_time,/msec),11)
endif else begin
  dprint, dlevel=0, 'No non-zero data'
endelse


;plot zeros in new window if requested
if keyword_set(zeros) then begin
  if n0 gt 0 then begin
    iplot, vec[idx0,0], vec[idx0,1], vec[idx0,2], $
           linestyle=6, sym_index=6, $
           xrange = rg, yrange=rg, zrange=rg, $
           window_title=time_string(da[0].time,/msec)+' - '+ $
                        strmid(time_string(da[i-1].end_time,/msec),11)
  endif else begin
    dprint, dlevel=0, 'No Zeros'
  endelse
endif


end