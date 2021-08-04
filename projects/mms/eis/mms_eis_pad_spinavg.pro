;+
; PROCEDURE:
;         mms_eis_pad_spinavg
;
; PURPOSE:
;         Calculates spin-averaged PADs for the EIS instrument
;
; KEYWORDS:
;         probes:       Probe # to calculate the spin averaged PAD for
;                       if no probe is specified the default is probe '1'
;         datatype:     EIS data types include ['extof' (default), 'phxtof', 'electronenergy', 'combined'].
;                       'combined' is only for use on combined phxtof and extof variables created by
;                       mms_eis_combine_proton_pad.pro
;         data_rate:    instrument data rates for EIS are: ['brst','srvy' (default)].
;         data_units:   desired units for data. Options are ['flux' (default), 'cps', 'counts'].
;         level:        data level ['l1a','l1b','l2pre','l2' (default)]
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         species:      species (should be: proton (default), oxygen, helium (formerly alpha), or electron)
;         scopes:       string array of telescopes to be included in PAD ('0'-'5')
;
; OUTPUT:
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2021-08-03 09:08:16 -0700 (Tue, 03 Aug 2021) $
;$LastChangedRevision: 30167 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_pad_spinavg.pro $
;
; REVISION HISTORY:
;       + 2016-01-26, I. Cohen      : added scopes keyword and scope_suffix definition to allow for distinction between 
;                                     single telescope PADs (reflects change in mms_eis_pad.pro)
;       + 2016-04-29 egrimes        : fixed issues with the suffix keyword     
;       + 2017-05-15 egrimes        : removed call to congrid, added the "extend_y_edges" option to the output;
;                                     this change makes the results produced by this routine consistent with the
;                                     non-spin averaged PAD
;       + 2017-11-17, I. Cohen      : updated to accept changes to mms_eis_pad.pro, introduced 'combined' datatype;
;                                     changed probe keyword to probes
;       + 2017-12-04, I. Cohen      : updated to create spin-averaged variables for all PAD variables, to mirror new
;                                     capabilities of mms_eis_pad.pro (changed pad_name variable to pad_vars); change 
;                                     size_pabin keyword to size_pabin                   
;       + 2020-12-11, I. Cohen      : changed "not KEYWORD_SET" to "undefined" in initialization of some keywords
;       + 2021-02-09, I. Cohen      : added helium to species in header under KEYWORD section
;       + 2021-04-08, I. Cohen      : added level keyword; updated prefix definition to handle new L2 variable names
;
;
;-

pro mms_eis_pad_spinavg, probes=probes, species = species, data_units = data_units, $
  datatype = datatype, energy = energy, size_pabin = size_pabin, data_rate = data_rate, $
  level = level, suffix = suffix, scopes = scopes
  ;
  compile_opt idl2
  if undefined(probes) then probes='1' else probes = strcompress(string(probes), /rem)
  if undefined(datatype) then datatype = 'extof'
  if undefined(data_units) then data_units = 'flux'
  if undefined(species) then species = 'proton'
  if undefined(level) then level = 'l2'
  if undefined(suffix) then suffix_in = '' else suffix_in = suffix
  if undefined(energy) then energy = [55, 800]
  if undefined(size_pabin) then size_pabin = 15
  if undefined(data_rate) then data_rate = 'srvy'
  if undefined(scopes) then scopes = ['0','1','2','3','4','5']
  ;
  en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV'
  units_label = data_units eq 'cps' ? '1/s': '1/(cm!U2!N-sr-s-keV)'
  ;
  prefix = 'mms'+probes+'_epd_eis_'+data_rate+'_'+level+'_'
  if (n_elements(scopes) eq 1) then scope_suffix = '_t'+scopes+suffix_in else if (n_elements(scopes) eq 6) then scope_suffix = '_omni'+suffix_in
  ;
  ; get the spin #s associated with each measurement
  if (datatype eq 'combined') then get_data, prefix + 'extof_spin'+suffix_in, data=spin_nums $
    else get_data, prefix + datatype + '_spin'+suffix_in, data=spin_nums
  ;
  ; find where the spins start
  spin_starts = uniq(spin_nums.Y)
  pad_vars = tnames(prefix + datatype + '_*keV_' + species + '_' + data_units + scope_suffix + '_pad')
  ;
  for ii=0,n_elements(pad_vars)-1 do begin
    get_data, pad_vars[ii], data=pad_data, dlimits=pad_dl
    ;
    if ~is_struct(pad_data) then begin
      ;stop
      dprint, dlevel = 0, 'Error, variable containing valid PAD data missing.'
      return
    endif
    ;
    spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(pad_data.y[0,*]))
    spin_times = dblarr(n_elements(spin_starts))
    ;
    current_start = 0
    ; loop through the spins for this telescope
    for spin_idx = 0, n_elements(spin_starts)-1 do begin
      ; loop over energies
      spin_sum_flux[spin_idx, *] = average(pad_data.y[where(spin_nums.y eq spin_nums.y[spin_starts[spin_idx]]), *], 1, /nan)
      spin_times[spin_idx] = pad_data.X[current_start]
      current_start = spin_starts[spin_idx]+1
    endfor
    ;
    newname = pad_vars[ii] + '_spin'
    ;
    n_pabins = 180./size_pabin
    new_bins = 180.*indgen(n_pabins+1)/n_pabins
    new_pa_label = 180.*indgen(n_pabins)/n_pabins+size_pabin/2.
    ;
    store_data, newname, data={x: spin_times, y: spin_sum_flux, v: new_pa_label}, dlimits=flux_dl
    options, newname, spec=1, ystyle=1, ztitle=units_label, minzlog=.01, /extend_y_edges
    zlim, newname, 0, 0, 1
    ylim, newname, 1., 180.
    tdegap, newname, /overwrite
  endfor
  ;
end