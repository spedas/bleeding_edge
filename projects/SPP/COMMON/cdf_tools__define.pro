;+
; Written by Davin Larson October 2018
;  cdf_tools
;  This basic object is the entry point for reading and writing cdf files
; $LastChangedBy: ali $
; $LastChangedDate: 2022-03-29 22:14:07 -0700 (Tue, 29 Mar 2022) $
; $LastChangedRevision: 30733 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/cdf_tools__define.pro $
;
;-
;
;PRO cdf_tools::Cleanup
;  COMPILE_OPT IDL2
;  ; Call our superclass Cleanup method
;  self->IDL_Object::Cleanup
;END


;PRO cdf_tools::help
;  help,/obj,self
;END


;+
;NAME: SW_VERSION
;Function:
;PURPOSE:
; Acts as a timestamp file to trigger the regeneration of SEP data products. Also provides Software Version info for the MAVEN SEP instrument.
;Author: Davin Larson  - January 2014
; $LastChangedBy: ali $
; $LastChangedDate: 2022-03-29 22:14:07 -0700 (Tue, 29 Mar 2022) $
; $LastChangedRevision: 30733 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/cdf_tools__define.pro $
;-


function cdf_tools::sw_version

  tb = scope_traceback(/structure)
  n_tb = n_elements(tb) -1 -1   ;  subtract 1 to Use calling routine
  this_file = tb[n_tb  > 0].filename
  this_file_date = (file_info(this_file)).mtime
  login_info = get_login_info()

  sw_hash = orderedhash()

  ;sw_hash['sw_version'] =  'v00'
  sw_hash['sw_time_stamp_file'] = this_file
  sw_hash['sw_time_stamp'] = time_string(this_file_date)
  sw_hash['sw_runtime'] = time_string(systime(1))
  sw_hash['sw_runby'] = login_info.user_name
  sw_hash['sw_machine'] = login_info.machine_name
  sw_hash['cdf_svn_changedby'] = '$LastChangedBy: ali $'
  sw_hash['cdf_svn_changedate'] = '$LastChangedDate: 2022-03-29 22:14:07 -0700 (Tue, 29 Mar 2022) $'
  sw_hash['cdf_svn_revision'] = '$LastChangedRevision: 30733 $'
  sw_hash['cdf_svn_URL'] = '$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/cdf_tools__define.pro $'

  return,sw_hash
end

;function cdf_tools::default_global_attributes
;  global_att=orderedhash()
;
;  global_att['Project'] = 'PSP>Parker Solar Probe'
;  global_att['Source_name'] = 'PSP>Parker Solar Probe'
;  global_att['Acknowledgement'] = !NULL
;  global_att['TITLE'] = 'PSP SPAN Electron and Ion Flux'
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
;  global_att['Sensor'] = ' '   ;'SEP1'
;  global_att['PI_name'] = 'J. Kasper'
;  global_att['PI_affiliation'] = 'U. Michigan'
;  global_att['IPI_name'] = 'D. Larson (davin@ssl.berkeley.edu)
;  global_att['IPI_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
;  global_att['InstrumentLead_name'] = '  '
;  global_att['InstrumentLead_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
;  global_att['Instrument_type'] = 'Electrostatic Analyzer Particle Detector'
;  global_att['Mission_group'] = 'PSP'
;  global_att['Parents'] = '' ; '2018-02-17/22:17:38   202134481 ChecksumExecutableNotAvailable            /disks/data/maven/data/sci/pfp/l0_all/2018/02/mvn_pfp_all_l0_20180201_v002.dat ...
;  global_att = global_att + self.sw_version()
;
;return,global_att
;end


; default variable attributes
;function cdf_tools::cdf_variable_attributes
;  var_att = orderedhash()
;  var_att['FIELDNAM']= ''
;  var_att['MONOTON']= 'INCREASE'
;  var_att['FORMAT']= ''
;  var_att['FORM_PTR']= ''
;  var_att['LABLAXIS']= ''
;  var_att['LABL_PTR_1']= ''
;  var_att['VAR_TYPE']= 'support_data'
;  var_att['FILLVAL']= !values.f_nan
;  var_att['DEPEND_0']= 'Epoch'
;  var_att['DEPEND_1']= ''
;  var_att['DISPLAY_TYPE']= ''
;  var_att['VALIDMIN']= !null
;  var_att['VALIDMAX']= !null
;  var_att['SCALEMIN']= !null
;  var_att['SCALEMAX']= !null
;  var_att['UNITS']= ''
;  var_att['CATDESC']= ''
;  return,var_att
;end


;pro cdf_tools::create_data_vars, var, vattributes=atts, varstr
;   array = self.data.array    ; this should be an array of structures
;   if isa(array) then begin
;     varnames = tag_names(array)
;     ntags = n_elements(varnames)
;     for i=0,ntags-1 do begin
;       val = array.(i)
;       cdf_var_att_create,self.fileid,varnames[i],val,attributes=atts
;     endfor
;   endif
;end


pro cdf_tools::write,pathname,cdftags=cdftags,verbose=verbose
  t0=systime(1)
  ;  if not keyword_set(self.cdf_pathname) then return
  dprint,'starting: '+pathname,dlevel=self.dlevel+1,verbose = isa(verbose) ? verbose : self.verbose

  global_attributes = self.g_attributes

  global_attributes['cdf_svn_changedby'] = '$LastChangedBy: ali $'
  global_attributes['cdf_svn_changedate'] = '$LastChangedDate: 2022-03-29 22:14:07 -0700 (Tue, 29 Mar 2022) $'
  global_attributes['cdf_svn_revision'] = '$LastChangedRevision: 30733 $'
  global_attributes['cdf_svn_URL'] = '$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/cdf_tools__define.pro $'
  login_info = get_login_info()
  global_attributes['sw_runby'] = login_info.user_name
  global_attributes['sw_machine'] = login_info.machine_name
  global_attributes['sw_runtime'] = time_string(systime(1)) + ' UTC'

  ;  if keyword_set(trange) then begin
  ;    if not keyword_set(trange) then trange=timerange()
  ;    pathname =  spp_file_retrieve(self.cdf_pathname ,trange=trange,/create_dir,/daily_names)
  ;    global_attributes['Logical_file_id'] = str_sub(pathname,'$NAME$',self.name)
  ;
  ;    pathname = global_attributes['Logical_file_id']
  ;
  ;  endif
  if ~isa(pathname,/string) then  pathname = 'temp.cdf'
  file_mkdir2,file_dirname(pathname),add_link=self.linkname,/add_parent_link,verbose=self.verbose
  self.fileid = cdf_create(pathname,/clobber,/col_major)
  ; dprint,'Making CDF file: '+pathname,dlevel=self.dlevel,verbose=verbose

  global_attributes = self.g_attributes
  foreach attvalue,global_attributes,name do begin
    dummy = cdf_attcreate(self.fileid,name,/global_scope)
    for gentnum=0,n_elements(attvalue)-1 do begin
      if isa(attvalue[gentnum]) then begin
        if isa(/string,attvalue[gentnum]) and ~keyword_set(attvalue[gentnum]) then continue ;ignore null strings
        cdf_attput,self.fileid,name,gentnum,attvalue[gentnum]
      endif
    endfor
  endforeach

  vars = self.vars
  foreach v,vars,k do begin
    if keyword_set(k) then self.var_att_create,v
  endforeach
  ;self.create_data_vars,fileid,vattributes=var_atts

  cdf_close,self.fileid
  self.fileid = 0
  dprint,'Created in '+strtrim(systime(1)-t0,2)+' Seconds '+file_info_string(pathname)
end


;function cdf_tools::struct    ; not needed, use self.getattr()
;  strct = create_struct(name=typename(self))
;  struct_assign , self, strct
;  return,strct
;END


;PRO cdf_tools::GetProperty,data=data, array=array, npkts=npkts, apid=apid, name=name,  typename=typename, $
;   nsamples=nsamples,nbytes=nbytes,strct=strct,ccsds_last=ccsds_last,tname=tname,dlevel=dlevel,ttags=ttags,last_data=last_data, $
;   window=window
;COMPILE_OPT IDL2
;IF (ARG_PRESENT(nbytes)) THEN nbytes = self.nbytes
;IF (ARG_PRESENT(name)) THEN name = self.name
;IF (ARG_PRESENT(tname)) THEN tname = self.tname
;IF (ARG_PRESENT(ttags)) THEN ttags = self.ttags
;IF (ARG_PRESENT(apid)) THEN apid = self.apid
;IF (ARG_PRESENT(npkts)) THEN npkts = self.npkts
;IF (ARG_PRESENT(ccsds_last)) THEN ccsds_last = self.ccsds_last
;IF (ARG_PRESENT(data)) THEN data = self.data
;if (arg_present(last_data)) then last_data = *(self.last_data_p)
;if (arg_present(window)) then window = self.window_obj
;IF (ARG_PRESENT(array)) THEN array = self.data.array
;IF (ARG_PRESENT(nsamples)) THEN nsamples = self.data.size
;IF (ARG_PRESENT(typename)) THEN typename = typename(*self.data)
;IF (ARG_PRESENT(dlevel)) THEN dlevel = self.dlevel
;if (arg_present(strct) ) then strct = self.struct()
;END



;PRO cdf_tools::SetProperty,apid=apid, _extra=ex
;COMPILE_OPT IDL2
;; If user passed in a property, then set it.
;;if isa(name,/string) then  self.name = name
;;if isa(routine,/string) then self.routine=routine
;if keyword_set(apid) then dprint,'apid can not be changed!'
;if keyword_set(ex) then begin
;  struct_assign,ex,self,/nozero
;endif
;END


function cdf_tools::cdf_var_type,strng
  stypes = 'CDF_'+strsplit(/extr,'XXX BYTE UINT1 INT1 CHAR UCHAR INT2 UINT2 INT4 UINT4 REAL4 FLOAT DOUBLE REAL8 EPOCH EPOCH16 LONG_EPOCH TIME_TT2000')
  vtypes = [0,1,1,1,1,1,2,12,3,13,4,4,5,5,5,9,9,14]
  type = array_union(strng,stypes)
  return,(vtypes[type])[0]
end


pro cdf_tools::help,vname
  print_struct, self.var_info_structures()

end

;+
; This is a wrapper routine to create CDF variables within an open CDF file.
; usage:
;  CDF_VAR_ATT_CREATE,fileid,'RandomVariable',randomn(seed,3,1000),attributes = atts
;  Attributes are contained in a orderedhash and should have already been created.
;-

pro cdf_tools::var_att_create,var

  dlevel = self.dlevel+1
  fileid = self.fileid
  varname = var.name
  data = var.data
  ZVARIABLE =  1  ; force it to be a zvar
  ;  ,name=varname,data=data,attributes=attributes,rec_novary=rec_novary,datatype=datatype
  rec_novary = ~var.recvary
  if isa(data,'DYNAMICARRAY') then begin
    data=  data.array
    if var.recvary then begin  ;will need to eliminate the transpose operations
      if size(/n_dimen,data) eq 2 then data = transpose(data)
      if size(/n_dimen,data) eq 3 then begin
        ;stop
        data = transpose(data,[2,1,0])
      endif
      if size(/n_dimen,data) ge 4 then message,'Not ready'
    endif
  endif

  dim = var.d
  ndim = var.ndimen
  numrec = var.numrec
  numelem = var.numelem
  if ndim ge 1 then  dim = dim[0:ndim-1] else dim=0

  if keyword_set(var.datatype) then type=-1 else type = size(/type,data)
  case type of
    -1: cdf_type = create_struct(var.datatype,1)
    0: message,'No valid data provided'
    1: cdf_type = {cdf_uint1:1}
    2: cdf_type = {cdf_int2:1}
    3: cdf_type = {cdf_int4:1}
    4: cdf_type = {cdf_float:1}
    5: cdf_type = {cdf_double:1}
    12: cdf_type = {cdf_uint2:1}
    13: cdf_type = {cdf_uint4:1}
    else: begin
      dprint,'Please add data type '+string(type)+' to this case statement for variable: '+varname,dlevel=4
      return
    end
  endcase
  opts = {cdf_type,ZVARIABLE:ZVARIABLE,rec_novary:rec_novary,numelem:numelem}


  dprint,dlevel=self.dlevel+2,phelp=2,varname,dim,opts,data
  if ~keyword_set(rec_novary)  then  begin
    if ndim ge 1 then begin
      varid = cdf_varcreate(fileid, varname,dim ne 0, DIMENSION=dim,_extra=opts)
    endif else begin
      varid = cdf_varcreate(fileid, varname,_extra=opts)
    endelse
  endif else begin
    if ndim ge 1 then begin
      varid = cdf_varcreate(fileid, varname,dim gt 1,dimension=dim,_extra=opts)
    endif else begin
      varid = cdf_varcreate(fileid, varname,_extra=opts)
    endelse
  endelse

  if isa(data) then begin
    cdf_varput,fileid,varname,data
  endif else begin
    dprint,dlevel=self.dlevel,'Warning! No data written for '+varname
  endelse


  if isa(var.attributes,'ORDEREDHASH')  then begin
    foreach value,var.attributes,attname do begin
      if not keyword_set(attname) then continue ;ignore null strings
      if ~cdf_attexists(fileid,attname) then begin
        dummy = cdf_attcreate(fileid,attname,/variable_scope)
        dprint,verbose=verbose,dlevel=dlevel,'Created new Attribute: ',attname, ' for: ',varname
      endif
      if isa(value) then begin
        if isa(/string,value) and ~keyword_set(value) then continue ;ignore null strings
        cdf_attput,fileid,attname,varname,value,CDF_TIME_TT2000=(varname eq 'Epoch' && typename(value) eq 'LONG64')  ;,ZVARIABLE=ZVARIABLE
      endif
    endforeach
  endif else dprint,dlevel=1,'Warning! No attributes for '+varname

end


;  return an array of structures
function cdf_tools::get_var_struct,  names, struct0=struct0,add_time = add_time
  if self.nvars eq 0 then return, !null
  if not keyword_set(names) then begin
    names = self.varnames()
    vary = bytarr(n_elements(names))
    foreach nam,names,i do begin
      vary[i] = self.vars[nam].recvary
    endforeach
    names = names[where(vary,/null)]
  endif
  ;if isa(struct0,'STRUCT') then strct0 = !null
  if keyword_set(add_time) then str_element,/add,strct0,'TIME',!values.d_nan
  numrec = 0
  for i=0,n_elements(names)-1 do begin   ;    define first record structure;
    vi = self.vars[names[i]]
    ;  val = vi.data.array
    if vi.ndimen ge 1 then begin
      dim = vi.d
      dim = dim[where(dim ne 0)]
      val = make_array(type=vi.type,/nozero,  dimension=dim)
    endif else begin
      val = make_array(type=vi.type,1,/nozero)
      val = val[0]
    endelse
    str_element,/add,strct0, names[i],val
    if numrec ne 0 then begin
      if numrec ne vi.numrec then dprint,'Warning! wrong number of records: ', names[i]
    endif
    numrec = numrec > vi.numrec    ; get largest record size
  endfor

  ;if numrec eq 1 then stop
  strct_n = replicate(strct0,numrec)
  for i=0,n_elements(names)-1 do begin
    vi = self.vars[names[i]]
    vals = vi.data.array
    ;  dprint,size(/n_dimen,vals),names[i]
    if size(/n_dimen,vals) ge 2 then begin   ; need a correction if ndimen >= 3
      vals = transpose(vals) ;will need to eliminate this
    endif  else if numrec eq 1 then vals = vals[0]
    str_element,/add,strct_n,names[i], vals
  endfor

  if keyword_set(add_time) then begin
    time = time_ephemeris(strct_n.epoch / 1d9 ,/et2ut)
    strct_n.time = time
  endif

  return,strct_n
end


pro cdf_tools::filter_variables, index
  ;  vnames = self.vars.keys()
  foreach var,self.vars,vname do begin
    if var.recvary then begin
      array = var.data.array
      if (size(array,/dim))[0] le max(index) then message,'Attempt to subscript ARRAY with INDEX out of range.'
      case var.ndimen of
        0:  var.data.array = array[index]
        1:  var.data.array = array[index,*]
        2:  var.data.array = array[index,*,*]
        3:  var.data.array = array[index,*,*,*]
      endcase
      var.numrec = n_elements(index)
      self.vars[vname] = var
      dprint,vname,var.numrec,dlevel=3 ;,var.data.size
    endif
  endforeach
end


pro cdf_tools::add_variable,vi
  if isa(vi,'OBJREF') then begin
    self.vars[vi.name] = vi.getattr()
    return
  endif
  self.vars[vi.name] = vi
end


function cdf_tools::datavary_struct,varnames=varnames
  strct0 = !null
  maxrec = 0
  foreach v,self.vars,k do begin
    maxrec = maxrec > v.numrec
    if 1 then begin
      printdat,v
      dat0 = make_array(type = v.type,dimension=v.d[0:v.ndimen-1 > 0] > 1 )
      if v.ndimen eq 0 then dat0 = dat0[0]
      printdat,dat0
    endif else begin
      dat=v.data.array
      printdat,v
      case v.ndimen of
        0: dat0= dat[0]
        1: dat0= reform(dat[0,*])
        2: dat0= reform(dat[0,*,*])
        3: dat0= reform(dat[0,*,*,*])
      endcase
    endelse
    strct0 = create_struct(strct0,k,dat0)
  endforeach
  strct = replicate(strct0,maxrec)
  foreach v,self.vars,k do begin
    dat=v.data.array
    strct.(k) = transpose(dat) ;will need to eliminate this
  endforeach

  printdat,strct

  return,strct
end


function cdf_tools::varnames,namematch,data=data
  vnames = self.vars.keys()
  l=list()
  depend = list()
  if isa(data) then begin
    foreach v,self.vars,k do begin
      if v.attributes.haskey('VAR_TYPE') && v.attributes['VAR_TYPE'] eq 'data' then begin
        l.add ,k  ; v.attributes['VAR_TYPE'].name
        if v.attributes.haskey('DEPEND_0') then depend.add, v.attributes['DEPEND_0']
        if v.attributes.haskey('DEPEND_1') then depend.add, v.attributes['DEPEND_1']
        if v.attributes.haskey('DEPEND_2') then depend.add, v.attributes['DEPEND_2']
      endif
    endforeach
    depend = depend.sort()
    depend = depend[ uniq( depend.toarray() ) ]
    l.add, depend
    return, l.toarray()

  endif
  return,vnames.toarray()

end


;
;function cdf_tools_var_type2,string
;  stypes = 'CDF_'+strsplit(/extr,'XXX BYTE UINT1 INT1 CHAR UCHAR INT2 UINT2 INT4 UINT4 REAL4 FLOAT DOUBLE REAL8 EPOCH EPOCH16 LONG_EPOCH TIME_TT2000')
;  vtypes = [0,1,1,1,1,1,2,12,3,13,4,4,5,5,5,9,9,14]
;  type = array_union(string,stypes)
;  return,(vtypes[type])[0]
;end


pro cdf_tools::read,filenames

  tstart = systime(1)
  ret_data=1
  if 0 then begin
    info2 = cdf_info2(filenames,/attri,/data)
    self.filenames.add,filenames
    self.filename = info2.filename
    *self.inq_ptr = info2.inq
    self.g_attributes = info2.g_attributes
    ;   self.nv  = info.nv
    if 1 then begin               ; info2 not working yet ????
      self.vars = info2.vars
    endif else begin
      info = cdf_load_vars(filename,varformat='*')   ; get all variables for now
      for i= 0,n_elements(info.vars)-1 do begin
        v = info.vars[i]
        if ptr_valid(v.dataptr) then values = *v.dataptr else values = !null
        vho = cdf_tools_varinfo(v.name,all_values=values,recvary=v.recvary)
        attr = *v.attrptr
        tagnames = tag_names(attr)
        for j=0,n_elements(tagnames)-1 do begin
          vho.attributes[tagnames[j]] = attr.(j)
        endfor
        self.add_variable,vho
      endfor
      ptr_free,info.vars.dataptr
      prt_free,info.vars.attrptr
    endelse
  endif else begin
    for n=0,n_elements(filenames)-1 do begin
      file = filenames[n]
      if file_test(file) then  self.fileid=cdf_open(file)      else begin
        dprint,dlevel=2,verbose=verbose,'File not found: '+file
        continue
      endelse
      ;   res = create_struct('filename',fn,'inq',inq,'g_attributes',g_atts,'nv',nv,'vars',vinfo)  ;'num_recs',num_recs,'nvars',nv
      dprint,dlevel=1,verbose=verbose,'Loading '+file_info_string(file)

      inq = cdf_inquire(self.fileid)
      q = !quiet
      nv = inq.nvars+inq.nzvars
      vinfo = self.vars   ;      vinfo = orderedhash()

      self.filename = file
      *self.inq_ptr = inq
      self.filenames.add,file
      self.nvars = nv
      self.g_attributes = cdf_var_atts2(self.fileid)   ; global attributes
      num_recs =0
      t0=systime(1)

      ; should make a check here to insure the same file type is loaded

      varinfo_format= {cdf_tools_varinfo}
      for zvar = 0,1 do begin   ; regular variables first, then zvariables
        nvars = zvar ? inq.nzvars : inq.nvars
        for v = 0,nvars-1 do begin
          vi = cdf_varinq(self.fileid,v,zvar=zvar)
          vname = vi.name
          if ~self.vars.haskey(vname) then begin
            vinfo_i = varinfo_format
            vinfo_i.data = dynamicarray(name=vname)
          endif    else begin
            vinfo_i = self.vars[vname]
            ; should make a check here to insure the same var type is loaded
          endelse
          vinfo_i.num = v
          vinfo_i.numattr = -1
          vinfo_i.is_zvar = zvar
          vinfo_i.name = vi.name
          vinfo_i.datatype = vi.datatype
          vinfo_i.type = self.cdf_var_type(vi.datatype)
          vinfo_i.numelem = vi.numelem
          recvar = vi.recvar eq 'VARY'
          vinfo_i.recvary = recvar

          if recvar then begin
            ;            !quiet = 1
            cdf_control,self.fileid,var=v,get_var_info=info,zvar = zvar
            ;            !quiet = q
            ;if vb ge 7 then print,ptrace(),vi.name
            nrecs = info.maxrec+1
          endif else nrecs = 0
          vinfo_i.numrec += nrecs

          if zvar then begin
            dimen = [vi.dim]
            ndimen = total(/preserve,vi.dimvar)
          endif else begin
            dimc = vi.dimvar * inq.dim
            w = where(dimc ne 0,ndimen)
            if ndimen ne 0 then dimen = dimc[w] else dimen=0
            dprint,'Warning!  rvars not debugged',dlevel=1
          endelse
          vinfo_i.ndimen = ndimen
          vinfo_i.d =  dimen
          ;dprint,dlevel=3,phelp=3,vi,dimen,dimc
          t2 = systime(1)
          dprint,dlevel=4,verbose=verbose,v,systime(1)-t2,' '+vi.name

          if 1 ||  keyword_set(ret_attr) then begin                                                      ; Get attributes first
            attr = cdf_var_atts2(self.fileid, v,zvar=zvar, convert_int1_to_int2=convert_int1_to_int2)   ; Fast Version
            vinfo_i.attributes = attr
            vinfo_i.numattr = n_elements(attr)
          endif

          if keyword_set(ret_data) then begin    ; Get data
            if  nrecs ge 1 then begin
              cdf_varget,self.fileid,vinfo_i.name,value ,rec_count=nrecs    ,string= vinfo_i.numelem gt 1
              if vinfo_i.recvary then begin
                if (vinfo_i.ndimen ge 1 && n_elements(record) eq 0) then begin
                  if nrecs eq 1 then begin
                    dprint,dlevel=3,'Warning: Single record! ',vinfo_i.name,vinfo_i.ndimen,vinfo_i.d
                    value = reform(/overwrite,value, [1,size(/dimensions,value)] )  ; Special case for variables with a single record
                  endif else begin
                    transshift = shift(indgen(vinfo_i.ndimen+1),1)
                    value=transpose(value,transshift) ;will need to eliminate this
                  endelse
                endif else value = reform(value,/overwrite)

              endif
              vinfo_i.data.append , value

            endif else begin   ; not record varying
              cdf_varget,self.fileid,vi.name,value     ,string= vinfo_i.numelem gt 1
              vinfo_i.data.array = value
            endelse
          endif
          vinfo[vname] = vinfo_i
          dprint,dlevel=4,verbose=verbose,v,systime(1)-t0,' '+vi.name
          t0=systime(1)
        endfor
      endfor
      cdf_close,self.fileid
      self.fileid = 0
    endfor    ;files

    dprint,dlevel=3,verbose=verbose,'Time=',systime(1)-tstart
    return

  endelse
end


pro cdf_tools::add_time,epochname
  if ~isa(epochname) then epochname = 'Epoch'
  if self.vars.haskey(epochname) then begin
    ;printdat,self.vars[epochname]
    epvar = self.vars[epochname]
    tt_2000 = epvar.data.array
    tt_2000_d = epvar.data.array / 1d9
    if epvar.attributes.haskey('FILLVAL') then begin
      fval =  epvar.attributes['FILLVAL']
      w = where(tt_2000 eq fval,/null)
      tt_2000_d[w] = !values.d_nan
    endif
    time = time_ephemeris(/et2ut,tt_2000 )
    vt = cdf_tools_varinfo('TIME',time[0],all_values=time,/set_default_atts,/recvary)
    self.add_variable,vt
  endif else begin
    dprint,epochname+ ' not found'
  endelse

end


pro cdf_tools::fill_nan,names

  foreach v,self.vars  do begin
    if v.attributes.haskey('FILLVAL') && isa(*v.data.ptr,/float) then begin
      dprint,dlevel=3,v.name
      fval = v.attributes['FILLVAL']
      w = where( *v.data.ptr eq fval,/null,nw)
      (*v.data.ptr)[w] = !values.f_nan
      if isa(w) then begin
        v.attributes['FILLVAL'] = (*v.data.ptr)[w[0]]
      endif
    endif
  endforeach
end



function cdf_tools::var_info_structures   ; not ready yet

  if self.vars.count gt 0 then begin
    strct = replicate( {cdf_tools_varinfo},self.vars.count )
    i = 0
    foreach v,self.vars,vname do begin
      strct[i++] = v
    endforeach
    return,strct
  endif
  return,!null

end

function cdf_tools::get_variable_structure,varns
  namelist = self.vars.keys()
  vars=!null
  foreach v,varns do begin
    if isa(/string,v) then vstruct = self.vars[varns]
    if isa(/number,v) then vstruct = self.vars[namelist[v]]
    vars = [vars,vstruct]
  endforeach
  return,vars
end


pro cdf_tools::load_variables_from_structure,datavary,names=vnames

  ;  if ~keyword_set(global_att) then begin
  ;    global_att = orderedhash()
  ;    global_att['Project'] = 'PSP>Parker Solar Probe'
  ;  endif
  ;  cdf.g_attributes += global_att

  fnan = !values.f_nan


  ;  vho = cdf_tools_varinfo('Epoch',epoch[0],/recvary,all_values=epoch,datatype = 'CDF_TIME_TT2000',/set_default_atts)
  ;  cdf.add_variable, vho

  if keyword_set(datavary) then begin
    ;    if ~keyword_set(vnames) then $
    vnames = tag_names(datavary)   ; if vnames is passed in then there is a bug
    datavary0 = datavary[0]   ; use first element as the template.

    dlevel=5
    for vn=0,n_elements(vnames)-1 do begin
      vname = vnames[vn]
      val = datavary0.(vn)
      vals = datavary.(vn)
      if isa(val,'pointer') then begin                ; special case for pointers
        if vname eq 'PDATA' then vname='DATA'  ; typically counts
        datasize = lonarr(n_elements(vals))
        for i=0,n_elements(vals)-1 do   if ptr_valid(vals[i]) then datasize[i] = n_elements( *vals[i] )
        maxsize = max(datasize,index)        ; determines maximum size of container
        if maxsize eq 0 then continue
        val = *vals[index]
        ndv = n_elements(datavary)
        ptrs = vals
        vals = replicate(fill_nan(val[0]),[ndv,maxsize])
        for i= 0,ndv-1 do  begin
          v = *ptrs[i]
          vals[i,0:n_elements(v)-1] = v
        endfor
      endif else begin
        if n_elements(vals) gt 1 then  begin
          vals = reform(transpose(vals)) ;may not be what we want for multi-dimensional arrays, will need to eliminate this
        endif
      endelse
      vho = cdf_tools_varinfo(vname, val, all_values=vals, /recvary,/set_default_atts)
      self.add_variable, vho
    endfor

  endif

end


pro cdf_tools::make_tplot_var,varnames,prefix=prefix

  default_epoch = 'epoch'
  if ~keyword_set(prefix) then prefix = ''
  foreach vname,varnames do begin

    if self.vars.haskey(vname) then begin
      var_str = self.vars[vname]
      depend_0 = default_epoch
      str_element,var_str.attributes,'DEPEND_0',depend_0
      time_str = self.vars[depend_0]
      time = time_ephemeris(time_str.data.array / 1d9,/et2ut)
      store_data,prefix+vname,time,var_str.data.array
    endif else begin
      dprint , var ,' not found'
    endelse

  endforeach

end


pro cdf_tools::copy,new
  self.filename = new.filename
  self.linkname = new.linkname
  self.filenames= (new.files)[*]
  self.G_attributes = (new.G_attributes)[*]
  self.nvars = new.nvars
  self.vars = (new.vars)[*] ;needs fixing. still results in cloning of DATA and ATTRIBUTES within the "vars" keys.
end


PRO cdf_tools::GetProperty,filename=filename,linkname=linkname,files=files,G_attributes=G_attributes,nvars=nvars,vars=vars
  COMPILE_OPT IDL2
  IF (ARG_PRESENT(filename)) THEN filename = self.filename
  IF (ARG_PRESENT(linkname)) THEN linkname = self.linkname
  IF (ARG_PRESENT(files))THEN files= self.filenames
  IF (ARG_PRESENT(G_attributes)) THEN G_attributes = self.G_attributes
  IF (ARG_PRESENT(nvars)) THEN nvars = n_elements(self.vars)
  IF (ARG_PRESENT(vars)) THEN vars = self.vars
END


FUNCTION cdf_tools::Init,filenames,_EXTRA=ex
  COMPILE_OPT IDL2
  ; Call our superclass Initialization method.
  void = self.generic_Object::Init(_extra=ex)
  self.inq_ptr = ptr_new(!null)
  self.filenames = list()
  self.g_attributes = orderedhash()
  self.vars = orderedhash()
  if keyword_set(name) then begin
    self.name  =name
    ;  insttype = strsplit(self.name
    ;  self.cdf_pathname = prefix + 'sweap/spx/
  endif
  ; self.data = dynamicarray(name=name)
  ;  self.dlevel = 3
  ;  if debug(3) and keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  self.read,filenames
  RETURN, 1
END


PRO cdf_tools__define
  void = {cdf_tools, $
    inherits generic_object, $    ; superclass
    filename: '',  $
    linkname: '',  $
    filenames: obj_new(), $
    fileid:  0uL,  $
    inq_ptr:  ptr_new() ,  $          ; pointer to inquire structure
    G_attributes: obj_new(),  $     ; ordered hash
    nvars: 0, $
    vars:  obj_new() $
  }

END