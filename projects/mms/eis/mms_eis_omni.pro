;+
; PROCEDURE:
;         mms_eis_omni
;
; PURPOSE:
;       Calculates the omni-directional flux for all 6 telescopes
;
; NOTES:
;       Originally based on Brian Walsh's EIS code from 7/29/2015
;
;
; REVISION HISTORY:
;       + 2016-02-26, I. Cohen      : changed 'cps' units_label from 'Counts/s' to '1/s' for compliance with mission standards
;       + 2016-03-09, I. Cohen      : altered ylabel for new omni variables
;       + 2018-01-03, I. Cohen      : added counts as acceptable data_units option
;       + 2018-01-19, I. Cohen      : simplified how p_num is pulled out
;       + 2018-01-23, I. Cohen      : convert zeros in data to NANs to correctly handle averaging         
;       + 2020-04-27, I. Cohen      : added creation of single variable with energy limits of each channel                    
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-04-27 12:15:45 -0700 (Mon, 27 Apr 2020) $
;$LastChangedRevision: 28611 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_omni.pro $
;-

pro mms_eis_omni, probe, species = species, datatype = datatype, tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
  ; default to electrons
  if undefined(species) then species = 'electron'
  if undefined(datatype) then datatype = 'electronenergy'
  if undefined(suffix) then suffix = ''
  if undefined(data_units) then data_units = 'flux'
  if undefined(data_rate) then data_rate = 'srvy'
  case data_units of 
    'flux'    : units_label = '1/(cm!U2!N-sr-s-keV)'
    'cps'     : units_label = '1/s'
    'counts'  : units_label = 'counts'
  endcase
  probe = strcompress(string(probe), /rem)
  species_str = datatype+'_'+species
  if (data_rate) eq 'brst' then prefix = 'mms'+probe+'_epd_eis_brst_' else prefix = 'mms'+probe+'_epd_eis_'
  ;
  ; find the telescope names
  telescopes = tnames(prefix + species_str + '_*' + data_units + '_t?'+suffix)
;  telescopes = strsplit(telescopes, '_', /extract, /regex, /fold_case)
  ;
  if telescopes[0] eq '' || n_elements(telescopes) ne 6 then begin
    dprint, dlevel = 0, 'Error, problem finding the telescopes to calculate omni-directional spectrograms'
    return
  endif
  ;
  str = string(strsplit(telescopes[0], '_', /extract))
  if (data_rate eq 'brst') then p_num = strmid(str[6],1,1) else p_num = strmid(str[5],1,1)
  ;
  if (p_num eq 'l') then p_num = '2'                                                    ; if no p_num in the tplot variable name, probably comes from v2.x.x CDFs
  ;
  get_data, telescopes[0], data = d, dlimits=dl
  ;
  if is_struct(d) then begin
    ; make sure the spectra has an energy table before continuing
    str_element, d, 'v', success=s
    if s ne 1 then return
    ;
    flux_omni = dblarr(n_elements(d.x),n_elements(d.v))
    for i=0, 5 do begin ; loop through each detector
      get_data, (telescopes[i])[0], data = d
      flux_omni = flux_omni + d.Y
    endfor
    newname = prefix+species_str+'_'+data_units+'_omni'+suffix
    store_data, newname, data={x:d.x, y:flux_omni/6d, v:d.v}, dlimits=dl
    ;
    options, newname, ylog = 1, spec = 1, yrange = minmax(d.v), $
      ytitle = 'mms'+probe+'!Ceis!C'+species, ysubtitle='Energy!C[keV]', ztitle=units_label, ystyle=1, /default, minzlog = .01
    zlim, newname, 0., 0., 1.
    ;
    ; special yrange based on P value # in the variable names 
    ; EIS changed the energization of the channels when the major file version switched from
    ; v2.1.0 to v3.0.0. (P# represents major version #)
    if (datatype eq 'phxtof') && (species eq 'proton') then begin
      if (p_num ge 3) then options, newname, yticks=2, yrange=[14, 45], ystyle=1 else options, newname, yticks=2, yrange=[10, 28], ystyle=1
    endif
    ;
    append_array, tplotnames, newname
    ; degap the data
    tdegap, newname, /overwrite
  endif
  ;
  ; create new variable with omni energy limits
  get_data, prefix+species_str+'_t0_energy_dminus', data=energy_minus
  get_data, prefix+species_str+'_t0_energy', data=energy_gm
  get_data, prefix+species_str+'_t0_energy_dplus', data=energy_plus
  if is_struct(energy_minus) and is_struct(energy_plus) then store_data, prefix+species_str+'_energy_range', data={x:energy_gm.x, y: [[energy_gm.y-energy_minus.y],[energy_gm.y+energy_plus.y]]} $
    else print, '*DMINUS/*DPLUS VARIABLES FOR CHANNEL ENERGY LIMITS ARE NOT LOADED'
end