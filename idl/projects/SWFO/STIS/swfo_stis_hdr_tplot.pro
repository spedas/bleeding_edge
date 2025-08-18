; Routine to extract the coefficients eta1 and eta2
; from a level 1b structure for plotting alongside the
; fluxes from the big pixel, tiny pixel, and merged flux.
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-07-21 09:59:43 -0700 (Mon, 21 Jul 2025) $
; $LastChangedRevision: 33477 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_hdr_tplot.pro $


pro swfo_stis_hdr_tplot, level_1b_structs, add=add, elec=elec, ion=ion, label=label


  if keyword_set(label) then label = label + '_' else label = ''
  prefix = 'swfo_stis_' + label

    ; Parameters for a spectra plot with a logarithmic y and z axes
    ; with a spec range of 10^-2 to 10^3 and y range of 10-600 keV
    dl = {spec: 1, ylog: 1, yrange: [1e-2, 1e3], zlog: 1}
    l = {ystyle: 1, ylog: 1, yrange: [10, 6000]}

    if keyword_set(elec) then begin

      store_data, prefix + 'elec_Ch3_flux', $
        data={x: level_1b_structs.time_unix, $
              v: transpose(level_1b_structs.elec_energy), $
              y: transpose(level_1b_structs.Ch3_elec_flux)}, dl=dl, limits=l
      store_data, prefix + 'elec_Ch1_flux', $
        data={x: level_1b_structs.time_unix, $
              v: transpose(level_1b_structs.elec_energy), $
              y: transpose(level_1b_structs.Ch1_elec_flux)}, dl=dl, limits=l
      store_data, prefix + 'elec_hdr_flux', $
        data={x: level_1b_structs.time_unix, $
              v: transpose(level_1b_structs.elec_energy), $
              y: transpose(level_1b_structs.hdr_elec_flux)}, dl=dl, limits=l
      tplot, prefix + ['elec_AR2_flux', 'elec_AR1_flux', 'elec_hdr_flux'], add=add
    endif

    if keyword_set(ion) then begin
      store_data, prefix+ 'ion_Ch3_flux', $
        data={x: level_1b_structs.time_unix, $
              v: transpose(level_1b_structs.ion_energy), $
              y: transpose(level_1b_structs.Ch3_ion_flux)}, dl=dl, limits=l
      store_data, prefix + 'ion_Ch1_flux', $
        data={x: level_1b_structs.time_unix, $
              v: transpose(level_1b_structs.ion_energy), $
              y: transpose(level_1b_structs.Ch1_ion_flux)}, dl=dl, limits=l
      store_data, prefix + 'ion_hdr_flux', $
        data={x: level_1b_structs.time_unix, $
              v: transpose(level_1b_structs.ion_energy), $
              y: transpose(level_1b_structs.hdr_ion_flux)}, dl=dl, limits=l
      tplot, prefix + ['ion_AR2_flux', 'ion_AR1_flux', 'ion_hdr_flux'], add=add

    endif

    ; Store the coefficients:
    store_data, prefix + 'l1b_eta2_elec', $
      data={x: level_1b_structs.time_unix, y: level_1b_structs.eta2_elec}
    store_data, prefix + 'l1b_eta2_ion', $
      data={x: level_1b_structs.time_unix, y: level_1b_structs.eta2_ion}
    store_data, prefix + 'l1b_eta1_elec', $
        data={x: level_1b_structs.time_unix, y: level_1b_structs.eta1_elec}
    store_data, prefix + 'l1b_eta1_ion', $
        data={x: level_1b_structs.time_unix, y: level_1b_structs.eta1_ion}

    ; Plot the etas alongside each other:
    store_data, prefix + 'l1b_eta',$
        data=[prefix + 'l1b_eta1_elec', prefix + 'l1b_eta1_ion',$
              prefix + 'l1b_eta2_elec', prefix + 'l1b_eta2_ion'],$
            dl={colors: "brgm", labels: ["elec n1", "ion n1", "elec n2", "ion n2"], labflag: -1}
    ylim, prefix + 'l1b_eta', -0.1, 1.1
    tplot, prefix + 'l1b_eta', /add

end