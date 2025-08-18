;+
; NAME:
;   rbsp_despin (procedure)
;
; PURPOSE:
;   Rotate data from a spinning frame to DSC. By default, the spinning frame is
;   assumed to be the UVW frame.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   rbsp_despin, sc, tvar, angle_offset = angle_offset, pertvar = pertvar, $
;     newname = newname, uvw = uvw, xyz = xyz, offset_name = offset_name, $
;     no_axial_processing = no_axial_processing,  $
;     no_offset_remove = no_offset_remove, $
;     tper = tper, tphase = tphase
;
; ARGUMENTS:
;   sc: (In, required) Spacecraft name. Should be 'a' or 'b'.
;   tvar: (In, required) Tplot variable to be despun, such as 'rbspa_mag_uvw'.
;
; KEYWORDS:
;   angle_offset: (In, optional) Angle offset additional to spin phase. For UVW,
;         angle_offset is 10 degree, which is the default.
;   pertvar: (In, optional) Spin period tplot data. By default, 
;         pertvar = 'rbsp' + strlowcase(sc[0]) + '_spinper'.
;   newname: (In, optional) New name for the despun data. By default, 
;         newname = tvar + '_dsc'
;   /uvw: Shortcut for rotating UVW data.
;   /xyz: Shortcut for rotating XYZ data. Equivalent to set angle_offset = 45.
;   offset_name: A tplot name for saving offsets in spin-plane components.
;   /no_axial_processing: If set, axial component is not processed. By default,
;         the first spin-tone harmonic is removed in the axial component.
;   /no_offset_remove: If set, offsets in spin-plane components are not removed.
;   tper: (In, optional) Tplot name of spin period data. By default, 
;         tper = pertvar. If tper is set, pertvar = tper.
;   tphase: (In, optional) Tplot name of spin phase data. By default, 
;         tphase = 'rbsp' + strlowcase(sc[0]) + '_spinphase'
;         Note: tper and and tphase are mostly used for using eclipse-corrected
;         spin data.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-11-03: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-05: Initial release to TDAS. JBT, SSL/UCB.
;   2012-11-06: JBT, SSL/UCB.
;         1. Added tper and tphase to use eclipse-corrected spin data.
;         2. Added keyword *no_offset_remove*.
;
; VERSION:
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-10-06 16:51:43 -0700 (Thu, 06 Oct 2016) $
; $LastChangedRevision: 22061 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_despin.pro $
;
;-

function rbsp_despin_remove_offset, bu, time_array, pertvar, offset = offset, $
  remove_spintone = remove_spintone
  compile_opt idl2, hidden

  get_data, pertvar, data = dat_per

  t = time_array - time_array[0]
  dt = median(t[1:*] - t)
  nt = n_elements(t)
  per0 = 10.95d
  seglen = long(per0 / dt * 5.0)
  nseg = long(nt / seglen)
  nseg >= 1

  offset = bu
  offset[*] = !values.f_nan
  spintone = bu * 0d

  for i = 0L, nseg - 1 do begin
    ista = i * seglen
    if i eq nseg-1 then iend = nt-1 else iend = ista + seglen
    x = t[ista:iend] - t[ista]
    y = bu[ista:iend]
    icenter = long(mean([ista,iend]))
    t0 = mean(time_array[ista:iend], /nan)
    per = interpol(dat_per.y, dat_per.x, t0)

    ; skip nans
    ind = where(finite(y) and finite(x), nind)
    if nind eq 0 then begin
      dprint, 'All NaNs.'
;       stop
      continue
    endif
    x = x[ind]
    y = y[ind]

;     npt = iend - ista + 1
    npt = nind
    w = 2d * !dpi / per
    D_mat = dblarr(3, npt)
    D_mat[1,*] = cos(w * x)
    D_mat[2,*] = sin(w * x)
    D_mat[0,*] = 1d
;     xhat = la_invert(transpose(D_mat) ## D_mat) ## $
;       transpose(D_mat) ## transpose(y)
    xhat = transpose(D_mat # y) # invert(D_mat # transpose(D_mat))
;     xhat = transpose(D_mat # y) # invert($
;       matrix_multiply(D_mat, D_mat, /Btranspose))
      
;     xhat = matrix_multiply( $
;       matrix_multiply(y, D_mat, /Atrans, /Btrans), $
;       invert(matrix_multiply(D_mat, D_mat, /Btranspose)))
    
    offset[icenter] = xhat[0]
    spintone[ista:iend] = xhat[1] * D_mat[1,*] + xhat[2] * D_mat[2,*]

;     print, 'iseg = ', i, '; xhat[0] = ', xhat[0], '; mean(y) = ', mean(y)

    ; Check
;     tmp = offset[icenter]
;     plot, y, title = 'i = ' + jbt_istr(i) + '; offset = ' + string(tmp)
;     hbar, tmp
;     stop
  endfor

;     stop
  if ~keyword_set(remove_spintone) then begin
    ind = where(finite(offset), nind)
    if nind eq 1 then begin
      offset[*] = offset[ind[0]]
      return, bu - offset
    endif
    offset[0] = offset[ind[0]]
    offset[nt-1] = offset[ind[nind-1]]
    offset = interp(offset, dindgen(nt), dindgen(nt), /ignore_nan)
    if seglen * 10 lt n_elements(offset) then begin
      offset = smooth(offset, seglen * 10, /edge_truncate)
    endif

    return, bu - offset
  endif else begin
;     spintone = smooth(spintone, seglen * 10, /edge_truncate)
    return, bu - spintone
  endelse
end


;-------------------------------------------------------------------------------
pro rbsp_despin, sc, tvar, angle_offset = angle_offset, pertvar = pertvar, $
  newname = newname, uvw = uvw, xyz = xyz, offset_name = offset_name, $
  no_axial_processing = no_axial_processing,  $
  no_offset_remove = no_offset_remove, $
  tper = tper, tphase = tphase

; tvar should be in a spinning spacecraft frame.
; angle_offset: An offset with respect to spin phase

compile_opt idl2
rbx = 'rbsp' + sc + '_'

coord = 'dsc'
if n_elements(newname) eq 0 then newname = tvar + '_' + coord

if keyword_set(tper) then pertvar = tper
if n_elements(pertvar) eq 0 then pertvar = rbx + 'spinper'
if ~spd_check_tvar(pertvar) then begin
  dprint, 'No spin period data available. Abort.'
  return
endif

if n_elements(angle_offset) eq 0 then begin
  if keyword_set(uvw) then angle_offset = 10d
  if keyword_set(xyz) then angle_offset = 45d
endif
if n_elements(angle_offset) eq 0 then angle_offset = 10d

rbsp_btrange, tvar, nb = nb, btr = btr, tind = tind

get_data, tvar, data = d, dlim = dl, lim = lim
str_element, dl.data_att, 'units', units
str_element, dl.data_att, 'coord_sys', offset_coord
out_d = d
out_offset = d
out_offset.y[*,2] = !values.f_nan
phase = rbsp_interp_spin_phase(sc, d.x, tper = tper, tphase = tphase)
; print, 'nb = ', nb
; stop
for ib = 0, nb - 1 do begin
  ista = tind[ib, 0]
  iend = tind[ib, 1]
  time_array = d.x[ista:iend]
  bu = d.y[ista:iend,0]  ; Suppose we are working on B-field data in UVW
  bv = d.y[ista:iend,1]
  bw = d.y[ista:iend,2]

  ; Remove offset in spin-plane components
;   stop
  if ~keyword_set(no_offset_remove) then begin
    bu = rbsp_despin_remove_offset(temporary(bu), time_array, pertvar, $
      offset = bu_offset)
    bv = rbsp_despin_remove_offset(temporary(bv), time_array, pertvar, $
      offset = bv_offset)
  endif else begin
    bu_offset = bu * !values.f_nan
    bv_offset = bv * !values.f_nan
  endelse

  ; Remove spintone in the axial component
  if ~keyword_set(no_axial_processing) then $
    bw = rbsp_despin_remove_offset(temporary(bw), time_array, pertvar, $
      /remove_spintone)

  angle = phase[ista:iend] + angle_offset

  angle = temporary(angle) * !dtor  ; convert to radian

;   plot, angle
;   stop

  ; Rotate uvw to dsc
;   bx = bu * cos(angle) - bv * sin(angle)
;   by = bu * sin(angle) + bv * cos(angle)
;   bz = bw
;   out_d.y[ista:iend, 0] = bx
;   out_d.y[ista:iend, 1] = by
;   out_d.y[ista:iend, 2] = bz
  out_d.y[ista:iend, 0] = bu * cos(angle) - bv * sin(angle)
  out_d.y[ista:iend, 1] = bu * sin(angle) + bv * cos(angle)
  out_d.y[ista:iend, 2] = bw
  out_offset.y[ista:iend,0] = bu_offset
  out_offset.y[ista:iend,1] = bv_offset
endfor

str_element, dl, 'data_att.coord_sys', coord, /add
store_data, newname, data = out_d, dlim = dl, lim = lim


if size(offset_name, /type) eq 7 then begin
  str_element, dl.data_att, 'units', units
  att = {units:units, coord_sys:offset_coord}
  dl = {data_att:att, ysubtitle:'[' + units + ']', $
    colors:[2, 4], labels:['x ', 'y '] + offset_coord}
  store_data, offset_name[0], data = {x:out_offset.x, y:out_offset.y[*,0:1]}, $
    dlim = dl
endif

; tplot, [newname, offset_name]
; stop

end
