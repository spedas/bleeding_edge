obsolete




pro mvn_sep_make_cal_cdf, data_vary, data_novary,filename = filename,dependencies=dependencies,global=global,add_link=add_link

time = data_vary.time
time_name = 'time_unix'
epoch_name = 'epoch'

nrec = n_elements(data_vary)

extra = mvn_sep_sw_version()

if not keyword_set(data_version) then data_version = extra

if 0 then begin
  tr = minmax(time)
  dprint,time_string(tr)
  days = round( tr /86400)
  ndays = days[1]-days[0]
  tr = days * 86400d  
endif

ver_str = extra.sw_version

cdf_leap_second_init

date_range = time_double(['2010-1-1','2030-1-1'])
met_range = [0d, 30d*86400.*365]

epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)


epoch = time_epoch(time)
timett2000 = long64((add_tt2000_offset(time)-time_double('2000-01-01/12:00'))*1e9)

tstr= time_string(minmax(time),tformat='YYYY-MM-DDThh:mm:ss.fffZ')


file_mkdir2,file_dirname(filename),add_link = add_link
fileid = cdf_create(filename,/single_file,/network_encoding,/clobber)

id0 = cdf_attcreate(fileid,'Acknowledgement',/global_scope)
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
id11 = cdf_attcreate(fileid,'Sensor',/global_scope)
id12 = cdf_attcreate(fileid,'PI_name',/global_scope)
id13 = cdf_attcreate(fileid,'PI_affiliation',/global_scope)
id14 = cdf_attcreate(fileid,'Instrument_type',/global_scope)
id15 = cdf_attcreate(fileid,'Mission_group',/global_scope)
id16 = cdf_attcreate(fileid,'Parents',/global_scope)
id16 = cdf_attcreate(fileid,'Planet',/global_scope)
id17 = cdf_attcreate(fileid,'PDS_collection_id',/global_scope)
id17 = cdf_attcreate(fileid,'PDS_start_time',/global_scope)
id17 = cdf_attcreate(fileid,'PDS_stop_time',/global_scope)


if keyword_set(extra) then exnames = tag_names(extra)
for i=0,n_elements(exnames)-1 do  idxx = cdf_attcreate(fileid,exnames[i],/global_scope)


;Load global Attributes

cdf_attput,fileid,'TITLE',0,'MAVEN SEP Electron and Ion Flux'
cdf_attput,fileid,'Project',0,'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
;cdf_attput,fileid,'Discipline',0,'Planetary Space Physics>Particles'
cdf_attput,fileid,'Discipline',0,'Planetary Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SEP>Solar Energetic Particle Experiment'
cdf_attput,fileid,'Data_type',0,global.data_type
cdf_attput,fileid,'Data_version',0,ver_str
cdf_attput,fileid,'TEXT',0,'MAVEN SEP electron and ion Flux'
cdf_attput,fileid,'MODS',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,global.filename
cdf_attput,fileid,'Logical_source',0,global.logical_source  
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SEP (Solar Energetic Particle) Instrument'
cdf_attput,fileid,'Sensor',0,global.sensor
cdf_attput,fileid,'PI_name',0,'D. Larson (davin@ssl.berkeley.edu)'
cdf_attput,fileid,'PI_affiliation',0,'U.C. Berkeley Space Sciences Laboratory'
cdf_attput,fileid,'Instrument_type',0,'Energetic Particle Detector'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
cdf_attput,fileid,'Planet',0,'Mars'
cdf_attput,fileid,'PDS_start_time',0,tstr[0]
cdf_attput,fileid,'PDS_stop_time',0,tstr[1]
cdf_attput,fileid,'PDS_collection_id',0,'MAVEN'
for i=0,n_elements(dependencies)-1 do    cdf_attput,fileid,'Parents',i,  file_checksum(dependencies[i],/add_mtime)
for i=0,n_elements(exnames)-1 do     cdf_attput,fileid,exnames[i],0,extra.(i)



; Variable attributes

default_atts = {fieldnam:'',monoton:'',format:'E10.2',lablaxis:'',VAR_TYPE:'support_data',display_type:'time_series',fillval:!values.f_nan,scaletyp:'linear', $
      VALIDMIN:-1e31,VALIDMAX:1e31,SCALEMIN:0.,SCALEMAX:100.,UNITS:'',CATDESC:'', $
      FORM_PTR:'',DEPEND_TIME:time_name,DEPEND_0:epoch_name,DEPEND_1:'',DEPEND_2:'',LABL_PTR_1:'' }

tags=tag_names(default_atts)
for i=0,n_elements(tags)-1 do dummy=cdf_attcreate(fileid,tags[i],/variable_scope)


;Unix Time
varid = cdf_varcreate(fileid, time_name, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,time_name,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F15.3',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,'Time (UTC)',/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,date_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,date_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,0.d,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,1d10,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'sec',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in Unix time',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE
cdf_varput,fileid,time_name,time



;Epoch

;TT2000

varname = 'epoch'
varid = cdf_varcreate(fileid, varname, /CDF_TIME_TT2000, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'E25.18',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,-9223372036854775808,/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,tt2000_range[0],/ZVARIABLE, /CDF_EPOCH
cdf_attput,fileid,'VALIDMAX',varid,tt2000_range[1],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'SCALEMIN',varid,timett2000[0],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'SCALEMAX',varid,timett2000[nrec-1],/ZVARIABLE,/CDF_EPOCH
cdf_attput,fileid,'UNITS',varid,'ns',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in TT2000 time base',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE

cdf_varput,fileid,varname,timett2000

;MET
varname = 'time_met'
varid = cdf_varcreate(fileid, varname, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,data_vary[0].met,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,data_vary[nrec-1].met,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'s',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Time, middle of sample, in raw mission elapsed time',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE


cdf_varput,fileid,varname,data_vary.met



;Ephemeris time
varname = 'time_ephemeris'
varid = cdf_varcreate(fileid, varname, /CDF_DOUBLE, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'F25.6',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,!values.d_nan,/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,met_range[0],/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,met_range[1],/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,data_vary[0].met,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,data_vary[nrec-1].met,/ZVARIABLE
cdf_attput,fileid,'UNITS',varid,'s',/ZVARIABLE
cdf_attput,fileid,'MONOTON',varid,'INCREASE',/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Ephermeris Time, middle of sample, compatible with spice',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE


str_element,data_vary,'time_ephemeris',et
str_element,data_vary,'et',et
if ~keyword_set(et) then et = time_ephemeris(data_vary.time)
cdf_varput,fileid,varname,et



;Attenuator State
;dim_vary = [1]
;dim = 1
varname = 'attenuator_state'
varid = cdf_varcreate(fileid, varname,/CDF_UINT2, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,uint(-1),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,1u,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,2u,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,0u,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,3u,/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Attenuator state, 0=Error,  1 = open, 2 = closed,   3= mixed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE
cdf_varput,fileid,varname,uint(data_vary.att)



varname = 'accum_time'
atts = default_atts
str_element,/add,atts,'FILLVAL',uint(-1)
str_element,/add,atts,'VALIDMIN',0u
str_element,/add,atts,'VALIDMAX',128u
str_element,/add,atts,'SCALEMIN',0u
str_element,/add,atts,'SCALEMAX',128u
str_element,/add,atts,'FORMAT','I6'
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Number of 1-second accumulations contained within this data sample.'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.duration,attributes=atts



varname = 'mapid'
atts = default_atts
str_element,/add,atts,'FILLVAL',uint(-1)
str_element,/add,atts,'VALIDMIN',0u
str_element,/add,atts,'VALIDMAX',128u
str_element,/add,atts,'SCALEMIN',0u
str_element,/add,atts,'SCALEMAX',128u
str_element,/add,atts,'FORMAT','I6'
atts.var_type ='support_data'
atts.fieldnam = varname
atts.lablaxis = varname
atts.catdesc = 'Binning Map ID number'
mvn_sep_cdf_var_att_create,fileid,varname,uint(data_vary.mapid),attributes=atts

varname = 'seq_cntr'
atts = default_atts
atts.var_type ='support_data'
str_element,/add,atts,'FILLVAL',uint(-1)
str_element,/add,atts,'VALIDMIN',0u
str_element,/add,atts,'VALIDMAX',2U^14
str_element,/add,atts,'SCALEMIN',0u
str_element,/add,atts,'SCALEMAX',2u^14
str_element,/add,atts,'FORMAT','I6'
atts.fieldnam = varname
atts.lablaxis = varname
atts.catdesc = 'CCSDS Sequence Counter'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.seq_cntr,attributes=atts

;varname = 'Raw_counts'
;atts = default_atts
;atts.fieldnam = varname
;atts.lablaxis = varname
;atts.var_type ='data'
;atts.catdesc = 'Raw Counts in each accumulation bin'
;mvn_sep_cdf_var_att_create,fileid,varname,data_vary.data,attributes=atts

varname = 'f_ion_flux'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
atts.catdesc = 'Ion Flux in Forward look direction (#/cm^2/sec/ster/keV)'
atts.depend_1 = 'f_ion_energy'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ION_FLUX,attributes=atts

varname = 'f_ion_flux_unc'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Ion Flux Uncertainty (#/cm^2/sec/ster/keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ION_FLUX_UNC,attributes=atts

varname = 'f_ion_flux_tot'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
atts.catdesc = 'Total Ion Flux in Forward look direction (#/cm^2/sec/ster)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ION_FLUX_TOT,attributes=atts

varname = 'f_ion_flux_tot_unc'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Total Ion Flux Uncertainty (#/cm^2/sec/ster)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ION_FLUX_TOT_UNC,attributes=atts

varname = 'f_ion_energy'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Ion Energy (keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ION_ENERGY,attributes=atts

varname = 'f_ion_denergy'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Ion Energy channel width (keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ION_DENERGY,attributes=atts

varname = 'f_elec_flux'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
atts.catdesc = 'Electron Flux in Forward look direction (#/cm^2/sec/ster/keV)'
atts.depend_1 = 'f_elec_energy'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ELEC_FLUX,attributes=atts

varname = 'f_elec_flux_unc'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Electron Flux Uncertainty (#/cm^2/sec/ster/keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ELEC_FLUX_UNC,attributes=atts


varname = 'f_elec_flux_tot'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
atts.catdesc = 'Integrated Electron Flux in Forward look direction (#/cm^2/ster/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ELEC_FLUX_TOT,attributes=atts

varname = 'f_elec_flux_tot_unc'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Integrated Electron Flux Uncertainty (#/cm^2/sec/ster)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ELEC_FLUX_TOT_UNC,attributes=atts

varname = 'f_elec_energy'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Electron Energy (keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ELEC_ENERGY,attributes=atts

varname = 'f_elec_denergy'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Electron Energy channel width (keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.F_ELEC_DENERGY,attributes=atts



varname = 'r_ion_flux'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
atts.catdesc = 'Ion Flux in Rear look direction (#/cm^2/sec/ster/keV)'
atts.depend_1 = 'r_ion_energy'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ION_FLUX,attributes=atts

varname = 'r_ion_flux_unc'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Ion Flux Uncertainty (#/cm^2/sec/ster/keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ION_FLUX_UNC,attributes=atts


varname = 'r_ion_flux_tot'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
atts.catdesc = 'Integrated Ion Flux in Rear look direction (#/cm^2/sec/ster/keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ION_FLUX_TOT,attributes=atts

varname = 'r_ion_flux_tot_unc'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Integrated Ion Flux Uncertainty (#/cm^2/sec/ster/keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ION_FLUX_TOT_UNC,attributes=atts

varname = 'r_ion_energy'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Ion Energy (keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ION_ENERGY,attributes=atts

varname = 'r_ion_denergy'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Ion Energy channel width (keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ION_DENERGY,attributes=atts

varname = 'r_elec_flux'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
atts.catdesc = 'Electron Flux in Rear look direction (#/cm^2/sec/ster/keV)'
atts.depend_1 = 'r_elec_energy'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ELEC_FLUX,attributes=atts

varname = 'r_elec_flux_unc'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Electron Flux Uncertainty (#/cm^2/sec/ster/keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ELEC_FLUX_UNC,attributes=atts

varname = 'r_elec_flux_tot'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
atts.catdesc = 'Integrated Electron Flux in Rear look direction (#/cm^2/sec/ster/keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ELEC_FLUX_TOT,attributes=atts

varname = 'r_elec_flux_tot_unc'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Integrated Electron Flux Uncertainty (#/cm^2/sec/ster/keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ELEC_FLUX_TOT_UNC,attributes=atts

varname = 'r_elec_energy'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Electron Energy (keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ELEC_ENERGY,attributes=atts

varname = 'r_elec_denergy'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Electron Energy channel width (keV)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.R_ELEC_DENERGY,attributes=atts


varname = 'a_t_rates'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Count Rate in THICK detectors of A Stack (#/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.A_T_RATE,attributes=atts

varname = 'b_t_rates'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Count Rate in THICK detectors of B Stack (#/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.B_T_RATE,attributes=atts


varname = 'a_fto_rates'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Count Rate of triple coincidence in A Stack (#/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.A_FTO_RATE,attributes=atts

varname = 'b_fto_rates'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Count Rate in triple coincidence in B Stack (#/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.B_FTO_RATE,attributes=atts


varname = 'f_o_rate'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Total Count Rate in Forward Open detector (#/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.f_o_rate,attributes=atts

varname = 'f_f_rate'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Total Count Rate in Forward Foil detector (#/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.f_f_rate,attributes=atts

varname = 'r_o_rate'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Total Count Rate in Rear Open detector (#/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.r_o_rate,attributes=atts

varname = 'r_f_rate'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Total Count Rate in Rear Foil detector (#/sec)'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.r_f_rate,attributes=atts




varname = 'quality_flag'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='support_data'
atts.catdesc = 'Quality FLAG'
defval = 0UL
str_element,/add,atts,'FILLVAL',defval-1
str_element,/add,atts,'VALIDMIN',defval
str_element,/add,atts,'VALIDMAX',2UL ^ 10
str_element,/add,atts,'SCALEMIN',0u
str_element,/add,atts,'SCALEMAX',2uL ^ 10
str_element,/add,atts,'FORMAT','I10'

mvn_sep_cdf_var_att_create,fileid,varname,data_vary.QUALITY_FLAG,attributes=atts


cdf_close,fileid
dprint,dlevel=2,'Created: "'+filename+'"'

end
