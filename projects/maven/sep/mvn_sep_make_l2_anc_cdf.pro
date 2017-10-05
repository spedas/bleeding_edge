
;+
;NAME: MVN_SEP_SW_VERSION
;Function: mvn_spice_kernels(name)
;PURPOSE:
; Acts as a timestamp file to trigger the regeneration of SEP data products. Also provides Software Version info for the MAVEN SEP instrument.  
;Author: Davin Larson  - January 2014
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-12-11 09:08:45 -0800 (Thu, 11 Dec 2014) $
; $LastChangedRevision: 16452 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_make_l2_anc_cdf.pro $
;-
function mvn_sep_anc_sw_version

tb = scope_traceback(/structure)
this_file = tb[n_elements(tb)-1].filename   
this_file_date = (file_info(this_file)).mtime

sw_structure = {  $
  sw_version : 'v01' , $
  sw_time_stamp_file : this_file , $
  sw_time_stamp : time_string(this_file_date) , $
  sw_runtime : time_string(systime(1))  , $
  sw_runby :  getenv('LOGNAME') , $
  svn_changedby : '$LastChangedBy: davin-mac $' , $
  svn_changedate: '$LastChangedDate: 2014-12-11 09:08:45 -0800 (Thu, 11 Dec 2014) $' , $
  svn_revision : '$LastChangedRevision: 16452 $' }
return,sw_structure
end





;
;
;
;+
;PROCEDURE: 
;	MVN_SEP_MAKE_L2_ANC_CDF
;PURPOSE: 
;	Routine to produce ancillary and ephemeris data files
;AUTHOR: 
;	Robert Lillis (rlillis@ssl.Berkeley.edu)
;CALLING SEQUENCE:
;	MVN_SEP_MAKE_L2_ANC_CDF, 
;KEYWORDS:
;	FILE: Output file name
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2014-12-11 09:08:45 -0800 (Thu, 11 Dec 2014) $
; $LastChangedRevision: 16452 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_make_l2_anc_cdf.pro $


pro mvn_sep_make_l2_anc_cdf, sep_ancillary,dependencies=dependencies, file = file, data_version = data_version

;  global_attribute_names = global_attribute_names,  global_attribute_values = global_attribute_values

if not keyword_set(data_version) then data_version = '1'
if not keyword_set(dependencies) then dependencies = 'None'

if not keyword_set(file) then file = 'test.cdf'

cdf_leap_second_init

date_range = time_double(['2013-11-18/00:00','2030-12-31/23:59'])

met_range = [0, 100.0d*86400.0*365]

met = mvn_spc_unixtime_to_met(SEP_ancillary.time_UNIX,correct_clockdrift=1)

;date_range - time_double('2000-01-01/12:00')
epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)


epoch = time_epoch(sep_ancillary.time_UNIX)
timett2000 = long64((add_tt2000_offset(sep_ancillary.time_UNIX)-time_double('2000-01-01/12:00'))*1e9)

fileid = cdf_create(file,/single_file,/network_encoding,/clobber)

nrec = n_elements (SEP_ancillary.time_UNIX)

varlist = ['TIME_UNIX', 'EPOCH','TIME_TT2000', 'TIME_MET', 'TIME_EPHEMERIS','LOOK_DIRECTIONS_MSO', $
           'LOOK_DIRECTIONS_SSO', 'LOOK_DIRECTIONS_GEO', 'VECTOR_COMPONENT_NUM', 'FOV_NUM']

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
idxx = cdf_attcreate(fileid,'Parents',/global_scope)
extra = mvn_sep_anc_sw_version()
if keyword_set(extra) then exnames = tag_names(extra)
for i=0,n_elements(exnames)-1 do  idxx = cdf_attcreate(fileid,exnames[i],/global_scope)


cdf_attput,fileid,'Title',0,'MAVEN SEP Ancillary and Ephemeris Data'
cdf_attput,fileid,'Project',0,'MAVEN'
cdf_attput,fileid,'Discipline',0,'Planetary Space Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SEP>Solar Energetic Particle Experiment'
cdf_attput,fileid,'Data_type',0,'Support data'
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,'MAVEN SEP ancillary and ephemeris data'
cdf_attput,fileid,'Mods',0,'None'
cdf_attput,fileid,'Logical_file_id',0,file
cdf_attput,fileid,'Logical_source',0,'SEP.ancillary'
cdf_attput,fileid,'Logical_source_description',0,'SEP ancillary and ephemeris data'
     
cdf_attput,fileid,'PI_name',0,'Davin Larson (davin@ssl.berkeley.edu)'
cdf_attput,fileid,'PI_affiliation',0,'U.C. Berkeley Space Sciences Laboratory'
cdf_attput,fileid,'Instrument_type',0,'Energetic Particle Detector'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
for i=0,n_elements(dependencies)-1 do begin
   str = file_checksum(dependencies[i],/add_mtime)
   cdf_attput,fileid,'Parents',i,str[0]
endfor

for  i=0,n_elements(exnames)-1 do cdf_attput,fileid,exnames[i],0,extra.(i)



;Variable Attributes

dummy = cdf_attcreate(fileid,'FIELDNAM',/variable_scope)
dummy = cdf_attcreate(fileid,'MONOTON',/variable_scope)
dummy = cdf_attcreate(fileid,'FORMAT',/variable_scope)
dummy = cdf_attcreate(fileid,'FORM_PTR',/variable_scope)
dummy = cdf_attcreate(fileid,'LABLAXIS',/variable_scope)
dummy = cdf_attcreate(fileid,'VAR_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'FILLVAL',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_0',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_1',/variable_scope)
dummy = cdf_attcreate(fileid,'DEPEND_2',/variable_scope)
dummy = cdf_attcreate(fileid,'DISPLAY_TYPE',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'VALIDMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMIN',/variable_scope)
dummy = cdf_attcreate(fileid,'SCALEMAX',/variable_scope)
dummy = cdf_attcreate(fileid,'UNITS',/variable_scope)
dummy = cdf_attcreate(fileid,'CATDESC',/variable_scope)


;Unix Time

name = 'TIME_UNIX'
varid = cdf_varcreate(fileid, name, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,sqrt(-7.3),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','TIME_UNIX',date_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','TIME_UNIX',date_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','TIME_UNIX',sep_ancillary[0].time_UNIX,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','TIME_UNIX',sep_ancillary[nrec-1].time_UNIX,/ZVARIABLE
cdf_attput,fileid,'UNITS','TIME_UNIX','s',/ZVARIABLE
cdf_attput,fileid,'MONOTON','TIME_UNIX','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','TIME_UNIX','Time, middle of sample, in Unix time',/ZVARIABLE

cdf_varput,fileid,'TIME_UNIX',sep_ancillary.time_UNIX


;EPOCH

name = 'EPOCH'
varid = cdf_varcreate(fileid, name, /CDF_EPOCH, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN','EPOCH',epoch_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','EPOCH',epoch_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','EPOCH',epoch[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','EPOCH',epoch[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS','EPOCH','ms',/ZVARIABLE
cdf_attput,fileid,'MONOTON','EPOCH','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','EPOCH','Time, middle of sample, in NSSDC EPOCH',/ZVARIABLE

cdf_varput,fileid,'EPOCH',epoch


;TT2000
name ='TIME_TT2000'
varid = cdf_varcreate(fileid, name, /CDF_TIME_TT2000, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I22',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-9223372036854775807,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,tt2000_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX','TIME_TT2000',tt2000_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN','TIME_TT2000',timett2000[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX','TIME_TT2000',timett2000[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS','TIME_TT2000','ns',/ZVARIABLE
cdf_attput,fileid,'MONOTON','TIME_TT2000','INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC','TIME_TT2000','Time, middle of sample, in TT2000 time base',/ZVARIABLE

cdf_varput,fileid,'TIME_TT2000',timett2000


;MET
name = 'TIME_MET'
varid = cdf_varcreate(fileid, name, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,sqrt(-7.3),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,met[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,met[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'s',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in raw mission elapsed time',/ZVARIABLE

cdf_varput,fileid,name,met

;Ephemeris time
name = 'TIME_EPH'
varid = cdf_varcreate(fileid, name, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,sqrt(-7.3),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',name,met[0],/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',name,met[nrec-1],/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'s',/ZVARIABLE
cdf_attput,fileid,'MONOTON',name,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'Time, middle of sample, in ephemeris time (used by SPICE)',/ZVARIABLE

cdf_varput,fileid,name,SEP_ancillary.time_ephemeris


;Look directions. 

dim_vary = [1,1]  
dim = [4,3]  
name = 'LOOK_DIRECTIONS_MSO'
varid = cdf_varcreate(fileid, name,dim_vary, /CDF_FLOAT, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F8.4',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,'FOV_MSO',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,-1.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',name,-1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',name,1.0,/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'Unit vector',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'Geometric center of each of the 4 fields of view of the SEP sensors in Mars-solar-orbital coordinates',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',name,'EPOCH',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1',name,'FOV_NUM',/ZVARIABLE
cdf_attput,fileid,'DEPEND_2',name,'VECTOR_COMPONENT_NUM',/ZVARIABLE

cdf_varput,fileid,name,sep_ancillary.LOOK_DIRECTIONS_MSO

name = 'LOOK_DIRECTIONS_SSO'
varid = cdf_varcreate(fileid, name,dim_vary, /CDF_FLOAT, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F8.4',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,'FOV_SSO',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,-1.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',name,-1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',name,1.0,/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'Unit vector',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'Geometric center of each of the 4 fields of view of the SEP sensors in Spacecraft-solar-orbital coordinates',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',name,'EPOCH',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1',name,'FOV_NUM',/ZVARIABLE
cdf_attput,fileid,'DEPEND_2',name,'VECTOR_COMPONENT_NUM',/ZVARIABLE

cdf_varput,fileid,name,sep_ancillary.LOOK_DIRECTIONS_SSO

name = 'LOOK_DIRECTIONS_GEO'
varid = cdf_varcreate(fileid, name,dim_vary, /CDF_FLOAT, DIM = dim, /REC_VARY,/ZVARIABLE) 
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F8.4',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,'FOV_GEO',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,-1.0,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',name,-1.0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',name,1.0,/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'Unit vector',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'Geometric center of each of the 4 fields of view of the SEP sensors in planet-fixed IAU Mars coordinates',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',name,'EPOCH',/ZVARIABLE
cdf_attput,fileid,'DEPEND_1',name,'FOV_NUM',/ZVARIABLE
cdf_attput,fileid,'DEPEND_2',name,'VECTOR_COMPONENT_NUM',/ZVARIABLE

cdf_varput,fileid,name,sep_ancillary.LOOK_DIRECTIONS_GEO


; we require the no-vary vector number, i.e. 1 to 3
dim_vary = [1]
dim = 3
name = 'VECTOR_COMPONENT_NUM'
varid = cdf_varcreate(fileid, name, dim_vary, /CDF_UINT1, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'i2',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-243657,/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,3,/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'N/A',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'XYZ Look Direction vector component number',/ZVARIABLE

cdf_varput,fileid,name,[1,2,3]

; also require the no-vary FOV number, i.e. 1 to 4
dim_vary = [1]
dim = 4
name = 'FOV_NUM'
varid = cdf_varcreate(fileid, name, dim_vary, /CDF_UINT1, DIM = dim, /REC_NOVARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'i2',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,name,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'metadata',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-243657,/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',name,1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',name,4,/ZVARIABLE
cdf_attput,fileid,'UNITS',name,'N/A',/ZVARIABLE
cdf_attput,fileid,'CATDESC',name,'Field of view number',/ZVARIABLE

cdf_varput,fileid,name,[1,2,3,4]


cdf_close,fileid

end
