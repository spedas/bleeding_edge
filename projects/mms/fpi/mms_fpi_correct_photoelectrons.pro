;+
;Procedure:
;  mms_fpi_correct_photoelectrons
;
;Purpose:
;  Returns 3D particle data structures containing MMS FPI
;  data for use with SPEDAS particle routines. This routine removes
;  DES photoelectrons from the distribution using Dan Gershman's model
;  prior to returning
;   
;
;
;Input:
;  tname: Tplot variable containing the desired data
; 
;Keywords:
;  scpot: tplot variable containing S/C potential data; loaded automatically if not otherwise specified
;  subtract_error: subtract the distErr (variable specified by the keyword: error)
;         data before returning; the error is subtracted prior to photoelectron removal
;  error: variable name of the disterr variable, e.g.:
;        'mms#_des_disterr_fast'
;
;        for fast survey electron data
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2021-04-13 14:32:42 -0700 (Tue, 13 Apr 2021) $
;$LastChangedRevision: 29877 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_correct_photoelectrons.pro $
;-

function mms_fpi_correct_photoelectrons, in_tvarname, scpot=scpot, trange=trange, _extra=_extra

  get_data, in_tvarname, data=indata
  
  if ~is_struct(indata) then begin
    dprint, dlevel=0, 'Error, ' + in_tvarname + ' not found.'
    return, -1
  endif
  
  if ~undefined(trange) then begin
    dprint, dlevel=0, 'Error, trange keyword not supported'
    undefine, trange
  endif
  
  fpi_photoelectrons = mms_part_des_photoelectrons(in_tvarname)

  if ~is_struct(fpi_photoelectrons) && fpi_photoelectrons eq -1 then begin
    dprint, dlevel=0, 'Photoelectron model missing for this date; re-run without photoelectron corrections'
    return, -1
  endif

  var_info = stregex(in_tvarname, 'mms([1-4])_d([ei])s_dist(err)?_(brst|fast|slow).*', /subexpr, /extract)

  ;use info from the variable name if not explicitly set
  if var_info[0] ne '' then begin
    probe = var_info[1]
    species = var_info[2]
    data_rate = var_info[4]
  endif
  
  if undefined(scpot) then begin
    mms_load_edp, trange=minmax(indata.X), probe=probe, data_rate=data_rate, datatype='scpot', /time_clip
    scpot = 'mms'+probe+'_edp_scpot_'+data_rate+'_l2'
  endif
  
  get_data, scpot, data=scpotdata
  sc_pot_data = scpotdata.Y
  
  ; will need stepper parities for burst mode data
  if data_rate eq 'brst' then begin
    scprefix = (strsplit(in_tvarname, '_', /extract))[0]
    get_data, scprefix+'_des_steptable_parity_brst', data=parity

    ; the following is so that we can use scope_varfetch using the parity_num found in the loop over times
    ; (scope_varfetch doesn't work with structure.structure syntax)
    bg_dist_p0 = fpi_photoelectrons.bgdist_p0
    bg_dist_p1 = fpi_photoelectrons.bgdist_p1
    n_0 = fpi_photoelectrons.n_0
    n_1 = fpi_photoelectrons.n_1
  endif
  
  dists = mms_get_dist(in_tvarname, /structure, probe=probe, $
    species=species, instrument='fpi', _extra=_extra)
    
  get_data, 'mms'+probe+'_des_startdelphi_count_'+data_rate, data=startdelphi
  
  for i = 0l,n_elements(dists)-1 do begin
    ; From Dan Gershman's release notes on the FPI photoelectron model:
    ; Find the index I in the startdelphi_counts_brst or startdelphi_counts_fast array
    ; [360 possibilities] whose corresponding value is closest to the measured
    ; startdelphi_count_brst or startdelphi_count_fast for the skymap of interest. The
    ; closest index can be approximated by I = floor(startdelphi_count_brst/16) or I =
    ; floor(startdelphi_count_fast/16)
    start_delphi_I = floor(startdelphi.Y[i]/16.)

    if data_rate eq 'brst' then begin
      parity_num = strcompress(string(fix(parity.Y[i])), /rem)

      bg_dist = scope_varfetch('bg_dist_p'+parity_num)
      n_value = scope_varfetch('n_'+parity_num)

      fphoto = bg_dist.Y[start_delphi_I, *, *, *]

      ; need to interpolate using SC potential data to get Nphoto value
      nphoto_scpot_dependent = reform(n_value.Y[start_delphi_I, *])
      nphoto = interpol(nphoto_scpot_dependent, n_value.V, sc_pot_data[i])
    endif else begin
      fphoto = fpi_photoelectrons.bg_dist.Y[start_delphi_I, *, *, *]

      ; need to interpolate using SC potential data to get Nphoto value
      nphoto_scpot_dependent = reform(fpi_photoelectrons.N.Y[start_delphi_I, *])
      nphoto = interpol(nphoto_scpot_dependent, fpi_photoelectrons.N.V, sc_pot_data[i])
    endelse

    ; now, the corrected distribution function is simply f_corrected = f-fphoto*nphoto
    ; note: transpose is to shuffle fphoto*nphoto to energy-azimuth-elevation, to match dist.data
    dists[i].data = dists[i].data-transpose(reform(fphoto*nphoto), [2, 0, 1])
  endfor
  
  return, dists
end