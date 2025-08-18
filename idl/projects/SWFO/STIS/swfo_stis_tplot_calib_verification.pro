;pro swfo_stis_tplot_calib_verification


noaa_xray_test_filename = '/Users/rjolitz/swfo_dat/SWFO_STIS_xray_combined_l0b.nc'
l0b_noaa_nc = swfo_ncdf_read(filenames=noaa_xray_test_filename)
level_0b_noaa = swfo_stis_level_0b_fromncdf(l0b_noaa_nc, /noaa)
level_1a_noaa =   swfo_stis_sci_level_1a(level_0b_noaa)
level_1b_noaa =   swfo_stis_sci_level_1b(level_1a_noaa)

if n_elements(level_0b_noaa) ne 0 then begin
    ddata = dynamicarray(name='Science_L0b')
    ddata.append, level_0b_noaa
  store_data,'L0b',data = ddata,tagnames = '*'  , verbose=1 ;, time_tag = 'TIME_UNIX';,val_tag='_NRG'    ; warning don't use time_tag keyword
  options,'L0b_SCI_COUNTS',spec=1, zlog=1
 endif

 if n_elements(level_1a_noaa) ne 0 then begin
    ddata = dynamicarray(name='Science_L1a')
    ddata.append, level_1a_noaa
  store_data,'L1a',data = ddata,tagnames = 'SPEC_??',val_tag='_NRG'
  options,'L1a_SPEC_??',spec=1, zlog=1, ylog=1, yrange=[10, 2e3]
endif

channels=['CH1','CH2','CH3','CH4','CH5','CH6']
options,/def,'*_BITS *USER_0A',tplot_routine='bitplot',psyms=1
options,/def,'*PTCU_BITS',numbits=4,labels=reverse(['P=PPS Missing','T=TOD Missing','C=Compression','U=Use LUT']),colors=[0,1,2,6]
options,/def,'*AAEE_BITS',numbits=4,labels=reverse(['Attenuator IN','Attenuator OUT','Checksum Error 1','Checksum Error 0']),colors=[0,1,2,6]
options,/def,'*PULSER_BITS',labels=reverse(['LUT 0:Lower 1:Upper','Pulser Enable',reverse(channels)]),colors='bgrbgrkm'
options,/def,'*DETECTOR_BITS',labels=reverse(['Decimate','NONLUT 0:Log 1:Linear',reverse(channels)]),colors='bgrbgrcm'
options,/def,'*DECIMATION_FACTOR_BITS',labels=['CH2','CH2','CH3','CH3','CH5','CH5','CH6','CH6'],colors='ggrrcckk'
options,/def,'*hkp?_VALID_ENABLE_MASK_BITS',numbits=6,labels=channels,colors='bgrmcd'
options,/def,'*NOISE_BITS',numbits=12,labels=reverse(['ENABLE','RES2','RES1','RES0','PERIOD7','PERIOD6','PERIOD5','PERIOD4','PERIOD3','PERIOD2','PERIOD1','PERIOD0']),colors=[0,1,2,6]

options, 'noaa_swfo_stis_L0b_SCI_RESOLUTION', tplot_routine='bitplot',psyms=1, numbits=4
options, '*_SCI_TRANSLATE', ylog=1

tplot, ['L1a_SPEC_F?', '*SCI_DETECTOR_BITS', 'L0b_SCI_TRANSLATE', 'L0b_SCI_RESOLUTION']

end