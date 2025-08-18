;+
;Procedure:
;  thm_part_slice2d_getsphere
;
;
;Purpose:
;  Helper function for thm_part_slice2d_getdata
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
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_getsphere.pro $
;
;-
pro thm_part_slice2d_getsphere, dist, data=data, energy=energy, $
                          rad=rad, phi=phi, theta=theta, $
                          dp=dp, dt=dt, dr=dr, $
                          fail = fail

    compile_opt idl2, hidden


  thm_part_slice2d_const, c=c


  ;Copy data
  data = dist.data

  ;Strip NaNs. They will invalidate a bin when it is summed and IDL's 
  ;contour routine makes no distinction between NaNs and 0s.
  nan_idx = where(~finite(data),nnan)
  if nnan gt 0 then begin
    data[nan_idx] = 0.
  endif  

  ;Calculate bin centers/widths in spherical coordinates. This only
  ;needs to be done once for an array of data structures if the 
  ;energy and angles bins are not changing (checked in thm_part_slice2d_getdata)
  if undefined(rad) || undefined(phi) || undefined(theta) then begin

    n = dimen1(dist.energy)
    
    ;conversion factor from eV/(km/s)^2 to eV/c^2
    erest = dist.mass * c^2 / 1e6

    ;determine gapless energy boundaries.
    ebounds = thm_part_slice2d_ebounds(dist)
    
    ;calculate radial values
    if keyword_set(energy) then begin
      ;use energy in eV
      rbounds = ebounds
    endif else begin
      ;use km/s (reletivistic calc for SST electrons)
      rbounds = c * sqrt( 1 - 1/((ebounds/erest + 1)^2) )  /  1000.
    endelse
    
    ;get radial centers
    rad = float(  (rbounds[0:n-1,*] + rbounds[1:n,*]) / 2  )
    phi = dist.phi
    theta = dist.theta

    ;get bin widths (mainly for geometric method)
    dr = float(  abs(rbounds[1:n,*] - rbounds[0:n-1,*])  )
    dp = dist.dphi
    dt = dist.dtheta 
    
  endif


  return

end

