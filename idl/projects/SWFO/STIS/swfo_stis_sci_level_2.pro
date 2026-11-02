;+
;FUNCTION:  SWFO_STIS_SCI_LEVEL_2
;PURPOSE: Creates an array of structures,
; where each structure has fields corresponding
; to the Level 2 data product for SWFO STIS, using
; the array of Level 1B structures produced
; by SWFO_STIS_SCI_LEVEL_1b.pro or read from
; a Level 1b netcdf via swfo_ncdf_read.
;
; Example call:
;  > l2 =   swfo_stis_sci_level_2(l1b_structs)
;
; Resamples the Level 1b HDR spectra to the energies
; in the Level 2 ACE EPAM product (note: not the same
; as the RTSW EPAM product, which has )
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2026-10-28 15:01:20 -0700 (Wed, 28 Oct 2026) $
; $LastChangedRevision: 35016 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_2.pro $


function swfo_stis_sci_level_2,strcts,cal=cal

  ; Replacing the ace keyword with the cal
  ; dict:
  ; Get the cal values if not defined:
  if ~isa(cal,'dictionary') then cal = swfo_stis_inst_response_calval()
  l2_ion_energy_ranges = cal.epam_ion_edge_energies
  l2_elec_energy_ranges = cal.epam_electron_edge_energies

  ; if ~keyword_set(ace) then begin
  ;   ranges = [ 30. ,50., 100., 200. , 400. , 800., 1600. , 3000.]
  ;   ace = {Ion_ranges : ranges , $
  ;     elec_ranges:ranges  }
  ;   ace_valid = 1
  ; endif else ace_valid = 0
  ; l2_ion_energy_ranges = ace.ion_ranges
  ; elec_energy_ranges = ace.elec_ranges

  n_ion = n_elements(l2_ion_energy_ranges) - 1
  n_elec = n_elements(l2_elec_energy_ranges) - 1

  sci_ex = {  $
    time: 0d, $
    ion_energy: fltarr(n_ion),   $   ; midpoint energy
    ion_denergy: fltarr(n_ion),  $
    ion_erange: fltarr(n_ion, 2),  $
    ion_flux :   fltarr(n_ion),  $
    elec_energy:  fltarr(n_elec),$
    elec_denergy: fltarr(n_elec),  $
    elec_erange: fltarr(n_elec, 2),  $
    elec_flux:  fltarr(n_elec)     }

  output = !null
  nd = n_elements(strcts)
  fill = !values.f_nan

  for n=0l,nd-1 do begin
    str = strcts[n]

    sci_ex.ion_flux = fill
    sci_ex.time = str.time
    for i=0 ,n_ion-1 do begin
      w = where(str.ion_energy gt l2_ion_energy_ranges[i] and str.ion_energy lt l2_ion_energy_ranges[i+1],/null,nw)
      if isa(w) then begin
        erange_i = str.ion_energy[w]
        sci_ex.ion_erange[i, *] = [erange_i[0], erange_i[-1]]
        sci_ex.ion_denergy[i] = erange_i[-1] - erange_i[0]
        sci_ex.ion_flux[i] = total(str.hdr_ion_flux[w]) / nw   ; computes average
        sci_ex.ion_energy[i] = total(erange_i) / nw
      endif
    endfor

    sci_ex.elec_flux = fill
    for i=0 ,n_elec-1 do begin
      w = where(str.elec_energy gt l2_elec_energy_ranges[i] and str.elec_energy lt l2_elec_energy_ranges[i+1],/null,nw)
      if isa(w) then begin
        erange_i = str.elec_energy[w]
        sci_ex.elec_erange[i, *] = [erange_i[0], erange_i[-1]]
        sci_ex.elec_denergy[i] = erange_i[-1] - erange_i[0]
        sci_ex.elec_flux[i] = total(str.hdr_elec_flux[w]) / nw
        sci_ex.elec_energy[i] = total(erange_i) / nw
      endif
    endfor


    ; sci = create_struct(str,sci_ex)
    sci = sci_ex

    if nd eq 1 then   return, sci
    if n  eq 0 then   output = replicate(sci,nd) else output[n] = sci

  endfor

  return,output

end

