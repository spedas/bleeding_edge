;+
;Procedure:
;  erg_lepe_get_dist
;
;Purpose:
;  The helper function to put all necesssary data and parameters
;  in a 3-D data structure common to part_products libraries. 
;
;Calling Sequence:
;  Usually this routine is called internally by erg_lepe_part_products.
;
;Author:
;  Tomo Hori, ERG Science Center, Nagoya Univ.
;  (E-mail tomo.hori _at_ nagoya-u.jp)
;
;History:
;  ver.0.0: The 1st experimental release
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2025-10-09 10:09:10 -0700 (Thu, 09 Oct 2025) $
;$LastChangedRevision: 33720 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/particle/erg_lepe_get_dist.pro $
;-
function erg_lepe_get_dist $
   , tname, index, trange=trange, times=times $
   , structure=structure $
   , species=species $
   , units=units $
   , level=level $
   , single_time=time_in $
   , subtract_error=subtract_err, error=error $
   , debug=debug $
   , _extra=_extra

  
  compile_opt idl2, hidden

  if undefined(debug) then debug = 0

  
  ;; If given the entire data set and times / time indices
  if is_struct(_extra) then begin
    if is_struct(*(_extra.alldist_ptr)) then begin

      ;;if debug then help, alldist
      
      if ~undefined(index) then begin
        return, (*(_extra.alldist_ptr))[index]
      endif
      
      if ~undefined(single_time) then begin
        nearest_time = find_nearest_neighbor((*(_extra.alldist_ptr)).time, time_double(single_time))
        if nearest_time eq -1 then begin
          dprint, 'Cannot find requested time in the data set: ' + time_string(single_time)
          return, 0
        endif
        index = where((*(_extra.alldist_ptr)).time eq nearest_time)
        return, (*(_extra.alldist_ptr))[index]
      endif
    endif
    
  endif

  if undefined(units) then units = 'flux'
  if undefined(level) then level = 'l2'
  level = strlowcase(level)

  name = (tnames(tname))[0]
  if name eq '' then begin
    dprint, 'Variable: "'+tname+'" not found!'
    return, 0
  endif

  ;; Extract some information from a tplot variable name
  ;; e.g., erg_lepe_l2_3dflux_FEDU
  vn_info = strsplit(/ext, name, '_')
  instrument = vn_info[1]
  level = vn_info[2]
  case instrument of
    'lepe': species = 'e'
    else: begin
      dprint, 'ERROR: given an invalid tplot variable: '+name
      return, 0
    endelse
  endcase
  
  ;; Get a reference to data and metadata
  get_data, name, ptr=p, dlimits=dl
  if ~is_struct(p) then begin
    dprint, 'Variable: "'+tname+'" contains invalid data or no data!'
    return, 0
  endif
  if size(*p.y, /n_dim) ne 4 then begin
    dprint, 'Variable: "'+tname+'" contains wrong number of elements!'
    return, 0
  endif
    

  ;; Return time labels
  if keyword_set(times) then begin
    return, *p.x
  endif

  ;; single_time supersedes index and trange
  if ~undefined(single_time) then begin
    nearest_time = find_nearest_neighbor(*p.x, time_double(single_time))
    if nearest_time eq -1 then begin
      dprint, 'Cannot find requested time in the data set: ' + time_string(single_time)
      return, 0
    endif
    index = where(*p.x eq nearest_time)
    n_times = n_elements(index)
  endif else begin
    ;;index supersedes time range
    if undefined(index) then begin
      if ~undefined(trange) then begin
        tr = minmax(time_double(trange))
        index = where( *p.x ge tr[0] and *p.x lt tr[1], n_times)
        if n_times eq 0 then begin
          dprint, 'No data in time range: '+strjoin(time_string(tr, tformat='YYYY-MM-DD/hh:mm:ss.fff'), ' ')
          return, 0
        endif
      endif else begin
        n_times = n_elements(*p.x)
        index = lindgen(n_times)
      endelse
    endif else begin
      n_times = n_elements(index)
    endelse
  endelse 

  ;; --------------------------------------------------------------

  ;; LEP-e data Array[10269(time), 32(energy), 12(anode), 16(spin
  ;; phase)] for the normal 3-D flux mode (fine channels are averaged
  ;;into two coarse channels)
  
  ;; Dimensions
  dim = (size(*p.y, /dim))[1:*]
  dim = dim[ [0, 2, 1] ] ;; to [ energy, spin phase(azimuth), anode(elevation) ]
  base_arr = fltarr(dim)

  ;; Support data
  ;; Mass is given in eV/(km/s)^2 for compatibility with other
  ;; routines
  case strlowcase(species) of

    'e': begin
      mass = 5.68566e-06
      charge = -1.
      data_name = 'LEP-e Electron 3dflux'
      integ_time = 7.99 / 32 / 16 ;; currently hard-coded
    end
    else: begin
      dprint, 'given species is not supported by this routine.'
      return, 0
    endelse
    
  endcase

  ;; basic template structure compatible with spd_slice2d and other
  ;;routines
  template = $
     { $
     project_name: 'ERG', $
     spacecraft: 1, $           ; always 1 as a dummy value
     data_name: data_name, $
     units_name: 'flux', $      ; LEP-e data in [/eV-s-sr-cm2] 
     units_procedure: 'erg_convert_flux_units', $
     species: species, $
     valid: 1b, $

     charge: charge, $
     mass: mass, $
     time: 0d, $
     end_time: 0d, $

     data: base_arr, $
     bins: base_arr+1, $        ; must be set or data will be consider invalid

     energy: base_arr, $        ; should be in eV
     denergy: base_arr, $
     nenergy: dim[0], $         ; # of energy chs
     nbins: dim[1]*dim[2], $    ; # thetas * # phis
     phi: base_arr, $
     dphi: base_arr, $
     theta: base_arr, $
     dtheta: base_arr $
     }

  dist = replicate( template, n_times)
    
  ;; Then, fill in arrays in the data structure
  ;;   dim[ nenergy, nspinph(azimuth), nanode(elevation), ntime]
  
  dist.time = (*p.x)[index]
  dist.end_time = (*p.x)[index] + integ_time ;; currently hard-coded

  ;; Shuffle the original data array [time,energy, anode, spin phase] to
  ;; be energy-azimuth(spin phase)-elevation-time.
  dist.data = transpose( (*p.y)[index, *, *, *], [1, 3, 2, 0] ) 

  ;; fishy negative flux values are all replaced with zero.
  ;;dat = dist.data
  ;;id = where( dat lt 0., nid )
  ;;if nid gt 0 then dat[id] = 0.
  ;;dist.data = temporary(dat)
  
  
  ;; Extract necessary information from the Lv2 data CDF file
  cdffpath = dl.cdf.filename
  if ~file_test(cdffpath) then begin
    dprint, 'Cannot locate a data CDF file from which necessary information is extacted from!!'
    return, 0
  endif
  cdfi = cdf_load_vars(cdffpath, varformat=['FEDU_Energy', 'FEDU_Angle_SGA', 'fedu_angle_sga'])
  
  ;; Energy ch
  ;; Energy bin width from the data variable in a CDF file
  ;;id = where( strcmp( cdfi.vars.name, 'FEDU_Energy' ) )
  ;;enearr = ( *( cdfi.vars[id].dataptr ) )[index, *, *] ;; [time, 2, 32] 
  ;;e0 = reform( (enearr[*, 0, *] + enearr[*, 1, *])/2  ) ;; [time, 32]

  e0 = (*p.v)[index, *] ;; [time, 32]

  dist.energy =  rebin( reform( transpose(e0), [dim[0], 1,  1, n_times]), [dim, n_times] )

  dearr = e0 + !values.f_nan ;; initialized as [ time, 32 ]  
  for i=0L, n_times-1 do begin

    enec0 = reform( e0[i, *] ) ;; [32]
    id = where( finite( enec0 ), nid)
    if nid lt 2 then continue
    enec = spd_uniq( enec0[id] )    ;sorting and picks up only uniq elements. nominally 30, 28, 5, 4.
    if n_elements(enec) lt 3 or total( enec lt 0. ) then continue ;; invalid energy value found
    
    logenec = alog10( enec ) & nenec = n_elements(enec) 
    logmn = (logenec[1:*]+logenec)/2  
    logdep = enec*0 & logdem = enec*0
    logdep[0:(nenec-2)] = logmn
    logdem[1:(nenec-1)] = logmn
    logdem[0] = logenec[0] - ( logmn[0]-logenec[0] )
    logdep[nenec-1] = logenec[nenec-1] + ( logenec[nenec-1]-logmn[nenec-2] )
    de = 10.^logdep - 10.^logdem

    id = nn( enec, enec0 ) 
    dearr[i, *] =  transpose(de[id])
  endfor
  
  dist.denergy = rebin( reform( transpose(dearr), [dim[0], 1,  1, n_times]), [dim, n_times] )

  
  ;; Array elements containing NaN are excluded from the further
  ;; calculations, by setting bins to be zero. 
  dist.bins = ( finite( dist.data ) and finite( dist.energy ) )

  
  ;; azimuthal angle in spin direction
  id = where( strcmp( cdfi.vars.name, 'FEDU_Angle_SGA' , /fold_case))
  angarr = *( cdfi.vars[id].dataptr )  ;;[elev/phi, (anode)] in SGA  (looking dir)

  ;; Flip the looking dirs to the flux dirs
  nanode = n_elements( angarr[0,*] )
  r = replicate(1., nanode) & elev = reform( angarr[0,*] ) & phi = reform( angarr[1,*] )
  sphere_to_cart, r, elev, phi, x, y, z 
  cart_to_sphere, -x, -y, -z, r, elev, phi, /ph_0_360
  angarr = [ transpose(elev), transpose(phi) ]  ;; [ elev/phi, (anode) ]

  phissi = reform( angarr[1, *] ) - (90.+21.6) ;; [(anode)] (21.6 = degree between sun senser and satellite coordinate)
  spinph_ofst = *p.v3 * 22.5
  phi0 = rebin( reform(phissi, [1, 1, dim[2], 1]), [dim, n_times] ) $
         + rebin( reform(spinph_ofst, [1, dim[1], 1, 1]), [dim, n_times] )

  ofst_sv = (findgen(dim[0])+0.5) * 22.5/dim[0] ;; [(energy)]
  phi_ofst_for_sv = rebin( reform(ofst_sv, [dim[0], 1, 1, 1]), [dim, n_times] )
  ;;  phi angle for the start of each spin phase
  ;;    + offset angle foreach sv step
  dist.phi = ( phi0 + phi_ofst_for_sv + 360. ) mod 360 
  dist.dphi = replicate( 22.5, [dim, n_times] ) ;; 22.5 deg as a constant
  undefine, phi0, phi_ofst_for_sv  ;; Clean huge arrays
  
  ;; elevation angle
  elev = reform( angarr[0, *] ) ;; [(anode)]
  dist.theta = rebin( reform(elev, [1, 1, dim[2], 1]), [dim, n_times] )
  
  ;; elevation angle for fine channel  
  vn_info = strsplit(/ext, tname, '_')
  fine_ch = ssl_check_valid_name(vn_info, 'finech',/no_warning)
  if (fine_ch eq 'finech') then begin
    dist.dtheta = replicate( 22.5/6, [dim, n_times] ) ;; Fill all with 22.5 first
  endif else begin
    dist.dtheta = replicate( 22.5, [dim, n_times] ) ;; Fill all with 22.5 first
    ;; give half weight for ch1,2,3,4, 19,20,21,22
    dist.dtheta[*, *, 0:3, *] = 11.25
    dist.dtheta[*, *, (dim[2]-4):(dim[2]-1), *] = 11.25
    if dim[2] eq 22 then begin ;; with full fine channels
      dist.dtheta[*, *, 5:16, *] = 22.5/6
    endif
  endelse
  
  return, dist
end
