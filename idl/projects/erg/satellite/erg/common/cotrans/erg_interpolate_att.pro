;+
; PRO/FUN
;
; :Description:
;  Interpolates erg att data to match erg_xxx_in. 
;
;
; :Params:
;    erg_xxx_in: input tplot variable relating to ERG to be transformed 
;    spinperiod: output variable in which the interpolated data of ERG spin period is stored 
;    spinphase: output variable in which the interpolated data of ERG spin phase is stored   
;    sgix_j2000, sgiy_j2000, or sgiz_j2000: output interporated SGI axis vector for each component
;    sgax_j2000, sgay_j2000, or sgaz_j2000: output interporated SGA axis vector for each component
;
;  
; :Keywords:
;
; :Examples:
;
; :History:
; 2016/9/10: drafted
;
; :Author: Tomo Hori, ISEE (tomo.hori at nagoya-u.jp)
;
;   $LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;   $LastChangedRevision: 27922 $
;
;-
pro erg_interpolate_att, erg_xxx_in, $
  spinperiod=spinperiod, spinphase=spinphase, $
  sgiz_j2000=sgiz_j2000, sgax_j2000=sgax_j2000, sgaz_j2000=sgaz_j2000, $
  sgay_j2000=sgay_j2000, sgix_j2000=sgix_j2000, sgiy_j2000=sgiy_j2000, $
  noload=noload
  
  npar = n_params() 
  if npar ne 1 then return 
  if undefined( erg_xxx_in ) then return 
  reload = undefined( noload )  ;; if reload = 1, all necessary data are loaded. 
  get_data, erg_xxx_in, time 
  
  ;Prepare some constants
  dtor = !dpi / 180.D 
  
  ;Load the attitude data 
  if tnames('erg_att_sprate') eq 'erg_att_sprate' then begin
    if reload then tdegap,'erg_att_sprate',/overwrite
    get_data, 'erg_att_sprate', data= sprate 
    if min(sprate.x) gt min(time)+8. or max(sprate.x) lt max(time)-8. then begin
      get_timespan, tr 
      timespan, minmax(time)+[-60.D, 60.D] 
      if reload then erg_load_att 
      timespan, tr
    endif
  endif else begin
    get_timespan, tr
    timespan, minmax(time)+[-60.D, 60.D] 
    if reload then erg_load_att
    timespan, tr 
  endelse
  
  ;Interpolate spin period 
  if reload then tdegap,'erg_att_sprate',/overwrite
  get_data, 'erg_att_sprate', data=sprate 
  sper = 1.D/ ( sprate.y / 60.D ) 
  sperInterp = interpol( sper, sprate.x, time ) 
  spinperiod = { x:time, y:sperInterp } 
  
  ;Interpolate spin phase
  if reload then tdegap,'erg_att_spphase',/overwrite
  get_data, 'erg_att_spphase', data=sphase 
  nnidx = nn( sphase.x, time ) 
  ph_nn = sphase.y[nnidx] ; [deg] 
  per_nn = spinperiod.y  ;[sec]
  dt = time - sphase.x[nnidx] 
  sphInterp = ( ph_nn + 360.D*dt / per_nn ) mod 360.D 
  sphInterp = ( sphInterp + 360.D ) mod 360.D 
  spinphase = { x:time, y:sphInterp } 
  
  
  ;Interporate SGI-Z axis vector 
  if reload then tdegap,'erg_att_izras',/overwrite
  if reload then tdegap,'erg_att_izdec',/overwrite
  get_data, 'erg_att_izras', data=ras 
  get_data, 'erg_att_izdec', data=dec
  time0 = ras.x  
  ras = ras.y & dec = dec.y 
  ez = cos( (90.D - dec)*dtor ) 
  ex = sin( (90.D - dec)*dtor ) * cos( ras * dtor ) 
  ey = sin( (90.D - dec)*dtor ) * sin( ras * dtor ) 
  ex_intrp = interp( ex, time0, time ) 
  ey_intrp = interp( ey, time0, time ) 
  ez_intrp = interp( ez, time0, time ) 
  sgiz_j2000 = { x:time, y:[ [ex_intrp], [ey_intrp], [ez_intrp] ] } 
  
  
  ;Interporate SGA-X axis vector
  if reload then tdegap,'erg_att_gxras',/overwrite
  if reload then tdegap,'erg_att_gxdec',/overwrite
  get_data, 'erg_att_gxras', data=ras
  get_data, 'erg_att_gxdec', data=dec
  time0 = ras.x
  ras = ras.y & dec = dec.y
  ez = cos( (90.D - dec)*dtor )
  ex = sin( (90.D - dec)*dtor ) * cos( ras * dtor )
  ey = sin( (90.D - dec)*dtor ) * sin( ras * dtor )
  ex_intrp = interp( ex, time0, time )
  ey_intrp = interp( ey, time0, time )
  ez_intrp = interp( ez, time0, time )
  sgax_j2000 = { x:time, y:[ [ex_intrp], [ey_intrp], [ez_intrp] ] }
  
  ;Interporate SGA-Z axis vector
  if reload then tdegap,'erg_att_gzras',/overwrite
  if reload then tdegap,'erg_att_gzdec',/overwrite
  get_data, 'erg_att_gzras', data=ras
  get_data, 'erg_att_gzdec', data=dec
  time0 = ras.x
  ras = ras.y & dec = dec.y
  ez = cos( (90.D - dec)*dtor )
  ex = sin( (90.D - dec)*dtor ) * cos( ras * dtor )
  ey = sin( (90.D - dec)*dtor ) * sin( ras * dtor )
  ex_intrp = interp( ex, time0, time )
  ey_intrp = interp( ey, time0, time )
  ez_intrp = interp( ez, time0, time )
  sgaz_j2000 = { x:time, y:[ [ex_intrp], [ey_intrp], [ez_intrp] ] }
  
  ;Derive the other three axes (SGA-Y, SGI-X, SGI-Y) 
  tcrossp, sgaz_j2000.y, sgax_j2000.y, out=sgay ; SGA-Y = SGA-Z x SGA-X 
  sgay_j2000 = { x:time, y:sgay } 
  
  tcrossp, sgiz_j2000.y, sgax_j2000.y, out=sgiy ; SGI-Y = SGI-Z x SGA-X 
  sgiy_j2000 = { x:time, y:sgiy } 
  tcrossp, sgiy_j2000.y, sgiz_j2000.y, out=sgix ; SGI-X = SGI-Y x SGI-Z 
  sgix_j2000 = { x:time, y:sgix } 
  
  
end
