;+
;Procedure:
;  erg_hep_get_dist
;
;Purpose:
;  The helper function to put all necesssary data and parameters
;  in a 3-D data structure common to part_products libraries. 
;
;Calling Sequence:
;  Usually this routine is called internally by erg_hep_part_products.
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-10-23 14:19:14 -0700 (Wed, 23 Oct 2019) $
;$LastChangedRevision: 27922 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/particle/erg_hep_get_dist.pro $
;-
function erg_hep_get_dist $
   , tname, index, trange=trange, times=times $
   , structure=structure $
   , species=species $
   , units=units $
   , level=level $
   , single_time=time_in $
   , subtract_error=subtract_err, error=error $
   , corrected_azim_ch_angle=corrected_azim_ch_angle $
   , new_effic=new_effic $
   , w_sct015=w_sct015 $
   , exclude_azms=exclude_azms $
   , flip_the_of_ssd3=flip_the_of_ssd3 $
   , debug=debug $
   , _extra=_extra
  
  
  compile_opt idl2, hidden

  if undefined(debug) then debug = 0
  if undefined(new_effic) then new_effic = 0
  if undefined(w_sct015) then w_sct015 = 0
  if undefined(flip_the_of_ssd3) then flip_the_of_ssd3 = 0
  
  ;;help,  _extra
  ;;help,  _extra.alldist
  ;;return, 0

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

;; only erg_hep_l2_3dflux_FEDU is acceptable for this routine
if ~strcmp(name, 'erg_hep_l2_FEDU_L') $
   and ~strcmp(name, 'erg_hep_l2_FEDU_H') $
   and ~strcmp(name, 'erg_hep_l2_rawcnt_L') and ~strcmp(name, 'erg_hep_l2_rawcnt_H') $
   and ~strcmp(name, 'erg_hep_l2_dtcorcnt_L') and ~strcmp(name, 'erg_hep_l2_dtcorcnt_H') $
   and ~strcmp(name, 'erg_hep_l2_dtcorcntrate_L') and ~strcmp(name, 'erg_hep_l2_dtcorcntrate_H') then begin
  dprint, 'Variable '+name+' is not acceptable. This routine can take only erg_hep_l2_(FEDU/rawcnt/dtcorcnt/dtcorcntrate)_? as the argument.'
  return, 0
endif

;; Extract some information from a tplot variable name
;; e.g., erg_hep_l2_3dflux_FEDU_L
vn_info = strsplit(/ext, name, '_')
instrument = vn_info[1] ;; hep
level = vn_info[2]      ;; l2
dtype = vn_info[3]      ;; FEDU or rawcnt or dtcorcnt or dtcorcntrate
suf = vn_info[-1] ;; L or H 
case instrument of
  'hep': species = 'e'
  else: begin
    dprint, 'ERROR: given an invalid tplot variable: '+name
    return, 0
  endelse
endcase

;; Reform a data array so that it is grouped for each spin
get_data, name, data=d, dlimits=dlimits
t_fedu =  d.x & fedu = d.y 
vn_angsga = strjoin( [ vn_info[0:2], 'FEDU', suf, 'Angle_sga' ], '_' )
if debug then dprint, vn_angsga
get_data, vn_angsga, data=d
angsga = d.y  
undefine, d
vn_sctno = strjoin( [ vn_info[0:2], 'sctno', suf ], '_' )
if tnames(vn_sctno) eq '' then begin
  dprint, 'Cannot find variable '+vn_sctno+', which is essential for this routine to work.'
  return, 0
endif
get_data, vn_sctno, t_scno, scno

id = where( scno eq 0, sc0num )
if sc0num lt 5 then begin
  dprint, 'Only data for less than 5 spins are loaded for HEP_'+suf+'!!'
  return, 0
endif

;; integration time for each spin sector
sctdt = t_scno[1:*]-t_scno
sctintgt = [ sctdt, sctdt[n_elements(sctdt)-1] ]

sc0_t = t_scno[id]  ;; times of spin sector #0, namely the start of each spin
dt = sc0_t[1:*]-sc0_t
sc0_dt = [ dt, dt[n_elements(dt)-1] ] ;; spin period

id_t_fedu = value_locate( sc0_t, t_fedu )

;; Genrate angarr by picking up angle values at each spin start
angarr = angsga[ id, *, * ]  ;;[(spin start time), elev/phi, (azm)] in SGA

;; fedu_arr:[ time, spin sct, energy, azm ]
nene = 16 & nazm = 15 & nsct = 16 ;; by default
if suf eq 'H' then nene = 11 ;; Lv2 HEP-H flux array has 11 elements for energy bin currently.
fedu_arr = fltarr( sc0num, nsct, nene, nazm )
intgt = fltarr( sc0num, nsct )
fedu_arr[*] = !values.f_nan ;; padded with NaN
intgt[*] = !values.f_nan

for i=0L, sc0num-1 do begin

  id = where( id_t_fedu eq i and scno ge 0 and scno le 15, num )
  if num lt 2 then continue

  datarr = fedu[id, *, *] ;; usually [16(time), 16(energy), 15(azm)]
  tarr = t_fedu[id]
  sctarr = scno[id]
  nsct = n_elements(sctarr) ;; occasionally sctarr could have less than 16 elements.
  inttarr = sctintgt[id]
  
  fedu_arr[i, [sctarr], *, *] = reform( datarr, [1, nsct, nene, nazm] )
  intgt[i, [sctarr]] = reform( inttarr, [1, nsct] )
  
endfor
p = { $
    x:sc0_t , $  ;; Put the start time of each spin 
    y:fedu_arr $     ;; [ time, 16(sct), 16(energu), 15(azm) ]
    }


;; Get a reference to data and metadata
if ~is_struct(p) then begin
  dprint, 'Variable: "'+tname+'" contains invalid data or no data!'
  return, 0
endif
if size(p.y, /n_dim) ne 4 then begin
  dprint, 'Variable: "'+tname+'" contains wrong number of elements!'
  return, 0
endif
  

;; Return time labels corresponding the middle time of each spin
if keyword_set(times) then begin
  return, p.x
endif

;; single_time supersedes index and trange
if ~undefined(single_time) then begin
  nearest_time = find_nearest_neighbor(p.x, time_double(single_time))
  if nearest_time eq -1 then begin
    dprint, 'Cannot find requested time in the data set: ' + time_string(single_time)
    return, 0
  endif
  index = where(p.x eq nearest_time)
  n_times = n_elements(index)
endif else begin
  ;;index supersedes time range
  if undefined(index) then begin
    if ~undefined(trange) then begin
      tr = minmax(time_double(trange))
      index = where( p.x ge tr[0] and p.x lt tr[1], n_times)
      if n_times eq 0 then begin
        dprint, 'No data in time range: '+strjoin(time_string(tr, tformat='YYYY-MM-DD/hh:mm:ss.fff'), ' ')
        return, 0
      endif
    endif else begin
      n_times = n_elements(p.x)
      index = lindgen(n_times)
    endelse
  endif else begin
    n_times = n_elements(index)
  endelse
endelse 

;; --------------------------------------------------------------

;; HEP data arr: [9550(time), 16(spin phase), 16(energy), 15(azimuth ch )]
;; Dimensions
dim = (size(p.y, /dim))[1:*]
dim = dim[ [1, 0, 2] ] ;; to [ energy, spin phase, azimuth ch(elevation) ]
base_arr = fltarr(dim)

;; Support data
;; Mass is given in eV/(km/s)^2 for compatibility with other
;; routines
case strlowcase(species) of

  'e': begin
    mass = 5.68566e-06
    charge = -1.
    data_name = 'HEP-'+suf+' Electron 3dflux'
    integ_time = 7.99 / 16 ;; currently hard-coded, but practically not used.
  end
  else: begin
    dprint, 'given species is not supported by this routine.'
    return, 0
  endelse
  
endcase
if strcmp(dtype, 'rawcnt') then data_name = 'HEP-'+suf+' Electron raw count/sample'
if strcmp(dtype, 'dtcorcnt') then data_name = 'HEP-'+suf+' Electron dead-time-corrected count/sample'
if strcmp(dtype, 'dtcorcntrate') then data_name = 'HEP-'+suf+' Electron dead-time-corrected count/sec'

;; basic template structure compatible with spd_slice2d and other
;;routines
template = $
   { $
   project_name: 'ERG', $
   spacecraft: 1, $           ; always 1 as a dummy value
   data_name: data_name, $
   units_name: 'flux', $      ; MEP-e data in [/keV-s-sr-cm2] should be converted to [/eV-s-sr-cm2] 
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
;;   dim[ nenergy, nspinph(azimuth), napd(elevation), ntime]

dist.time = (p.x)[index]    ;; the start time of spin
dist.end_time = (p.x)[index] + sc0_dt[index] ;; the end time of spin 

;; Shuffle the original data array [time,spin phase,energy,apd] to
;; be energy-azimuth-elevation-time.
;; The factor 1d-3 is to convert [/keV-s-sr-cm2] (default unit of
;; HEP Lv2 flux data) to [/eV-s-sr-cm2] 
if strpos( dtype, 'cnt' ) lt 0 then dist.data = transpose( (p.y)[index, *, *, *], [2, 1, 3, 0] ) * 1d-3 $
  else dist.data = transpose( (p.y)[index, *, *, *], [2, 1, 3, 0] ) ;; for count/sample, count/sec

;; Exclude spin phases #0 and #15 currently from spectrum
;; calculations
if ~keyword_set(w_sct015) then begin
  dist.bins[*, 0, *, *] = 0
  dist.bins[*, 15, *, *] = 0
endif

;; Exclude invalid azimuth channels 
if keyword_set(exclude_azms) then begin
  invalid_azms = [0, 4, 5, 9, 10, 11, 14]
  dist.bins[*, *, invalid_azms, *] = 0
endif

;; Apply the empiricallly-derived efficiency (only for cnt/cntrate/dtcntrate)
if new_effic and strpos( dtype, 'cnt' ) ge 0 then begin
  ;; efficiency for each azim. ch. based on the inter-ch. calibration
  ;; Only valid for 2017-06-21 through 2019-02-07 
  effic = [ $
          0.171, 0.460, 1.013, 0.411, 0.158, $
          0.162, 0.450, 1.000, 0.399, 0.158, $
          0.120, 0.170, 0.629, 0.346, 0.132 ]
  for i=0, 14 do begin
    dist.data[*, *, i, *] /= effic[i]
  endfor
  dprint, ' new_effic has been applied!'
endif

  ;; Energy ch
  ;;; Extract necessary information from the Lv2 data CDF file
  cdffpath = dlimits.cdf.filename
  if ~file_test(cdffpath) then begin
    dprint, 'Cannot locate a data CDF file from which necessary information is extacted from!!'
    return, 0
  endif
  cdfi = cdf_load_vars(cdffpath, varformat=['*Energy', '*Angle_sga'])


  id = where( strcmp( cdfi.vars.name, 'FEDU_'+suf+'_Energy' ) )
  enearr = *( cdfi.vars[id].dataptr )  ;; [2(min,max), 16 (ene ch) ]
  ;;enearr[0, 0] = 30.                   ;; the effective lowest energy limit is assumed to be 30 keV

  ;; Calculate averages, which may be replaced with a more
  ;; appropriate averaging method for representative energies. 
  ;; Currently the geometric average is adopted. 
  ;; 1e3 is to convert [keV] (default of HEP Lv2 flux data) to [eV]
  e0 = reform( sqrt(enearr[0, *]*enearr[1, *]) *1e3 )
  dist.energy = rebin( reform(e0, [dim[0], 1, 1, 1]), [dim, n_times] )

  de0 = reform( enearr[1, *] - enearr[0, *] ) *1e3  ;; [16]  denergy is defined asEch_max - Ech_min 
  dist.denergy = rebin( reform(de0, [dim[0], 1, 1, 1]), [dim, n_times] )


  ;; Replace azim. ch. angles with the corrected ones  <-- obsolete now that the v01_03 data are released.
  ;;if keyword_set(corrected_azim_ch_angle) then begin
    ;;if strcmp( suf, 'L' ) then begin
      ;;corrected_rel_angs = [ 24.8, 14.1, 0., -14.1, -24.8 ] ;; with enabled strip chs of the 20170621 setting 
      ;;looking_azim_angs = [ [corrected_rel_angs+60.], [corrected_rel_angs+0], [corrected_rel_angs-60.] ] ;; [15]
      ;;angarr[0,*] = transpose(looking_azim_angs)
    ;;endif
    ;;if strcmp( suf, 'H' ) then begin
      ;; not yet implemented for HEP-H!
    ;;endif
  ;;endif


  ;; converted to the flux dirs
  unitvec = reform( angarr[*, 0, *] ) & unitvec[*] = 1. 
  sphere_to_cart, unitvec, reform(angarr[*, 0, *]), reform(angarr[*, 1, *]), $
                  ex, ey, ez  ;; [ (time), 15 ]
  cart_to_sphere, -ex, -ey, -ez, r, the, phi, /ph_0_360
  ;;angarr = transpose( [ [the], [phi] ] ) ;; flux dirs [elev/phi, (azm)]
  angarr = [ [reform(the, [n_times, 1, dim[2]])], [reform(phi, [n_times, 1, dim[2]])] ] ;; --> [(time), 2, 15]

  spinper = sc0_dt[index]   ;; spin period [n_times]
  if n_elements(spinper) eq 1 then spinper = [ spinper ] 
  rel_sct_time = intgt[index, *] & rel_sct_time[*] = 0.   ;; [n_times,16(sct)]
  ;; Elapsed time from spin start through the center of each spin sector 
  for i=0, 15 do begin
    if i eq 0 then begin
      rel_sct_time[*, i] = 0. + intgt[index, i]/2 
    endif else if i eq 1 then begin
      rel_sct_time[*, i] = intgt[index, 0] + intgt[index, i]/2
    endif else begin
      rel_sct_time[*, i] = total( intgt[index, 0:(i-1)], 2 ) + intgt[index, i]/2
    endelse
  endfor
  
  phissi = reform( angarr[*, 1, *] ) - (90.+21.6) ;; [ (time), (azm)] 
  spinph_ofst = rel_sct_time / rebin(spinper, [n_times, 16] ) * 360.
 
  phi0 = rebin( reform( transpose(phissi), [1, 1, dim[2], n_times] ), [dim, n_times] ) $
         + transpose( rebin( reform(spinph_ofst, [n_times, 1, dim[1], 1]), [n_times, dim] ), [1, 2, 3, 0] )
  
  ;;  phi angle for the start of each spin phase
  ;;    + offset angle 
  dist.phi = ( phi0 + 360. ) mod 360 
  dist.dphi = replicate( 22.5, [dim, n_times] )
  undefine, phi0  ;; Clean up huge arrays

  ;; elevation angle
  elev = reform( angarr[*, 0, *] ) ;; [ (time), (Az.ch)]
  dist.theta = rebin( reform( transpose(elev), [1, 1, dim[2], n_times]), [dim, n_times] )
  dist.dtheta = replicate( 12.0, [dim, n_times] )

  ;; Flip the elevation angles of azim. ch. of SSD#3 if the keyword is set.
  ;; This is obsolete after the release of the v01_03 data.
  ;;if flip_the_of_ssd3 then begin
    ;;if debug then dprint, 'flip_the_of_ssd3 is ON!'
    ;;if debug then print, 'BEFORE: theta of az. 5-9:', dist[5].theta[0, 0, [5:9] ]
    ;;dist[*].theta[*, *, [5:9] ] *= -1.
    ;;if debug then print, 'AFTER: theta of az. 5-9:', dist[5].theta[0, 0, [5:9] ]
  ;;endif
  
  return, dist
end
