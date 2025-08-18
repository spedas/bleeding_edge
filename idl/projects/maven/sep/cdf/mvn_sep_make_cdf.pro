; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-30 19:45:35 -0700 (Sun, 30 May 2021) $
; $LastChangedRevision: 30010 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/cdf/mvn_sep_make_cdf.pro $
; $ID: $

pro mvn_sep_make_cdf,data_vary,data_novary,filename=filename,dependencies=dependencies,global=global,add_link=add_link,raw=raw,cal=cal

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
  if keyword_set(cal) then cdf_attput,fileid,'TITLE',0,'MAVEN SEP Electron and Ion Flux'
  if keyword_set(raw) then cdf_attput,fileid,'TITLE',0,'MAVEN SEP Electron and Ion Raw Counts'
  cdf_attput,fileid,'Project',0,'MAVEN>Mars Atmosphere and Volatile EvolutioN Mission'
  cdf_attput,fileid,'Discipline',0,'Planetary Physics>Particles'
  cdf_attput,fileid,'Source_name',0,'MAVEN>Mars Atmosphere and Volatile Evolution Mission'
  cdf_attput,fileid,'Descriptor',0,'SEP>Solar Energetic Particle Experiment'
  cdf_attput,fileid,'Data_type',0,global.data_type
  cdf_attput,fileid,'Data_version',0,ver_str
  if keyword_set(cal) then cdf_attput,fileid,'TEXT',0,'MAVEN SEP electron and ion flux'
  if keyword_set(raw) then cdf_attput,fileid,'TEXT',0,'MAVEN SEP electron and ion raw counts'
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
    FORM_PTR:'',DEPEND_TIME:time_name,DEPEND_0:epoch_name,DEPEND_1:'',DEPEND_2:'',LABL_PTR_1:''}

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

  ;Epoch TT2000
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
  cdf_attput,fileid,'CATDESC',varid,'Attenuator state, 0=error, 1=open, 2=closed, 3=mixed',/ZVARIABLE
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
  atts.fieldnam = varname
  atts.lablaxis = varname
  atts.var_type ='support_data'
  atts.catdesc = 'Binning Map ID number'
  mvn_sep_cdf_var_att_create,fileid,varname,uint(data_vary.mapid),attributes=atts

  varname = 'seq_cntr'
  atts = default_atts
  str_element,/add,atts,'FILLVAL',uint(-1)
  str_element,/add,atts,'VALIDMIN',0u
  str_element,/add,atts,'VALIDMAX',2U^14
  str_element,/add,atts,'SCALEMIN',0u
  str_element,/add,atts,'SCALEMAX',2u^14
  str_element,/add,atts,'FORMAT','I6'
  atts.fieldnam = varname
  atts.lablaxis = varname
  atts.var_type ='support_data'
  atts.catdesc = 'CCSDS Sequence Counter'
  mvn_sep_cdf_var_att_create,fileid,varname,data_vary.seq_cntr,attributes=atts

  if keyword_set(cal) then begin

    varnames1=['f','r']
    vartypes1=['in Forward','in Rear']
    var_type1=hash(varnames1,vartypes1)

    varnames2=['ion','elec']
    vartypes2=['Ion','Electron']
    var_type2=hash(varnames2,vartypes2)

    varnames3=['','_tot']
    vartypes3=['Differential ','Total ']
    varunits3=['/keV','']
    var_type3=hash(varnames3,vartypes3)
    var_unit3=hash(varnames3,varunits3)

    varnames4=['','_unc']
    vartypes4=['data','support_data']
    varuncer4=['','Uncertainty ']
    var_type4=hash(varnames4,vartypes4)
    varuncert=hash(varnames4,varuncer4)

    varnames5=['energy','denergy']
    vartypes5=['',' Channel Width']
    var_type5=hash(varnames5,vartypes5)

    foreach varname1,varnames1 do begin
      foreach varname2,varnames2 do begin
        foreach varname3,varnames3 do begin
          foreach varname4,varnames4 do begin
            varname = varname1+'_'+varname2+'_flux'+varname3+varname4
            atts = default_atts
            atts.fieldnam = varname
            atts.lablaxis = varname
            atts.var_type =var_type4[varname4]
            atts.catdesc = var_type3[varname3]+var_type2[varname2]+' Flux '+varuncert[varname4]+var_type1[varname1]+' Look Direction (#/cm^2/sec/ster'+var_unit3[varname3]+')'
            atts.units= '#/cm^2/sec/ster'+var_unit3[varname3]
            atts.scaletyp= 'log'
            if varname3 eq '' then begin
              atts.depend_1 = varname1+'_'+varname2+'_energy'
              atts.display_type='spectrogram'
            endif
            str_element,data_vary,varname,data
            mvn_sep_cdf_var_att_create,fileid,varname,data,attributes=atts
          endforeach
        endforeach

        foreach varname5,varnames5 do begin
          varname = varname1+'_'+varname2+'_'+varname5
          atts = default_atts
          atts.fieldnam = varname
          atts.lablaxis = varname
          atts.var_type ='support_data'
          atts.catdesc = var_type2[varname2]+' Energy'+var_type5[varname5]+' (keV)'
          atts.units= 'keV'
          atts.scaletyp= 'log'
          str_element,data_vary,varname,data
          mvn_sep_cdf_var_att_create,fileid,varname,data,attributes=atts
        endforeach
      endforeach
    endforeach

    varname = 'a_t_rates'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Count Rate in Thick Detectors of A Stack (#/sec)'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.A_T_RATE,attributes=atts

    varname = 'b_t_rates'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Count Rate in Thick Detectors of B Stack (#/sec)'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.B_T_RATE,attributes=atts

    varname = 'a_fto_rates'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Count Rate of Triple Coincidence in A Stack (#/sec)'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.A_FTO_RATE,attributes=atts

    varname = 'b_fto_rates'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Count Rate in Triple Coincidence in B Stack (#/sec)'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.B_FTO_RATE,attributes=atts

    varname = 'f_o_rate'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Total Count Rate in Forward Open Detector (#/sec)'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.f_o_rate,attributes=atts

    varname = 'f_f_rate'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Total Count Rate in Forward Foil Detector (#/sec)'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.f_f_rate,attributes=atts

    varname = 'r_o_rate'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Total Count Rate in Rear Open Detector (#/sec)'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.r_o_rate,attributes=atts

    varname = 'r_f_rate'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Total Count Rate in Rear Foil Detector (#/sec)'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.r_f_rate,attributes=atts

    varname = 'quality_flag'
    atts = default_atts
    atts.fieldnam = varname
    atts.lablaxis = varname
    atts.var_type ='support_data'
    atts.catdesc = 'Quality Flag'
    defval = 0UL
    str_element,/add,atts,'FILLVAL',defval-1
    str_element,/add,atts,'VALIDMIN',defval
    str_element,/add,atts,'VALIDMAX',2UL ^ 10
    str_element,/add,atts,'SCALEMIN',0u
    str_element,/add,atts,'SCALEMAX',2uL ^ 10
    str_element,/add,atts,'FORMAT','I10'
    mvn_sep_cdf_var_att_create,fileid,varname,data_vary.QUALITY_FLAG,attributes=atts

  endif

  if keyword_set(raw) then begin
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
    atts.display_type='spectrogram'
    atts.scaletyp= 'log'
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
      mvn_sep_cdf_var_att_create,fileid,'MAP_BIN'  ,fix(bmap.bin),attributes=atts,/rec_novary

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

      atts.catdesc = 'Energy Width of Bin'
      atts.fieldnam = 'MAP.NRG_MEAS_DELTA'
      mvn_sep_cdf_var_att_create,fileid,'MAP_NRG_MEAS_DELTA'  ,bmap.nrg_meas_delta,attributes=atts,/rec_novary
    endif
  endif

  cdf_close,fileid
  dprint,dlevel=1,'Created '+file_info_string(filename)

end
