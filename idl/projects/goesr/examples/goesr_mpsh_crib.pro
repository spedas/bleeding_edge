;+
; GOES-R MPS-HI crib
;
; This crib shows L1 and L2 proton and electron fluxes, L1 uncertainties and
; quality flags, and L2 effective channel energies.
;
; Space Environment In-Situ Suite (SEISS) Magnetospheric Particle Sensor High (MPS-HI)
;
; The SEISS/MPS-HI instrument on board of each GOES-R probe (GOES-16, GOES-17, GOES-18),
; contains 5 particle telescopes (detectors) for protons labeled T1-T5, with 11 energy channels each,
; and 5 particle telescopes for electrons with 10 channels each (plus 1 for electrons >2MeV).
;
; The north-to-south order of telescope numbers is (3, 1, 4, 2, 5) for electrons
; and (1, 4, 2, 5, 3) for protons when the spacecraft is upright.
;
; L2 SEISS/MPS-HI 5-minute flux-average netCDF files contain:
; 1. AvgDiffProtonFlux
; 2. AvgDiffElectronFlux
; 3. AvgIntElectronFlux
;
; The same files contain information for the effective energies for each channel,
; which can be different depending on the probe, telescope and channel.
; The loader retains effective energies in the flux variable's
; CDF.VATT.EffectiveEnergies metadata and in each split telescope variable's
; EffectiveEnergies option, rather than separate energy tplot variables.
;
; The L1 examples show DiffProtonFluxes, DiffElectronFluxes and IntgElectronFluxes,
; together with their uncertainties and quality flags. L1 differential arrays
; are split by telescope; the integral array retains all five telescopes.
; L1 does not provide the L2 effective-energy metadata used in this crib.
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2026-10-15 18:38:10 -0700 (Thu, 15 Oct 2026) $
; $LastChangedRevision: 34986 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/examples/goesr_mpsh_crib.pro $
;-

compile_opt idl2

; Define a date, a probe, and load MPSH data
del_data, '*'
trange = ['2024-05-11/00:00:00', '2024-05-11/23:59:59']
probes = '18'

; Load l2 data
goesr_load_data, trange = trange, probes = probes, datatype = 'mpsh', /get_support_data

; Show the list of tplot variables
tplot_names
stop

; Protons
; There are five telescopes
; Plot proton flux for the first telescope
p0 = 'goes18_AvgDiffProtonFlux_0'
p1 = 'goes18_AvgDiffProtonFlux_1'
p2 = 'goes18_AvgDiffProtonFlux_2'
p3 = 'goes18_AvgDiffProtonFlux_3'
p4 = 'goes18_AvgDiffProtonFlux_4'
tplot, p0
stop

; Get the data, and print the information from the dlimits structure
; Notice that the first telescope number is 'T1'
; The following should print the upper energies for 5 telescopes, 11 channels
get_data, p0, data = dp0, dl = dlp0
get_data, p1, data = dp1, dl = dlp1
get_data, p2, data = dp2, dl = dlp2
get_data, p3, data = dp3, dl = dlp3
get_data, p4, data = dp4, dl = dlp4
help, dlp0
print, 'Protons:'
print, 'telescope number: ', dlp0.telescope, ' effective energies: ', dlp0.effectiveenergies
print, 'telescope number: ', dlp1.telescope, ' effective energies: ', dlp1.effectiveenergies
print, 'telescope number: ', dlp2.telescope, ' effective energies: ', dlp2.effectiveenergies
print, 'telescope number: ', dlp3.telescope, ' effective energies: ', dlp3.effectiveenergies
print, 'telescope number: ', dlp4.telescope, ' effective energies: ', dlp4.effectiveenergies
stop

; Electrons
; Plot electron flux for the first telescope
e0 = 'goes18_AvgDiffElectronFlux_0'
e1 = 'goes18_AvgDiffElectronFlux_1'
e2 = 'goes18_AvgDiffElectronFlux_2'
e3 = 'goes18_AvgDiffElectronFlux_3'
e4 = 'goes18_AvgDiffElectronFlux_4'
tplot, e0
stop

; Get the data, and print the information from the dlimits structure
; Notice that the first telescope number is 'T3'
; The following should print the effective energies for 5 telescopes, 10 channels
get_data, e0, data = de0, dl = dle0
get_data, e1, data = de1, dl = dle1
get_data, e2, data = de2, dl = dle2
get_data, e3, data = de3, dl = dle3
get_data, e4, data = de4, dl = dle4
help, dle0
print, 'Electrons:'
print, 'telescope number: ', dle0.telescope, ' effective energies: ', dle0.effectiveenergies
print, 'telescope number: ', dle1.telescope, ' effective energies: ', dle1.effectiveenergies
print, 'telescope number: ', dle2.telescope, ' effective energies: ', dle2.effectiveenergies
print, 'telescope number: ', dle3.telescope, ' effective energies: ', dle3.effectiveenergies
print, 'telescope number: ', dle4.telescope, ' effective energies: ', dle4.effectiveenergies
stop

; Time-averaged electron fluxes in the E11 >2 MeV integral channel
ei = 'goes18_AvgIntElectronFlux'
tplot, ei

; Delete all data
del_data, '*'

; Load l1 data
goesr_load_data, trange = trange, probes = probes, datatype = 'mpsh', level = 'l1', /get_support_data

; Show the L1 variables, including uncertainties and quality flags.
tplot_names
stop

; L1 differential flux arrays are split into five time-by-energy variables.
; TELESCOPE contains the array index (0-4), rather than an L2 telescope label.
; L1 does not provide the L2 EffectiveEnergies metadata used above.
l1prefix = 'goes' + probes + '_'

; Protons: inspect all five telescopes, with 11 channels per telescope.
l1p = l1prefix + 'DiffProtonFluxes_' + strtrim(string(indgen(5)), 2)
tplot, l1p[0]
stop

for i = 0, 4 do begin
  get_data, l1p[i], data = l1dp, dl = l1dlp
  print, 'L1 proton telescope index: ', l1dlp.telescope
  help, l1dp.x, l1dp.y
endfor
; For example, l1dp.y[*, 0] is the first channel versus time for index 4.
stop

; Matching uncertainties and integer data-quality flags for telescope index 0.
get_data, l1prefix + 'DiffProtonUncertainties_0', data = l1pu
get_data, l1prefix + 'DiffProtonFluxDQFs_0', data = l1pq
help, l1pu.y, l1pq.y
stop

; Electrons: inspect all five telescopes, with 10 differential channels each.
l1e = l1prefix + 'DiffElectronFluxes_' + strtrim(string(indgen(5)), 2)
tplot, l1e[0]
stop

for i = 0, 4 do begin
  get_data, l1e[i], data = l1de, dl = l1dle
  print, 'L1 electron telescope index: ', l1dle.telescope
  help, l1de.x, l1de.y
endfor
stop

; Matching uncertainties and integer data-quality flags for telescope index 0.
get_data, l1prefix + 'DiffElectronUncertainties_0', data = l1eu
get_data, l1prefix + 'DiffElectronFluxDQFs_0', data = l1eq
help, l1eu.y, l1eq.y
stop

; Integral electron flux above 2 MeV: one time-by-five-telescope array.
; Unlike the 3-D differential arrays, this 2-D array is not split by the loader.
l1ei = l1prefix + 'IntgElectronFluxes'
tplot, l1ei
get_data, l1ei, data = l1di
l1ei0 = l1di.y[*, 0] ; Integral flux for telescope index 0.
get_data, l1prefix + 'IntgElectronUncertainties', data = l1iu
get_data, l1prefix + 'IntgElectronFluxDQFs', data = l1iq
help, l1di.y, l1iu.y, l1iq.y
stop

end
