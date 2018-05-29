;+
;  SPP_GEN_APDAT
;  This basic object is the entry point for defining and obtaining all data for all apids
;-
COMPILE_OPT IDL2


FUNCTION spp_gen_apdat::Init,apid,name,_EXTRA=ex
COMPILE_OPT IDL2
; Call our superclass Initialization method.
void = self->IDL_Object::Init()
;printdat,a
self.apid  =apid
self.dlevel = 2
;self.sort_flag = 1
self.last_data_p = ptr_new(!null)
if keyword_set(name) then self.name  =name
self.ccsds_last = ptr_new(/allocate_heap)
;self.ccsds_array = obj_new('dynamicarray')
self.data = obj_new('dynamicarray',name = self.name)
if debug(3) and keyword_set(ex) then dprint,ex,phelp=2,dlevel=2
IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
RETURN, 1
END
 
 
 
PRO spp_gen_apdat::Clear, tplot_names=tplot_names
  COMPILE_OPT IDL2
  dprint,'clear arrays: ',self.apid,self.name,dlevel=4
  self.nbytes=0
  self.npkts = 0
  self.lost_pkts = 0
  self.data.array = !null
  ptr_free,  ptr_extract(*self.ccsds_last)
  *self.ccsds_last = !null
  if keyword_set(tplot_names) && keyword_set(self.tname) then store_data,self.tname+'*',/clear
END


PRO spp_gen_apdat::zero
  COMPILE_OPT IDL2
  dprint,'zero counters: ',self.apid,self.name,dlevel=4
  self.nbytes=0
  self.npkts = 0
  self.lost_pkts = 0
END



PRO spp_gen_apdat::Cleanup
  COMPILE_OPT IDL2
  ; Call our superclass Cleanup method
  ptr_free,self.ccsds_last
  self->IDL_Object::Cleanup
END



PRO spp_gen_apdat::help
  help,/obj,self
  printdat,self.last_data_p
END


function spp_gen_apdat::info,header=header
;rs =string(format="(Z03,'x ',a-14, i8,i8 ,i12,i3,i3,i8,' ',a-14,a-36,' ',a-36, ' ',a-20,a)",self.apid,self.name,self.npkts,self.lost_pkts, $
;    self.nbytes,self.save_flag,self.rt_flag,self.data.size,self.data.typename,string(/print,self),self.routine,self.tname,self.save_tags)
  fmt ="(Z03,'x ',a-14, i8,i8 ,i12,i3,i3,i3,i8,' ',a-14,a-26,' ',a-20,'<',a,'>','     ',a)"
  hfmt="( a4,' ',a-14, a8,a8 ,a12,a3,a3,a3,a8,' ',a-14,a-26,' ',a-20,'<',a,'>','     ',a)"
;  if keyword_set(header) then rs=string(format=hfmt,'APID','Name','npkts','lost','nbytes','save','rtf','size','type','objname','routine','tname','tags')
  rs =string(format=fmt,self.apid,self.name,self.npkts,self.lost_pkts, $
    self.nbytes,self.save_flag,self.rt_flag,self.dlevel,self.data.size,self.data.typename,typename(self),self.tname,self.ttags,self.routine)

  if keyword_set(header) then rs=string(format=hfmt,'APID','Name','Npkts','lost','nbytes','sv','rt','dl','size','type','objname','tname','tags','routine') +string(13b)+ rs

return,rs
end


PRO spp_gen_apdat::print,dlevel=dlevel,verbose=verbose,strng,header=header
  print,self.info(header=header)
END



;pro spp_gen_apdat::store_data,  strct,pname,verbose=verbose
;  if self.rt_flag && self.rt_tags then begin
;    store_data,self.tname+pname,data=strct, tagnames=self.rt_tags, /append, verbose=0, gap_tag='GAP'
;  endif
;end




function spp_gen_apdat::decom,ccsds,header
;if typename(ccsds) eq 'BYTE' then return,  self.spp_gen_apdat( spp_swp_ccsds_decom(ccsds) )  ;; Byte array as input

strct = ccsds
  strct.pdata = ptr_new()
ap = self.struct()
if self.routine then  strct = call_function(self.routine,ccsds, ptp_header=header ,apdat = ap) 
dprint,dlevel=self.dlevel+3,phelp=2,strct

return,strct
end


pro spp_gen_apdat::increment_counters,ccsds
  self.npkts += 1
  self.nbytes += ccsds.pkt_size
  if ccsds.seqn_delta gt 1 then self.lost_pkts += (ccsds.seqn_delta -1)
;  if ccsds.time_delta eq 0 then self.print
  self.drate = ccsds.pkt_size / ( ccsds.time_delta > .001)
  *self.ccsds_last = ccsds
end




pro spp_gen_apdat::handler,ccsds,header,source_info=source_info
  
  strct = self.decom(ccsds)
  if keyword_set(strct) then  *self.last_data_p= strct

;if ccsds.seq_group ne 3 then self.help   ;dprint,dlevel=2,ccsds.seq_group,ccsds.apid

  if self.save_flag && keyword_set(strct) then begin
    dprint,self.name,dlevel=self.dlevel+4,self.apid
    self.data.append,  strct
  endif

  if self.rt_flag && keyword_set(strct) then begin
    if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]
    store_data,self.tname,data=strct, tagnames=self.ttags , append = 1, gap_tag='GAP'
  endif
  
end
 
 
 
 
pro spp_gen_apdat::finish,ttags=ttags
  if self.npkts ne 0 then self.print ,dlevel=3,'finish'
  verbose=1
  datarray = self.data.array
  if keyword_set(self.sort_flag) then begin
    s = sort(datarray.time)
    datarray = datarray[s]
  endif
  if keyword_set(ttags) eq 0 then ttags = self.ttags
  if keyword_set(datarray) && keyword_set(self.tname) then  begin
    store_data,self.tname,data=datarray, tagnames=ttags,  gap_tag='GAP',verbose=verbose
    options,self.tname+'*_BITS',tplot_routine='bitplot'
  endif
  self.process_time = systime(1)
end
 
 
 ;+
;NAME: MVN_SEP_SW_VERSION
;Function: mvn_spice_kernels(name)
;PURPOSE:
; Acts as a timestamp file to trigger the regeneration of SEP data products. Also provides Software Version info for the MAVEN SEP instrument.
;Author: Davin Larson  - January 2014
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-05-28 15:52:35 -0700 (Mon, 28 May 2018) $
; $LastChangedRevision: 25286 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_gen_apdat__define.pro $
;-
function spp_gen_apdat::sw_version

  tb = scope_traceback(/structure)
  this_file = tb[n_elements(tb)-1].filename
  this_file_date = (file_info(this_file)).mtime

  sw_hash = orderedhash()
  
  sw_hash['sw_version'] =  'v00'
  sw_hash['sw_time_stamp_file'] = this_file
  sw_hash['sw_time_stamp'] = time_string(this_file_date)
  sw_hash['sw_runtime'] = time_string(systime(1))
  sw_hash['sw_runby'] = getenv('LOGNAME')
  sw_hash['svn_changedby '] = '$LastChangedBy: davin-mac $'
  sw_hash['svn_changedate'] = '$LastChangedDate: 2018-05-28 15:52:35 -0700 (Mon, 28 May 2018) $'
  sw_hash['svn_revision '] = '$LastChangedRevision: 25286 $'

  return,sw_hash
end
 
function spp_gen_apdat::cdf_global_attributes
  global_att=orderedhash()
 
  global_att['Acknowledgement'] = !NULL
  global_att['TITLE'] = 'PSP SPAN Electron and Ion Flux'
  global_att['Project'] = 'PSP>Parker Solar Probe'
  global_att['Discipline'] = 'Heliospheric Physics>Particles'
  global_att['Source_name'] = 'PSP>Parker Solar Probe'
  global_att['Descriptor'] = 'INSTname>SWEAP generic Sensor Experiment'
  global_att['Data_type'] = self.name +'>Survey Calibrated Particle Flux'
  global_att['Data_version'] = 'v00'
  global_att['TEXT'] = 'PSP'
  global_att['MODS'] = 'Revision 0'
  global_att['Logical_file_id'] =  self.name+'_test.cdf'  ; 'mvn_sep_l2_s1-cal-svy-full_20180201_v04_r02.cdf'
  global_att['dirpath'] = './'
  global_att['Logical_source'] = 'SEP.cal.spec_svy'
  global_att['Logical_source_description'] = 'DERIVED FROM: PSP SWEAP'  ; SEP (Solar Energetic Particle) Instrument
  global_att['Sensor'] = ' '   ;'SEP1'
  global_att['PI_name'] = 'J. Kasper'
  global_att['PI_affiliation'] = 'U. Michigan'
  global_att['IPI_name'] = 'D. Larson (davin@ssl.berkeley.edu)
  global_att['IPI_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
  global_att['InstrumentLead_name'] = '  ' 
  global_att['InstrumentLead_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
  global_att['Instrument_type'] = 'Electrostatic Analyzer Particle Detector'
  global_att['Mission_group'] = 'PSP'
  global_att['Parents'] = '' ; '2018-02-17/22:17:38   202134481 ChecksumExecutableNotAvailable            /disks/data/maven/data/sci/pfp/l0_all/2018/02/mvn_pfp_all_l0_20180201_v002.dat ...
  global_att = global_att + self.sw_version()
;  global_att['Planet'] = 'Mars
;  global_att['PDS_collection_id'] = 'MAVEN
;  global_att['PDS_start_time'] = '2018-02-01T00:00:14.230Z
;  global_att['PDS_stop_time'] = '2018-02-02T00:00:05.594Z
;  global_att['SW_VERSION'] = 'v00'
;  global_att['SW_TIME_STAMP_FILE'] = '/home/mavensep/socware/projects/maven/sep/mvn_sep_sw_version.pro
;  global_att['SW_TIME_STAMP'] =  time_string(systime(1))  
;  global_att['SW_RUNTIME'] =  time_string(systime(1)) 
;  global_att['SW_RUNBY'] = 
;  global_att['SVN_CHANGEDBY'] = '$LastChangedBy: davin-mac $'
;  global_att['SVN_CHANGEDATE'] = '$LastChangedDate: 2018-05-28 15:52:35 -0700 (Mon, 28 May 2018) $'
;  global_att['SVN_REVISION'] = '$LastChangedRevision: 25286 $'

return,global_att
end



function spp_gen_apdat::cdf_variable_attributes
  var_att = orderedhash()
  var_att['FIELDNAM']= ''
  var_att['MONOTON']= 'INCREASE'
  var_att['FORMAT']= ''
  var_att['FORM_PTR']= ''
  var_att['LABLAXIS']= ''
  var_att['LABL_PTR_1']= ''
  var_att['VAR_TYPE']= 'support_data'
  var_att['FILLVAL']= !values.f_nan
  var_att['DEPEND_0']= 'Epoch'
  var_att['DEPEND_1']= ''
  var_att['DISPLAY_TYPE']= ''
  var_att['VALIDMIN']= !null
  var_att['VALIDMAX']= !null
  var_att['SCALEMIN']= !null
  var_att['SCALEMAX']= !null
  var_att['UNITS']= ''
  var_att['CATDESC']= ''
  return,var_att
end




pro spp_gen_apdat::cdf_create_data_vars, fileid, var, vattributes=atts, varstr

   array = self.data.array    ; this should be an array of structures
   varnames = tag_names(array)
   ntags = n_elements(varnames)
   for i=0,ntags-1 do begin
     val = array.(i)
     spp_swp_cdf_var_att_create,fileid,varnames[i],val,attributes=atts
   endfor
  
end


pro spp_gen_apdat::cdf_create_file,cdftags=cdftags,trange=trange
  dprint,'Making CDF for ',self.name,dlevel=self.dlevel
 ; dirpathname = self.cdf_dirpathname
 ; filename = dirpathname + self.name
  global_attributes = self.cdf_global_attributes()
  if not keyword_set(trange) then trange=timerange()
  pathname = root_data_dir() + time_string(trange[0],tformat =self.cdf_pathname )
  global_attributes['Logical_file_id'] = pathname
  
  pathname = global_attributes['Logical_file_id']
  file_mkdir2,file_dirname(pathname)
  fileid = cdf_create(pathname,/clobber)
  
  foreach attvalue,global_attributes,name do begin
     dummy = cdf_attcreate(fileid,name,/global_scope)
     if keyword_set(attvalue) then cdf_attput,fileid,name,0,attvalue
  endforeach
  
  var_atts = self.cdf_variable_attributes()
  foreach att,var_atts,name do begin
    dummy = cdf_attcreate(fileid,name,/variable_scope)  ;  Variable attributes are created - but not filled
  endforeach
  
  self.cdf_create_data_vars,fileid,vattributes=var_atts
   
  cdf_close,fileid
end



function spp_gen_apdat::struct
  strct = create_struct(name=typename(self))
  struct_assign , self, strct
  return,strct
END

 
 
 
PRO spp_gen_apdat::GetProperty,data=data, array=array, npkts=npkts, apid=apid, name=name,  typename=typename, $
   nsamples=nsamples,nbytes=nbytes,strct=strct,ccsds_last=ccsds_last,tname=tname,dlevel=dlevel,ttags=ttags,last_data=last_data, $
   window=window
COMPILE_OPT IDL2
IF (ARG_PRESENT(nbytes)) THEN nbytes = self.nbytes
IF (ARG_PRESENT(name)) THEN name = self.name
IF (ARG_PRESENT(tname)) THEN tname = self.tname
IF (ARG_PRESENT(ttags)) THEN ttags = self.ttags
IF (ARG_PRESENT(apid)) THEN apid = self.apid
IF (ARG_PRESENT(npkts)) THEN npkts = self.npkts
IF (ARG_PRESENT(ccsds_last)) THEN ccsds_last = self.ccsds_last
IF (ARG_PRESENT(data)) THEN data = self.data
if (arg_present(last_data)) then last_data = *(self.last_data_p)
if (arg_present(window)) then window = self.window_obj
IF (ARG_PRESENT(array)) THEN array = self.data.array
IF (ARG_PRESENT(nsamples)) THEN nsamples = self.data.size
IF (ARG_PRESENT(typename)) THEN typename = typename(*self.data)
IF (ARG_PRESENT(dlevel)) THEN dlevel = self.dlevel
if (arg_present(strct) ) then strct = self.struct()
END
 
  
 
PRO spp_gen_apdat::SetProperty,apid=apid, _extra=ex
COMPILE_OPT IDL2
; If user passed in a property, then set it.
;if isa(name,/string) then  self.name = name
;if isa(routine,/string) then self.routine=routine
if keyword_set(apid) then dprint,'apid can not be changed!'
if keyword_set(ex) then begin
  struct_assign,ex,self,/nozero
endif
END
 
 
 
PRO spp_gen_apdat__define
void = {spp_gen_apdat, $
  inherits IDL_Object, $    ; superclass
  apid: 0u,  $
  name: '', $
  nbytes: 0UL,  $
  npkts: 0UL,  $
  process_time: 0d, $
  lost_pkts: 0UL,  $
  drate: 0. , $
  rt_flag: 0b, $
  save_flag: 0b, $
  sort_flag: 0b, $
  routine:  '', $
  tname: '',  $
  ttags: '',  $
  ccsds_last: ptr_new(), $
  last_data_p:  ptr_new(),  $
  ccsds_array: obj_new(), $  
  data: obj_new(), $
  window_obj: obj_new(), $
  cdf_pathname:'', $
  cdf_tagnames:'', $
  dlevel: 0  $
  }
END



