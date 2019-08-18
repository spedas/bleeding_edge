obsolete




pro mvn_sep_make_raw_cdf, data_vary, data_novary,filename = filename,dependencies=dependencies,global=global,add_link=add_link

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

cdf_attput,fileid,'TITLE',0,'MAVEN SEP Electron and Ion Raw Counts'
cdf_attput,fileid,'Project',0,'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
;cdf_attput,fileid,'Discipline',0,'Planetary Space Physics>Particles'
cdf_attput,fileid,'Discipline',0,'Planetary Physics>Particles'
cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
cdf_attput,fileid,'Descriptor',0,'SEP>Solar Energetic Particle Experiment'
cdf_attput,fileid,'Data_type',0,global.data_type
cdf_attput,fileid,'Data_version',0,ver_str
cdf_attput,fileid,'TEXT',0,'MAVEN SEP electron and ion raw counts'
cdf_attput,fileid,'MODS',0,'Revision 0'
cdf_attput,fileid,'Logical_file_id',0,global.filename
cdf_attput,fileid,'Logical_source',0,global.logical_source  
cdf_attput,fileid,'Logical_source_description',0,'DERIVED FROM: MAVEN SEP (Solar Energetic Particle) Instrument'
cdf_attput,fileid,'Sensor',0,global.sensor
cdf_attput,fileid,'PI_name',0,'D. Larson (davin@ssl.berkeley.edu)'
cdf_attput,fileid,'PI_affiliation',0,'U.C. Berkeley Space Sciences Laboratory'
cdf_attput,fileid,'Instrument_type',0,'Particles (space)'
cdf_attput,fileid,'Mission_group',0,'MAVEN'
cdf_attput,fileid,'Planet',0,'Mars'
cdf_attput,fileid,'PDS_start_time',0,tstr[0]
cdf_attput,fileid,'PDS_stop_time',0,tstr[1]
cdf_attput,fileid,'PDS_collection_id',0,'MAVEN'
for i=0,n_elements(dependencies)-1 do    cdf_attput,fileid,'Parents',i,  file_checksum(dependencies[i],/add_mtime)
for i=0,n_elements(exnames)-1 do     cdf_attput,fileid,exnames[i],0,extra.(i)



; Variable attributes

default_atts = {fieldnam:'',monoton:'',format:'F10.2',lablaxis:'',VAR_TYPE:'support_data',DISPLAY_TYPE:'time_series',fillval:!values.f_nan,scaletyp:'linear', $
      VALIDMIN:-1e31,VALIDMAX:1e31,SCALEMIN:0.,SCALEMAX:100.,UNITS:'',CATDESC:'', $
      FORM_PTR:'',DEPEND_TIME:time_name,DEPEND_0:epoch_name,DEPEND_1:'',DEPEND_2:'' }

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
;cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE
cdf_varput,fileid,time_name,time



;Epoch
;TT2000

varname = 'epoch'
varid = cdf_varcreate(fileid, varname, /CDF_TIME_TT2000, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I22',/ZVARIABLE
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
cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE

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
cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE

str_element,data_vary,'time_ephemeris',et
str_element,data_vary,'et',et
if ~keyword_set(et) then et = time_ephemeris(data_vary.time)
cdf_varput,fileid,varname,et



;Attenuator State
;dim_vary = [1]
;dim = 1
varname = 'attenuator_state'
varid = cdf_varcreate(fileid, varname,/CDF_INT2, /REC_VARY,/ZVARIABLE)
cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
cdf_attput,fileid,'VAR_TYPE',varid,'data',/ZVARIABLE
cdf_attput,fileid,'FILLVAL',varid,fix(-32768),/ZVARIABLE
cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
cdf_attput,fileid,'VALIDMIN',varid,1,/ZVARIABLE
cdf_attput,fileid,'VALIDMAX',varid,2,/ZVARIABLE
cdf_attput,fileid,'SCALEMIN',varid,0,/ZVARIABLE
cdf_attput,fileid,'SCALEMAX',varid,3,/ZVARIABLE
cdf_attput,fileid,'CATDESC',varid,'Attenuator state, 0=Error,  1 = open, 2 = closed,   3= mixed',/ZVARIABLE
cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE
cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE
cdf_varput,fileid,varname,data_vary.att

if 0 then begin
  ; Accumulation Time
  varname = 'accum_time'
  varid = cdf_varcreate(fileid, varname, /CDF_INT2, /REC_VARY,/ZVARIABLE)
  cdf_attput,fileid,'FIELDNAM',varid,varname,/ZVARIABLE
  cdf_attput,fileid,'FORMAT',varid,'I7',/ZVARIABLE
  cdf_attput,fileid,'LABLAXIS',varid,varname,/ZVARIABLE
  cdf_attput,fileid,'VAR_TYPE',varid,'support_data',/ZVARIABLE
  cdf_attput,fileid,'FILLVAL',varid,0,/ZVARIABLE
  cdf_attput,fileid,'DISPLAY_TYPE',varid,'time_series',/ZVARIABLE
  cdf_attput,fileid,'VALIDMIN',varid,1,/ZVARIABLE
  cdf_attput,fileid,'VALIDMAX',varid,8192,/ZVARIABLE
  cdf_attput,fileid,'SCALEMIN',varid,0,/ZVARIABLE
  cdf_attput,fileid,'SCALEMAX',varid,8192,/ZVARIABLE
  cdf_attput,fileid,'CATDESC',varid,'Number of 1-second accumulations contained within this data sample.',/ZVARIABLE
  cdf_attput,fileid,'DEPEND_TIME',varid,time_name,/ZVARIABLE
  cdf_attput,fileid,'DEPEND_0',varid,epoch_name,/ZVARIABLE
  cdf_varput,fileid,varname,data_vary.duration  
endif else begin
  varname = 'accum_time'
  atts = default_atts
  atts.fieldnam = varname
  atts.lablaxis = varname
  atts.var_type ='support_data'
  str_element,/add,atts,'FILLVAL',uint(-1)
  str_element,/add,atts,'VALIDMIN',0u
  str_element,/add,atts,'VALIDMAX',128u
  str_element,/add,atts,'SCALEMIN',0u
  str_element,/add,atts,'SCALEMAX',128u
  str_element,/add,atts,'FORMAT','I6'
  atts.catdesc = 'Number of 1-second accumulations contained within this data sample.'
  mvn_sep_cdf_var_att_create,fileid,varname,data_vary.duration,attributes=atts  
endelse


varname = 'mapid'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.catdesc = 'Binning Map ID number'
str_element,/add,atts,'FILLVAL',255b
str_element,/add,atts,'VALIDMIN',0b
str_element,/add,atts,'VALIDMAX',255b
str_element,/add,atts,'SCALEMIN',0b
str_element,/add,atts,'SCALEMAX',255b
str_element,/add,atts,'FORMAT','I3'

mvn_sep_cdf_var_att_create,fileid,varname,data_vary.mapid,attributes=atts

varname = 'seq_cntr'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
str_element,/add,atts,'FILLVAL',uint(-1)
str_element,/add,atts,'VALIDMIN',0u
str_element,/add,atts,'VALIDMAX',2U^14
str_element,/add,atts,'SCALEMIN',0u
str_element,/add,atts,'SCALEMAX',2u^14
str_element,/add,atts,'FORMAT','I6'
atts.var_type ='support_data'
atts.catdesc = 'CCSDS Sequence Counter'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.seq_cntr,attributes=atts


varname = 'raw_counts'
atts = default_atts
atts.fieldnam = varname
atts.lablaxis = varname
atts.var_type ='data'
str_element,/add,atts,'VALIDMIN',0.
str_element,/add,atts,'VALIDMAX',2.^19
str_element,/add,atts,'SCALEMIN',0.
str_element,/add,atts,'SCALEMAX',2.^16

atts.catdesc = 'Raw Counts in each accumulation bin'
mvn_sep_cdf_var_att_create,fileid,varname,data_vary.data,attributes=atts


if keyword_set(data_novary) then begin
  atts=default_atts
  str_element,/add,atts,'FILLVAL',fix(-1)
  str_element,/add,atts,'VALIDMIN',0
  str_element,/add,atts,'VALIDMAX',255
  str_element,/add,atts,'SCALEMIN',0
  str_element,/add,atts,'SCALEMAX',255
  str_element,/add,atts,'FORMAT','I3'
  atts.var_type ='support_data'

  
  bmap = data_novary  
  atts.catdesc = 'BIN Number -  Counts Accumulation Bin'
  atts.fieldnam = 'MAP.BIN'
  mvn_sep_cdf_var_att_create,fileid,'MAP_BIN'  ,bmap.fto,attributes=atts,/rec_novary
  
  atts.catdesc = 'FTO Pattern - Coincidence pattern for Telescope stack'
  atts.fieldnam = 'MAP.FTO'
  mvn_sep_cdf_var_att_create,fileid,'MAP_FTO'  ,bmap.fto,attributes=atts,/rec_novary
  
  atts.catdesc = 'TID  - Telescope ID  0=Side A,  1=Side B'
  atts.fieldnam = 'MAP.TID'
  mvn_sep_cdf_var_att_create,fileid,'MAP_TID'  ,bmap.tid,attributes=atts,/rec_novary

  str_element,/add,atts,'VALIDMIN',0
  str_element,/add,atts,'VALIDMAX',2^14
  str_element,/add,atts,'SCALEMIN',0
  str_element,/add,atts,'SCALEMAX',2^14
  str_element,/add,atts,'FORMAT','i8'
  
  atts.catdesc = 'ADC Low Limit -   ( LOW <= ADC < HIGH) '
  atts.fieldnam = 'MAP.ADC_LOW'
  mvn_sep_cdf_var_att_create,fileid,'MAP_ADC_LOW'  ,bmap.adc[0],attributes=atts,/rec_novary
  
  atts.catdesc = 'ADC High Limit -   ( LOW <= ADC < HIGH) '
  atts.fieldnam = 'MAP.ADC_HIGH'
  mvn_sep_cdf_var_att_create,fileid,'MAP_ADC_HIGH'  ,bmap.adc[1],attributes=atts,/rec_novary

  str_element,/add,atts,'VALIDMIN',0.
  str_element,/add,atts,'VALIDMAX',2.^16
  str_element,/add,atts,'SCALEMIN',0.
  str_element,/add,atts,'SCALEMAX',2.^14
  str_element,/add,atts,'FORMAT','F8'

  atts.catdesc = 'ADC Average -  Average of ADC Values'
  atts.fieldnam = 'MAP.ADC_AVG'
  mvn_sep_cdf_var_att_create,fileid,'MAP_ADC_AVG'  ,bmap.adc_avg,attributes=atts,/rec_novary
  
  atts.catdesc = 'ADC Delta -  Delta of ADC Values'
  atts.fieldnam = 'MAP.ADC_DELTA'
  mvn_sep_cdf_var_att_create,fileid,'MAP_ADC_DELTA'  ,bmap.adc_delta,attributes=atts,/rec_novary

  atts=default_atts
  str_element,/add,atts,'VALIDMIN',0.
  str_element,/add,atts,'VALIDMAX',50.e6
  str_element,/add,atts,'SCALEMIN',0u
  str_element,/add,atts,'SCALEMAX',6e6
  str_element,/add,atts,'FORMAT','f9'

  atts.catdesc = 'Energy -  Average Measured Energy in Bin'
  atts.fieldnam = 'MAP.NRG_MEAS_AVG'
  mvn_sep_cdf_var_att_create,fileid,'MAP_NRG_MEAS_AVG'  ,bmap.nrg_meas_avg,attributes=atts,/rec_novary

  atts.catdesc = 'Energy Width of bin'
  atts.fieldnam = 'MAP.NRG_MEAS_DELTA'
  mvn_sep_cdf_var_att_create,fileid,'MAP_NRG_MEAS_DELTA'  ,bmap.nrg_meas_delta,attributes=atts,/rec_novary

endif

 
cdf_close,fileid
dprint,dlevel=2,'Created: '+filename

end
