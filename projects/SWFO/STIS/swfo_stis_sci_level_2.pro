; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:10:39 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 30999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_2.pro $


function swfo_stis_sci_level_2,strcts,ace_config = ace

  if ~keyword_set(ace) then begin
    ranges = [ 30. ,50., 100., 200. , 400. , 800., 1600. , 3000.]
    ace = {Ion_ranges : ranges , $
      elec_ranges:ranges  }
    ace_valid = 1
  endif else ace_valid = 0

  n_ion = n_elements(ace.ion_ranges) -1
  n_elec = n_elements(ace.elec_ranges) -1

  sci_ex = {  $
    ion_energy_L2: fltarr(n_ion),   $   ; midpoint energy
    ion_flux_L2 :   fltarr(n_ion),  $
    elec_energy_L2:  fltarr(n_elec), $
    elec_flux_L2:  fltarr(n_elec)     }

  output = !null
  nd=n_elements(strcts)
  fill = !values.f_nan

  for n=0l,nd-1 do begin
    str = strcts[n]

    for i=0 ,n_ion-1 do begin
      sci_ex.ion_flux_L2 = fill
      w = where(str.ion_energy gt ace.ion_ranges[i] and str.ion_energy lt ace.ion_ranges[i+1],/null,nw)
      sci_ex.ion_flux_L2[i] = total(str.ion_flux[w] / nw)   ; computes average
      sci_ex.ion_energy_L2[i] = total(str.ion_energy[w] / nw)
    endfor

    if 1 then begin   ;  electron not ready yet
      for i=0 ,n_elec-1 do begin
        sci_ex.elec_flux_L2 = fill
        w = where(str.elec_energy gt ace.elec_ranges[i] and str.elec_energy lt ace.elec_ranges[i+1],/null,nw)
        sci_ex.elec_flux_L2[i] = total(str.elec_flux[w] / nw)
        sci_ex.elec_energy_L2[i] = total(str.elec_energy[w] / nw)
      endfor

    endif

    sci = create_struct(str,sci_ex)

    if nd eq 1 then   return, sci
    if n  eq 0 then   output = replicate(sci,nd) else output[n] = sci

  endfor

  return,output

end

