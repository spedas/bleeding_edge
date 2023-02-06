;+
;  swfo_GEN_APDAT
;  This basic object is the entry point for defining and obtaining all data for all apids
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-02-05 00:32:07 -0800 (Sun, 05 Feb 2023) $
; $LastChangedRevision: 31471 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_gen_apdat__define.pro $
;-
;COMPILE_OPT IDL2


FUNCTION swfo_gen_apdat::Init,apid,name,_EXTRA=ex
  COMPILE_OPT IDL2
  ; Call our superclass Initialization method.
  void = self->IDL_Object::Init()
  ;printdat,a
  self.apid  =apid
  self.dlevel = 2
  ;self.sort_flag = 1
  self.last_data_p = ptr_new(!null)
  if keyword_set(name) then begin
    self.name  =name
    ;  insttype = strsplit(self.name
    ;  self.cdf_pathname = prefix + 'sweap/spx/
  endif
  self.last_ccsds_p = ptr_new(!null)
  self.data = dynamicarray(name=self.name)
  self.ncdf_testdir = 'swfo/data/sci/test/ncdf/'
  if  keyword_set(ex) then dprint,ex,phelp=2,dlevel=self.dlevel
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  RETURN, 1
END


; Clear data and statistics of given apid
PRO swfo_gen_apdat::Clear, tplot_names=tplot_names
  COMPILE_OPT IDL2
  dprint,'clear arrays: ',self.apid,self.name,dlevel=4
  self.nbytes=0
  self.npkts = 0
  self.lost_pkts = 0
  self.ngaps = 0
  ptr_free,ptr_extract(self.data.array)
  self.data.array = !null
  ptr_free,  ptr_extract(*self.last_ccsds_p)
  *self.last_ccsds_p = !null
  if keyword_set(tplot_names) && keyword_set(self.tname) then store_data,self.tname+'*',/clear
END


PRO swfo_gen_apdat::zero
  COMPILE_OPT IDL2
  dprint,'zero counters: ',self.apid,self.name,dlevel=4
  self.nbytes=0
  self.npkts = 0
  self.lost_pkts = 0
  self.ngaps = 0
END


PRO swfo_gen_apdat::Cleanup
  COMPILE_OPT IDL2
  ; Call our superclass Cleanup method
  ptr_free,self.last_ccsds_p
  self->IDL_Object::Cleanup
END


PRO swfo_gen_apdat::help
  help,/obj,self
  printdat,self.last_data_p,varname='last_data_p'
END


pro swfo_gen_apdat::trim
  if isa(self.data.array) then self.data.trim
  *self.last_data_p=!null
  *self.last_ccsds_p=!null
end


pro swfo_gen_apdat::copy,new
  self.npkts = new.npkts
  self.nbytes = new.nbytes
  self.lost_pkts = new.lost_pkts
  self.data.array = new.data.array
end


pro swfo_gen_apdat::append,new
  if self.npkts eq 0 then begin
    self.copy,  new
  endif else begin
    self.npkts += new.npkts
    self.nbytes += new.nbytes
    self.lost_pkts += new.lost_pkts
    self.data.append, new.data.array
  endelse
end


function swfo_gen_apdat::info,header=header
  ;rs =string(format="(Z03,'x ',a-14, i8,i8 ,i12,i3,i3,i8,' ',a-14,a-36,' ',a-36, ' ',a-20,a)",self.apid,self.name,self.npkts,self.lost_pkts, $
  ;    self.nbytes,self.save_flag,self.rt_flag,self.data.size,self.data.typename,string(/print,self),self.routine,self.tname,self.save_tags)
  fmt ="(Z03,'x ',a-14, i8,i6,i8 ,i12,i3,i3,i3,i8,' ',a-14,a-26,' ',a-20,'<',a,'>','     ',a)"
  hfmt="( a4,' ' ,a-14, a8,a6,a8 ,a12,a3,a3,a3,a8,' ',a-14,a-26,' ',a-20,'<',a,'>','     ',a)"
  ;  if keyword_set(header) then rs=string(format=hfmt,'APID','Name','npkts','lost','nbytes','save','rtf','size','type','objname','routine','tname','tags')
  rs =string(format=fmt,self.apid,self.name,self.npkts,self.ngaps,self.lost_pkts, $
    self.nbytes,self.save_flag,self.rt_flag,self.dlevel,self.data.size,self.data.typestring,typename(self),self.tname,self.ttags,self.routine)

  if keyword_set(header) then rs=string(format=hfmt,'APID','Name','Npkts','gaps','lost','nbytes','sv','rt','dl','size','type','objname','tname','tags','routine') +string(13b)+ rs

  return,rs
end


PRO swfo_gen_apdat::print,dlevel=dlevel,verbose=verbose,strng,header=header
  print,self.info(header=header)
END


;pro spp_gen_apdat::store_data,  strct,pname,verbose=verbose
;  if self.rt_flag && self.rt_tags then begin
;    store_data,self.tname+pname,data=strct, tagnames=self.rt_tags, /append, verbose=0, gap_tag='GAP'
;  endif
;end


pro swfo_gen_apdat::increment_counters,ccsds,source_dict=source_dict
  ;dprint,self.apid
  self.npkts += 1
  self.nbytes += ccsds.pkt_size
  lost_pkts = ccsds.seqn_delta - 1
  if ccsds.seqn_delta gt 1 then begin
    self.lost_pkts += lost_pkts
    self.ngaps++
  endif
  ;  if ccsds.time_delta eq 0 then self.print
  ;  self.drate = ccsds.pkt_size / ( ccsds.time_delta > .001)   ; this line produce numerous floating point exceptions
  *self.last_ccsds_p = ccsds
end


; The following routine is not used for SWFO
function swfo_gen_apdat::decom_aggregate,str=str,ccsds0,source_dict=source_dict

  n = ccsds0.aggregate

  if n ne 0 then begin
    buffer  = spp_swp_ccsds_data(ccsds0)
    ccsds = ccsds0
    ccsds.aggregate =0
    ccsds.pdata = ptr_new(!null)
    strcts = !null
    new_header = buffer[0:17]
    data_size = (ccsds.pkt_size - 18) / n
    dprint,'aggregate:',n,data_size,ccsds0.apid,dlevel=self.dlevel+3
    delt=str.time_total
    ;delt = .87 * 2               ; needs fixing
    delseqn = 1                               ; needs fixing
    for i=0,n-1 do begin
      new_buffer= [new_header,buffer[18+i*data_size:18+i*data_size+data_size-1]]
      *ccsds.pdata = new_buffer
      ccsds.pkt_size = data_size +18
      pkt_size_m7= ccsds.pkt_size -7
      new_buffer[4] = ishft(pkt_size_m7 , 8)    ; fix pkt_size in header - may not be needed!
      new_buffer[5] = pkt_size_m7 and 255
      ccsds.seqn = ccsds0.seqn + i *  delseqn
      ccsds.met = ccsds0.met + i * delt
      ccsds.time = ccsds0.time + i * delt
      strct = self.decom(ccsds,source_dict=source_dict )
      if not isa(strcts) then strcts = replicate(strct,n)
      strcts[i] = strct
      if debug(self.dlevel+3) then hexprint,new_buffer,ncol=32+20
    endfor
    ptr_free,ccsds.pdata
    return,strcts
  endif else begin
    return, self.decom( ccsds ,source_dict=source_dict )
  endelse
end


function swfo_gen_apdat::decom,ccsds,source_dict=source_dict   ; general purpose - should be overloaded - does nothing special here

  strct = ccsds
  strct.pdata = ptr_new()
  ;ap = self.struct()
  ;if self.routine then  strct = call_function(self.routine,ccsds,source_dict=source_dict)   ; This mechanism is obsolete
  ;dprint,dlevel=self.dlevel+3,phelp=2,strct

  return,strct
end


function swfo_gen_apdat::decom_time,ccsds,source_dict=source_dict
  if isa(source_dict,'dictionary') && source_dict.haskey('test') && source_dict.test then begin
    ;  do nothing
  endif
  return, ccsds.ptp_time
end


pro swfo_gen_apdat::handler,ccsds,source_dict=source_dict ;,header,source_info=source_info

  if self.test && debug(self.dlevel,msg=self.name + ' handler') then begin
    ;dprint,dlevel=self.dlevel,'hi',self.apid,self.dlevel
    hexprint,*ccsds.pdata
  endif

  self.drate = ccsds.pkt_size/ccsds.time_delta

  if not self.ignore_flag then strct = self.decom(ccsds,source_dict=source_dict)
  if keyword_set(strct) then  *self.last_data_p= strct

  if self.save_flag && obj_valid(self.ccsds_array) then begin
    self.ccsds_array.append, ccsds
  endif


  if self.save_flag && obj_valid(self.data) && keyword_set(strct) then begin
    dprint,verbose=self.verbose,dlevel=4,self.name,self.apid
    self.data.append,  strct
  endif

  if self.rt_flag && keyword_set(strct) then begin
    if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]   ; insert a NAN structure as a gap
    store_data,self.tname,data=strct, tagnames=self.ttags , append = 1, gap_tag='GAP',  seperator='_'
  endif

  self.handler2,strct,source_dict=source_dict

end


pro swfo_gen_apdat::handler2,strct,source_dict=source_dict
  ;  This routine is a place holder for users. It should be overloaded
end


pro swfo_gen_apdat::sort
  datarray = self.data.array
  if keyword_set(datarray) then begin
    s = sort(datarray.time)
    datarray = datarray[s]
    self.data.array = datarray
  endif
  self.process_time = systime(1)
end

pro swfo_gen_apdat::create_tplot_vars,ttags=ttags
  dprint,dlevel=2,verbose=self.verbose,'Creating tplot variables for: ',self.name
  if ~keyword_set(ttags) then ttags = self.ttags
  dyndata = self.data
  if isa(dyndata,'dynamicarray') && keyword_set(self.tname) then begin
    store_data,self.tname,data=dyndata, tagnames=ttags, gap_tag='GAP',verbose = self.verbose
  endif
end



pro swfo_gen_apdat::finish,ttags=ttags
  if self.npkts ne 0 then self.print ,dlevel=3,'finish'
  verbose=0
  datarray = self.data.array
  if ~keyword_set(ttags) then ttags = self.ttags
  if keyword_set(datarray) && keyword_set(self.tname) then  begin
    store_data,self.tname+'_',data=datarray, tagnames=ttags,  gap_tag='GAP',verbose=verbose
    ;    options,self.tname+'*_BITS',tplot_routine='bitplot'
  endif
end


function swfo_gen_apdat::sw_version

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
    sw_hash['svn_changedate'] = '$LastChangedDate: 2023-02-05 00:32:07 -0800 (Sun, 05 Feb 2023) $'
    sw_hash['svn_revision '] = '$LastChangedRevision: 31471 $'

    return,sw_hash
end


function swfo_gen_apdat::cdf_global_attributes
  global_att=orderedhash()

  global_att['Acknowledgement'] = !NULL
  global_att['Project'] = 'LWS>Living With a Star
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
  ;  global_att['SVN_CHANGEDBY'] = '$LastChangedBy: davin-mac $'
  ;  global_att['SVN_CHANGEDATE'] = '$LastChangedDate: 2023-02-05 00:32:07 -0800 (Sun, 05 Feb 2023) $'
  ;  global_att['SVN_REVISION'] = '$LastChangedRevision: 31471 $'

  return,global_att
end


;pro swfo_gen_apdat::cdf_create_data_vars, fileid, var, vattributes=atts, varstr
;
;message,'Obsolete'
;  array = self.data.array    ; this should be an array of structures
;  if isa(array) then begin
;    varnames = tag_names(array)
;    ntags = n_elements(varnames)
;    for i=0,ntags-1 do begin
;      val = array.(i)
;      spp_swp_cdf_var_att_create,fileid,varnames[i],val,attributes=atts
;    endfor
;  endif
;
;end


;function swfo_gen_apdat::cdf_makeobj,  datavary, datanovary,  vnames=vnames, ignore=ignore,global_att=global_att,_extra=ex
;
;  cdf = cdf_tools(_extra=ex)
;  if ~keyword_set(global_att) then begin
;    global_att = orderedhash()
;    global_att['Project'] = 'PSP>Parker Solar Probe'
;  endif
;  cdf.g_attributes += global_att
;
;  fnan = !values.f_nan
;
;  ; Force Epoch as first variable. If datavary contains an EPOCH variable it will add or overwrite this value
;  epoch = time_ephemeris(datavary.time,/ut2et)                ;  may want to change this later to base it on met
;  epoch = long64(epoch * 1d9)
;  vho = cdf_tools_varinfo('Epoch',epoch[0],/recvary,all_values=epoch,datatype = 'CDF_TIME_TT2000',/set_default_atts)
;  ;  vh = vho.getattr()
;  ;  vh.data.array = epoch
;  ;  vatts =  self.cdf_variable_attributes('Epoch')
;  ;  vh.attributes  += vatts
;  ;  cdf.add_variable, vh
;  cdf.add_variable, vho
;
;  if keyword_set(datavary) then begin
;    ;    if ~keyword_set(vnames) then $
;    vnames = tag_names(datavary)   ; if vnames is passed in then there is a bug
;    datavary0 = datavary[0]   ; use first element as the template.
;
;    dlevel=5
;    for vn=0,n_elements(vnames)-1 do begin
;      vname = vnames[vn]
;      val = datavary0.(vn)
;      vals = datavary.(vn)
;      if isa(val,'pointer') then begin                ; special case for pointers
;        if vname eq 'PDATA' then vname='DATA'  ; typically counts
;        datasize = lonarr(n_elements(vals))
;        for i=0,n_elements(vals)-1 do   if ptr_valid(vals[i]) then datasize[i] = n_elements( *vals[i] )
;        maxsize = max(datasize,index)        ; determines maximum size of container
;        if maxsize eq 0 then continue
;        if maxsize gt 4096 then maxsize=4097 ;if this happens, then something is wrong with size
;        val = *vals[index]
;        ndv = n_elements(datavary)
;        ptrs = vals
;        vals = replicate(fill_nan(val[0]),[ndv,maxsize])
;        for i= 0,ndv-1 do  begin
;          v = *ptrs[i]
;          nv=n_elements(v)
;          if nv gt 4096 then begin
;            nv=4097 ;prevents cdf files to be huge due to wrong size
;            v=v[0:4096]
;            val=v
;          endif
;          vals[i,0:nv-1] = v
;        endfor
;      endif else begin
;        if n_elements(vals) gt 1 then         vals = reform(transpose(vals))
;      endelse
;      vho = cdf_tools_varinfo(vname, val, all_values=vals, /recvary,/set_default_atts)
;      ;      vh = vho.getattr()
;      ;      vh.data.array = vals
;      ;      vatt  = self.cdf_variable_attributes(vname)
;      ;      ;  dprint,dlevel=dlevel,'hello1'
;      ;      vh.attributes += vatt
;      ;      ;  dprint,dlevel=dlevel,'hello2'
;      cdf.add_variable, vho
;    endfor
;
;  endif
;
;  return,cdf
;end


pro swfo_gen_apdat::cdf_makefile,trange=trange,verbose=verbose,filename=filename,parents=parents

  ;  printdat,time_string(trange)
  datarray = self.data.array
  if ~keyword_set(datarray) then return
  if keyword_set(trange) then begin
    w= where(datarray.time ge trange[0] and datarray.time lt trange[1],/null)
    datarray = datarray[w]
  endif

  ;  str_element,datarray,'datasize',datasize
  ;  if keyword_set(datasize) then begin
  ;      w = where( datarray.ndat eq datarray.datasize,/null)
  ;      datarray = datarray[w]
  ;      if ~keyword_set(datarray) then return
  ;  endif

  if keyword_set(datarray) then begin
    g_att = self.cdf_global_attributes()
    cdf = self.cdf_makeobj(datarray,global_att=g_att)  ;, datanovary,  varnames=varnames, ignore=ignore,_extra=ex
    if ~isa(filename) then begin
      cdf_format=self.cdf_pathname
      filename=time_string(trange[0],tformat=cdf_format)
      filename=root_data_dir()+str_sub(filename,'$NAME$',self.name)
    endif
    if keyword_set(self.cdf_linkname) then cdf.linkname=root_data_dir()+self.cdf_linkname
    if keyword_set(parents) then cdf.g_attributes['Parents'] = parents
    cdf.write,filename,verbose = verbose    ; isa(verbose) ? verbose : self.verbose
    obj_destroy,cdf
  endif
end


pro swfo_gen_apdat::sav_makefile,sav_format=sav_format,parent=parent,verbose=verbose

  datarray=self.data.array
  if ~keyword_set(datarray) then return
  tr=minmax(datarray.time)
  days=long(tr/(24*60*60l))
  ndays=days[1]-days[0]
  if total(self.apid eq ['342'x,'3b8'x,'36d'x,'37d'x]) ne 0 then self.nomem ;loading from sav files repopulates the memdump ram
  for i=0,ndays do begin
    trange=24*60*60d*(days[0]+[0,1]+i)
    w=where((datarray.time ge trange[0]) and (datarray.time lt trange[1]),/null,nw)
    if nw eq 0 then continue
    self.data.array=datarray[w]
    self.data.size=nw
    self.data.name=self.name ;in case spp_swp_apdat_init updated the object name (e.g., from wrp_P5 to wrp_P5P7)
    filename=time_string(trange[0],tformat=sav_format)
    filename=root_data_dir()+str_sub(filename,'$NAME$',self.name)
    file_mkdir2,file_dirname(filename)
    dprint,dlevel=3,'Saving '+filename
    save,file=filename,self,parent,verbose=verbose,/compress
    dprint,dlevel=1,'Saved '+file_info_string(filename)
  endfor
end


pro swfo_gen_apdat::ncdf_make_file,ddata=ddata,pathname=pathname,testdir=testdir,ret_filename=ret_filename,type=type,trange=trange
  if ~isa(type) then type='l0b'
  if keyword_set(pathname) then self.ncdf_pathname = pathname
  if ~keyword_set(self.ncdf_pathname) then begin
    self.ncdf_pathname = self.name+'/'+type + '/YYYY/MM/swfo_' + self.name+'_'+type + '_YYYYMMDD_hhmm_v00.nc'
  endif

  ; More work needs to be done here to separate into daily (or hourly) files...
  ; For now just create one big file
  if ~isa(ddata) then ddata=self.data

  if keyword_set(trange) then begin
    data_array = ddata.sample(range=trange,tagname='time')
  endif else begin
    data_array = ddata.array
    trange = minmax(data_array.time)
    trange[0] = median(data_array.time)  ;  cluge to fix problem in which the time is out of bounds
  endelse
  pathname = time_string(trange[0],tformat= self.ncdf_pathname )
  filename = root_data_dir() + self.ncdf_testdir + pathname
  swfo_ncdf_create,data_array,filename = filename
  ;dprint,dlevel=1,'Created file: "'+filename+'"
  ret_filename = filename
end


function swfo_gen_apdat::struct
  strct = create_struct(name=typename(self))
  struct_assign , self, strct
  return,strct
END


PRO swfo_gen_apdat::GetProperty,data=data, array=array, npkts=npkts,lost_pkts=lost_pkts, apid=apid, name=name,  typename=typename, $
  nsamples=nsamples,nbytes=nbytes,strct=strct,ccsds_last=ccsds_last,last_ccsds=last_ccsds,tname=tname,dlevel=dlevel,ttags=ttags,last_data=last_data, $
  window=window,cdf_pathname=cdf_pathname,ccsds_raw=ccsds_raw,test=test
  COMPILE_OPT IDL2
  IF (ARG_PRESENT(nbytes)) THEN nbytes = self.nbytes
  IF (ARG_PRESENT(name)) THEN name = self.name
  IF (ARG_PRESENT(tname)) THEN tname = self.tname
  IF (ARG_PRESENT(ttags)) THEN ttags = self.ttags
  if (ARG_PRESENT(test))  then test  = self.test
  IF (ARG_PRESENT(apid)) THEN apid = self.apid
  IF (ARG_PRESENT(npkts)) THEN npkts = self.npkts
  IF (ARG_PRESENT(lost_pkts)) THEN lost_pkts = self.lost_pkts
  IF (ARG_PRESENT(ccsds_last)) THEN ccsds_last = *self.last_ccsds_p
  IF (ARG_PRESENT(last_ccsds)) THEN last_ccsds = *self.last_ccsds_p
  if (arg_present(ccsds_raw)) then ccsds_raw = *(*self.last_ccsds_p).pdata
  IF (ARG_PRESENT(data)) THEN data = self.data
  if (arg_present(last_data)) then last_data = *(self.last_data_p)
  if (arg_present(window)) then window = self.window_obj
  IF (ARG_PRESENT(array)) THEN array = self.data.array
  IF (ARG_PRESENT(nsamples)) THEN nsamples = self.data.size
  IF (ARG_PRESENT(cdf_pathname)) THEN cdf_pathname = self.cdf_pathname
  IF (ARG_PRESENT(typename)) THEN typename = typename(*self.data)
  IF (ARG_PRESENT(dlevel)) THEN dlevel = self.dlevel
  if (arg_present(strct) ) then strct = self.struct()
END


PRO swfo_gen_apdat::SetProperty,apid=apid, _extra=ex
  COMPILE_OPT IDL2
  ; If user passed in a property, then set it.
  if keyword_set(apid) then dprint,'apid can not be changed!'
  if keyword_set(ex) then begin
    struct_assign,ex,self,/nozero
  endif
END


PRO swfo_gen_apdat__define
  void = {swfo_gen_apdat, $
    inherits generic_object, $    ; superclass
    apid: 0u,  $
    name: '', $
    nbytes: 0UL,  $
    npkts: 0UL,  $
    process_time: 0d, $
    lost_pkts: 0UL,  $
    ngaps: 0UL, $
    drate: 0. , $
    rt_flag: 0b, $
    save_flag: 0b, $
    sort_flag: 0b, $
    ignore_flag: 0b, $
    cdf_flag: 0b,  $
    routine:  '', $                 ; obsolete, do not use
    tname: '',  $
    ttags: '',  $
    test: 0, $                 ; general purpose flag for use in testing
    errors: 0, $               ; error counter
    last_ccsds_p: ptr_new(), $      ; pointer to the last ccsds packet
    last_data_p:  ptr_new(),  $     ; pointer to the loast decomutated packet
    ccsds_array: obj_new(), $        ; dynamicarray to hold raw packets
    data: obj_new(), $               ; dynamicarray to hold stored data
    user_dict:  obj_new(), $         ; user definable object  (typically a dictionary)
    window_obj: obj_new(), $         ; user definable object  (typically a plot window)
    cdf_pathname:'', $
    cdf_linkname:'', $
    cdf_tagnames:'', $
    ncdf_pathname:'', $
    ncdf_tagnames:'',  $
    ncdf_testdir:'',  $      ; relative test directory name
    output_lun: 0 $
    ;    verbose: 0 , $
    ;    dlevel: 0  $
  }
END


