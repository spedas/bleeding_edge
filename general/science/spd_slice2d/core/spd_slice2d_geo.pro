
;+
; 
; Name:
;   spd_slice2d_geo.pro
; 
; Purpose:  
;   Helper function for spd_slice2d.pro
;
;   Produces slices showing each bin's boundaries by assigning
;   each bin's value to all points on the slice plane that 
;   fall within that bin's boundaries.
;
;   This is essentially a hack to allow plotting of bin boundaries 
;   with contour instead of creating a new plotting routine.
;
; Input:
;   data: N element array of data values
;   rad: N element array of radial values
;   phi: N element array of phi values
;   theta: N element array of theta values
;
;   dp: N element array of phi ranges
;   dt: N element array of theta ranges
;   dr: N element array of velocity ranges
;
;   resolution: Single value (R) giving the number of points in each
;               dimension of the slice
;   average_angle: Two element array specifying an angle range over which 
;                  averaging will be applied. The angle is measured 
;                  from the slice plane and about the slice's x-axis.
;                    e.g. [-25,25] will average data within 25 degrees
;                         of the slice plane about it's x-axis
;
;   custom_matrix: Rotation matrix from native -> user specified coordinates
;                  (applied first)
;   rotation_matrix: Rotation matrix from given coordinates to built in 
;                    rotated coordinates, e.g. GSM -> BV, perp_xy
;                    (applied second)
;   slice_matrix: Rotation matrix from specified coords/rotation into
;                  the slice plane's final coordinates as defined by
;                  the user specified normal and x projection.
;                  (applied last)
;   shift: Vector by which the slice should be shifted (e.g. bulk velocity subtraction).
;          The slice plane will be shifted by the z value and the x & y values will be 
;          subtracted from the corresponding axes' grids (it should already be in the 
;          slice plane's coordinates). 
; 
; Output:
;   xgrid: R element array of x-axis values for the slice
;   ygrid: R element array of y-axis values for the slice
;   slice: RxR element array containing the slice data
; 
; Other Keywords: 
;   msg_obj: dprint display object reference
;   msg_prefix: String prefix to be printed with progress messages.
; 
; Notes: 
;   -This routine will slow as the number of bins (N) increases.
;    Averaging will significantly lengthen the required time. 
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-10-19 09:02:17 -0700 (Wed, 19 Oct 2016) $
; $LastChangedRevision: 22148 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_geo.pro $
;-
pro spd_slice2d_geo, data=data, resolution=resolution, $
                     rad=r, phi=phi, theta=theta, $
                     dr=dr, dp=dp, dt=dt, $ 
                     custom_matrix=ct, rotation_matrix=rot, orient_matrix=mt, $
                     shift=shift, $
                     average_angle=average_angle, $
                    ; Data Output
                     slice=slice, xgrid=xgrid, ygrid=ygrid, $
                    ; Info Output
                     fail=fail, msg_obj=msg_obj, msg_prefix=msg_prefix, $
                    ; Other
                     _extra=_extra

    compile_opt idl2, hidden

  ;for progress messages
  previous_time = systime(/sec)

  n = float(resolution)
  rd = 180./!dpi
  tolerance = 5d-7

  ;Initialize slice and coordinates
  slice = dblarr(n,n)

  ;Create grid of coordinates for entire slice plane
  vrange = max(abs(r))*[-1,1]
  xgrid = interpol(vrange + [-1,1]*max(dr), n)
  ygrid = interpol(vrange + [-1,1]*max(dr), n)
  z = undefined(shift) ? 0. : shift[2]
  u = [ [reform(xgrid # replicate(1.,n), n^2)], $  ;x
        [reform(replicate(1.,n) # ygrid, n^2)], $  ;y
        [reform(replicate(z,[n,n]), n^2)]   ]      ;z


  ;Rotate slice coordinates to desired location. 
  ;The "ct" and "rot" matrices transform INTO the slice plane's coordinates.  
  ;To determine which bins intersect the slice plane the transformtion
  ;is reversed and the applied to the slice itself to transorm it
  ;into the data's native coordinates.
  m = mt
  if keyword_set(ct) then begin
    if keyword_set(rot) then m = (ct # rot) # m $
      else m = ct # m
  endif else begin
    if keyword_set(rot) then m = rot # m
  endelse
  u = u # transpose(m)


  ;Get necesary rotations for averaging.
  ;The coordinates of the slice plane will be rotated through the 
  ;specified angle range. A separate search will be done at each 
  ;new plane. The number of planes is determined from the desired
  ;resolution and the width of the average.
  if keyword_set(average_angle) then begin
    alpha = minmax(average_angle)
    
    ;number of additional slices to average over 
    na = (2 * sqrt(n) * (alpha[1]-alpha[0])/90.) > 2
    
    ;copy slice's x-vector
    xv = m[*,0] ## replicate(1d,na)
    
    ;interpolate across the angle range
    a = ([dindgen(na-1)/(na-1),1] * (alpha[1]-alpha[0])) + alpha[0]

    ;constuct quaternion array to get rotation matricies
    qs = qcompose(xv,a/rd, /free) ;quaternions to rotate about x by a
    ms = qtom(qs) ;get matricies
    
    if n_elements(ms) eq 1 then begin
      fail = 'Error: Cannot construct rotation matrices for angular averaging.'
      dprint, dlevel=0, fail 
      return
    endif

;    Testing vectorization...
;    ut = u
;    for i=0, na-1 do begin
;      ut = [ [temporary(ut)], [qrotv2(qs[i,*],u)] ]
;    endfor
;    
;    u = temporary(ut)
;
;    ix = lindgen(na)*3
;    iy = ix+1
;    iz = ix+2
;
;    ;Convert transformed slice coordinates to spherical
;    pcoords = rd * atan(u[*,iy],u[*,ix])                        ;phi
;    tcoords = rd * atan(u[*,iz], sqrt(u[*,ix]^2 + u[*,iy]^2))   ;theta
;    rcoords = sqrt(u[*,ix]^2 + u[*,iy]^2 + temporary(u[*,iz]^2));r
  
  endif else na = 0 ;simplify first loop below
  

  ;Loop over slice planes (if averaging over angle)
  ;A vectorized method was tested and took longer.
  weight = bytarr(size(slice,/dim))
  np = n_elements(data)
  for j=-1, na-1 do begin
    
    ut = j ge 0 ? reform(ms[j,*,*]) ## u:u
    
    ;Convert transformed slice coordinates to spherical
    pcoords = rd * atan(ut[*,1],ut[*,0])                       ;phi
    tcoords = rd * atan(ut[*,2], sqrt(total(ut[*,0:1]^2,2)) )  ;theta
    rcoords = sqrt(ut[*,0]^2 + ut[*,1]^2 + ut[*,2]^2)          ;r
    
    ;Loop over bins to determine what region each bin covers on the slice plane.
    for i=0, np-1 do begin
      if data[i] eq 0 then continue
  
      ; Theta--
      tlim = [ theta[i]-0.5*dt[i], theta[i]+0.5*dt[i] ]
  
      ;account for rounding errors
      ;this is particularly important is slice plane is at zero elevation
      tr = where( abs(tlim - round(tlim)) lt tolerance, ntr)
      if ntr gt 0 then tlim[tr] = round(tlim[tr])
      
      t = (tcoords gt tlim[0]) and (tcoords le tlim[1])
  
      if total(t) lt 1 then continue
  
      
      ; Phi--
      plim = [ phi[i]-0.5*dp[i], phi[i]+0.5*dp[i] ]
      
      ; keep limits within [-180,180]
      over = where(plim gt 180, no)
      under = where(plim lt -180, nu)
      if no gt 0 then plim[over] += -360
      if nu gt 0 then plim[under] += 360
      
      ;account for rounding errors
      pr = where( abs(plim - round(plim)) lt tolerance, npr)
      if npr gt 0 then plim[pr] = round(plim[pr])
      
      ;determine which region ( p0->p1 or p1->p0) the bin spans
      if plim[0] gt plim[1] then begin
        p = (pcoords gt plim[0]) or (pcoords le plim[1])
      endif else begin
        p = (pcoords gt plim[0]) and (pcoords le plim[1])
      endelse
  
      if total(p) lt 1 then continue
  
      
      ; R (velocity/energy)--
      s = (rcoords ge r[i]-0.5*dr[i]) and (rcoords lt r[i]+0.5*dr[i])
  
  
      ; Combine criteria and assign values--
      bidx = where( p and t and s, nb) 
  
      if nb gt 0 then begin
        weight[bidx]++ 
        slice[bidx] += data[i]
      endif
  
  
      ; Output progress messages every 6 seconds--
      if systime(/sec) - previous_time gt 6 then begin
      
        msg = strtrim(long(  100.*((j+1)*np + i)/((na>1)*np)  ),2) + '% complete'
        if keyword_set(msg_prefix) then msg = msg_prefix + msg
        
        dprint, dlevel=2, msg, display_object=msg_obj
        
        previous_time = systime(/sec)
      endif
      
    endfor
  endfor
  
  
  ;Average areas where bins overlapped
  adj = where(weight eq 0, na)
  if na gt 0 then weight[adj] = 1b
  slice = slice / weight
  
  
  ;Align the x & y axis values if there was a shift
  if ~undefined(shift) then begin
    xgrid -= shift[0]
    ygrid -= shift[1]
  endif

  return

end

