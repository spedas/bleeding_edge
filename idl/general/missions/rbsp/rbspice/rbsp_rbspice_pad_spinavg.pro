;+
; PROCEDURE:
;         rbsp_rbspice_pad_spinavg
;
; PURPOSE:
;         Calculates spin-averaged PADs for the RBSPICE instrument
;
; KEYWORDS:
;         probe:        RBSP spacecraft indicator [Options: 'a' (default), 'b']
;         datatype:     desired data type [Options: 'TOFxEH' (default), 'TOFxEnonH']
;         level:      data level ['l1','l2','l3' (default),'l3pap']
;         species:      desired ion species [Options: 'proton' (default), 'helium', 'oxygen']
;         energy:       user-defined energy range to include in the calculation in keV [default = [0,1000]]
;         bin_size:     desired size of the pitch angle bins in degrees [default = 15]
;         scopes:       string array of telescopes to be included in PAD [0-5, default is all]
;
; OUTPUT:
;
;
; REVISION HISTORY:
;       + 2017-02-22, I. Cohen      : created based on mms_eis_pad_spinavg.pro and tailored to work with rbsp_rbspice_pad.pro
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-03-03 08:08:58 -0800 (Fri, 03 Mar 2017) $
;$LastChangedRevision: 22902 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/rbspice/rbsp_rbspice_pad_spinavg.pro $
;-
pro rbsp_rbspice_pad_spinavg, probe=probe, datatype = datatype, level=level, $
    species=species, energy = energy, bin_size = bin_size, scopes=scopes

  if undefined(probe) then probe='a'
  if undefined(datatype) then datatype = 'TOFxEH'
  if undefined(level) then level = 'l3'
  if (level ne 'l1') then units_label = '1/(cm!U2!N-sr-s-keV)' else units_label = 'counts/s'
  if undefined(species) and (datatype eq 'TOFxEH') then species = 'proton' $
    else if undefined(species) and (datatype eq 'TOFxEnonH') then species = ['helium','oxygen'] $
    else if undefined(species) and (datatype eq 'TOFxPHHHELT') then species = ['proton','oxygen']
  if undefined(energy) then energy = [0, 1000]
  if undefined(bin_size) then bin_size = 15.
  if undefined(scopes) then scopes = [0,1,2,3,4,5]

  en_range_string = strcompress(string(energy[0]), /remove_all) + '-' + strcompress(string(energy[1]), /remove_all) + 'keV'

  prefix = 'rbsp'+probe+'_rbspice_'+level+'_'+datatype+'_'
  get_data, prefix + 'Spin', data=spin_nums

  ; find where the spins start
  spin_starts = uniq(spin_nums.Y)
  if (n_elements(scopes) eq 6) then pad_name = prefix+species+'_omni_'+en_range_string+'_pad' else pad_name = tnames(prefix+species+'_T?_'+en_range_string+'_pad')

  for ii=0,n_elements(pad_name)-1 do begin
    get_data, pad_name(ii), data=pad_data, dlimits=pad_dl
    
    if ~is_struct(pad_data) then begin
      ;stop
      dprint, dlevel = 0, 'Error, variable containing valid PAD data missing.'
      return
    endif
    
    spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(pad_data.y[0, *]))
    spin_times = dblarr(n_elements(spin_starts))
    
    current_start = 0
    ; loop through the spins for this telescope
    for spin_idx = 0, n_elements(spin_starts)-1 do begin
      ; loop over energies
      spin_sum_flux[spin_idx, *] = average(pad_data.y[current_start:spin_starts[spin_idx], *], 1, /nan)
      spin_times[spin_idx] = pad_data.x[current_start]
      current_start = spin_starts[spin_idx]+1
    endfor
    
    newname = pad_name(ii)+'_spin'
    if (n_elements(scopes) eq 6) then ytitle= 'rbsp-'+probe+'!Crbspice!C'+species+'!CTomni' $
      else ytitle = 'rbsp-'+probe+'!Crbspice!C'+species+'!CT'+strmid(pad_name(t),4,1,/reverse)
    
    ; rebin the data before storing it
    ; the idea here is, for bin_size = 15 deg, rebin the data from center points to:
    ;    new_bins = [0, 15, 30, 45, 60, 75, 90, 105, 120, 135 , 150, 165, 180]

    n_pabins = 180./bin_size
    new_bins = 180.*indgen(n_pabins+1)/n_pabins

    rebinned_data = congrid(spin_sum_flux, n_elements(spin_starts), n_elements(new_bins), /center, /interp)
    
    store_data, newname, data={x: spin_times, y: rebinned_data, v: new_bins}, dlimits=flux_dl
    options, newname, spec=1, ystyle=1, ztitle=units_label, ytitle=ytitle, ysubtitle=en_range_string+'!Cspin-avg!CPAD (deg)', minzlog=.01
    zlim, newname, 0, 0, 1
    ylim, newname, 1., 180.

    ; zlim, newname, 0, 0, 1
    ;options, newname, no_interp=0
    tdegap, newname, /overwrite
  endfor
 
end