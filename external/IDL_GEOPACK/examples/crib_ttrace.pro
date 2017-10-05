;+
;Procedure: crib_ttrace
;
;Purpose: crib demonstrating the usage of tracing routines
;
;Notes: tracing may take a while to complete, don't worry it is
;not hung.
;Haje Korth's IDL/Geopack DLM must be installed for this
;       to work
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2014-03-05 09:46:43 -0800 (Wed, 05 Mar 2014) $
; $LastChangedRevision: 14500 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/examples/crib_ttrace.pro $
;-

;this makes all int declarations long by default and doesn't
;allow ambiguous array access (ie a(i) is illegal only a[i] is
;acceptable)

compile_opt idl2

;make sure a color table is loaded that will display all the lines

thm_init
;BASIC USAGE
;footprint trace in gsm

timespan,'2007-03-23'

thm_load_state,probe='c',coord='gsm',suffix='_gsm'

;input to the t89 model(par value) is the kp index(can be an array of kp indices)
ttrace2iono,'thc_state_pos_gsm',newname='thc_ifoot_gsm',external_model='t89',par=2.0D,/km
ttrace2equator,'thc_state_pos_gsm',newname='thc_efoot_gsm',external_model='t89',par=2.0D,/km

;increase the x margin so that you can see the labels on the left
tplot_options, 'xmargin', [15, 5]

tplot,['thc_state_pos_gsm','thc_ifoot_gsm','thc_efoot_gsm'], title = 'Themis C position & footprints'

stop

;MAP PROJECTIONS OF TRACES
;now load in geo
;for projection of ionospheric footprint on map

del_data,'*'

thm_load_state,probe='c',coord='geo'

ttrace2iono,'thc_state_pos',newname='thc_ifoot',external_model='t89',par=2.0D,/km,in_coord='geo',out_coord='geo'

xyz_to_polar,'thc_ifoot'

get_data,'thc_ifoot_phi',data=d
i_lon=d.y

get_data,'thc_ifoot_th',data=d
i_lat=d.y

;generate a map,(centered on some random point in the projection)
;if you want to see the projection with ground station data, see 
;themis/examples/thm_crib_asi.pro
;look at the plain map_set routine to see other types of maps that can
;be generated for plotting

thm_map_set,central_lon=i_lon[400],central_lat=i_lat[400],xsize=700,ysize=400

;ionospheric footpoint trace plotted on the map
plots,i_lon,i_lat

stop

del_data,'*'

;reset the colors because the map routine switches the color table
device,decomposed=0

loadct2,43

;2D TRACE PLOTS

;load data
thm_load_state,probe='c',coord='gsm'

tKm2Re,'thc_state_pos',/replace

;generate the trace
ttrace2equator,'thc_state_pos',newname='thc_efoot',external_model='t89',par=2.0D,in_coord='gsm',out_coord='gsm'

;plot y vs x with y having its maximum on the left

;NOTE: if the plot goes off the edge of your screen you should
;decrease the xsize and ysize keywords...the default in this crib
;is set for high resolution
tplotxy,'thc_state_pos',multi='2 2',versus='xryr', xtitle = 'Re', ytitle = 'Re',title='x vs y, pos and e-foot',window=0,xsize=1000,ysize=1000,wtitle='position & footprint plots'
tplotxy,'thc_efoot',versus='xryr',/overplot,linestyle=2,/isotropic

;plot y vs z with y having its maximum on the left
tplotxy,'thc_state_pos',/add,versus='yrz', xtitle = 'Re', ytitle = 'Re',/isotropic,title='y vs z, pos and e-foot'
tplotxy,'thc_efoot',versus='yrz',/overplot,linestyle=2,/isotropic

;plot x vs z with x having its maximum on the left
tplotxy,'thc_state_pos',/add,versus='xrz', xtitle = 'Re', ytitle = 'Re',/isotropic,title='x vs z, pos and e-foot'
tplotxy,'thc_efoot',versus='xrz',/overplot,linestyle=2,/isotropic

stop

;2D PLOT FIELD LINES WITH TRACES

;generate some dummy data to generate field line traces
t = replicate(time_double('2007-03-23/11:00:00'), 18)

x = -1*(dindgen(18)+2)^2
y = replicate(0D,18)
z = replicate(0D,18)
v = [[x], [y], [z]]

str = {x:t, y:v}

;this stores the dummy data

store_data, 'trace_data', data = str

;get the traces
ttrace2iono,'trace_data',trace_var_name = 'trace_n', newname='thc_ifoot',external_model='t89',par=2.0D,in_coord='gsm',out_coord='gsm'
ttrace2iono,'trace_data',trace_var_name = 'trace_s', newname='thc_ifoot',external_model='t89',par=2.0D,in_coord='gsm',out_coord='gsm', /south

;generate the 2-d plot
timespan,'2007-03-23/10:00:00',2,/hour

tplotxy,'thc_state_pos',/add, versus = 'xrz', xtitle = 'Re', ytitle = 'Re',title = 'fields x vs z',xrange=[-10,-4],yrange=[-6,4]

tplotxy,'thc_efoot', versus = 'xrz', /overplot, linestyle = 5
tplotxy, 'trace_n', versus = 'xrz', /overplot, linestyle = 2
tplotxy, 'trace_s', versus = 'xrz', /overplot, linestyle = 2

stop

;HOW TO USE THE OTHER MODELS

;these models are quite a bit slower than t89 so don't worry they will
;finish (-:

;timespan,'2008-07-02',1,/day
timespan, '2010-07-30',1,/day;date chosen at random here

thm_load_state,probe='c',coord='gsm'

;you may have to set the default download directory manually
;here are some examples:
;setenv,'ROOT_DATA_DIR=~/data' ;good for single user unix/linux system
;setenv,'ROOT_DATA_DIR=C:/Documents and Settings/YOURUSERNMAE/My Documents' ;example  if you don't want to use the default windows location (C:/data/ or E:/data/)

;load kyoto dst
kyoto_load_dst

;load wind data
wi_mfi_load
wi_3dp_load

cotrans,'wi_h0_mfi_B3GSE','wi_b3gsm',/GSE2GSM

get_tsy_params,'kyoto_dst','wi_b3gsm','wi_3dp_k0_ion_density','wi_3dp_k0_ion_vel','T96'

;arguments to t96 are:
;solar wind pressure nP
;dst index nT
;y component of interplanetary magnetic field
;z component of interplanetary magnetic field
;par must be a 10 element array(or Nx10) so all other values should be 0d

;longer timespans take a long time to run
;timespan,'2008-07-02/12:00:00',30,/minute
timespan,'2010-07-30/12:00:00',30,/minute

;time_clip,'thc_state_pos','2008-07-02/12:00:00','2008-07-02/12:30:00',newname='pos_clipped'
time_clip,'thc_state_pos','2010-07-30/12:00:00','2010-07-30/12:30:00',newname='pos_clipped'

ttrace2iono,'pos_clipped',newname='thc_ifoot_gsm',external_model='t96',par='t96_par',/km

tplot,['pos_clipped','thc_ifoot_gsm'], title = 'Themis C position & footprints'

stop

tplotxy,'pos_clipped',multi='2,1',title='thc_state_pos',versus='xrz',xtitle='X(km)',ytitle='Z(km)',xsize=1000,ysize=500,window=2

tplotxy,'thc_ifoot_gsm',/add,title='thc_ifoot_gsm',versus='xrz',xtitle='X(km)',ytitle='Z(km))'

stop

;arguments to t01 are:
;solar wind pressure nPa
;dst index nT
;y component of interplanetary magnetic field
;z component of interplanetary magnetic field
;g1,g2 indices describing solar wind conditions
;generate g1,g2 with geopack_getg
;par must be a 10 element array(or Nx10) so all other values should be 0d

;par = [2.0D,-30.0D,0.0D,-5D,g[0,0],g[0,1],0D,0D,0D,0D]

;parameters will be generated by get_tsy_params
get_tsy_params,'kyoto_dst','wi_b3gsm','wi_3dp_k0_ion_density','wi_3dp_k0_ion_vel','T01'

ttrace2iono,'pos_clipped',newname='thc_ifoot_gsm',external_model='t01',par='t01_par',/km

tplot,['thc_ifoot_gsm','pos_clipped']

stop

tplotxy,'pos_clipped',multi='2,1',title='thc_state_pos',versus='xrz',xtitle='X(km)',ytitle='Z(km)',xsize=1000,ysize=500,window=2
tplotxy,'thc_ifoot_gsm',/add,title='thc_ifoot_gsm',versus='xrz',xtitle='X(km)',ytitle='Z(km)'

stop

;geopack_getw generates arguments for the ts04 model
;arguments are:
;solar wind density cm^-3
;solar wind speed km/s
;z component of interplanetary magnetic field nT
;if you pass in N length arrays for each of the arguments it will
;produce an Nx2 length output
;All arrays of data must be sampled at 5 minute intervals
;these parameters represent integrals over the timeseries
;so history is important(thus we use a whole series of ace params)

get_tsy_params,'kyoto_dst','wi_b3gsm','wi_3dp_k0_ion_density','wi_3dp_k0_ion_vel','T04s'

;arguments to ts04 are:
;solar wind pressure nPa
;dst index nT
;y component of interplanetary magnetic field
;z component of interplanetary magnetic field
;w1,w2,w3,w4,w5,w6 storm time integral indices
;par can be a 10 element or an Nx10 element array

ttrace2iono,'pos_clipped',newname='thc_ifoot_gsm',external_model='t04s',par='t04s_par',/km

;same as above w/r/t time range
tplot,['thc_ifoot_gsm','pos_clipped']

stop

tplotxy,'pos_clipped',multi='2,1',title='thc_state_pos',versus='xrz',xtitle='X(km)',ytitle='Z(km)',xsize=1000,ysize=500,window=2
tplotxy,'thc_ifoot_gsm',/add,title='thc_ifoot_gsm',versus='xrz',xtitle='X(km)',ytitle='Z(km)'

stop

;here is an example using ace data
;it may take a little while to complete
;NOTE: Data availability from ISTP may change over time; for example,
;mfi k0 data is periodically pruned (removed) from the site as
;higher quality processed data becomes available.
ace_mfi_load
ace_swe_load

;load_ace_mag loads data in gse coords

cotrans,'ace_k0_mfi_BGSEc','ace_mag_Bgsm',/GSE2GSM

get_tsy_params,'kyoto_dst','ace_mag_Bgsm','ace_k0_swe_Np','ace_k0_swe_Vp','T96',/speed

ttrace2iono,'thc_state_pos',newname='thc_ifoot_gsm',external_model='t96',par='t96_par',/km

tplot,['thc_state_pos','thc_ifoot_gsm'], title = 'Themis C position & footprints'

stop

tplotxy,'pos_clipped',multi='2,1',title='thc_state_pos',versus='xrz',xtitle='X(km)',ytitle='Z(km)',xsize=1000,ysize=500,window=2

tplotxy,'thc_ifoot_gsm',/add,title='thc_ifoot_gsm',versus='xrz',xtitle='X(km)',ytitle='Z(km)'

stop

;here is an example using omni_hro_data
;it may take a little while to complete
;also omni data has nan flags in any data gaps
;so you may want to use tdeflag to interpolate
;across data gaps

;timespan,'2008-07-02/12:00:00',30,/minute

omni_hro_load

store_data,'omni_imf',data=['OMNI_HRO_1min_BY_GSM','OMNI_HRO_1min_BZ_GSM']

get_tsy_params,'kyoto_dst','omni_imf','OMNI_HRO_1min_proton_density','OMNI_HRO_1min_flow_speed','T96',/speed,/imf_yz

ttrace2iono,'thc_state_pos',newname='thc_ifoot_gsm',external_model='t96',par='t96_par',/km

tplot,['thc_state_pos','thc_ifoot_gsm'], title = 'Themis C position & footprints'

stop

timespan,'2007-03-23',1,/day

thm_load_state,probe='c',coord='gsm'

;example querying tilt used for each sampling period using get_tilt
ttrace2iono,'thc_state_pos',newname='thc_ifoot',external_model='t89',par=2.0D,in_coord='gsm',out_coord='gsm',get_tilt='out_tilt_reg',get_nperiod=np,/km

;example modifying tilt, adds ~ +- 2 degrees of noise, returns value used in tplot variable(add_tilt keyword works for ionospheric routines as well)
ttrace2equator,'thc_state_pos',newname='thc_efoot',external_model='t89',par=2.0D,in_coord='gsm',out_coord='gsm',get_tilt='out_tilt_eq',add_tilt=randomn(1,np),/km

;example replacing tilt,  uses +- 2 degrees of noise, returns value used in tplot variable(set_tilt keyword works for equatorial routines as well)
ttrace2iono,'thc_state_pos',newname='thc_ifoot',external_model='t89',par=2.0D,in_coord='gsm',out_coord='gsm',get_tilt='out_tilt_io',get_nperiod=np,set_tilt=randomn(1,1440),/km

;plot the tilt values that were used in each call
tplot,['out_tilt_reg','out_tilt_eq','out_tilt_io']

end
