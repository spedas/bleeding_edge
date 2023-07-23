; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:10:39 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 30999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_sci_level_1b.pro $


function swfo_stis_sci_level_1b,strcts,format=format,reset=reset,cal=cal

  output = !null
  nd = n_elements(strcts)
  for i=0l,nd-1 do begin
    str = strcts[i]

    cal = swfo_stis_cal_params(str,reset=reset)

    n_energy = cal.n_energy
    duration = str.duration

    period = cal.period   ; approximate period (in seconds) of Version 64 FPGA
    integration_time = str.duration * period
    srate  = str.counts/integration_time          ; srate is the measure (actual) count rate

    ; Determine deadtime correctons here
    rate14 = str.total14/ integration_time    ; this needs to be checked
    Exrate = reform(replicate(1,n_energy) # rate14,n_energy * 14)
    deadtime_correction = 1 / (1- exrate*cal.deadtime)
    w = where(deadtime_correction gt 10. or deadtime_correction lt .5,/null)
    deadtime_correction[w] = !values.f_nan
    crate  = srate * deadtime_correction       ; crate is the count rate corrected for deadtime

    bins = cal.prot_resp
    ion_flux = crate / bins.geom
    ion_energy = bins.energy
    w = where(bins.species eq 1,/null)
    ion_flux = ion_flux[w]
    ion_energy= ion_energy[w]

    bins = cal.elec_resp
    elec_flux = crate / bins.geom
    elec_energy = bins.energy
    w = where(bins.species eq 0,/null,nw)
    elec_flux = elec_flux[w]
    elec_energy= elec_energy[w]

    sci_ex = {  $
      integration_time : duration * period, $
      srate : srate , $
      crate : crate , $
      TID:  bins.tid,  $
      FTO:  bins.fto,  $
      geom:  bins.geom,  $
      ewidth: bins.ewidth,  $
      ion_energy: ion_energy,   $   ; midpoint energy
      ion_flux :   ion_flux,  $
      elec_energy:  elec_energy, $
      elec_flux:  elec_flux, $
      lut_id: 0 }

    sci = create_struct(str,sci_ex)

    if nd eq 1 then   return, sci
    if i  eq 0 then   output = replicate(sci,nd) else output[i] = sci

  endfor

  return,output

end

