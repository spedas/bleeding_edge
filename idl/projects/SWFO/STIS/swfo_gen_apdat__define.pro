;+
;  swfo_GEN_APDAT
;  This basic object is the entry point for defining and obtaining all data for all apids
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-04 10:57:07 -0800 (Tue, 04 Mar 2025) $
; $LastChangedRevision: 33161 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_gen_apdat__define.pro $
;-
;COMPILE_OPT IDL2


FUNCTION swfo_gen_apdat::Init_old,apid,name,_EXTRA=ex,verbose=verbose
  COMPILE_OPT IDL2
  ; Call our superclass Initialization method.
  void = self->IDL_Object::Init()
  ;printdat,a
  self.apid  =apid
  self.dlevel = 2
  if isa(verbose) then self.verbose = verbose else self.verbose = 2
  ;self.sort_flag = 1
  self.last_data_p = ptr_new(!null)
  self.last_replay_p = ptr_new(!null)
  if keyword_set(name) then begin
    self.name  =name
    ;  insttype = strsplit(self.name
    ;  self.cdf_pathname = prefix + 'sweap/spx/
  endif
  self.last_ccsds_p = ptr_new(!null)
  self.data = dynamicarray(name=self.name)
  self.ncdf_directory = root_data_dir() + 'swfo/data/sci/stis/prelaunch/realtime/test/'
  self.ncdf_fileformat = '$NAME$/$TYPE$/YYYY/MM/DD/swfo_$NAME$_$TYPE$_$RES$_YYYYMMDD_hhmm_v00.nc'
  if  keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel,verbose=verbose
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  RETURN, 1
END



function swfo_gen_apdat::cdf_global_attributes
  global_att=orderedhash()

  global_att['Acknowledgement'] = !NULL
  global_att['Project'] = 'LWS>Living With a Star'
  global_att['Source_name'] = 'SWFO-L1>Space Weather Follow On'
  global_att['TITLE'] = 'STIS'
  global_att['Discipline'] = 'Heliospheric Physics>Particles'
  global_att['Descriptor'] = 'STIS'
  global_att['Data_type'] = '>Solar Wind Particle Distributions'
  global_att['Data_version'] = 'v00'
  global_att['TEXT'] = ''
  global_att['MODS'] = 'Revision 0'
  global_att['Logical_file_id'] =  self.name
  global_att['dirpath'] = './'
  global_att['Logical_source'] = self.name
  global_att['Logical_source_description'] = 'DERIVED FROM: STIS'
  global_att['Sensor'] = ' '
  global_att['PI_name'] = 'Davin Larson (davin@berkeley.edu)'
  global_att['PI_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
  global_att['Instrument_type'] =['Plasma and Solar Wind','Particles (space)']
  global_att['Mission_group'] = 'SWFO'
  global_att['Parents'] = ' '

  global_att = global_att + self.sw_version()
  ;  global_att['SW_VERSION'] = 'v00'
  ;  global_att['SW_TIME_STAMP_FILE'] = ''
  ;  global_att['SW_TIME_STAMP'] =  time_string(systime(1))
  ;  global_att['SW_RUNTIME'] =  time_string(systime(1))
  ;  global_att['SW_RUNBY'] =
  ;  global_att['SVN_CHANGEDBY'] = '$LastChangedBy: rjolitz $'
  ;  global_att['SVN_CHANGEDATE'] = '$LastChangedDate: 2025-03-04 10:57:07 -0800 (Tue, 04 Mar 2025) $'
  ;  global_att['SVN_REVISION'] = '$LastChangedRevision: 33161 $'

  return,global_att
end


PRO swfo_gen_apdat__define
  void = {swfo_gen_apdat, $
    inherits generic_apdat $    ; superclass
  }
END


