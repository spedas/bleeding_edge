;+
; PROCEDURE:
;         mms_eis_spin_avg
;
; PURPOSE:
;         Calculates spin-averaged fluxes for the EIS instrument
;
; KEYWORDS:
;         probe:        Probe # to calculate the spin average for
;                       if no probe is specified the default is probe '1'
;         datatype:     eis data types include ['electronenergy', 'extof', 'partenergy', 'phxtof'].
;                       If no value is given the default is 'extof'.
;         data_rate:    instrument data rates for eis include 'brst' 'srvy'. The
;                       default is 'srvy'.
;         data_units:   desired units for data. for eis units are ['flux', 'cps', 'counts'].
;                       The default is 'flux'.
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         species:      species (should be: proton, oxygen, alpha or electron)
;
; OUTPUT:
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-11-02 13:32:57 -0700 (Wed, 02 Nov 2016) $
;$LastChangedRevision: 22258 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_spin_avg.pro $
;-

pro mms_eis_spin_avg, probe=probe, species = species, data_units = data_units, $
  datatype = datatype, data_rate = data_rate, suffix=suffix
  if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
  if undefined(datatype) then datatype = 'extof'
  if undefined(data_units) then data_units = 'flux'
  if undefined(species) then species = 'proton'
  if undefined(suffix) then suffix = ''
  if undefined(data_rate) then data_rate = 'srvy'
  if datatype eq 'electronenergy' then species = 'electron'

  if (data_rate eq 'brst') then prefix = 'mms'+probe+'_epd_eis_brst_'+datatype+'_' else prefix = 'mms'+probe+'_epd_eis_'+datatype+'_'
  ; get the spin #s associated with each measurement
  get_data, prefix + 'spin'+suffix, data=spin_nums
  
  if ~is_struct(spin_nums) then return ; gracefully handle the case of no spin # variable found

  ; find where the spins start
  spin_starts = uniq(spin_nums.Y)

  ; find the telescope names
  telescopes = tnames(prefix + species + '_*' + data_units + '_t?'+suffix)
  telescopes = strsplit(telescopes, prefix + species + '_.' + data_units + '_t*'+suffix, /extract, /regex, /fold_case)

  if telescopes[0] eq '' || n_elements(telescopes) ne 6 then begin
      dprint, dlevel = 0, 'Error, problem finding the telescopes to calculate the spin averages'
      return
  endif
  
  ; loop over the telescopes
  for scope_idx = 0, 5 do begin
    this_scope = (telescopes[scope_idx])[0]
    get_data, this_scope, data=flux_data, dlimits=flux_dl
    
    ; check that this spectra variable contains an energy table - and gracefully halt
    ; before crashing
    str_element, flux_data, 'v', success=s
    if s ne 1 then begin
      dprint, dlevel = 0, 'Error, couldn''t find energy table for the variable: ' + this_scope
      continue
    endif

    spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(flux_data.Y[0, *]))

    current_start = 0
    ; loop through the spins for this telescope
    for spin_idx = 0, n_elements(spin_starts)-1 do begin
      ; loop over energies
      ;spin_sum_flux[spin_idx, *] = total(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)
      spin_sum_flux[spin_idx, *] = average(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)
      current_start = spin_starts[spin_idx]+1
    endfor
    sp = '_spin'
    store_data, this_scope+sp, data={x: spin_nums.X[spin_starts], y: spin_sum_flux, v: flux_data.V}, dlimits=flux_dl
    options, this_scope+sp, spec=1, minzlog = .01, ystyle=1
    
    ; changed the energy in late September, when the major file version switched from
    ; v2.1.0 to v3.0.0; set the y axes limits based on version in variable name
    if datatype eq 'phxtof' && species eq 'proton' then begin
      p_num = long(strsplit(telescopes[0], prefix + species + '_P.' + data_units + '_t0'+suffix, /extract))
      if p_num ge 3 then begin
        ylim, this_scope+sp, 14, 45, 1 
      endif else begin
        ylim, this_scope+sp, 10, 28, 1
      endelse
    endif
    zlim, this_scope+sp, 0, 0, 1
  endfor
end
