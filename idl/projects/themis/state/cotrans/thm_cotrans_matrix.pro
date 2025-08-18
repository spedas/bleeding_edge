;+
;NAME:
; thm_cotrans_matrix
;PURPOSE:
; brute force method of creating rotation matrix for a
; THEMIS coordinate transform.
;CALLING SEQUENCE:
; rotmat = thm_cotrans_matrix(in_name, $
;                             in_coord=in_coord, $
;                             out_coord=out_coord, $
;                             interpolate_state=interpolate_state, $
;                             use_spinaxis_correction=use_spinaxis_correction, $
;                             use_spinphase_correction=use_spinphase_correction, $
;                             use_eclipse_corrections=use_eclipse_corrections)
;INPUT:
; in_name = a THEMIS tplot variable, 
;OUTPUT:
; rotmat = a 3x3 transformation matrix for each time given by the
;          input variable
;KEYWORDS:
; Standard thm_cotrans keywords:
;  probe = 'a', 'b', 'c', 'd', 'e', If not set, then we will try to
;           get it from the variable name
;  in_coord = 'spg', 'ssl', 'dsl', 'gse', 'gsm','sm', 'gei','geo', 'sse', 'sel' or
;          'mag' coordinate system of input.
;          This keyword is optional if the dlimits.data_att.coord_sys attribute
;          is present for the tplot variable, and if present, it must match
;          the value of that attribute.  See cotrans_set_coord,
;          cotrans_get_coord
;  out_coord = 'spg', 'ssl', 'dsl', 'gse', 'gsm', 'sm', 'gei','geo', 'sse','sel', or 'mag'
;           coordinate system of output.  This keyword is optional if
;           out_suffix is specified and last 3 characters of suffix specify
;           the output coordinate system.
; interpolate_state: use interpolation on 1-minute state CDF spinper/spinphase
;     samples for despinning instead of spin model
; use_spinaxis_correction: uses spinaxis correction as in THM_COTRANS
; use_spinphase_correction: uses spinphase correction as in THM_COTRANS
; use_eclipse_correction: uses eclipse correction as in THM_COTRANS
; support_suffix: if support_data is loaded with a suffix you can
; specify it here
; slp_suffix: if slp_sun_pos, slp_lun_pos, slp_lunn_att variables have
; this suffix, you can specify it here
;EXAMPLE:
; For converting DSL to GSE coordinates, using ptens variable
;  rotmat = thm_cotrans_matrix('tha_peif_ptens', out_coord = 'GSE')
;Any input can be used, only the time variable is important, but if
;the variable has no coordinate system defined (e.g., density) then
;the in_coord keyword should be set.
;HISTORY:
; 2019-01-16, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-02-13 11:37:26 -0800 (Wed, 13 Feb 2019) $
; $LastChangedRevision: 26620 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/state/cotrans/thm_cotrans_matrix.pro $
;-
Function thm_cotrans_matrix, in_name, $
                             probe = probe, $
                             in_coord=in_coord, $
                             out_coord=out_coord, $
                             interpolate_state=interpolate_state, $
                             use_spinaxis_correction=use_spinaxis_correction, $
                             use_spinphase_correction=use_spinphase_correction, $
                             use_eclipse_corrections=use_eclipse_corrections, $
                             support_suffix=support_suffix, $
                             slp_suffix=slp_suffix, $
                             _extra=_extra
;First get the data, all that is really needed is the time
  get_data, in_name, data = d, dlimits = dl
  If(~is_struct(d)) Then Begin
     dprint, 'No data for: '+in_name
     Return, -1
  Endif
;Get input coordinate system
  If(keyword_set(in_coord)) Then icoord = in_coord Else Begin
     If(is_struct(dl)) Then icoord = cotrans_get_coord(dl) $
     Else icoord = cotrans_get_coord(in_name)
     If(~is_string(icoord) || icoord Eq 'unknown' ) Then Begin
        dprint, 'Input Coordinates not set for: '+in_name
        Return, -1
     Endif
  Endelse
;You need a probe
  If(~keyword_set(Probe)) Then probe = strlowcase(strmid(in_name, 2, 1))
  ss = where(['a','b','c','d','e'] Eq probe, nss)
  If(nss Eq 0) Then Begin
     dprint, 'Invalid probe: '+probe
     Return, -1
  Endif
;Load state data, if not available
  have_state = 0b
  If(keyword_set(support_suffix)) Then Begin
     tn_state = tnames('th'+probe+'_state_man'+support_suffix)
  Endif Else tn_state = tnames('th'+probe+'_state_man')
  Get_data, tn_state[0], data = s
  If(is_struct(s)) Then Begin
     state_trange = minmax(s.x)
     data_trange = minmax(d.x)
     If(state_trange[0] Le data_trange[0] And $
        state_trange[1] Ge data_trange[1]) Then have_state = 1b
  Endif
  If(~have_state) Then thm_load_state, probe=probe, trange=minmax(d.x), $
                                       suffix = support_suffix, /get_support
;Create 'basis' variables, and cotrans
  nx = n_elements(d.x)
  ytmp = dblarr(nx, 3) & ytmp[*, 0] = 1
  store_data, 'tmp_xbasis', data={x:d.x, y:ytmp}
  ytmp = dblarr(nx, 3) & ytmp[*, 1] = 1
  store_data, 'tmp_ybasis', data={x:d.x, y:ytmp}
  ytmp = dblarr(nx, 3) & ytmp[*, 2] = 1
  store_data, 'tmp_zbasis', data={x:d.x, y:ytmp}
;Cotrans the basis vectors
  thm_cotrans, 'tmp_?basis', in_coord=icoord, out_coord=out_coord, probe=probe, $
               interpolate_state=interpolate_state, $
               use_spinaxis_correction=use_spinaxis_correction, $
               use_spinphase_correction=use_spinphase_correction, $
               use_eclipse_corrections=use_eclipse_corrections, $
               support_suffix=support_suffix, slp_suffix=slp_suffix
;If the dlimits structure does no have the correct output cordinates,
;then the transform did not happen
  oc_check = cotrans_get_coord('tmp_xbasis')
  ocoord = strlowcase(out_coord)
  If(strlowcase(oc_check) Ne strlowcase(out_coord)) Then Begin
     dprint, 'Cotrans to' +out_coord+' Failed: '+in_name
     return, -1
  Endif
;Form the rotation matrix
  r = dblarr(nx, 3, 3)
  get_data, 'tmp_xbasis', data = dx
  get_data, 'tmp_ybasis', data = dy
  get_data, 'tmp_zbasis', data = dz
  r[*, *, 0] = dx.y
  r[*, *, 1] = dy.y
  r[*, *, 2] = dz.y
;  r = transpose(r, [0, 2, 1]) ;TEST 
;No transpose here, r gives the correct answer when using tvector_rotate
  out_name = in_name+'_matrix_'+icoord+'2'+ocoord
  out_name = out_name[0] ;Not clear why out_name isn't scalar
;Dlimits structure, hacked from thm_fac_matrix_make
  dlimits = {data_att:{source_sys:icoord[0],coord_sys:ocoord[0]}}
  store_data, out_name, data = {x:d.x, y:r}, dlimits=dlimits
;  rt = transpose(temporary(r)) ;so that e.g., data.y[0, *]#rt[*, *, 0] gives transformed velocity
;cleanup
  del_data, 'tmp_?basis'
  undefine, dx
  undefine, dy
  undefine, dz
  undefine, ytmp

Return, out_name
End

