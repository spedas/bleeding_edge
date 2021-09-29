; SITL Feeps Crib
; 

mms_init

timespan, '2018-04-01/20:00:00', 6, /hours

probes = '1'

mms_sitl_get_feeps, probes=probes

feeps_e_omni = 'mms' + probes + '_epd_feeps_srvy_sitl_electron_intensity_omni'
feeps_i_omni = 'mms' + probes + '_epd_feeps_srvy_sitl_ion_intensity_omni'

options, [feeps_e_omni, feeps_i_omni], 'spec', 1

options, [feeps_e_omni, feeps_i_omni], 'ylog', 1

options, [feeps_e_omni, feeps_i_omni], 'zlog', 1

ylim, [feeps_e_omni], 35, 500

ylim, [feeps_i_omni], 55, 500

tplot, [feeps_e_omni, feeps_i_omni]

end