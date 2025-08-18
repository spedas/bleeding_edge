;+
;Procedure:
;  spd_pgs_regrid
;
;Purpose:
;  Regrids rotated data to a new set of regularly gridded spherical interpolates
;
;Input:
;  data: The struct to be regridded
;  regrid_dimen: 2-element array specifying the requested number of phis & thetas in regridded output.
;    
;Output:
;  output=output:  The struct of regridded data
;  error=error: 1 indicates error occured, 0 indicates no error occured
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-07-05 09:17:03 -0700 (Wed, 05 Jul 2017) $
;$LastChangedRevision: 23548 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_regrid.pro $
;-


pro spd_pgs_regrid,data,regrid_dimen,output=output,error=error


  compile_opt idl2,hidden

  error = 1

  n_energy = (dimen(data.data))[0]  
 
  ;code copied from thm_part_moments2.pro
  ;not necessarily the most efficient way, but the best way to match old result
  n_phi_grid = ulong64(regrid_dimen[0])
  n_theta_grid = ulong64(regrid_dimen[1])
  n_bins_grid = n_phi_grid*n_theta_grid
  
  ;Modified to use ull's so we problably don't need this chec
  ; check to make sure the xyz array sizes don't exceed 32-bit limit
;  if (n_bins_grid * ns * 3D * 8 gt 2D^31) AND gui_flag then begin
;    mess = ['Regrid sizes are too large for amount of time requested.', $
;      strupcase(format) + ' will not be processed.']
;    dum = dialog_message(mess, title='THM_PART_GETSPEC: Insufficient Memory', $
;      /center, /info)
;    continue
;  end
  
  ; create FAC version of phis, thetas, dphis, dthetas using REGRID input
  d_phi_grid = 360./n_phi_grid
  d_theta_grid = 180./n_theta_grid
  phi_grid = replicate(1,n_energy)#((findgen(n_bins_grid) mod n_phi_grid)*d_phi_grid + d_phi_grid/2)
  theta_grid = replicate(1,n_energy)#(fix(findgen(n_bins_grid)/n_phi_grid)*d_theta_grid + d_theta_grid/2 - 90)
  d_phi_grid = replicate(1,n_energy)#(fltarr(n_bins_grid)+d_phi_grid)
  d_theta_grid = replicate(1,n_energy)#(fltarr(n_bins_grid)+d_phi_grid)

  data_grid = fltarr([n_energy,n_bins_grid])
  bins_grid = intarr([n_energy,n_bins_grid])
  
 ;copied from thm_pgs_clean_sst.pro
  output_t = {data:data_grid, $ ;particle data 2-d array, energy by angle. (Float or double)
            scaling:data_grid, $
            mass:data.mass, $
            time:data.time, $ ;sample start time(1-element double precision scalar)
            end_time:data.end_time, $ ;sample end time(1-element double precision scalar)
            phi:phi_grid, $ ;Measurment angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
            dphi:d_phi_grid, $ ;Width of measurement angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
            theta:theta_grid, $ ;Measurment angle in plane perpendicular to spacecraft spin.(2-d array matching data array.) (Float or double)
            dtheta:d_theta_grid, $ ;Width of measurement angle in plane perpendicular to spacecraft spin. (2-d array matching data array.) (Float or double)
            energy:data_grid, $ ;Contains measurment energy for each component of data array. (2-d array matching data array.) (Float or double)
            denergy:data_grid, $ ;Width of measurment energy for each component of data array. (2-d array matching data array.)
            bins:bins_grid $ ; 0-1 array, indicating which bins are enabled for subsequent calculations. (2-d array matching data array.)  (Integer type.)
          }

  ; add dimensions if it exists in the input structure; some MMS PGS routines use
  ; this to determine angular bin sizes
  if tag_exist(data, 'dims') then str_element, output_t, 'dims', data.dims, /add
  if tag_exist(data, 'orig_energy') then str_element, output_t, 'orig_energy', data.orig_energy, /add
 
  ;some magic with griddata goes here
  ;
  ;griddata magic copied from thm_part_slice2d_getxyz.pro
   method = 'NearestNeighbor'
;  phigrid = interpol( [0.,360], regrid[0])
;  thetagrid = interpol( minmax(thedata.theta), regrid[1])

  ;assumes energies are constant across angle
  output_t.energy = data.energy[*,0] # replicate(1,n_bins_grid)
  output_t.denergy = data.denergy[*,0] # replicate(1,n_bins_grid)
  
  ;qhull will choke if given only a single angle to triangulate
  if n_elements(reform(data.phi[0,*])) gt 1 then begin
    ; Create a (required) spherical triangulation
    ;for ESA & SST this triangulation is invariant across energy, even if the angles themselves may change across energy
    qhull, reform(data.phi[0,*]), reform(data.theta[0,*]), triangles, sphere=dummy
  endif


  for i = 0,n_energy-1 do begin

    ; Angles and data must be copied into new variable for triangulation/gridding
    phi_temp = reform(data.phi[i,*])
    theta_temp = reform(data.theta[i,*])
    data_temp = reform(data.data[i,*])
    bins_temp = reform(data.bins[i,*])
    scaling_temp = reform(data.scaling[i,*])
    
;    if regrid[0] lt n_elements(phitemp[uniq(phitemp, sort(phitemp))]) or $
;      regrid[1] lt n_elements(thetatemp[uniq(thetatemp, sort(thetatemp))]) then begin
;      dprint, dlevel=1, "WARNING: Current regrid settings are below the current data's resolution."
;    endif
;    
    
    ;qhull will choke if given only a single angle to triangulate
    if n_elements(phi_temp) gt 1 then begin 

      ;If griddata is reports triangles not in counterclockwise order:
      ;  -look directions my differ between energies
      ;   (this will require that qhull be called for each energy)
      ;  -there may be duplicate points in the input to qhull
      ;   (check for theta = +-90) 
     
      ; Interpolate this energy's data onto a regular spherical grid
      output_t.data[i,*] = griddata(phi_temp, theta_temp, data_temp, $
        method=method, /sphere, /degrees, $
        triangles=triangles, $
        ;/grid,$
        xout=reform(phi_grid[i,*]), yout=reform(theta_grid[i,*]))
          
      ; Interpolate this energy's bins onto a regular spherical grid
      output_t.bins[i,*] = griddata(phi_temp, theta_temp, bins_temp, $
        method=method, /sphere, /degrees, $
        triangles=triangles, $
        ;/grid,$
        xout=reform(phi_grid[i,*]), yout=reform(theta_grid[i,*]))
      
      ; Interpolate this energy's scaling factors onto a regular spherical grid
      ; (for error estimate)
      output_t.scaling[i,*] = griddata(phi_temp, theta_temp, scaling_temp, $
        method=method, /sphere, /degrees, $
        triangles=triangles, $
        ;/grid,$
        xout=reform(phi_grid[i,*]), yout=reform(theta_grid[i,*]))
    endif else begin
;      
      output_t.data[i,*] = data_temp
      output_t.bins[i,*] = bins_temp  
      output_t.scaling[i,*] = scaling_temp   
;       
    endelse
        
          
  endfor
  
  output=output_t ; overwrite output with temp variable
  
  error = 0
end