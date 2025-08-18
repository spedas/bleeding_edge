;+
;Procedure:
;  thm_part_slice2d_regridsphere
;  
;
;Purpose:
;  Helper function for thm_part_slice2d_getdata
;  Spherically interpolates a structure's data to a specified regular grid
;  and returns the center and width of all bins in spherical coordinates. 
;
;
;Input:
;  dist: 3D data structure
;  energy: flag to return radial componenets in eV instead of km/s
;  regrid: 3 Element array specifying the new number of points in 
;          phi, theta, and energy respectively.
;
;
;Output:
;  data: N element array containing interpolated particle data
;  bins: N element array of flags denoting datapoint validity
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
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-03-04 18:05:22 -0800 (Fri, 04 Mar 2016) $
;$LastChangedRevision: 20331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/core/thm_part_slice2d_regridsphere.pro $
;
;-
pro thm_part_slice2d_regridsphere, dist, energy=energy, regrid=regrid, $
                           rad=rad, phi=phi, theta=theta, $
                           dp=dp, dt=dt, dr=dr, $
                           data=data_out, bins=bins_out, $
                           fail=fail

    compile_opt idl2, hidden


  thm_part_slice2d_const, c=c

  if n_elements(regrid) lt 3 then begin
    fail = 'REGRID keyword must contain 3 elements [phi,theta,energy]'
    return
  endif

  method = 'NearestNeighbor'

  ;convert mass from eV/(km/s)^2 to eV/c^2
  erest = dist.mass * c^2 / 1e6

  nangles = regrid[0] * regrid[1]
  nenergy = dimen1(dist.energy)
  ncopies = round(regrid[2]/nenergy) > 1
  
  ;set up new angle grid
  phigrid0 = interpol([0,360],regrid[0]+1)
  phigrid = (phigrid0[0:regrid[0]-1] + phigrid0[1:*])/2
  thetagrid0 = interpol([-90,90],regrid[1]+1)
  thetagrid = (thetagrid0[0:regrid[1]-1] + thetagrid0[1:*])/2
  

  ;Spherically interpolate the data at each energy using the nearest neighbor.
  ;----------------------------------------------------------------
  for i=0, nenergy-1 do begin
    
;    ;ignore energies with no valid bins (saves resources)
;    if total(dist.bins[i,*]) lt 1 then continue
    
    ;Angles and data must be copied into new variable for triangulation/gridding
    phitemp = reform(dist.phi[i,*])
    thetatemp = reform(dist.theta[i,*])
    datatemp = reform(dist.data[i,*])
    binstemp = reform(dist.bins[i,*]) 
    
    ;Create a required sphereical triangulation
    ;(2013-11) this could probably be moved outside the loop
    qhull, phitemp, thetatemp, triangles, sphere=dummy
    
    ;Interpolate this energy's data onto a regular spherical grid
    newdata = griddata(phitemp, thetatemp, datatemp, $
                       method=method, /sphere, /degrees, triangles=triangles, $
                       /grid, xout=phigrid, yout=thetagrid)
                       
    newbins = griddata(phitemp, thetatemp, binstemp, $
                       method=method, /sphere, /degrees, triangles=triangles, $
                       /grid, xout=phigrid, yout=thetagrid)

    ;Expand/copy data if energies are being added
    data = array_concat( reform(temporary(newdata),nangles), data)
    bins = array_concat( reform(temporary(newbins),nangles), bins)
                  
  endfor


  ;Calculate new spherical coordinates (only do this once).
  ;---------------------------------------------------------------
  if undefined(rad) || undefined(phi) || undefined(theta) then begin

    ;calculate radial values
    ebounds = thm_part_slice2d_ebounds(dist)
    if keyword_set(energy) then begin
      ;use energy in eV
      rbounds = ebounds
    endif else begin
      ;use km/s (reletivistic calc for SST electrons)
      rbounds = c * sqrt( 1 - 1/((ebounds/erest + 1)^2) )  /  1000.
    endelse
    
    ;get radial values & widths
    rad = reform(float(  (rbounds[0:nenergy-1,0] + rbounds[1:*,0]) / 2  ))
    dr =  reform(float(  abs( rbounds[1:*,0] - rbounds[0:nenergy-1,0] )  ))
    
    ;combine angle arrays
    phi =   reform( phigrid # replicate(1,regrid[1])   ,nangles)
    theta = reform( replicate(1,regrid[0]) # thetagrid ,nangles)

    ;expand all arrays to match data dimensions ( nangles x nenergies )
    rad =   reform(  replicate(1,nangles) # rad   ,nangles*nenergy)
    phi =   reform(  phi # replicate(1,nenergy)   ,nangles*nenergy)
    theta = reform(  theta # replicate(1,nenergy) ,nangles*nenergy)
    
    dr = reform(  replicate(1,nangles) # dr  ,nangles*nenergy)
    dp = replicate( 360./regrid[0], nangles*nenergy)
    dt = replicate( 180./regrid[1], nangles*nenergy)
  
    ;expand if extra energies are needed
    if ncopies gt 1 then begin
      
      ;create new evenly spaced energies
      rad = rad # (1 + 1./(ncopies+1) * ( findgen(ncopies) - .5 * (ncopies-1 > 1) ))
      phi = phi # replicate(1,ncopies)
      theta = theta # replicate(1,ncopies)

      dr = (dr # replicate(1,ncopies)) / ncopies
      dp = dp # replicate(1,ncopies)
      dt = dt # replicate(1,ncopies)
      
    endif
  
  endif


  ;Pass out interpolated data and bins
  ;---------------------------------------------------------------
  
  ;expand if extra energies are needed
  if ncopies gt 1 then begin
    data = data # replicate(1.,ncopies)
    bins = bins # replicate(1.,ncopies)    
  endif

  ;move arrays to output variables
  data_out = temporary(data)
  bins_out = temporary(bins)

  return

end

