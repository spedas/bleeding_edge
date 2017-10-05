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
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-11-03 08:11:22 -0700 (Thu, 03 Nov 2016) $
;$LastChangedRevision: 22263 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_omni.pro $
;-

pro mms_eis_omni, probe, species = species, datatype = datatype, tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
  ; default to electrons
  if undefined(species) then species = 'electron'
  if undefined(datatype) then datatype = 'electronenergy'
  if undefined(suffix) then suffix = ''
  if undefined(data_units) then data_units = 'flux'
  if undefined(data_rate) then data_rate = 'srvy'
  units_label = data_units eq 'flux' ? '1/(cm!U2!N-sr-s-keV)' : '1/s'

  probe = strcompress(string(probe), /rem)
  species_str = datatype+'_'+species
  if (data_rate) eq 'brst' then prefix = 'mms'+probe+'_epd_eis_brst_' else prefix = 'mms'+probe+'_epd_eis_'

  ; find the telescope names
  telescopes = tnames(prefix + species_str + '_*' + data_units + '_t?'+suffix)
  telescopes = strsplit(telescopes, prefix + species_str + '_.' + data_units + '_t*'+suffix, /extract, /regex, /fold_case)

  if telescopes[0] eq '' || n_elements(telescopes) ne 6 then begin
    dprint, dlevel = 0, 'Error, problem finding the telescopes to calculate omni-directional spectrograms'
    return
  endif
  
  varname_components = strsplit(telescopes[0], '_', /extract)
  
  if data_rate eq 'brst' then $
    p_val = varname_components[6] $
  else $
    p_val = varname_components[5] 

  if p_val eq 'flux' then begin
    ; if no p_val in the name, probably comes from v2.x.x CDFs
    p_val = 'P2'
  endif
  
  p_val_num = long((strsplit(p_val, 'P', /extract))[0])
  
  get_data, (telescopes[0])[0], data = d, dlimits=dl

  if is_struct(d) then begin
    ; make sure the spectra has an energy table before continuing
    str_element, d, 'v', success=s
    if s ne 1 then return

    flux_omni = dblarr(n_elements(d.x),n_elements(d.v))
    for i=0, 5 do begin ; loop through each detector
      get_data, (telescopes[i])[0], data = d
      flux_omni = flux_omni + d.Y
    endfor
    newname = prefix+species_str+'_'+data_units+'_omni'+suffix
    store_data, newname, data={x:d.x, y:flux_omni/6., v:d.v}, dlimits=dl

    options, newname, ylog = 1, spec = 1, yrange = minmax(d.v), $
      ytitle = 'mms'+probe+'!Ceis!C'+species, ysubtitle='Energy!C[keV]', ztitle=units_label, ystyle=1, /default, minzlog = .01
    zlim, newname, 0., 0., 1.
    
    ; special yrange based on P value # in the variable names 
    ; EIS changed the energization of the channels when the major file version switched from
    ; v2.1.0 to v3.0.0. (P# represents major version #)
    if datatype eq 'phxtof' && species eq 'proton' then begin
      if p_val_num ge 3 then options, newname, yticks=2, yrange=[14, 45], ystyle=1 else options, newname, yticks=2, yrange=[10, 28], ystyle=1
    endif
    
    append_array, tplotnames, newname
    ; degap the data
    tdegap, newname, /overwrite
  endif
end