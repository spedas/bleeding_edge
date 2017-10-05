; Generic routine to produce PDS4-compliant CDF files.

; ARGUMENTS:
; 
;   STRUCT: an array of structures. Rules concerning 'Struct':
;   1) The number of elements in 'struct' must be equal to the number of timestamps. 
;   2) Each element in the array correspond to a single timestamp.  In other words, there can be no "ancillary"
;      data that is relevant to all the data in the file unless it is repeated for every timestamp. 
;      For example, an energy table must be repeated N times if there are N elements in 'struct'
;   3) Each of the tags in 'struct' will become a CDF variable name in the output file.
;   4) 'struct' must have the following  tags: Time_MET (mission elapsed time) and Time_UNIX
;   5) The rest of the  tags can have any name.
; 
;   UNITS: an array of strings with the same number of elements as tags in 'struct', expressing the physical units in which each variable is represented

;   DESCRIPTION: an array of strings with the same number of elements as tags in 'struct'describing explicitly in words what each variable is

; KEYWORDS: none are mandatory for the program to run aand make a PDS-compliant file.  
;   However,  this is where all the descriptive information goes.  
;   DISPLAY_RANGE: This is a 2 x N_tags-element array (where N_tags is the number of tags in 'struct') of minimum and maximum values that should be displayed.  
;                  Certain web interfaces such as CDA-web use this information for auto plotting.  
;                  If this keyword is not set (or if the minimum or maximum for a given tag is a NaN), 
;                  then the minimum and maximum are set to the nearest factor of 10 either positive or negative, whichever is appropriate.
;   FILE:  this is the output CDF file name you want, including the path.
; 
; The remainder of the keywords are best described by the default values shown below (pertaining to the MAVEN SEP instrument)
;   
; 
pro mvn_pf_make_cdf, struct, units, description, display_range  = display_range, $
    file = file,$
    title = title, $
    project = project, $
    mission = mission,  $
    discipline = discipline, $
    descriptor = descriptor, $
    data_type = data_type,$
    data_version = data_version, $
    experiment_description  = experiment_description, $
    software_revision  = software_revision, $
    logical_source = logical_source, $
    logical_source_description = logical_source_description, $
    Instrument_lead_name  = instrument_lead_name, $  
    Instrument_lead_affiliation = instrument_lead_affiliation, $
    Instrument_type = instrument_type, $
    mission_group = mission_group, $
    Parent_CDF_files = parent_CDF_files,$
    HTTP_LINK = HTTP_LINK, $
    LINK_TEXT = LINK_TEXT, $
    LINK_TITLE = LINK_TITLE
    
  if not keyword_set(file) then file = 'test.cdf'
  If not keyword_set (title)  then  title = 'MAVEN SEP ion spectra'
  If not keyword_set (project)  then project = 'MAVEN'
  
  ;; Just in case the mission name is different from the project name.
  If not keyword_set (mission) then  mission = project
 
  If not keyword_set (discipline) then  discipline = 'Planetary Science>Planetary Plasma Interactions'
  If not keyword_set (descriptor) then  descriptor = 'SEP> Solar Energetic Particle Instrument'
  If not keyword_set (data_type) then data_type =  'Level 2'
  If not keyword_set (data_version)  then data_version= '1'
  If not keyword_set (experiment_description) then experiment_description = 'MAVEN SEP energetic electron and ion fluxes'
  if not keyword_set (software_revision) then software_revision =  'Revision 0'
  
  ; This is  the logical source identifier in the SIS
  If not keyword_set (logical_source) then logical_source  =  'sep.calibrated.ion_spec_svy'
  
  ;; This is a full-word description of logical source identifier in the SIS
  If not keyword_set (logical_source_description) then logical_source_description = $
     'DERIVED FROM: MAVEN SEP (Solar Energetic Particle) ion spectra in 4 look directions'
     
  If not keyword_set (instrument_lead_name)  then instrument_lead_name = 'Davin Larson (davin@ssl.berkeley.edu)'
  If not keyword_set (instrument_lead_affiliation) then $
      instrument_lead_affiliation = 'UC Berkeley Space Sciences Laboratory'
  If not keyword_set (instrument_type)  then instrument_type = 'Energetic Particle Detector'
  If not keyword_set (mission_group) then mission_group =  'MAVEN'
  If not keyword_set (parent_CDF_files) then parent_CDF_files = 'None'
  If not keyword_set (HTTP_LINK) then HTTP_LINK  = 'http://lasp.colorado.edu/home/maven/'
  If not keyword_set (LINK_TEXT) then LINK_TEXT  = 'General Information about the MAVEN mission'
  If not keyword_set (LINK_TITLE) then LINK_TITLE = 'MAVEN homepage'
  
  
cdf_leap_second_init

date_range = time_double(['2013-11-18/00:00','2040-12-31/23:59'])
met_range = time_double('2040-12-31/23:59') - time_double('2013-11-18/00:00')
epoch_range = time_epoch(date_range)
tt2000_range = long64((add_tt2000_offset(date_range)-time_double('2000-01-01/12:00'))*1e9)


epoch = time_epoch(struct.time_UNIX)
timett2000 = long64((add_tt2000_offset(struct.time_unix)-time_double('2000-01-01/12:00'))*1e9)

fileid = cdf_create(file,/single_file,/network_encoding,/clobber)


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
id17 = cdf_attcreate(fileid,'HTTP_LINK',/global_scope)
id18 = cdf_attcreate(fileid,'LINK_TEXT',/global_scope)
id19 = cdf_attcreate(fileid,'LINK_TITLE',/global_scope)

cdf_attput,fileid,'Title',0, title
cdf_attput,fileid,'Project',0,project
cdf_attput,fileid,'Discipline',0,discipline
cdf_attput,fileid,'Source_name',0,mission
cdf_attput,fileid,'Descriptor',0,descriptor
cdf_attput,fileid,'Data_type',0,data_type
cdf_attput,fileid,'Data_version',0,data_version
cdf_attput,fileid,'TEXT',0,experiment_description
cdf_attput,fileid,'Mods',0,software_revision
cdf_attput,fileid,'Logical_file_id',0,file
cdf_attput,fileid,'Logical_source',0,logical_source
cdf_attput,fileid,'Logical_source_description',0,logical_source_description
cdf_attput,fileid,'PI_name',0,instrument_lead_name
cdf_attput,fileid,'PI_affiliation',0,instrument_lead_affiliation
cdf_attput,fileid,'Instrument_type',0,instrument_type
cdf_attput,fileid,'Mission_group',0,mission_group
cdf_attput,fileid,'Parents',0,parent_CDF_files
cdf_attput,fileid,'HTTP_LINK',0,HTTP_LINK
cdf_attput,fileid,'LINK_TEXT',0,LINK_TEXT
cdf_attput,fileid,'LINK_TITLE',0,LINK_TITLE


dummy = cdf_attcreate(fileid,'FIELDNAM',/variable_scope) ; description of the variable
dummy = cdf_attcreate(fileid,'MONOTON',/variable_scope) ; monotonicity of the variable
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

;variable_list = ['Epoch','Time_TT2000','Time_MET','Time_Unix','Atten_State','Grouping','Num_Accum','Counts','Diff_En_Fluxes']
Variable_list = strlowcase(tag_names  (struct))

nvars = n_elements(variable_list)
nrec = n_elements(struct)
if n_elements (units) ne n_tags (struct) then message, $
  'The number of elements in Units mmust be equal to the number of variables in struct'

 
; Due to specific keywords, we have to do all of the making for these two  before going on to the other the variables.

  n_dimension  = size (Epoch,/n_dimensions)
  Dim = reform (size (epoch,/dimension))
  dim_vary = replicate (1, n_dimension)
  variable_ID  = $
      cdf_varcreate(fileid, 'Epoch',dim_vary, $
      /CDF_EPOCH, /REC_VARY,/ZVARIABLE)
  cdf_attput,fileid,'FORMAT','Epoch','F17.7',/ZVARIABLE
  cdf_attput,fileid,'FIELDNAM','Epoch','Epoch',/ZVARIABLE
  cdf_attput,fileid,'LABLAXIS','Epoch','Epoch',/ZVARIABLE
  cdf_attput,fileid,'VAR_TYPE','Epoch','data',/ZVARIABLE
  cdf_attput,fileid,'FILLVAL','Epoch',-1.0e31,/ZVARIABLE
  cdf_attput,fileid,'DISPLAY_TYPE','Epoch','time_series',/ZVARIABLE
  cdf_attput,fileid,'VALIDMIN','Epoch',epoch_range[0],/ZVARIABLE
  cdf_attput,fileid,'VALIDMAX','Epoch',epoch_range[1],/ZVARIABLE
  cdf_attput,fileid,'SCALEMIN','Epoch',epoch[0],/ZVARIABLE
  cdf_attput,fileid,'SCALEMAX','Epoch',epoch[nrec-1],/ZVARIABLE
  cdf_attput,fileid,'UNITS','Epoch','ms',/ZVARIABLE
  cdf_attput,fileid,'MONOTON','Epoch','INCREASE',/ZVARIABLE
  cdf_attput,fileid,'CATDESC','Epoch','Time, start of sample, in NSSDC Epoch',/ZVARIABLE
  cdf_varput,fileid,'Epoch',epoch

  variable_id = $
      cdf_varcreate(fileid,'Time_TT2000',dim_vary, $
      /CDF_TIME_TT2000,/REC_VARY,/ZVARIABLE)
  cdf_attput,fileid,'FORMAT','Time_TT2000','F17.7',/ZVARIABLE
  cdf_attput,fileid,'FIELDNAM','Time_TT2000','Time_TT2000',/ZVARIABLE
  cdf_attput,fileid,'LABLAXIS','Time_TT2000','Time_TT2000',/ZVARIABLE
  cdf_attput,fileid,'VAR_TYPE','Time_TT2000','data',/ZVARIABLE
  cdf_attput,fileid,'FILLVAL','Time_TT2000',-1.0e31,/ZVARIABLE
  cdf_attput,fileid,'DISPLAY_TYPE','Time_TT2000','time_series',/ZVARIABLE
  cdf_attput,fileid,'VALIDMIN','Time_TT2000',tt2000_range[0],/ZVARIABLE
  cdf_attput,fileid,'VALIDMAX','Time_TT2000',tt2000_range[1],/ZVARIABLE
  cdf_attput,fileid,'SCALEMIN','Time_TT2000',timett2000[0],/ZVARIABLE
  cdf_attput,fileid,'SCALEMAX','Time_TT2000',timett2000[nrec-1],/ZVARIABLE
  cdf_attput,fileid,'UNITS','Time_TT2000','ns',/ZVARIABLE
  cdf_attput,fileid,'MONOTON','Time_TT2000','INCREASE',/ZVARIABLE
  cdf_attput,fileid,'CATDESC','Time_TT2000','Time, start of sample, in TT2000 time base',/ZVARIABLE
  cdf_varput,fileid,'Time_TT2000',timett2000

  for i = 0,nvars-1 do begin
	; Now determine  the dimensionality and type  of the variable
	n_dimension  = size (struct.(i),/n_dimensions)
	; The dimension used to create the CDF variable must be 1 lower than the IDL variable.   
	; In other words, the CDF dimensionality  refers to the dimensionality of each record. 
	; For example, electron temperature is not a CDF variable of dimension (n_times), but instead has dimension zero, but varies with each record.
	Dim = reform (size (struct.(i),/dimension))-1 ; 
	type = size (struct.(i),/type)
	dim_vary = replicate (1, n_dimension)

  case type of
    1: begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $
        /CDF_BYTE,/REC_VARY,/ZVARIABLE)
      cdf_attput,fileid,'FORMAT',variable_ID,'I4',/ZVARIABLE
      end
    2: begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $
        /CDF_INT1,/REC_VARY,/ZVARIABLE) 
      cdf_attput,fileid,'FORMAT',variable_ID,'I6',/ZVARIABLE
      end
    3: begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $       
        /CDF_INT2,/REC_VARY,/ZVARIABLE)
      cdf_attput,fileid,'FORMAT',variable_ID,'I11',/ZVARIABLE
      end
    4: begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $      
        /CDF_FLOAT,/REC_VARY,/ZVARIABLE) 
      cdf_attput,fileid,'FORMAT',variable_ID,'F15.7',/ZVARIABLE
      end
    5: begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $      
        /CDF_DOUBLE,/REC_VARY,/ZVARIABLE) 
      cdf_attput,fileid,'FORMAT',variable_ID,'F15.7',/ZVARIABLE
      end
    6: message, 'No complex data types allowed in CDF variables.  Real  variables only!'
    7: message, 'No string data types allowed in CDF variables.'
    8: message, 'No structure data types allowed in CDF variables.'
    9: message, 'No complex data types allowed in CDF variables.  Real  variables only!'
   10: message, 'No pointer data types allowed in CDF variables.'
   11: message, 'No object reference data types allowed in CDF variables.      
   12: Begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $       
        /CDF_UINT1,/REC_VARY,/ZVARIABLE) 
      cdf_attput,fileid,'FORMAT',variable_ID,'I6',/ZVARIABLE
      end
   13: begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $     
        /CDF_UINT2,/REC_VARY,/ZVARIABLE) 
      cdf_attput,fileid,'FORMAT',variable_ID,'I10',/ZVARIABLE
      end
   14: begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $       
        /CDF_INT4,/REC_VARY,/ZVARIABLE)
      cdf_attput,fileid,'FORMAT',variable_ID,'I20',/ZVARIABLE
      end
   15: begin
      variable_ID  = $
        cdf_varcreate(fileid, variable_list[i],dim_vary, $      
        /CDF_UINT4,/REC_VARY,/ZVARIABLE) 
      cdf_attput,fileid,'FORMAT',variable_ID,'I20',/ZVARIABLE
      end
Endcase

	cdf_attput,fileid,'FIELDNAM',variable_ID,variable_list[i],/ZVARIABLE
	cdf_attput,fileid,'LABLAXIS',variable_ID,variable_list[i],/ZVARIABLE
	cdf_attput,fileid,'VAR_TYPE',variable_ID,'data',/ZVARIABLE 
	cdf_attput,fileid,'FILLVAL',variable_ID,-1.0e31,/ZVARIABLE
	cdf_attput,fileid,'DISPLAY_TYPE',variable_ID,'time_series',/ZVARIABLE

  if variable_list[i] eq 'time_met' then begin
    Valid_range = [0, 60*365L*86400] ; 60 years
    Scale_range  = [struct[0].time_met, struct[nrec-1].time_met]
    Monotonic = 'INCREASE'
  endif else if variable_list[i] eq 'time_unix' then begin
    Valid_range = time_double (['1970-01-01','2050-01-01']) 
    Scale_range  = [struct[0].time_unix, struct[nrec-1].time_unix]
   Monotonic = 'INCREASE'
  endif else begin
    Monotonic = 'FALSE'
    Valid_range = [-1e25,1e25]
    temp_range = minmax(struct.(i), /nan)
    if sign(temp_range [0]) eq 1 then $ ;Some guesswork as to what a reasonable range might be if the user doesn't specify
      autoscale_range = [10^(Floor(alog10(temp_range[0]))),$
      10^(Ceil(alog10(temp_range[1])))] else if sign(temp_range [0]) eq -1 then $
      autoscale_range = [-1*10^(Ceil(alog10(abs(temp_range[0])))),$
      10^(Ceil(alog10(temp_range[1])))] else autoscale_range =  [0,10^(Ceil(alog10(temp_range[1])))]
    If keyword_set (display_range) then begin
      if finite (total (display_range[*,i])) then scale_range = display_range [*,i] else scale_range = autoscale_range
    endif else begin
      scale_range = autoscale_range
    endelse
  endelse
     
; Fill in some of the attributes for the variables
  cdf_attput,fileid,'VALIDMIN',variable_list[i],valid_range[0],/ZVARIABLE
  cdf_attput,fileid,'VALIDMAX',variable_list[i],valid_range[1],/ZVARIABLE
  cdf_attput,fileid,'SCALEMIN',variable_list[i],scale_range[0],/ZVARIABLE
  cdf_attput,fileid,'SCALEMAX',variable_list[i],scale_range[1],/ZVARIABLE
  cdf_attput,fileid,'UNITS',variable_list[i],units[i],/ZVARIABLE
  cdf_attput,fileid,'MONOTON',variable_list[i],monotonic,/ZVARIABLE
  cdf_attput,fileid,'CATDESC',variable_list[i],description[i],/ZVARIABLE
	cdf_varput,fileid,variable_list[i],struct.(i)


endfor


cdf_close,fileid

end
