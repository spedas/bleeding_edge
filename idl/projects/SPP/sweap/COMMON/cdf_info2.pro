function cdf_var_type2,string
stypes = 'CDF_'+strsplit(/extr,'XXX BYTE UINT1 INT1 CHAR UCHAR INT2 UINT2 INT4 UINT4 REAL4 FLOAT DOUBLE REAL8 EPOCH EPOCH16 LONG_EPOCH TIME_TT2000')
vtypes = [0,1,1,1,1,1,2,12,3,13,4,4,5,5,5,9,9,14]
type = array_union(string,stypes)
return,(vtypes[type])[0]
end

;+
;NAME:  cdf_info2
;FUNCTION:   cdf_info2(id)
;PURPOSE:
;  Returns a HASH with useful information about a CDF file.
;  In particular the number of file records is returned in this structure.
;INPUT:
;   id:   CDF file ID or filename
;CREATED BY:    Davin Larson
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/cdf_info2.pro $
;-

function cdf_info2,files,data=ret_data,attributes=ret_attr,verbose=verbose,convert_int1_to_int2=convert_int1_to_int2
tstart = systime(1)
vb = keyword_set(verbose) ? verbose : 0
if n_elements(ret_data) eq 0 then ret_data=1

for n=0,n_elements(files)-1 do begin
  
  file = files[n]
  if size(/type,file) eq 7 then begin
    if file_test(file) then  id=cdf_open(file)  $
    else begin
      if vb ge 1 then dprint,verbose=verbose,'File not found: "'+file+'"'
      return,0
    endelse
  endif  else id=file

  inq = cdf_inquire(id)
  q = !quiet
  cdf_control,id,get_filename=fn
  ; need to add .cdf to the filename, since "cdf_control,id, get_filename="
  ;    returns the filename without the extension
  fn = fn + '.cdf'

  if 1 then begin
    varinfo_format= {cdf_tools_varinfo}
  endif else begin
    varinfo_format = { $
      name:'', $
      num:0, $
      is_zvar:0, $
      datatype:'' , $
      type:0, $
      numattr:-1,  $
      numelem:0, $
      recvary:0b, $
      numrec:0l, $
      ndimen:0, $
      d:lonarr(6) , $
      data:obj_new(), $
      attributes:obj_new()  }
  endelse


  nv = inq.nvars+inq.nzvars
  ;vinfo = nv gt 0 ? replicate(varinfo_format, nv) : 0
  vinfo = orderedhash()
  ;i = 0
  g_atts = cdf_var_atts2(id)
  ;g_att_names = cdf_var_atts(id,/names_only)   ; If cdf_var_atts were modified slightly these calls could be made in parallel
  num_recs =0
  t0=systime(1)

  att=0
  for zvar = 0,1 do begin   ; regular variables first, then zvariables
    nvars = zvar ? inq.nzvars : inq.nvars
    for v = 0,nvars-1 do begin
      vi = cdf_varinq(id,v,zvar=zvar)
      i = vi.name
      vinfo_i = varinfo_format
      vinfo_i.num = v
      vinfo_i.numattr = -1
      vinfo_i.is_zvar = zvar
      vinfo_i.name = vi.name
      vinfo_i.datatype = vi.datatype
      vinfo_i.type = cdf_var_type2(vi.datatype)
      vinfo_i.numelem = vi.numelem
      recvar = vi.recvar eq 'VARY'
      vinfo_i.recvary = recvar


      if recvar then begin
        ;if vb ge 6 then print,ptrace(),v,' '+vi.name
        !quiet = 1
        cdf_control,id,var=v,get_var_info=info,zvar = zvar
        !quiet = q
        ;if vb ge 7 then print,ptrace(),vi.name
        nrecs = info.maxrec+1
      endif else nrecs = 0
      vinfo_i.numrec = nrecs

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
      if keyword_set(ret_data) then begin
        if  nrecs ge 1 then begin
          cdf_varget,id,vinfo_i.name,value ,rec_count=nrecs    ,string= vinfo_i.numelem gt 1
          if vinfo_i.recvary then begin
            if (vinfo_i.ndimen ge 1 && n_elements(record) eq 0) then begin
              if nrecs eq 1 then begin
                dprint,dlevel=3,'Warning: Single record! ',vinfo_i.name,vinfo_i.ndimen,vinfo_i.d
                value = reform(/overwrite,value, [1,size(/dimensions,value)] )  ; Special case for variables with a single record
              endif else begin
                transshift = shift(indgen(vinfo_i.ndimen+1),1)
                value=transpose(value,transshift)
              endelse
            endif else value = reform(value,/overwrite)
            if ~obj_valid(vinfo_i.data) then  begin
              vinfo_i.data = dynamicarray(value,name=vinfo_i.name)              
            endif else begin
              vinfo_i.data.append , value
            endelse
            
          endif
          ;        if vinfo_i.ndimen ge 1 then begin
          ;          dim = vinfo_i.d[0: vinfo_i.ndimen-1]  > 1
          ;          value=reform(value,[nrecs,dim],/overwrite)                             ;  set dimensions
          ;        endif

        endif else begin
          if ~obj_valid(vinfo_i.data) then  begin
            vinfo_i.data = dynamicarray(value,name=vinfo_i.name)
          endif else begin
            vinfo_i.data.array = value
          endelse
          cdf_varget,id,vi.name,value     ,string= vinfo_i.numelem gt 1
          vinfo_i.data = dynamicarray(value,name=vinfo_i.name)
        endelse
      endif

      if 1 &&  keyword_set(ret_attr) then begin
        attr = cdf_var_atts2(id, v,zvar=zvar, convert_int1_to_int2=convert_int1_to_int2)   ; Fast Version
        vinfo_i.attributes = attr
        vinfo_i.numattr = n_elements(attr)
      endif
      vinfo[i] = vinfo_i
      ;    i = i+1
      dprint,dlevel=4,verbose=verbose,v,systime(1)-t0,' '+vi.name
      t0=systime(1)
    endfor
  endfor
  if size(/type,id) eq 7 then cdf_close,id
  
endfor    ;files


;g_att_names = (g_atts.keys()).toarray()
;g_att_names = strarr(g_atts.count())
;i = 0
;foreach v,g_atts,k do g_att_names[i++] = k    ; this avoids using a list which can cause memory leak


;res = create_struct('filename',fn,'inq',inq,'g_attributes',g_atts,'g_att_names',g_att_names,'nv',nv,'vars',vinfo)  ;'num_recs',num_recs,'nvars',nv
res = create_struct('filename',fn,'inq',inq,'g_attributes',g_atts,'nv',nv,'vars',vinfo)  ;'num_recs',num_recs,'nvars',nv
;if size(/type,id0) eq 7 then cdf_close,id0

dprint,dlevel=4,verbose=verbose,'Time=',systime(1)-tstart
return,res
end
