;+
;Procedure:
;  spd_slice2d_get_sphere
;
;
;Purpose:
;  Helper function for spd_slice2d_getdata
;  Calculates the center and width of all bins in spherical coordinates.
;
;
;Input:
;  dist: 3D data structure
;  energy: flag to return energy as radial componenet instead of velocity
;
;
;Output:
;  data: N element array containing interpolated particle data
;  rad: N element array of bin centers along r (eV or km/s)
;  phi: N element array of bin centers along phi
;  theta: N element array of bin centers along theta
;  dr: N element array of bin widths along r (eV or km/s)
;  dp: N element array of bin widths along phi
;  dt: N element array of bin widths along theta
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-10-02 20:01:21 -0700 (Fri, 02 Oct 2015) $
;$LastChangedRevision: 18995 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_get_sphere.pro $
;
;-
pro spd_slice2d_get_sphere, dist, data=data, energy=energy, $
                            rad=rad, phi=phi, theta=theta, $
                            dp=dp, dt=dt, dr=dr

    compile_opt idl2, hidden


  spd_slice2d_const, c=c


  ;Copy data
  data = dist.data

  ;Strip NaNs. They will invalidate a bin when it is summed and IDL's 
  ;contour routine makes no distinction between NaNs and 0s.
  nan_idx = where(~finite(data),nnan)
  if nnan gt 0 then begin
    data[nan_idx] = 0.
  endif  

  ;Calculate bin centers/widths in spherical coordinates.
  ;This only needs to be done once for an array of data structures if the 
  ;energy and angles bins are not changing (checked in spd_slice2d_getdata)
  if undefined(rad) || undefined(phi) || undefined(theta) then begin

    n = dimen1(dist.energy)
    
    ;determine gapless energy boundaries.
    ebounds = spd_slice2d_get_ebounds(dist)
    
    ;calculate radial values
    if keyword_set(energy) then begin
      ;energy in eV
      rbounds = ebounds
    endif else begin
      ;convert mass from eV/(km/s)^2 to eV/c^2
      erest = dist.mass * c^2 / 1e6
      ;velocity in km/s (reletivistic calc for high energy electrons)
      rbounds = c * sqrt( 1 - 1/((ebounds/erest + 1)^2) )  /  1000.
    endelse
    
    ;get radial centers
    ;extra * indices needed in case of extra data dimension
    rad = float(  (rbounds[0:n-1,*,*] + rbounds[1:n,*,*]) / 2  )
    phi = dist.phi
    theta = dist.theta

    ;get bin widths (mainly for geometric method)
    dr = float(  abs(rbounds[1:n,*,*] - rbounds[0:n-1,*,*])  )
    dp = dist.dphi
    dt = dist.dtheta 
    
  endif


  return

end

