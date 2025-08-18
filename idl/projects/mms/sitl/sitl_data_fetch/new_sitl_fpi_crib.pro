;mms_init, local_data_dir='~/Desktop/MMS/data/mms/'
mms_init;, local_data_dir='/MMS/data/mms/'

;cdf_leap_second_init

Re = 6378.137

;timespan, '2015-04-18/12:20:00', 25, /minutes
;timespan, '2015-05-07', 1, /day
timespan, '2016-02-14/23:10:00', 6, /hour

sc_id = 'mms3'

mms_sitl_get_fpi_basic, sc_id='mms3'

options, sc_id+'_fpi_eEnergySpectr_omni', 'spec', 1
options, sc_id+'_fpi_eEnergySpectr_omni', 'ylog', 1
options, sc_id+'_fpi_eEnergySpectr_omni', 'zlog', 1
options, sc_id+'_fpi_eEnergySpectr_omni', 'no_interp', 1
options, sc_id+'_fpi_eEnergySpectr_omni', 'ytitle', 'elec E, eV'
ylim, sc_id+'_fpi_eEnergySpectr_omni', 10, 26000
zlim, sc_id+'_fpi_eEnergySpectr_omni', .1, 2000

options, sc_id+'_fpi_iEnergySpectr_omni', 'spec', 1
options, sc_id+'_fpi_iEnergySpectr_omni', 'ylog', 1
options, sc_id+'_fpi_iEnergySpectr_omni', 'zlog', 1
options, sc_id+'_fpi_iEnergySpectr_omni', 'no_interp', 1
options, sc_id+'_fpi_iEnergySpectr_omni', 'ytitle', 'ion E, eV'
ylim, sc_id+'_fpi_iEnergySpectr_omni', 10, 26000
zlim, sc_id+'_fpi_iEnergySpectr_omni', .1, 2000

options, sc_id+'_fpi_ePitchAngDist_midEn', 'spec', 1
options, sc_id+'_fpi_ePitchAngDist_midEn', 'ylog', 0
options, sc_id+'_fpi_ePitchAngDist_midEn', 'zlog', 1
options, sc_id+'_fpi_ePitchAngDist_midEn', 'no_interp', 1
options, sc_id+'_fpi_ePitchAngDist_midEn', 'ytitle', 'ePADM, eV'
ylim, sc_id+'_fpi_ePitchAngDist_midEn', 1, 180
zlim, sc_id+'_fpi_ePitchAngDist_midEn', 100, 10000

options, sc_id+'_fpi_ePitchAngDist_highEn', 'spec', 1
options, sc_id+'_fpi_ePitchAngDist_highEn', 'ylog', 0
options, sc_id+'_fpi_ePitchAngDist_highEn', 'zlog', 1
options, sc_id+'_fpi_ePitchAngDist_highEn', 'no_interp', 1
options, sc_id+'_fpi_ePitchAngDist_highEn', 'ytitle', 'ePADH, eV'
ylim, sc_id+'_fpi_ePitchAngDist_highEn', 1, 180
zlim, sc_id+'_fpi_ePitchAngDist_highEn', 100, 10000

ylim, sc_id+'_fpi_DISnumberDensity', 1, 100
options, sc_id+'_fpi_DISnumberDensity', 'ylog', 1
options, sc_id+'_fpi_DISnumberDensity', 'ytitle', 'n, cm!U-3!N'

options, sc_id+'_fpi_iBulkV_DSC', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, sc_id+'_fpi_iBulkV_DSC', 'ytitle', 'V!DDSC!N, km/s'

bent_vec = sc_id + '_fpi_bentPipeB_DSC'
bent_mag = sc_id + '_fpi_bentPipeB_MAG'

tplot, [1, 2, 4, 5, 6, 7, 8]

end
