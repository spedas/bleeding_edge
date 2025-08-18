; the following script deals with SEP calibration

; First the conversion from ADC value to energy

Energy_am241 = 59.5 ; keV

; the order is A-F, A-T, F-O, B-F, B-T, B-O

SEP1_ADC_peak = [41.08, 38.45, 43.76, 42.28, 40.29, 42.00]
sig_SEP1_ADC_peak= [1.47, 1.89, 1.43, 1.45, 1.90, 1.31]
SEP2_ADC_peak = [43.90, 44.06, 40.25, 41.96, 43.97, 43.20]
sig_SEP2_ADC_peak = [1.54, 2.00, 1.34, 1.38, 2.04, 1.42]

SEP1_kev_per_ADC = Energy_am241/SEP1_ADC_peak
err_SEP1_kev_per_ADC = Energy_am241/sig_SEP1_ADC_peak
SEP2_kev_per_ADC = Energy_am241/SEP2_ADC_peak
err_SEP2_kev_per_ADC = Energy_am241/sig_SEP2_ADC_peak

print,1.0/SEP1_kev_per_ADC
print, 1.0/err_SEP1_kev_per_ADC
print,1.0/SEP2_kev_per_ADC
Print, 1.0/err_SEP2_kev_per_ADC

; next comes the energy deposited when a 35 and 40 keV protons source
; was used.  Use this to calculate the dead layer thickness

Gun_energies = [35.0, 40.0]

; the 2nd element is for 40 keV
SEP1AO_ADC_peak = [16.94, 20.08]
sig_SEP1AO_ADC_peak = [1.51, 1.52]

SEP1BO_ADC_peak = [16.07, 19.18]
sigSEP1AO_ADC_peak = [1.50, 1.52]
SEP2AO_ADC_peak = [14.85, 18.04]
sigSEP1AO_ADC_peak = [1.63, 1.58]
SEP2BO_ADC_peak = [16.42, 19.74]
sigSEP1AO_ADC_peak = [2.28, 2.28]


SEP1AO_energy_dep = SEP1AO_ADC_peak*SEP1_kev_per_ADC[2]
SEP1BO_energy_dep = SEP1BO_ADC_peak*SEP1_kev_per_ADC[5]

SEP2AO_energy_dep = SEP2AO_ADC_peak*SEP2_kev_per_ADC[2]
SEP2BO_energy_dep = SEP2BO_ADC_peak*SEP2_kev_per_ADC[5]

PRINT, SEP1AO_energy_dep
PRINT, SEP1BO_energy_dep
PRINT, SEP2AO_energy_dep
PRINT, SEP2BO_energy_dep

; now load up the GEANT4 results

dead_layer = array(50, 990.0, 95); array of deadlier thicknesses
nt = 95
path = '/home/pdunn/work/geant4/g4work/mavenCurrent/results/deadLayerAngstrom/3rdRun/'
;dirs = path+'/'+get_file_name_string(path)
;dira = get_file_name_string(path)
;num_dir = strarr(nt)
;for J = 0, nt-1 do num_dir[J] = strsplit(dira[J], 'A',/extract)
;order = sort(float(num_dir))

file_names = path+'mvn_sep_AO_'+roundst(replicate (1.0,nt)##([25, 30, 35, 40]))+'keV_'+$
  numbered_filestring (replicate (1, 4)#round(dead_layer), digits = 3) +'A.dat'
Center_energy = fltarr (nt, 4)
sigma_energy = fltarr (nt, 4) 
energy_array = array(0.125, 49.875, 200)
energies = [25, 30, 35, 40.0]
plotset
!p.multi = [0,2,4]
!p.charsize = 1.9
popen, 'Detected_energy_25-40_keV_proton_beam_dead_layers_50-1000A'
for J = 0, nt -1 do begin & $
  plot, [0, 0], yr = [0, 3000], xr = [0, 40], xtit = 'keV', $
  title = 'Dead Layer: '+roundst (dead_layer [J]) +' Angstroms',$
  charsize = 1.8&$
  for L = 0, 3 do begin & $
  f = read_ASCII (file_names[l,J], comment = '#') &$
  h = histogram (f.field01 [14,*], min = 1e-30, max = 50.0, nbins = 200, $
                  loc = loc) & $
  gf = gaussfit(loc+0.125, h,A,nterms = 3, estimates = $
                [2000,median(f.field01 [14,*]),2.0])& $
  Center_energy[J,L] = A[1]& $
  Sigma_energy [J,L] = A[2]& $
  oplot,energy_array,h, psy = 10& $
  oplot, energy_array,gf, color = L+1 & $
  xyouts, 31.0, 2000-L*300, roundst(energies [L]) + $
                                    ' keV protons', charsize = 0.7, color = L+1 & $
  endfor& $  
  print, J, ' out of ',nt & $
endfor

pclose




; now list the detected energies for each of the 4 O-detectors, as
; shown in the analogous plot in the official SEP calibration report
nan = sqrt (-7.2)
energy_detected_1A = [nan, nan,23.03, 27.35]
energy_detected_1B = [13.64, 17.56, 21.80, 26.15]
energy_detected_2A = [11.62, 15.81, 20.20, 24.52]
energy_detected_2B= [13.02, 17.21, 22.30, 26.65]
!p.multi=[0,1,2]
popen, 

plot, dead_layer,abs(energy_detected_1A[2] - center_energy[*, 2]), $
  yr = [-0.2, 3.5], /ysty, xr = [50,825],/xsty,psy=-4, $
  ytit = 
oplot, dead_layer,abs(energy_detected_1A[3] - center_energy[*, 3]),line=2

for L = 0, 3 do oplot, dead_layer,abs(energy_detected_1B[L] - center_energy[*, L]),$
  line = L+1,color = 1

for L = 0, 3 do oplot, dead_layer,abs(energy_detected_2A[L] - center_energy[*, L]),$
  line = L+1,color = 2

for L = 0, 3 do oplot, dead_layer,abs(energy_detected_2B[L] - center_energy[*, L]),$
  line = L+1,color = 6
pclose
; calculator chi-square

chisq_1A = fltarr(nt)
chisq_1B = fltarr(nt)
chisq_2A = fltarr(nt)
chisq_2B = fltarr(nt)

for J = 0, nt -1 do begin & $
  chisq_1A[J] = total ((energy_detected_1A - center_energy [J,*])^2.0,/nan)/$
  n_finite(energy_detected_1A)& $
chisq_1B[J] = total ((energy_detected_1B - center_energy [J,*])^2.0,/nan)/$
  n_finite(energy_detected_1B)& $
chisq_2A[J] = total ((energy_detected_2A - center_energy [J,*])^2.0,/nan)/$
  n_finite(energy_detected_2A)& $
chisq_2B[J] = total ((energy_detected_2B - center_energy [J,*])^2.0,/nan)/$
  n_finite(energy_detected_2B)& $
  endfor

minchisq_1A = min (chisq_1A, ind1A)
minchisq_1B = min (chisq_1B, ind1B)
minchisq_2A = min (chisq_2A, ind2A)
minchisq_2B = min (chisq_2B, ind2B)

plotset
!p.multi=[0,2,4]
!p.charsize = 1.7
popen,'MAVEN_SEP_dead_layer_calibration_20140312'
plot,dead_layer, chisq_1A, yr = [-0.2,3], xtit = 'dead layer thickness', $
  ytit = 'chi-square', psy = -4,/ysty, symsize = 0.5, title = 'Fits to Calibration Runs'
oplot,dead_layer, chisq_1A,color=1, psy = -4, symsize = 0.5
oplot, dead_layer, chisq_1B,color=2, psy = -4, symsize = 0.5
oplot, dead_layer, chisq_2A,color=4, psy = -4, symsize = 0.5
oplot, dead_layer, chisq_2B,color=6, psy = -4, symsize = 0.5
xyouts, 600, 2.4, 'SEP 1A-O', color = 1, charsize = 0.8
xyouts, 600, 2.0, 'SEP 1B-O', color = 2, charsize = 0.8
xyouts, 600, 1.6, 'SEP 2A-O', color = 4, charsize = 0.8
xyouts, 600, 1.2, 'SEP 2B-O', color = 6, charsize = 0.8

colors = [1, 2, 4, 6]
best_fit_dead_layers = ['SEP1A: '+roundst (dead_layer [ind1A]),$
                        'SEP1B: '+roundst (dead_layer [ind1B]),$
                        'SEP2A: '+roundst (dead_layer [ind2A]),$
                        'SEP2B: '+roundst (dead_layer [ind2B])]
plot, energies, energy_detected_1A, psy = 4,xr = [20.0, 47.0],yr=[10,30], $
  xtit = 'Incident proton energy, keV', ytit = 'Deposited energy, keV', symsize = 1.5, $
  /xsty, title = 'Best fit dead layers'
oplot, energies, energy_detected_1A, psy = 4, symsize = 0.9, color = 1
oplot, energies, energy_detected_1B, psy = 4, symsize = 0.9, color = 2
oplot, energies, energy_detected_2A, psy = 4, symsize = 0.9, color = 4
oplot, energies, energy_detected_2B, psy = 4, symsize = 0.9, color = 6
oplot, energies, Center_energy [ind1A,*], color = 1
oplot, energies, Center_energy [ind1B,*], color = 2
oplot, energies, Center_energy [ind2A,*], color = 4
oplot, energies, Center_energy [ind2B,*], color = 6
xyouts,21, 27.0, 'Dead Layers:', charsize = 0.8
 for J = 0, 3 do xyouts,37, 20.0-3.0*J, best_fit_dead_layers [J]+'A',$
   color = colors [J], charsize = 0.8
pclose
