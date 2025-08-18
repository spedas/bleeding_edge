;+
;Procedure:
;  erg_pgs_make_phi_spec
;
;Purpose:
;  Builds phi (longitudinal) spectrogram from simplified particle data structure.
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
;  
;  -Each time this procedure runs it will concatenate the sample's data
;   to the SPEC variable.
;  -Both variables will be initialized if not set
;  -The y axis will remain a single dimension until a change is detected
;   in the data, at which point it will be expanded to two dimensions.
;
;
;Notes:
;  -Code for original value_locate() based version remains commented out
;   below. It should produce identical spectrograms for regular phi grids.
;
;History:
;  2018-12-20: forked this from spd_pgs_make_phi_spec.pro in SPEDAS
;              implementd "no_ang_weighting" keyword (by T. Hori)
;
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;-

pro erg_pgs_make_phi_spec, data, spec=spec, sigma=sigma, yaxis=yaxis, resolution=resolution, $
                           no_ang_weighting=no_ang_weighting, _extra=ex

    compile_opt idl2, hidden
  
  
  if ~is_struct(data) then return
  if undefined(no_ang_weighting) then no_ang_weighting = 0
  
  dr = !dpi/180.
  rd = 1/dr
  
  enum = dimen1(data.energy)
  anum = dimen2(data.energy)

  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
;  scaling = data.scaling
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  

  ;determine number of energies
  n_energy = (size(/dim, data.data))[0]

  ;determine number of phi bins at small theta for an energy
  ; -number of phis per theta decreases at higher latitudes for ESA
  ; -using the max number across phi should allow for equal 
  ;  statistics across phi bins
  ; -this assumes the number does not change across energy
  if undefined(resolution) then begin
    dummy = min(abs(data.theta[0,*]),tminidx)
    dummy = where(data.theta[0,*] eq (data.theta[0,*])[tminidx], n_phi)
  endif else begin
    n_phi = resolution
  endelse
  

  ;init this sample's piece of the spectrogram
  ave = replicate(!values.f_nan,n_phi)
  ave_s = ave

  ;form grid specifying the spectrogram's phi bins
  phi_grid = interpol([0,360.],n_phi+1)
  phi_grid_width = median(phi_grid - shift(phi_grid,1))
  
  
;  phi_idx = value_locate(phi_grid, data.phi)
;  phi_half_width = ceil(0.5*data.dphi / phi_grid_width)  
   

  ;get min/max of all data bins
  ;keep phi in [0,360]
  phi_min = (data.phi - 0.5*data.dphi) 
  phi_max = (data.phi + 0.5*data.dphi) mod 360.
  phic = data.phi

  ;algorithm below assumes maximums at 360 not wrapped to 0
  zm = where(phi_max eq 0, nzm)
  if nzm gt 0 then phi_max[zm] = 360
  
  ;keep phi in [0,360]
  ltz = where(phi_min lt 0, nltz)
  if nltz gt 0 then phi_min[ltz] += 360


  ;keep track of bins that span phi=0
  wrapped = phi_min gt phi_max
  
  
  ;When averaging data bins will be weighted by the solid angle of their overlap,
  ;with the given spectrogram bin.  Since each spectrogram bin spans all theta 
  ;values the theta portion of that calculation can be done in advance.  These
  ;values will later be multiplied by the overlap along phi to get the total 
  ;solid angle. 
  omega_part = abs(sin( dr * (data.theta + .5*data.dtheta) ) - $
                   sin( dr * (data.theta - .5*data.dtheta) )    )   
  
  
  ;Loop over each phi bin in the spectrogram and determine which data bins
  ;overlap.  All overlapping bins will be weighted according to the solid 
  ;angle of their intersection and averaged.
  for i=0, n_phi-1 do begin


;    idx = where( (phi_idx eq i) ,n)
    if ~no_ang_weighting then begin

      weight = fltarr(size(/dim, phi_min))
      
      ;;data bins whose maximum overlaps the current spectrogram bin
      idx_max = where(phi_max gt phi_grid[i] and phi_max lt phi_grid[i+1], nmax)
      if nmax gt 0 then begin
        weight[idx_max] = (phi_max[idx_max] - phi_grid[i]) * omega_part[idx_max]
      endif
      
      ;;data bins whose minimum overlaps the current spectrogram bin
      idx_min = where(phi_min gt phi_grid[i] and phi_min lt phi_grid[i+1], nmin)
      if nmin gt 0 then begin
        weight[idx_min] = (phi_grid[i+1] - phi_min[idx_min]) * omega_part[idx_min]
      endif
      
      ;;data bins contained withing the current spectrogram bin
      ;;check for single phi data (phi_min=phi_max)
      contained = ssl_set_intersection(idx_max, idx_min)
      if contained[0] ne -1 && n_phi gt 1 then begin
        weight[contained] = data.dphi[contained] * omega_part[contained]
      endif
      
      ;;data bins which completely cover the current spectrogram bin 
      idx_all = where( phi_min le phi_grid[i] and phi_max ge phi_grid[i+1] $
                       or (wrapped and phi_min gt phi_grid[i+1] and phi_max gt phi_grid[i+1]) $
                       or (wrapped and phi_min lt phi_grid[i]   and phi_max lt phi_grid[i]), nall)
      if nall gt 0 then begin
        weight[idx_all] = phi_grid_width * omega_part[idx_all]
      endif

      ;;combine indices 
      idx = ssl_set_union(idx_min, idx_max)
      idx = ssl_set_union(idx, idx_all)
      
      ;;assign a weighted average to this bin
      if (nmax + nmin + nall) gt 0 then begin
        
        ;; ave[i] = total(d[idx]) / total(data.bins[idx])

        ;;indices will contain a -1 if any other the searches failed 
        if idx[0] eq -1 then begin
          idx = idx[1:n_elements(idx)-1]
        endif
        
        ;;normalize weighting to selected, active bins
        weight = weight[idx] * data.bins[idx]
        weight = weight / total(weight)
        
        ;;average
        ave[i] = total(d[idx] * weight)
        
        ;;standard deviation
        ave_s[i] = sqrt(  total(d[idx] * data.scaling[idx] * weight^2)  )
        
      endif else begin
        ;;nothing
      endelse

    endif else begin ;;wighout weighting by dphi and dtheta
      
      id = where( finite(d) and data.bins and phic gt phi_grid[i] and phic lt phi_grid[i+1], nid )
      if nid eq 0 then continue

      ;;average
      if nid gt 0 then ave[i] = mean( d[id], /nan )
      ;;standard deviation
      if nid gt 2 then ave_s[i] = stddev( d[id] * data.scaling[id], /nan )

    endelse
    
  endfor

  ;------------------------------
  
  
  ;get y axis
  y = ( phi_grid + shift(phi_grid,1) ) / 2.
  y = y[1:n_phi]
  
  ;testing kludge for single-phi data
  if n_phi eq 1 then begin
    y = [0.,360]
    ave = [ave,ave]
    ave_s = [ave_s,ave_s]
  endif
  
  ;concatenate y axes
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    spd_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse

  
  ;concatenate spectra
  if undefined(spec) then begin
    spec = temporary(ave)
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