;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIC_CDF
;PURPOSE: 
;	Routine to produce CDF file from SWIA coarse survey or archive data
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIC_CDF, FILE=FILE, /ARCHIVE, DATA_VERSION = DATA_VERSION
;KEYWORDS:
;	FILE: Output file name
;	ARCHIVE: If set, produce a file with archive data rather than survey (default)
;	DATA_VERSION: Data version to put in file (default = '1')
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2015-05-27 06:43:06 -0700 (Wed, 27 May 2015) $
; $LastChangedRevision: 17736 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swic_cdf.pro $
;
;-

pro mvn_swia_make_swic_cdf, file = file, archive = archive, data_version = data_version

if not keyword_set(data_version) then data_version = '1'

common mvn_swia_data

if not keyword_set(file) then file = 'test.cdf'

if keyword_set(archive) then begin
	data = swica 
	tail = 'arc'
endif else begin
	data = swics
	tail = 'svy'
endelse

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

varlist = ['epoch','time_tt2000','time_met','time_unix','atten_state','grouping','num_accum','counts','diff_en_fluxes', 'geom_factor','de_over_e_coarse','accum_time_coarse','energy_coarse','theta_coarse','theta_atten_coarse','g_theta_coarse', 'g_theta_atten_coarse','phi_coarse','g_phi_coarse','g_phi_atten_coarse','dindex','phi_label','def_label','en_label','num_dists']
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


cdf_attput,fileid,'TITLE',0,'MAVEN SWIA Coarse 3d Distributions'
cdf_attput,fileid,'Project',0,'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
cdf_attput,fileid,'Discipline',0,'Planetary Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
cdf_attput,fileid,'Descriptor',0,'SWIA>Solar Wind Ion Analyzer'
cdf_attput,fileid,'Data_type',0,'CAL>Calibrated'
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,'MAVEN SWIA Coarse 3d Distributions'
cdf_attput,fileid,'MODS',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,'maven_cal_swia_'+ strmid( time_string(data[0].time_unix, FORMAT=6),0,8)+'_v'+data_version
cdf_attput,fileid,'Logical_source',0,'SWIA.calibrated.coarse_'+tail+'_3d'
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SWIA (Solar Wind Ion Analyzer), Coarse 3d Distributions'
cdf_attput,fileid,'PI_name',0,'J.S. Halekas'
cdf_attput,fileid,'PI_affiliation',0,'U Iowa'
cdf_attput,fileid,'Instrument_type',0,'Plasma and Solar Wind'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
cdf_attput,fileid,'Parents',0,'None'
cdf_attput,fileid,'PDS_collection_id',0,'urn:nasa:pds:maven.swia.calibrated:data.coarse_'+tail+'_3d'
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
dummy = cdf_attcreate(fileid,'LABL_PTR_2',/variable_scope)
dummy = cdf_attcreate(fileid,'LABL_PTR_3',/variable_scope)
dummy = cdf_attcreate(fileid,'VAR_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'FILLVAL',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_0',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_1',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_2',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_3',/variable_scope)
dummy = cdf_attcreate(fileid,'DISPLAY_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)
dummy = cdf_attcreate(fileid,'CATDESC',/variable_scope)



;TT2000 epoch

varid = cdf_varcreate(fileid, varlist[0], /CDF_time_tt2000, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[0],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I22',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[0],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-9223372036854775808,/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','epoch',tt2000_range[0],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'VALIDMAX','epoch',tt2000_range[1],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'SCALEMIN','epoch',timett2000[0],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'SCALEMAX','epoch',timett2000[nrec-1],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'UNITS','epoch','ns',/ZVARIABLE
cdf_attput,fileid,'MONOTON','epoch','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','epoch','Time, start of sample, in TT2000 time base',/ZVARIABLE

cdf_varput,fileid,'epoch',timett2000


;MET

varid = cdf_varcreate(fileid, varlist[2], /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
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

cdf_varput,fileid,'time_met',data.time_met


;Unix Time

varid = cdf_varcreate(fileid, varlist[3], /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
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

cdf_varput,fileid,'time_unix',data.time_unix


;Attenuator State

varid = cdf_varcreate(fileid, varlist[4], /CDF_UINT1, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[4],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[4],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,255B,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','atten_state',1B,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','atten_state',3B,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','atten_state',1B,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','atten_state',3B,/ZVARIABLE
cdf_attput,fileid,'CATDESC','atten_state','Attenuator state, 1 = open, 2 = closed, 3 = cover closed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','atten_state','epoch',/ZVARIABLE

cdf_varput,fileid,'atten_state',data.atten_state



;grouping

varid = cdf_varcreate(fileid, varlist[5], /CDF_UINT1, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,255B,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','grouping',0B,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','grouping',2B,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','grouping',0B,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','grouping',2B,/ZVARIABLE
cdf_attput,fileid,'CATDESC','grouping','Data Binning Flag: 0 = 48 energies, 1 = 24 energies, 2 = 16 energies',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','grouping','epoch',/ZVARIABLE

cdf_varput,fileid,'grouping',data.grouping


;Number of Accumulations per Sample

varid = cdf_varcreate(fileid, varlist[6], /CDF_INT2, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,fix(-32768),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','num_accum',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','num_accum',512,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','num_accum',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','num_accum',512,/ZVARIABLE
cdf_attput,fileid,'CATDESC','num_accum','Number of Accumulations Summed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','num_accum','epoch',/ZVARIABLE

cdf_varput,fileid,'num_accum',data.num_accum


;counts

dim_vary = [1,1,1]  
dim = [48,4,16]  
varid = cdf_varcreate(fileid, varlist[7],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F18.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','counts',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','counts',1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','counts',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','counts',1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS','counts','counts',/ZVARIABLE
cdf_attput,fileid,'CATDESC','counts','Raw Instrument counts',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','counts','epoch',/ZVARIABLE
cdf_attput,fileid,'DEPEND_3','counts','energy_coarse',/ZVARIABLE
cdf_attput,fileid,'DEPEND_2','counts','dindex',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1','counts','phi_coarse',/ZVARIABLE

;note the above are reversed for row-major vs. column-major


for i = 0,nrec-1 do begin
	if i eq 0 then start = 1 else start = 0
			
	dat = mvn_swia_get_3dc(index = i, start = start, archive = archive)
			
	dat = conv_units(dat,'counts')

	data[i].data = reform(dat.data,48,4,16)

endfor

cdf_varput,fileid,'counts',data.data



;Differential Energy Flux

dim_vary = [1,1,1]  
dim = [48,4,16]  
varid = cdf_varcreate(fileid, varlist[8],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F20.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE 
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','diff_en_fluxes',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','diff_en_fluxes',1e14,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','diff_en_fluxes',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','diff_en_fluxes',1e11,/ZVARIABLE
cdf_attput,fileid,'UNITS','diff_en_fluxes','ev/[eV cm^2 sr s]',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE','diff_en_fluxes','data',/ZVARIABLE
cdf_attput,fileid,'CATDESC','diff_en_fluxes','Calibrated Differential Energy Flux',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','diff_en_fluxes','epoch',/ZVARIABLE
cdf_attput,fileid,'DEPEND_3','diff_en_fluxes','energy_coarse',/ZVARIABLE
cdf_attput,fileid,'DEPEND_2','diff_en_fluxes','dindex',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1','diff_en_fluxes','phi_coarse',/ZVARIABLE
cdf_attput,fileid,'LABL_PTR_1','diff_en_fluxes','phi_label',/ZVARIABLE
cdf_attput,fileid,'LABL_PTR_2','diff_en_fluxes','def_label',/ZVARIABLE
cdf_attput,fileid,'LABL_PTR_3','diff_en_fluxes','en_label',/ZVARIABLE

for i = 0,nrec-1 do begin
	if i eq 0 then start = 1 else start = 0
			
	dat = mvn_swia_get_3dc(index = i, start = start,archive = archive)
			
	dat = conv_units(dat,'Eflux')

	data[i].data = reform(dat.data,48,4,16)

endfor

cdf_varput,fileid,'diff_en_fluxes',data.data


;Geometric Factor

varid = cdf_varcreate(fileid, varlist[9], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','geom_factor',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','geom_factor',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','geom_factor',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','geom_factor',1e-2,/ZVARIABLE
cdf_attput,fileid,'UNITS','geom_factor','cm^2 sr eV/eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','geom_factor','Full Analyzer Geometric Factor',/ZVARIABLE

cdf_varput,fileid,'geom_factor',use_info_str.geom


;DE/E

varid = cdf_varcreate(fileid, varlist[10], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','de_over_e_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','de_over_e_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','de_over_e_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','de_over_e_coarse',0.2,/ZVARIABLE
cdf_attput,fileid,'UNITS','de_over_e_coarse','eV/eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','de_over_e_coarse','Coarse DeltaE/E',/ZVARIABLE

cdf_varput,fileid,'de_over_e_coarse',use_info_str.deovere_coarse



;Accumulation Time

varid = cdf_varcreate(fileid, varlist[11], /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[11],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','accum_time_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','accum_time_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','accum_time_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','accum_time_coarse',0.1,/ZVARIABLE
cdf_attput,fileid,'UNITS','accum_time_coarse','s',/ZVARIABLE
cdf_attput,fileid,'CATDESC','accum_time_coarse','Coarse Integration Time',/ZVARIABLE

cdf_varput,fileid,'accum_time_coarse',use_info_str.dt_int*12



;Energy

dim_vary = [1]
dim = 48

varid = cdf_varcreate(fileid, varlist[12], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[12],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','energy_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','energy_coarse',5e4,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','energy_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','energy_coarse',3e4,/ZVARIABLE
cdf_attput,fileid,'UNITS','energy_coarse','eV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','energy_coarse','Coarse Energy Table',/ZVARIABLE

cdf_varput,fileid,'energy_coarse',use_info_str.energy_coarse


;Theta

dim_vary = [1,1]
dim = [48,4]

varid = cdf_varcreate(fileid, varlist[13], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[13],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','theta_coarse',-180.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','theta_coarse',180.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','theta_coarse',-45.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','theta_coarse',45.0,/ZVARIABLE
cdf_attput,fileid,'UNITS','theta_coarse','degrees',/ZVARIABLE
cdf_attput,fileid,'CATDESC','theta_coarse','Coarse Deflection Angle (Theta) Table for Attenuator Open',/ZVARIABLE

cdf_varput,fileid,'theta_coarse',use_info_str.theta_coarse


;Theta Atten

dim_vary = [1,1]
dim = [48,4]

varid = cdf_varcreate(fileid, varlist[14], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[14],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[14],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','theta_atten_coarse',-180.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','theta_atten_coarse',180.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','theta_atten_coarse',-45.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','theta_atten_coarse',45.0,/ZVARIABLE
cdf_attput,fileid,'UNITS','theta_atten_coarse','degrees',/ZVARIABLE
cdf_attput,fileid,'CATDESC','theta_atten_coarse','Coarse Deflection Angle (Theta) Table for Attenuator Closed',/ZVARIABLE

cdf_varput,fileid,'theta_atten_coarse',use_info_str.theta_coarse_atten


;G Theta

dim_vary = [1,1]
dim = [48,4]

varid = cdf_varcreate(fileid, varlist[15], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[15],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[15],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','g_theta_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','g_theta_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','g_theta_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','g_theta_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'CATDESC','g_theta_coarse','Coarse Relative Sensitivity Table for Attenuator Open',/ZVARIABLE

cdf_varput,fileid,'g_theta_coarse',use_info_str.g_th_coarse


;G Theta Atten

dim_vary = [1,1]
dim = [48,4]

varid = cdf_varcreate(fileid, varlist[16], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[16],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[16],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','g_theta_atten_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','g_theta_atten_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','g_theta_atten_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','g_theta_atten_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'CATDESC','g_theta_atten_coarse','Coarse Relative Sensitivity Table for Attenuator Closed',/ZVARIABLE

cdf_varput,fileid,'g_theta_atten_coarse',use_info_str.g_th_coarse_atten


;Phi

dim_vary = [1]
dim = 16

varid = cdf_varcreate(fileid, varlist[17], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[17],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[17],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','phi_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','phi_coarse',360.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','phi_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','phi_coarse',360.0,/ZVARIABLE
cdf_attput,fileid,'UNITS','phi_coarse','degrees',/ZVARIABLE
cdf_attput,fileid,'CATDESC','phi_coarse','Coarse Anode Angle (Phi) Table',/ZVARIABLE

cdf_varput,fileid,'phi_coarse',use_info_str.phi_coarse


;G Phi

dim_vary = [1]
dim = 16

varid = cdf_varcreate(fileid, varlist[18], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[18],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[18],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','g_phi_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','g_phi_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','g_phi_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','g_phi_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'CATDESC','g_phi_coarse','Coarse Relative Sensitivity Table for Attenuator Open',/ZVARIABLE

cdf_varput,fileid,'g_phi_coarse',use_info_str.geom_coarse


;G Phi Atten

dim_vary = [1]
dim = 16

varid = cdf_varcreate(fileid, varlist[19], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[19],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[19],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e31,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','g_phi_atten_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','g_phi_atten_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','g_phi_atten_coarse',0.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','g_phi_atten_coarse',1.0,/ZVARIABLE
cdf_attput,fileid,'CATDESC','g_phi_atten_coarse','Coarse Relative Sensitivity Table for Attenuator Closed',/ZVARIABLE

cdf_varput,fileid,'g_phi_atten_coarse',use_info_str.geom_coarse_atten


;Deflection Index

dim_vary = [1]
dim = 4

varid = cdf_varcreate(fileid, varlist[20], dim_vary, DIM = dim, /CDF_UINT1, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[20],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[20],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,255B,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','dindex',0B,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','dindex',3B,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','dindex',0B,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','dindex',3B,/ZVARIABLE
cdf_attput,fileid,'CATDESC','dindex','Deflection Index for CDF compatibility',/ZVARIABLE

cdf_varput,fileid,'dindex',indgen(4)


;Phi Label

dim_vary = [1]
dim = 16

varid = cdf_varcreate(fileid, varlist[21], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=3)
cdf_attput,fileid,'FIELDNAM',varid,varlist[21],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'A3',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid," ",/ZVARIABLE
cdf_attput,fileid,'CATDESC','phi_label','Phi Axis Label for CDF compatibility',/ZVARIABLE

labs = 'A'+strcompress(string(indgen(16)),/rem)
len = strlen(labs)
w = where(len lt 3)
if w[0] ne -1 then labs(w) = ' '+labs(w)

cdf_varput,fileid,'phi_label',labs


;Def Label

dim_vary = [1]
dim = 4

varid = cdf_varcreate(fileid, varlist[22], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=2)
cdf_attput,fileid,'FIELDNAM',varid,varlist[22],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'A2',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid," ",/ZVARIABLE
cdf_attput,fileid,'CATDESC','def_label','Deflection Axis Label for CDF compatibility',/ZVARIABLE


cdf_varput,fileid,'def_label','D'+strcompress(string(indgen(4)),/rem)

;Energy Label

dim_vary = [1]
dim = 48

varid = cdf_varcreate(fileid, varlist[23], dim_vary, DIM = dim, /CDF_CHAR, /REC_NOVARY,/ZVARIABLE,numelem=3)
cdf_attput,fileid,'FIELDNAM',varid,varlist[23],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'A3',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid," ",/ZVARIABLE
cdf_attput,fileid,'CATDESC','en_label','Energy Axis Label for CDF compatibility',/ZVARIABLE

labs = 'E'+strcompress(string(indgen(48)),/rem)
len = strlen(labs)
w = where(len lt 3)
if w[0] ne -1 then labs(w) = ' '+labs(w)

cdf_varput,fileid,'en_label',labs


;Number of Distributions

varid = cdf_varcreate(fileid, varlist[24], /CDF_INT2, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[24],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[24],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,fix(-32768),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','num_dists',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','num_dists',21600,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','num_dists',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','num_dists',21600,/ZVARIABLE
cdf_attput,fileid,'CATDESC','num_dists','Number of Coarse Distributions in File',/ZVARIABLE

cdf_varput,fileid,'num_dists',nrec


cdf_close,fileid

end
