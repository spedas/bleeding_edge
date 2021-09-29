;obsolete -  functionality pulled into spp_gen_apdat__define


function spp_swp_span_variable_attributes, vname

message,'obsolete'

dlevel =3
fnan = !values.f_nan
att = orderedhash()
;  Create default value place holders
att['CATDESC']    = ''
att['FIELDNAM']    = vname
att['LABLAXIS']    = vname
att['DEPEND_0'] = 'Epoch'
att['DISPLAY_TYPE'] = ''
case vname of
  'Epoch': begin
    att['CATDESC']    = 'Time at middle of sample'
    att['FIELDNAM']    = 'Time in TT2000 format'
    att['LABLAXIS']    = 'Epoch'
    att['UNITS']    = 'ns'
    att['FILLVAL']    = -1
    att['VALIDMIN']    = -315575942816000000
    att['VALIDMAX']    = 946728068183000000
    att['VAR_TYPE']    = 'support_data'
    att['DICT_KEY']    = 'time>Epoch'
    att['SCALETYP']    = 'linear'
    att['MONOTON']    = 'INCREASE'
    end
  'TIME': begin
    att['CATDESC']    = 'Time at middle of sample'
    att['FIELDNAM']    = 'Time in UTC format'
    att['LABLAXIS']    = 'Unix Time'
    att['UNITS']    = 'sec'
    att['FILLVAL']    = fnan
    att['VALIDMIN']    = time_double('2010')
    att['VALIDMAX']    = time_double('2030')
    att['VAR_TYPE']    = 'support_data'
    att['DICT_KEY']    = 'time>UTC'
    att['SCALETYP']    = 'linear'
    att['MONOTON']    = 'INCREASE'
    end
  'COUNTS': begin
     att['CATDESC']    = 'Counts in Energy/angle bin'
     att['FIELDNAM']    = 'Counts in '
     att['DEPEND_0']    = 'Epoch'
     att['LABLAXIS']    = 'Counts'
     att['UNITS']    = ''
     att['FILLVAL']    = fnan
     att['VALIDMIN']    = 0
     att['VALIDMAX']    = 1e6
     att['VAR_TYPE']    = 'data'
     att['DICT_KEY']    = ''
     att['SCALETYP']    = 'log'
     att['MONOTON']    = ''
    end
  else:  begin    ; assumed to be support
    att['CATDESC']    = 'Not known'
    att['FIELDNAM']    = 'Unknown '
    att['DEPEND_0']    = 'Epoch'
    att['LABLAXIS']    = vname
    att['UNITS']    = ''
    att['FILLVAL']    = fnan
    att['VALIDMIN']    = -1e30
    att['VALIDMAX']    = 1e30
    att['VAR_TYPE']    = 'ignore_data'
    att['DICT_KEY']    = ''
    att['SCALETYP']    = 'linear'
    att['MONOTON']    = ''
    
    dprint,dlevel=dlevel, 'variable ' +vname+ ' not recognized'
  
    end
  
endcase

return, att
end





function spp_swp_span_makecdf,  datavary, datanovary,  vnames=vnames, ignore=ignore,global_att=global_att,_extra=ex


message,'obsolete'
cdf = cdf_tools(_extra=ex)
if ~keyword_set(global_att) then begin
  global_att = orderedhash()
  global_att['Project'] = 'PSP>Parker Solar Probe'
;  global_att['Source_name'] = 'PSP>Parker Solar Probe'
;  global_att['Acknowledgement'] = !NULL
;  global_att['TITLE'] = 'PSP SPAN Electron and Ion Counts'
;  global_att['Discipline'] = 'Heliospheric Physics>Particles'
;  global_att['Descriptor'] = 'INSTname>SWEAP generic Sensor Experiment'
;  global_att['Data_type'] = '>Survey Calibrated Particle Flux'
;  global_att['Data_version'] = 'v00'
;  global_att['TEXT'] = 'Reference Paper or URL'
;  global_att['MODS'] = 'Revision 0'
;  ;global_att['Logical_file_id'] =  self.name+'_test.cdf'  ; 'mvn_sep_l2_s1-cal-svy-full_20180201_v04_r02.cdf'
;  global_att['dirpath'] = './'
;  ;global_att['Logical_source'] = '.cal.spec_svy'
;  ;global_att['Logical_source_description'] = 'DERIVED FROM: PSP SWEAP'  ; SEP (Solar Energetic Particle) Instrument
;  global_att['Sensor'] = ' '   
;  global_att['PI_name'] = 'J. Kasper'
;  global_att['PI_affiliation'] = 'Univ. of Michigan'
;  global_att['IPI_name'] = 'D. Larson (davin@ssl.berkeley.edu)'
;  global_att['IPI_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
;  global_att['InstrumentLead_name'] = '  '
;  global_att['InstrumentLead_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
;  global_att['Instrument_type'] = 'Electrostatic Analyzer Particle Detector'
;  global_att['Mission_group'] = 'PSP'
;  global_att['Parents'] = '' ; '2018-02-17/22:17:38   202134481 ChecksumExecutableNotAvailable            /disks/data/maven/data/sci/pfp/l0_all/2018/02/mvn_pfp_all_l0_20180201_v002.dat ...
;  global_att = global_att + cdf.sw_version()
endif
cdf.g_attributes += global_att
  
fnan = !values.f_nan
 
; Force Epoch as first variable. If datavary contains an EPOCH variable it will add or overwrite this value
epoch = time_ephemeris(datavary.time,/et2ut)                ;  may want to change this later to base it on met
vho = cdf_tools_varinfo('Epoch',epoch[0],/recvary,datatype = 'CDF_EPOCH')
vh = vho.getattr()
vh.data.array = epoch
vatts =  spp_swp_span_variable_attributes('Epoch')
vh.attributes  += vatts
cdf.add_variable, vh

if keyword_set(datavary) then begin
  if ~keyword_set(vnames) then vnames = tag_names(datavary)
  datavary0 = datavary[0]   ; use first element as the template.

  dlevel=5
  for vn=0,n_elements(vnames)-1 do begin
    vname = vnames[vn]
    val = datavary0.(vn)
    vals = datavary.(vn)
    if isa(val,'pointer') then begin                ; special case for pointers
      maxsize = max(datavary.datasize,index)        ; determines maximum size of container
      val = *vals[index]
      ndv = n_elements(datavary)
      ptrs = vals
      vals = replicate(fill_nan(val[0]),[ndv,maxsize])
      for i= 0,ndv-1 do if maxsize eq n_elements(*ptrs[i]) then  vals[i,*] = *ptrs[i]    ; only the largest arrays will get filled - should correct in the future.
    endif else begin
      vals = reform(transpose(vals))
    endelse
    vho = cdf_tools_varinfo(vname, val, /recvary)
    vh = vho.getattr()
    vh.data.array = vals
    vatt  = spp_swp_span_variable_attributes(vname)
    ;  dprint,dlevel=dlevel,'hello1'
    vh.attributes += vatt
    ;  dprint,dlevel=dlevel,'hello2'
    cdf.add_variable, vh
  endfor
  
endif


return,cdf
end
