;+
; GOES-R MPS-HI crib
;
; This crib shows how to get the flux and channel energies for protons and electrons.
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
; Every L2 SEISS/MPS-HI (5-minute Flux Averages) netcdf file contains data about:
; 1. AvgDiffProtonFlux
; 2. AvgDiffElectronFlux
; 3. AvgIntElectronFlux
;
; The same files contain information for the effective energies for each channel,
; which can be different depending on the probe, telescope and channel.
; The relevant tplot variables are:
; 1. DiffProtonEffectiveEnergy
; 2. DiffProtonLowerEnergy
; 3. DiffProtonUpperEnergy
; 4. DiffElectronEffectiveEnergy
;
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2024-08-11 10:00:55 -0700 (Sun, 11 Aug 2024) $
; $LastChangedRevision: 32786 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/goesr/examples/goesr_mpsh_crib.pro $
;-

; Define a date, a probe, and load MPSH data
del_data, '*'
trange = ['2024-05-11/00:00:00', '2024-05-11/23:59:59']
probes = '18'

goesr_load_data, trange=trange, probes=probes, datatype='mpsh', /get_support_data

; Show the list of tplot variables
tplot_names
stop

; Protons
; Plot proton flux for the first telescope
p1 = 'goes18_AvgDiffProtonFlux_0'
tplot, p1
stop

; Get the data, and print the information from the dlimits structure
; Notice that the telescope number is 'T1'
get_data, p1, data=dp, dl=dlp
help, dlp

print, 'telescope number: ', dlp.TELESCOPE
print, 'effective energies: ', dlp.EFFECTIVEENERGIES
stop

; Get the data for all proton effective energies
pe0 = 'goes18_DiffProtonEffectiveEnergy'
pe1 = 'goes18_DiffProtonLowerEnergy'
pe2 = 'goes18_DiffProtonUpperEnergy'

; The following should print the effective energies for 5 telescopes, 11 channels
get_data, pe0, data=dpe0, dl=dlpe0
print, 'protons: effective energies'
print, dpe0.y
print, '======================='

; The following should print the lower energies for 5 telescopes, 11 channels
get_data, pe1, data=dpe1, dl=dlpe1
print, 'protons: lower energies'
print, dpe1.y
print, '======================='

; The following should print the upper energies for 5 telescopes, 11 channels
get_data, pe2, data=dpe2, dl=dlpe2
print, 'protons: upper energies'
print, dpe2.y
print, '======================='
stop

; Electrons
; Plot electron flux for the first telescope
e1 = 'goes18_AvgDiffElectronFlux_0'
tplot, e1
stop

; Get the data, and print the information from the dlimits structure
; Notice that the telescope number is 'T3'
get_data, e1, data=de, dl=dle
help, dle

print, 'telescope number: ', dle.TELESCOPE
print, 'effective energies: ', dle.EFFECTIVEENERGIES
stop

; Get the data for all electron telescope effective energies
ee = 'goes18_DiffElectronEffectiveEnergy'

; The following should print the effective energies for 5 telescopes, 10 channels
get_data, ee, data=dee, dl=dlee
print, 'electrons: effective energies'
print, dee.y
print, '======================='
stop

; Time-averaged electron fluxes in the E11 >2 MeV integral channel
ei = 'goes18_AvgIntElectronFlux'
tplot, ei

end
