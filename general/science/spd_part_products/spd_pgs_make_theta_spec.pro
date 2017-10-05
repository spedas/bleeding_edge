;+
;Procedure:
;  spd_pgs_make_theta_spec
;
;Purpose:
;  Builds theta (latitudinal) spectrogram from simplified particle data structure.
;
;
;Input:
;  data: single sanitized data structure
;
;
;Input/Output:
;  spec: The spectrogram (ny x ntimes)
;  yaxis: The y axis (ny OR ny x ntimes)
;  resolution: (optional) Specify output resolution
;  colatitude: Flag to specify that data is in colatitude
;  
;  -Each time this procedure runs it will concatenate the sample's data
;   to the SPEC variable.
;  -Both variables will be initialized if not set
;  -The y axis will remain a single dimension until a change is detected
;   in the data, at which point it will be expanded to two dimensions.
;
;
;Notes:
;  -Resolution of output grid is determined by number of unique theta values
;   for the first energy.
;
;
;History:
;  2016-01-20: Changed algorithm to allow ungrouped theta values (~8% slower now)
;  2016-09-23: Generalized to remove restrictions on data regularity
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-09-30 17:20:25 -0700 (Fri, 30 Sep 2016) $
;$LastChangedRevision: 21989 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_make_theta_spec.pro $
;-


pro spd_pgs_make_theta_spec, data, spec=spec, sigma=sigma, yaxis=yaxis, resolution=resolution, colatitude=colatitude, _extra=ex

    compile_opt idl2, hidden
  
  
  if ~is_struct(data) then return
  
  
  dr = !dpi/180.
  rd = 1/dr
  
  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  
  ;get unique theta values
  if undefined(resolution) then begin
    values = data.theta[0,uniq( data.theta[0,*], sort(data.theta[0,*]) )]
    n_theta = n_elements(values)
  endif else begin
    n_theta = resolution
  endelse

  range = keyword_set(colatitude) ? [0,180] : [-90,90]
  theta_grid = interpol(range,n_theta+1)

  ;init this sample's piece of the spectrogram
  ave = replicate(!values.f_nan, n_theta)
  ave_s = ave
  
  theta_min = data.theta - 0.5*data.dtheta
  theta_max = data.theta + 0.5*data.dtheta


  ;loop over output grid to sum all active data and bin flags
  for i=0, n_theta-1 do begin

    weight = fltarr(size(/dim,theta_min))

    ;data bins whose maximum overlaps the current spectrogram bin
    idx_max = where(theta_max gt theta_grid[i] and theta_max lt theta_grid[i+1], nmax)
    if nmax gt 0 then begin
      weight[idx_max] = ( sin(dr * theta_max[idx_max]) - sin(dr * theta_grid[i]) ) * data.dphi[idx_max]
    endif
    
    ;data bins whose minimum overlaps the current spectrogram bin
    idx_min = where(theta_min gt theta_grid[i] and theta_min lt theta_grid[i+1], nmin)
    if nmin gt 0 then begin
      weight[idx_min] = ( sin(dr * theta_grid[i+1]) - sin(dr * theta_min[idx_min]) ) * data.dphi[idx_min]
    endif
    
    ;data bins contained withing the current spectrogram bin
    contained = ssl_set_intersection(idx_max,idx_min)
    if contained[0] ne -1 then begin
      weight[contained] = ( sin(dr * theta_max[contained]) - sin(dr * theta_min[contained]) ) * data.dphi[contained] 
    endif
    
    ;data bins that completely cover the current spectrogram bin 
    idx_all = where( theta_min le theta_grid[i] and theta_max ge theta_grid[i+1], nall)
    if nall gt 0 then begin
      weight[idx_all] = ( sin(dr * theta_grid[i+1]) - sin(dr * theta_grid[i]) ) * data.dphi[idx_all]
    endif

    ;combine indices 
    idx = ssl_set_union(idx_min,idx_max)
    idx = ssl_set_union(idx,idx_all)
    
    ;assign a weighted average to this bin
    if (nmax + nmin + nall) gt 0 then begin
    
      ;indices will contain a -1 if any other the searches failed 
      if idx[0] eq -1 then begin
        idx = idx[1:n_elements(idx)-1]
      endif
      
      ;normalize weighting to selected, active bins
      weight = weight[idx] * data.bins[idx]
      weight = weight / total(weight)
      
      ;average
      ave[i] = total(d[idx] * weight)
      
      ;standard deviation
      ave_s[i] = sqrt(  total(d[idx] * data.scaling[idx] * weight^2)  )
      
    endif else begin
      ;nothing
    endelse

  endfor


  ;get values for the y axis
  y = ( theta_grid + shift(theta_grid,1) ) / 2.
  y = y[1:n_theta]

  ;set the y axis
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    spd_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse
  
  
  ;concatenate spectra
  if undefined(spec) then begin
    spec = ave
  endif else begin
    spd_pgs_concat_spec, spec, ave
  endelse 
  
  
  ;concatenate standard deviation
  if undefined(sigma) then begin
    sigma = temporary(ave_s)
  endif else begin
    spd_pgs_concat_spec, sigma, ave_s
  endelse 

end