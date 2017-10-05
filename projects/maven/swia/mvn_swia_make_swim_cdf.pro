;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIM_CDF
;PURPOSE: 
;	Routine to produce CDF file from SWIA onboard moment data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIM_CDF, FILE=FILE, DATA_VERSION = DATA_VERSION
;KEYWORDS:
;	FILE: Output file name
;	DATA_VERSION: Data version to put in file (default = '1')
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-05-27 06:43:06 -0700 (Wed, 27 May 2015) $
; $LastChangedRevision: 17736 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swim_cdf.pro $
;
;-

pro mvn_swia_make_swim_cdf, file = file, data_version = data_version

if not keyword_set(data_version) then data_version = '1'

;Need to put in real rotation code

common mvn_swia_data

if not keyword_set(file) then file = 'test.cdf'

data = swim
tail = 'svy'

;FIXME - Need to consider case where parameters change during the day being processed (probably split files)

info = data[0].info_index
use_info_str = info_str[info]

nrec = n_elements(data)

cdf_leap_second_init

date_range = time_double(['2013-11-18/00:00','2030-12-31/23:59'])
met_range = date_range - time_double('2000-01-01/12:00')
epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)


epoch = time_epoch(data.time_unix)
timett2000 = long64((add_tt2000_offset(data.time_unix)-time_double('2000-01-01/12:00'))*1e9)

fileid = cdf_create(file,/single_file,/network_encoding,/clobber)

varlist = ['epoch','time_tt2000','time_met','time_unix','atten_state','telem_mode','quality_flag','decom_flag','density','pressure','velocity','velocity_mso','temperature','temperature_mso','pindex','vindex','tindex','p_label','v_label','t_label','num_mom']
nvars = n_elements(varlist)


id0 = cdf_attcreate(fileid,'TITLE',/global_scope)
id1 = cdf_attcreate(fileid,'Project',/global_scope)
id2 = cdf_attcreate(fileid,'Discipline',/global_scope)
id3 = cdf_attcreate(fileid,'Source_name',/global_scope)
id4 = cdf_attcreate(fileid,'Descriptor',/global_scope)
id5 = cdf_attcreate(fileid,'Data_type',/global_scope)
id6 = cdf_attcreate(fileid,'Data_version',/global_scope)
id7 = cdf_attcreate(fileid,'TEXT',/global_scope)
id8 = cdf_attcreate(fileid,'MODS',/global_scope)
id9 = cdf_attcreate(fileid,'Logical_file_id',/global_scope)
id10 = cdf_attcreate(fileid,'Logical_source',/global_scope)
id11 = cdf_attcreate(fileid,'Logical_source_description',/global_scope)
id12 = cdf_attcreate(fileid,'PI_name',/global_scope)
id13 = cdf_attcreate(fileid,'PI_affiliation',/global_scope)
id14 = cdf_attcreate(fileid,'Instrument_type',/global_scope)
id15 = cdf_attcreate(fileid,'Mission_group',/global_scope)
id16 = cdf_attcreate(fileid,'Parents',/global_scope)
id17 = cdf_attcreate(fileid,'PDS_collection_id',/global_scope)
id18 = cdf_attcreate(fileid,'PDS_start_time',/global_scope)
id19 = cdf_attcreate(fileid,'PDS_stop_time',/global_scope)
id20 = cdf_attcreate(fileid,'PDS_sclk_start_count',/global_scope)
id21 = cdf_attcreate(fileid,'PDS_sclk_stop_count',/global_scope)
id22 = cdf_attcreate(fileid,'leapseconds_kernel',/global_scope)
id23 = cdf_attcreate(fileid,'Spacecraft_clock_kernel',/global_scope)


cdf_attput,fileid,'TITLE',0,'MAVEN SWIA Onboard Moments'
cdf_attput,fileid,'Project',0,'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
cdf_attput,fileid,'Discipline',0,'Planetary Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
cdf_attput,fileid,'Descriptor',0,'SWIA>Solar Wind Ion Analyzer'
cdf_attput,fileid,'Data_type',0,'CAL>Calibrated'
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,'MAVEN SWIA Onboard Moments'
cdf_attput,fileid,'MODS',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,'maven_cal_swia_'+ strmid( time_string(data[0].time_unix, FORMAT=6),0,8)+'_v'+data_version
cdf_attput,fileid,'Logical_source',0,'SWIA.calibrated.onboard_'+tail+'_mom'
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SWIA (Solar Wind Ion Analyzer), Onboard Moments'
cdf_attput,fileid,'PI_name',0,'J.S. Halekas'
cdf_attput,fileid,'PI_affiliation',0,'U Iowa'
cdf_attput,fileid,'Instrument_type',0,'Plasma and Solar Wind'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
cdf_attput,fileid,'Parents',0,'None'
cdf_attput,fileid,'PDS_collection_id',0,'urn:nasa:pds:maven.swia.calibrated:data.onboard_svy_mom'
cdf_attput,fileid,'PDS_start_time',0,time_string(data[0].time_unix,tformat = 'YYYY-MM-DDThh:mm:ss.fffZ')
cdf_attput,fileid,'PDS_stop_time',0,time_string(data[nrec-1].time_unix,tformat = 'YYYY-MM-DDThh:mm:ss.fffZ')

etstart = time_ephemeris(data[0].time_unix)
etend = time_ephemeris(data[nrec-1].time_unix)
cspice_sce2c,-202,etstart,sclkdp0
cspice_sce2c,-202,etend,sclkdp1

cdf_attput,fileid,'PDS_sclk_start_count',0,sclkdp0
cdf_attput,fileid,'PDS_sclk_stop_count',0,sclkdp1

tls = mvn_spice_kernels('LSK')
sclk = mvn_spice_kernels('SCK')
leap = strmid(tls,strpos(tls,'naif',/reverse_search),12)
clock = strmid(sclk,strpos(sclk,'MVN_SCLKSCET',/reverse_search),22)

cdf_attput,fileid,'leapseconds_kernel',0,leap[0]
cdf_attput,fileid,'Spacecraft_clock_kernel',0,clock[0]


dummy = cdf_attcreate(fileid,'FIELDNAM',/variable_scope)
dummy = cdf_attcreate(fileid,'MONOTON',/variable_scope)
dummy = cdf_attcreate(fileid,'FORMAT',/variable_scope)
dummy = cdf_attcreate(fileid,'FORM_PTR',/variable_scope)
dummy = cdf_attcreate(fileid,'LABLAXIS',/variable_scope)
dummy = cdf_attcreate(fileid,'LABL_PTR_1',/variable_scope)
dummy = cdf_attcreate(fileid,'VAR_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'FILLVAL',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_0',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_1',/variable_scope)
dummy = cdf_attcreate(fileid,'DISPLAY_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)
dummy = cdf_attcreate(fileid,'CATDESC',/variable_scope)



;TT2000 epoch

varid = cdf_varcreate(fileid, varlist[0], /CDF_time_tt2000, /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'epoch',timett2000

cdf_attput,fileid,'FIELDNAM',varid,varlist[0],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I22',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[0],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,long64(-9223372036854775808),/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','epoch',tt2000_range[0],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'VALIDMAX','epoch',tt2000_range[1],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'SCALEMIN','epoch',timett2000[0],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'SCALEMAX','epoch',timett2000[nrec-1],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'UNITS','epoch','ns',/ZVARIABLE
cdf_attput,fileid,'MONOTON','epoch','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','epoch','Time, start of sample, in TT2000 time base',/ZVARIABLE



;MET

varid = cdf_varcreate(fileid, varlist[2], /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'time_met',data.time_met

cdf_attput,fileid,'FIELDNAM',varid,varlist[2],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[2],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0d31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','time_met',met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','time_met',met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','time_met',data[0].time_met,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','time_met',data[nrec-1].time_met,/ZVARIABLE
cdf_attput,fileid,'UNITS','time_met','s',/ZVARIABLE
cdf_attput,fileid,'MONOTON','time_met','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','time_met','Time, start of sample, in raw mission elapsed time',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','time_met','epoch',/ZVARIABLE



;Unix Time

varid = cdf_varcreate(fileid, varlist[3], /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'time_unix',data.time_unix

cdf_attput,fileid,'FIELDNAM',varid,varlist[3],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[3],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0d31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','time_unix',date_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','time_unix',date_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','time_unix',data[0].time_unix,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','time_unix',data[nrec-1].time_unix,/ZVARIABLE
cdf_attput,fileid,'UNITS','time_unix','s',/ZVARIABLE
cdf_attput,fileid,'MONOTON','time_unix','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','time_unix','Time, start of sample, in Unix time',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','time_unix','epoch',/ZVARIABLE



;Attenuator State

varid = cdf_varcreate(fileid, varlist[4], /CDF_UINT1, /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'atten_state',data.atten_state

cdf_attput,fileid,'FIELDNAM',varid,varlist[4],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[4],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,byte(255),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','atten_state',byte(1),/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','atten_state',byte(3),/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','atten_state',byte(1),/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','atten_state',byte(3),/ZVARIABLE
cdf_attput,fileid,'CATDESC','atten_state','Attenuator state, 1 = open, 2 = closed, 3 = cover closed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','atten_state','epoch',/ZVARIABLE



;Telemetry Mode

varid = cdf_varcreate(fileid, varlist[5], /CDF_UINT1, /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'telem_mode',data.swi_mode

cdf_attput,fileid,'FIELDNAM',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,byte(255),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','telem_mode',byte(0),/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','telem_mode',byte(1),/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','telem_mode',byte(0),/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','telem_mode',byte(1),/ZVARIABLE
cdf_attput,fileid,'CATDESC','telem_mode','Telemetry Mode: 1 = Sheath, 0 = Solar Wind',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','telem_mode','epoch',/ZVARIABLE



;Quality Flag

varid = cdf_varcreate(fileid, varlist[6], /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'quality_flag',data.quality_flag

cdf_attput,fileid,'FIELDNAM',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','quality_flag',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','quality_flag',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','quality_flag',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','quality_flag',1.0,/ZVARIABLE
cdf_attput,fileid,'CATDESC','quality_flag','Quality Flag: 0 = bad, 1 = good',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','quality_flag','epoch',/ZVARIABLE



;Decommutation Flag

varid = cdf_varcreate(fileid, varlist[7], /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'decom_flag',data.decom_flag

cdf_attput,fileid,'FIELDNAM',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','decom_flag',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','decom_flag',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','decom_flag',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','decom_flag',1.0,/ZVARIABLE
cdf_attput,fileid,'CATDESC','decom_flag','Decommutation Flag: 0 = uncertain mode/attenuator flags, 1 = known mode/attenuator flags',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','decom_flag','epoch',/ZVARIABLE



;density

varid = cdf_varcreate(fileid, varlist[8], /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'density',data.density

cdf_attput,fileid,'FIELDNAM',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','density',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','density',1e6,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','density',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','density',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','density','cm^-3',/ZVARIABLE
cdf_attput,fileid,'CATDESC','density','Onboard density Moment',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','density','epoch',/ZVARIABLE




;pressure
dim_vary = [1]
dim = 6

varid = cdf_varcreate(fileid, varlist[9], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'pressure',data.pressure

cdf_attput,fileid,'FIELDNAM',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F16.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','pressure',-1e6,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','pressure',1e6,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','pressure',-1e5,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','pressure',1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS','pressure','eV/cm^-3',/ZVARIABLE
cdf_attput,fileid,'CATDESC','pressure','Onboard pressure Moment (Inst. Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','pressure','epoch',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1','pressure','pindex',/ZVARIABLE
cdf_attput,fileid,'LABL_PTR_1','pressure','p_label',/ZVARIABLE




;velocity (Inst)
dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[10], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'velocity',data.velocity

cdf_attput,fileid,'FIELDNAM',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F18.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','velocity',-1e7,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','velocity',1e7,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','velocity',-1e3,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','velocity',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','velocity','km/s',/ZVARIABLE
cdf_attput,fileid,'CATDESC','velocity','Onboard velocity Moment (Inst. Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','velocity','epoch',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1','velocity','vindex',/ZVARIABLE
cdf_attput,fileid,'LABL_PTR_1','velocity','v_label',/ZVARIABLE



;velocity (MSO)

dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[11], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)

get_data,'mvn_swim_velocity_mso',data = vmso
cdf_varput,fileid,'velocity_mso',transpose(vmso.y[*,0:2])    

cdf_attput,fileid,'FIELDNAM',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F18.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','velocity_mso',-1e7,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','velocity_mso',1e7,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','velocity_mso',-1e3,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','velocity_mso',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','velocity_mso','km/s',/ZVARIABLE
cdf_attput,fileid,'CATDESC','velocity_mso','Onboard velocity Moment (MSO Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','velocity_mso','epoch',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1','velocity_mso','vindex',/ZVARIABLE
cdf_attput,fileid,'LABL_PTR_1','velocity_mso','v_label',/ZVARIABLE





;temperature (Inst)
dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[12], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)

cdf_varput,fileid,'temperature',data.temperature

cdf_attput,fileid,'FIELDNAM',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','temperature',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','temperature',1e6,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','temperature',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','temperature',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','temperature','eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','temperature','Onboard temperature Moment (Inst. Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','temperature','epoch',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1','temperature','tindex',/ZVARIABLE
cdf_attput,fileid,'LABL_PTR_1','temperature','t_label',/ZVARIABLE



;temperature (MSO)

dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[13], dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE)

get_data,'mvn_swim_temperature_mso',data = tmso
cdf_varput,fileid,'temperature_mso',transpose(tmso.y[*,0:2])    

cdf_attput,fileid,'FIELDNAM',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','temperature_mso',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','temperature_mso',1e6,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','temperature_mso',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','temperature_mso',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','temperature_mso','eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','temperature_mso','Onboard temperature Moment (MSO Coords)',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','temperature_mso','epoch',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1','temperature_mso','tindex',/ZVARIABLE
cdf_attput,fileid,'LABL_PTR_1','temperature_mso','t_label',/ZVARIABLE



;pressure Index

dim_vary = [1]
dim = 6

varid = cdf_varcreate(fileid, varlist[14], dim_vary, DIM = dim, /CDF_UINT1, /REC_NOVARY,/ZVARIABLE)

cdf_varput,fileid,'pindex',indgen(6)

cdf_attput,fileid,'FIELDNAM',varid,varlist[14],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[14],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-127,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','pindex',byte(0),/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','pindex',byte(5),/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','pindex',byte(0),/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','pindex',byte(5),/ZVARIABLE
cdf_attput,fileid,'CATDESC','pindex','pressure Index for CDF compatibility',/ZVARIABLE



;velocity Index

dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[15], dim_vary, DIM = dim, /CDF_UINT1, /REC_NOVARY,/ZVARIABLE)

cdf_varput,fileid,'vindex',indgen(3)

cdf_attput,fileid,'FIELDNAM',varid,varlist[15],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[15],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,255B,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','vindex',byte(0),/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','vindex',byte(2),/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','vindex',byte(0),/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','vindex',byte(2),/ZVARIABLE
cdf_attput,fileid,'CATDESC','vindex','velocity Index for CDF compatibility',/ZVARIABLE



;temperature Index

dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[16], dim_vary, DIM = dim, /CDF_UINT1, /REC_NOVARY,/ZVARIABLE)

cdf_varput,fileid,'tindex',indgen(3)

cdf_attput,fileid,'FIELDNAM',varid,varlist[16],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[16],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,255B,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','tindex',byte(0),/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','tindex',byte(2),/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','tindex',byte(0),/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','tindex',byte(2),/ZVARIABLE
cdf_attput,fileid,'CATDESC','tindex','temperature Index for CDF compatibility',/ZVARIABLE


;Pressure Label

dim_vary = [1]
dim = 6

varid = cdf_varcreate(fileid, varlist[17], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=3)
cdf_attput,fileid,'FIELDNAM',varid,varlist[17],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'A2',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid," ",/ZVARIABLE
cdf_attput,fileid,'CATDESC','p_label','Pressure Tensor Label for CDF compatibility',/ZVARIABLE

cdf_varput,fileid,'p_label',['Pxx','Pyy','Pzz','Pxy','Pxz','Pyz']


;Velocity Label

dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[18], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=2)
cdf_attput,fileid,'FIELDNAM',varid,varlist[18],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'A2',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid," ",/ZVARIABLE
cdf_attput,fileid,'CATDESC','v_label','Velocity Label for CDF compatibility',/ZVARIABLE

cdf_varput,fileid,'v_label',['Vx','Vy','Vz']


;Temperature Label

dim_vary = [1]
dim = 3

varid = cdf_varcreate(fileid, varlist[19], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=2)
cdf_attput,fileid,'FIELDNAM',varid,varlist[19],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'A2',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid," ",/ZVARIABLE
cdf_attput,fileid,'CATDESC','t_label','Energy Axis Label for CDF compatibility',/ZVARIABLE

cdf_varput,fileid,'t_label',['Tx','Ty','Tz']



;Number of Moments 

varid = cdf_varcreate(fileid, varlist[20], /CDF_INT2, /REC_NOVARY,/ZVARIABLE)

cdf_varput,fileid,'num_mom',nrec

cdf_attput,fileid,'FIELDNAM',varid,varlist[20],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[20],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,fix(-32767),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','num_mom',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','num_mom',21600,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','num_mom',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','num_mom',21600,/ZVARIABLE
cdf_attput,fileid,'CATDESC','num_mom','Number of Moment Sets in File',/ZVARIABLE







cdf_close,fileid

end
