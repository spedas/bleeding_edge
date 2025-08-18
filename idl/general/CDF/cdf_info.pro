function cdf_var_type,string
  stypes = 'CDF_'+strsplit(/extr,'XXX BYTE UINT1 INT1 CHAR UCHAR INT2 UINT2 INT4 UINT4 REAL4 FLOAT DOUBLE REAL8 EPOCH EPOCH16 LONG_EPOCH TIME_TT2000')
  vtypes = [0,1,1,1,1,1,2,12,3,13,4,4,5,5,5,9,9,14]
  type = array_union(string,stypes)
  return,(vtypes[type])[0]
end

;+
;NAME:  cdf_info
;FUNCTION:   cdf_info(id)
;PURPOSE:
;  Returns a structure with useful information about a CDF file.
;  In particular the number of file records is returned in this structure.
;INPUT:
;   id:   CDF file ID.
;CREATED BY:    Davin Larson
; $LastChangedBy: ali $
; $LastChangedDate: 2020-03-04 13:03:28 -0800 (Wed, 04 Mar 2020) $
; $LastChangedRevision: 28371 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/cdf_info.pro $
;-

function cdf_info,id0,data=ret_data,attributesf=ret_attr,verbose=verbose,convert_int1_to_int2=convert_int1_to_int2
  tstart = systime(1)
  if n_elements(id0) eq 0 then id0 = dialog_pickfile(/multi)
  vb = keyword_set(verbose) ? verbose : 0

  ;Get cdf version, hacked from read_myCDF
  CDF_LIB_INFO, VERSION=V, RELEASE=R, COPYRIGHT=C, INCREMENT=I
  cdfversion = string(V, R, I, FORMAT='(I0,".",I0,".",I0,A)')
  ;set readonly for versions prior to cdf 3.7.0
  if cdfversion Lt '3.7.0' then readonly = 1b else readonly = 0b

  ;for i=0,n_elements(id0)-1 do begin
  if size(/type,id0) eq 7 then begin
    if file_test(id0) then  id=cdf_open(id0, readonly = readonly)  $
    else begin
      if vb ge 1 then dprint,verbose=verbose,'File not found: "'+id0+'"'
      return,0
    endelse
  endif  else id=id0

  inq = cdf_inquire(id)
  CDF_COMPRESSION,id,GET_COMPRESSION=comp_level,GET_GZIP_LEVEL=gzip_level
  q = !quiet
  cdf_control,id,get_filename=fn
  ; need to add .cdf to the filename, since "cdf_control,id, get_filename="
  ;    returns the filename without the extension
  fn = fn + '.cdf'

  nullp = ptr_new()
  varinfo_format = {name:'',num:0, is_zvar:0, datatype:'',type:0, $
    ;   depend_0:'', $
    numattr:-1,  $
    ;   userflag1:0, $
    ;   userstr1:'', $
    ;   index:0,     $
    numelem:0, recvary:0b, numrec:0l, $
    comp:0, gzip:0, block:0, $
    ndimen:0, d:lonarr(6) , $
    dataptr:ptr_new(), attrptr:ptr_new()  }

  nv = inq.nvars+inq.nzvars
  vinfo = nv gt 0 ? replicate(varinfo_format, nv) : 0
  i = 0
  g_atts = cdf_var_atts(id)
  g_att_names = cdf_var_atts(id,/names_only)   ; If cdf_var_atts were modified slightly these calls could be made in parallel
  num_recs =0
  t0=systime(1)

  att=0
  for zvar = 0,1 do begin   ; regular variables first, then zvariables
    nvars = zvar ? inq.nzvars : inq.nvars
    for v = 0,nvars-1 do begin
      vi = cdf_varinq(id,v,zvar=zvar)
      vinfo[i].num = v
      vinfo[i].is_zvar = vi.is_zvar
      vinfo[i].name = vi.name
      vinfo[i].datatype = vi.datatype
      vinfo[i].type = cdf_var_type(vi.datatype)
      vinfo[i].numelem = vi.numelem
      recvar = vi.recvar eq 'VARY'
      vinfo[i].recvary = recvar
      if float(!version.release) gt 8.61 then begin ;GET_VAR_BLOCKINGFACTOR was introduced in IDL 8.6.1; this line will ensure only IDL 8.7 and above will run this
        CDF_COMPRESSION,id,VARIABLE=v,zvar=vi.is_zvar,GET_VAR_COMPRESSION=comp,GET_VAR_GZIP_LEVEL=gzip,GET_VAR_BLOCKINGFACTOR=block
        vinfo[i].comp = comp
        vinfo[i].gzip = gzip
        vinfo[i].block = block
      endif

      if recvar then begin
        ;if vb ge 6 then print,ptrace(),v,' '+vi.name
        !quiet = 1
        cdf_control,id,var=v,get_var_info=info,zvar = zvar
        !quiet = q
        ;if vb ge 7 then print,ptrace(),vi.name
        nrecs = info.maxrec+1
      endif else nrecs = -1
      vinfo[i].numrec = nrecs

      if zvar then begin
        dimen = [vi.dim]
        ndimen = total(vi.dimvar)
      endif else begin
        dimc = vi.dimvar * inq.dim
        w = where(dimc ne 0,ndimen)
        if ndimen ne 0 then dimen = dimc[w] else dimen=0
      endelse
      vinfo[i].ndimen = ndimen
      vinfo[i].d =  dimen
      ;dprint,dlevel=3,phelp=3,vi,dimen,dimc
      t2 = systime(1)
      dprint,dlevel=8,verbose=verbose,v,systime(1)-t2,' '+vi.name
      if keyword_set(ret_data) then begin
        message,'Routine not finished use cdf_load_vars'
        ;       var_type=''
        ;       str_element,attr,'VAR_TYPE',var_type
        cdf_varget,id,vi.name,value  ;,rec_count=nrecs                ;,string= var_type eq 'metadata'
        value=reform(value,/overwrite)                             ;  get rid of trailing 1's
        vinfo[i].dataptr = ptr_new(value,/no_copy)
      endif

      if keyword_set(ret_attr) then begin
        ;       attr = cdf_var_atts(id,vi.name,attribute=att, convert_int1_to_int2=convert_int1_to_int2)   ;   Slow version
        attr = cdf_var_atts(id, v,zvar=zvar,  attribute=att, convert_int1_to_int2=convert_int1_to_int2)   ; Fast Version
        vinfo[i].attrptr = ptr_new(attr,/no_copy)
      endif
      i = i+1
      dprint,dlevel=8,verbose=verbose,v,systime(1)-t0,' '+vi.name
      t0=systime(1)
    endfor
  endfor

  res = create_struct('filename',fn,'inq',inq,'compression',comp_level,'gzip_level',gzip_level,'g_attributes',g_atts,'g_att_names',g_att_names,'nv',nv,'vars',vinfo)  ;'num_recs',num_recs,'nvars',nv
  if size(/type,id0) eq 7 then cdf_close,id

  dprint,dlevel=4,verbose=verbose,'Time=',systime(1)-tstart
  return,res
end
