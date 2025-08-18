;+
; This is a wrapper routine to create CDF variables within an open CDF file.
; usage:
;  CDF_VAR_ATT_CREATE,fileid,'RandomVariable',randomn(seed,3,1000),attributes = atts
;  Attributes are contained in a structure and should have already been created.
;-
pro mvn_sep_cdf_var_att_create,fileid,varname,data,attributes=attributes,rec_novary=rec_novary,cdf_type_string=cdf_type_string

  ;if size(/type,attributes) ne 8 then attributes= {}
  if keyword_set(cdf_type_string) then type=-1 else type = size(/type,data)
  case type of
    -1: cdf_type = create_struct(cdf_type_string,1)
    0: message,'No valid data provided'
    1: cdf_type = {cdf_uint1:1}
    2: cdf_type = {cdf_int2:1}
    3: cdf_type = {cdf_int4:1}
    4: cdf_type = {cdf_float:1}
    5: cdf_type = {cdf_double:1}
    12: cdf_type = {cdf_uint2:1}
    13: cdf_type = {cdf_uint4:1}
    else: message,'Please add data type ',type,' to this case statement'
  endcase
  opts = struct(cdf_type,/zvariable,rec_novary=rec_novary)

  dim = size(/dimen,data)
  ndim= size(/n_dimen,data)
  dprint,dlevel=3,phelp=2,varname,dim,opts,data
  if ~keyword_set(rec_novary)  then  begin
    if ndim ge 2 then begin
      dim = dim[0:ndim-2]
      varid = cdf_varcreate(fileid, varname,dim ne 0, DIM=dim,_extra=opts)
    endif else begin
      varid = cdf_varcreate(fileid, varname,_extra=opts)
    endelse
  endif else  varid = cdf_varcreate(fileid, varname,dim gt 1,dimension=dim,_extra=opts,/rec_novary)


  if size(/type,attributes) eq 8 then begin
    tags= tag_names(attributes)
  endif
  for i=0,n_elements(tags)-1 do begin
    att = attributes.(i)
    if size(/type,att) eq 7 && (att eq '') then continue      ; ignore null strings
    cdf_attput,fileid,tags[i],varid,attributes.(i),/ZVARIABLE
  endfor
  cdf_varput,fileid,varname,data

end




