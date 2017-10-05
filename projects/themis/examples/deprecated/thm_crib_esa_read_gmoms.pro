;+
;NAME:
; thm_crib_esa_read_gmoms
;PURPOSE:
;This crib shows how to extract the ground-based moments from level 2
;ESA data files
;
;Note on variable/routine names: Particle variables/routines follow
;the naming convention th[a/b/c/d/e]_p[e/s][i/e][f/r/b] where
;th=themis, [a/b/c/d/e]=spacecraft, p=particle, [e/s]=ESA or SST
;instrument, [i/e]=ion/electron, [f/r/b]=full/reduced/burst
;distribution
;
; 3-dec-2007, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-09-19 10:56:58 -0700 (Thu, 19 Sep 2013) $
; $LastChangedRevision: 13080 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/deprecated/thm_crib_esa_read_gmoms.pro $
;-
;To get *all* of the moments for all probes and one time_range
timespan, '2007-07-07', 1       ;set time span for a day in july 2007
thm_load_esa, level = 'l2'      ;level=2 works too
print, tnames()                 ;Gives the names of data variables that you loaded:

;For a single probe?
del_data, '*'                   ;deletes all data, so you can do more tests...
thm_load_esa, probe = ['a'], level = 'l2'

;For multiple, but not all probes?
del_data, '*'                   ;deletes all data, so you can do more tests...
thm_load_esa, probe = ['a',  'b'], level = 'l2'

;there are many different data types: Here load THEMIS B peif data:
;'peif' means 'particle - esa - ion - full'
del_data, '*'                   ;deletes all data, so you can do more tests...
thm_load_esa, probe = 'b', level = 2, datatype = 'pe?f_*'

;Here
;thb_peif_density                             ESA-FULL Ion Density
;thb_peif_avgtemp                             ESA-FULL Ion Average Temperature
;thb_peif_vthermal                            ESA-FULL Ion Thermal Velocity
;thb_peif_sc_pot                              ESA-FULL Ion Sc_Potential
;thb_peif_sc_current                          ESA-FULL Ion Sc_Current
;thb_peif_en_eflux                            ESA-FULL Ion energy spectrogram
;thb_peif_t3                                  ESA-FULL Diagonalized Ion Temperature
;thb_peif_magt3                               ESA-FULL Ion Temperature, Parallel and Perp. to Field
;thb_peif_ptens                               ESA-FULL Ion Pressure Tensor
;thb_peif_mftens                              ESA-FULL Ion Momentum Flux Tensor
;thb_peif_flux                                ESA-FULL Ion Particle Flux
;thb_peif_symm                                ESA-FULL Ion Symmetry Vector
;thb_peif_symm_ang                            ESA-FULL Ion Symm_ang
;thb_peif_magf                                Magnetic Field DSL, ESA-FULL Ions
;thb_peif_velocity_dsl                        ESA-FULL Ion Velocity DSL
;thb_peif_velocity_gse                        ESA-FULL Ion Velocity GSE
;thb_peif_velocity_gsm                        ESA-FULL Ion Velocity GSM
;thb_peif_mode                                ESA-FULL survey mode
;thb_peef_density                             ESA-FULL Electron Density
;thb_peef_avgtemp                             ESA-FULL Electron Average Temperature
;thb_peef_vthermal                            ESA-FULL Electron Thermal Velocity
;thb_peef_sc_pot                              ESA-FULL Electron Sc_Pot
;thb_peef_sc_current                          ESA-FULL Electron Sc_Current
;thb_peef_en_eflux                            ESA-FULL Electron energy spectrogram
;thb_peef_t3                                  ESA-FULL Diagonalized Electron Temperature
;thb_peef_magt3                               ESA-FULL Electron Temperature, Parallel and Perp. to Field
;thb_peef_ptens                               ESA-FULL Electron Pressure Tensor
;thb_peef_mftens                              ESA-FULL Electron Momentum Flux Tensor
;thb_peef_flux                                ESA-FULL Electron Particle Flux
;thb_peef_symm                                ESA-FULL Electron Symmetry Vector
;thb_peef_symm_ang                            ESA-FULL Electron Symm_ang
;thb_peef_magf                                Magnetic Field DSL, ESA-FULL Electrons
;thb_peef_velocity_dsl                        ESA-FULL Electron Velocity DSL
;thb_peef_velocity_gse                        ESA-FULL Electron Velocity GSE
;thb_peef_velocity_gsm                        ESA-FULL Electron Velocity GSM
;thb_peef_mode                                ESA-FULL survey mode


;to get all densities and pressures:
del_data, '*'
thm_load_esa, level = 2, datatype = '*_density *_ptens'
print,  tnames()
;In addition to * for wild cards, you can use ? for single character
;wild cards this will oad the t3 moment array for all electron modes
del_data, '*'
thm_load_esa, level = 'l2', datatype = ['pee?_t3']
print, tnames()

End

