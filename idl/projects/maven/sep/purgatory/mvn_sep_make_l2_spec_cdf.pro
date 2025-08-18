;+
;PROCEDURE: 
;	MVN_SEP_MAKE_SPEC_L2_CDF
;PURPOSE: 
;	Routine to produce deconvoluted energetic electron and ion spectra
;AUTHOR: 
;	Robert Lillis (rlillis@ssl.Berkeley.edu)
; Revisions by D Larson
;CALLING SEQUENCE:
;	MVN_SEP_MAKE_L2_CDF, FILE=FILE, /ARCHIVE, DATA_VERSION = DATA_VERSION
;KEYWORDS:
;	FILE: Output file name
;	ARCHIVE: If set, produce a file with archive data rather than survey (default)
;	DATA_VERSION: Data version to put in file (default = '1')
;
; this function assumes the existence of 2 structures: "sep_data" and "sep_info" 
; sep_info should have the following tags:
; 1) ion_energy - an array of 16 (TBR) ion energies 
; 2) electron_energy -an array of 8 (TBR) electron energies
;
; sep_data should be an array of structures and have the following tags:
; 1) time_UNIX
; 2) time_MET
; 3) Delta_t - the number of 1-second accumulations per spectrum
; 4) Atten_State - 1 = open, 0 = closed
; 5) Electron_Energy_Flux - 16 x 4-element array differential energy flux of ions in each look direction
; 6) Ion_Energy_Flux - 8 x 4-element array differential energy flux of electrons in each look direction
; 7) Look_Directions - 4 x 3-element array of unit vectors of each of the four FOVs in Mars-solar-orbital coordinates.


pro mvn_sep_make_l2_spec_cdf, sep_data, sep_info, global_attribute_names = global_attribute_names, $
  global_attribute_values = global_attribute_values, $
;  rawdat_sep1 = rawdat_sep1, rawdat_sep2 = rawdat_sep2, bmaps=bmaps, $
  file = file, archive = archive, data_version = data_version

if not keyword_set(data_version) then data_version = '00'

if not keyword_set(file) then file = 'test.cdf'

nrec = n_elements(sep_data)
n_electron_energy =n_elements (sep_info.electron_energy)
n_ion_energy = n_elements (sep_info.ion_energy)

cdf_leap_second_init

date_range = time_double(['2010-1-1','2030-1-1'])

met_range = [0d, 100d*86400.*365]


;date_range - time_double('2000-01-01/12:00')
epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)


epoch = time_epoch(sep_data.time)
timett2000 = long64((add_tt2000_offset(sep_data.time)-time_double('2000-01-01/12:00'))*1e9)

fileid = cdf_create(file,/single_file,/network_encoding,/clobber)


;FIX ME: make sure the variables associated with raw counts are produced.  Currently they are not.

varlist = strupcase( ['Epoch','Time_TT2000','Time_MET','Time_Unix','Atten_State',$
           'Accumulation_Time', 'Look_Directions', $
           'Electron_Energy_Flux', 'Ion_Energy_Flux','Electron_Energy', 'Ion_Energy'])
nvars = n_elements(varlist)


id0 = cdf_attcreate(fileid,'Title',/global_scope)
id1 = cdf_attcreate(fileid,'Project',/global_scope)
id2 = cdf_attcreate(fileid,'Discipline',/global_scope)
id3 = cdf_attcreate(fileid,'Source_name',/global_scope)
id4 = cdf_attcreate(fileid,'Descriptor',/global_scope)
id5 = cdf_attcreate(fileid,'Data_type',/global_scope)
id6 = cdf_attcreate(fileid,'Data_version',/global_scope)
id7 = cdf_attcreate(fileid,'TEXT',/global_scope)
id8 = cdf_attcreate(fileid,'Mods',/global_scope)
id9 = cdf_attcreate(fileid,'Logical_file_id',/global_scope)
id10 = cdf_attcreate(fileid,'Logical_source',/global_scope)
id11 = cdf_attcreate(fileid,'Logical_source_description',/global_scope)
id12 = cdf_attcreate(fileid,'PI_name',/global_scope)
id13 = cdf_attcreate(fileid,'PI_affiliation',/global_scope)
id14 = cdf_attcreate(fileid,'Instrument_type',/global_scope)
id15 = cdf_attcreate(fileid,'Mission_group',/global_scope)
id16 = cdf_attcreate(fileid,'Parents',/global_scope)


cdf_attput,fileid,'Title',0,'MAVEN SEP Electron and Ion spectra'
cdf_attput,fileid,'Project',0,'MAVEN'
cdf_attput,fileid,'Discipline',0,'Planetary Space Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SEP>Solar Energetic Particle Experiment'
cdf_attput,fileid,'Data_type',0,'CAL>Calibrated'
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,'MAVEN SEP electron and ion spectra'
cdf_attput,fileid,'Mods',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,file
cdf_attput,fileid,'Logical_source',0,'SEP.calibrated.spec_svy'
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SEP (Solar Energetic Particle) electron and ion spectra in 4 look directions'
     
cdf_attput,fileid,'PI_name',0,'Davin Larson (davin@ssl.berkeley.edu)'
cdf_attput,fileid,'PI_affiliation',0,'U.C. Berkeley Space Sciences Laboratory'
cdf_attput,fileid,'Instrument_type',0,'Energetic Particle Detector'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
cdf_attput,fileid,'Parents',0,'None'

dummy = cdf_attcreate(fileid,'FIELDNAM',/variable_scope)
dummy = cdf_attcreate(fileid,'MONOTON',/variable_scope)
dummy = cdf_attcreate(fileid,'FORMAT',/variable_scope)
dummy = cdf_attcreate(fileid,'FORM_PTR',/variable_scope)
dummy = cdf_attcreate(fileid,'LABLAXIS',/variable_scope)
dummy = cdf_attcreate(fileid,'VAR_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'FILLVAL',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_0',/variable_scope)
dummy = cdf_attcreate(fileid,'DISPLAY_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)
dummy = cdf_attcreate(fileid,'CATDESC',/variable_scope)


;Epoch

varid = cdf_varcreate(fileid, varlist[0], /CDF_EPOCH, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[0],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.16',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[0],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,0.0,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Epoch',epoch_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Epoch',epoch_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Epoch',epoch[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Epoch',epoch[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS','Epoch','ms',/ZVARIABLE
cdf_attput,fileid,'MONOTON','Epoch','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Epoch','Time, middle of sample, in NSSDC Epoch',/ZVARIABLE

cdf_varput,fileid,'Epoch',epoch


;TT2000

varid = cdf_varcreate(fileid, varlist[1], /CDF_TIME_TT2000, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[1],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I22',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[1],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-9223372036854775807,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Time_TT2000',tt2000_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Time_TT2000',tt2000_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Time_TT2000',timett2000[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Time_TT2000',timett2000[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS','Time_TT2000','ns',/ZVARIABLE
cdf_attput,fileid,'MONOTON','Time_TT2000','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Time_TT2000','Time, middle of sample, in TT2000 time base',/ZVARIABLE

cdf_varput,fileid,'Time_TT2000',timett2000


;MET

varid = cdf_varcreate(fileid, varlist[2], /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[2],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[2],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Time_MET',met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Time_MET',met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Time_MET',sep_data[0].met,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Time_MET',sep_data[nrec-1].met,/ZVARIABLE
cdf_attput,fileid,'UNITS','Time_MET','s',/ZVARIABLE
cdf_attput,fileid,'MONOTON','Time_MET','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Time_MET','Time, middle of sample, in raw mission elapsed time',/ZVARIABLE

cdf_varput,fileid,'Time_MET',sep_data.met


;Unix Time

varid = cdf_varcreate(fileid, varlist[3], /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[3],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[3],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Time_Unix',date_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Time_Unix',date_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Time_Unix',sep_data[0].time,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Time_Unix',sep_data[nrec-1].time,/ZVARIABLE
cdf_attput,fileid,'UNITS','Time_Unix','s',/ZVARIABLE
cdf_attput,fileid,'MONOTON','Time_Unix','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Time_Unix','Time, middle of sample, in Unix time',/ZVARIABLE

cdf_varput,fileid,'Time_Unix',sep_data.time


;Attenuator State
dim_vary = [1]
dim = 4
varid = cdf_varcreate(fileid, varlist[4],dim_vary, DIM = dim,/CDF_INT1, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[4],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[4],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-127,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Atten_State',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Atten_State',2,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Atten_State',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Atten_State',2,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Atten_State','Attenuator state for each of the four look directions, 1 = open, 0 = closed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Atten_State','Epoch',/ZVARIABLE

cdf_varput,fileid,'Atten_State',sep_data.atten_state

; Accumulation Time
varid = cdf_varcreate(fileid, varlist[5], /CDF_INT2, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[5],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-127,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Accumulation_Time',1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Accumulation_Time',8192,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Accumulation_Time',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Accumulation_Time',8192,/ZVARIABLE
cdf_attput,fileid,'CATDESC','Accumulation_Time','Number of 1-second accumulations contained within this data sample.',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Accumulation_Time','Epoch',/ZVARIABLE

cdf_varput,fileid,'Accumulation_Time',sep_data.delta_time


;Look directions. Comment out for now.

dim_vary = [1,1]  
dim = [4,3]  
varid = cdf_varcreate(fileid, varlist[6],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[6],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Look_Directions',-1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Look_Directions',1,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Look_Directions',-1,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Look_Directions',1,/ZVARIABLE
cdf_attput,fileid,'UNITS','Look_Directions','Unit vector, MSO',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Look_Directions','Geometric center of each of the 4 fields of view of the SEP sensors',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Look_Directions','Epoch',/ZVARIABLE

;cdf_varput,fileid,'Look_Directions',sep_data.Look_Directions


; Electron Energy Flux

dim_vary = [1,1]  
dim = [4, n_electron_energy]  
varid = cdf_varcreate(fileid, varlist[7],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[7],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Electron_Energy_Flux',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Electron_Energy_Flux',1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Electron_Energy_Flux',1e-2,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Electron_Energy_Flux',1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS','Electron_Energy_Flux','keV/(cm^2 second steradian keV)',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Electron_Energy_Flux','Electron differential energy flux in each of the four look directions',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Electron_Energy_Flux','Epoch',/ZVARIABLE

cdf_varput,fileid,'Electron_Energy_Flux',sep_data.electron_energy_flux

; Ion Energy Flux

dim_vary = [1,1]  
dim = [4, n_ion_energy]  
varid = cdf_varcreate(fileid, varlist[8],dim_vary, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[8],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Ion_Energy_Flux',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Ion_Energy_Flux',1e10,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Ion_Energy_Flux',1e-2,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Ion_Energy_Flux',1e5,/ZVARIABLE
cdf_attput,fileid,'UNITS','Ion_Energy_Flux','keV/(cm^2 second steradian keV)',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Ion_Energy_Flux','Ion differential energy flux in each of the four look directions',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0','Ion_Energy_Flux','Epoch',/ZVARIABLE

cdf_varput,fileid,'Ion_Energy_Flux',sep_data.ion_energy_flux

;Electron Energy

dim_vary = [1]
dim = n_electron_energy

varid = cdf_varcreate(fileid, varlist[9], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[9],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Electron_Energy',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Electron_Energy',2e4,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Electron_Energy',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Electron_Energy',1e3,/ZVARIABLE
cdf_attput,fileid,'UNITS','Electron_Energy','keV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Electron_Energy','Electron energy table',/ZVARIABLE

cdf_varput,fileid,'Electron_Energy',sep_info.electron_energy

;Ion Energy

dim_vary = [1]
dim = n_ion_energy

varid = cdf_varcreate(fileid, varlist[10], dim_vary, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varlist[10],/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-1.0e30,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','Ion_Energy',0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','Ion_Energy',5e4,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','Ion_Energy',0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','Ion_Energy',2e4,/ZVARIABLE
cdf_attput,fileid,'UNITS','Ion_Energy','keV',/ZVARIABLE
cdf_attput,fileid,'CATDESC','Ion_Energy','Ion energy table',/ZVARIABLE

cdf_varput,fileid,'Ion_Energy',sep_info.ion_energy




cdf_close,fileid

end
