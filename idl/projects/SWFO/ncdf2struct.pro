
;+
; name:
;   ncdf2struct.pro
;
; purpose:
;   reads variables, parameter attributes and global attributes from
;   ncdf-files into a single idl-structure.
;
; category:
;   file handling
;
; calling sequence:
;   ncdf2struct, ncdf_file
;
; input:
;   ncdf_file : string. full filepath of ncdf file.
;   data : structure according to ncdf-file.
;
; restrictions:
;   dimension-names are not retreived.
;
; examples
;   data=ncdf2struct('c:\temp\test.ncdf')
;   help, data, /stru
;
; modification history:
;   andi christen, tu berlin, 23-aug-05, andreas.christen@tu-berlin.de
;-

function ncdf2struct, ncdf_file

    ;open ncdf-file -----------------------------------------

    if file_test(ncdf_file) eq 0 then begin
      dprint,'Unable to open ncdf file: ',ncdf_file
      return,!null
    endif
    cdfid = ncdf_open(ncdf_file)

    ;inquire ncdf-file --------------------------------------

    inq = ncdf_inquire(cdfid)

    ;resolve parameter names ---------------------------------

    for varid=0, inq.nvars-1 do begin
     varinq = ncdf_varinq(cdfid, varid)
     if varid eq 0 then begin
      var_name=varinq.name
     endif else var_name=[var_name,varinq.name]
    endfor

    ;resolve parameter values and parameter attributes --------

    for varid=0, inq.nvars-1 do begin
     varinq = ncdf_varinq(cdfid, varid)
     ncdf_varget, cdfid, varid, value
     if strlowcase(varinq.datatype) eq 'char' then value=string(value)
     if varid eq 0 then variables = create_struct(var_name[varid],value) else $
                        variables = create_struct(variables,var_name[varid],value)
     for va=0, varinq.natts-1 do begin
     vattname = ncdf_attname(cdfid, varid, va)
     var_attb_inq = ncdf_attinq(cdfid, varid, vattname)
     ncdf_attget, cdfid, varid, vattname, value
     if strlowcase(var_attb_inq.datatype) eq 'char' then value=string(value)
     variables = create_struct(variables,var_name[varid]+'_'+vattname,value)
     endfor
    endfor

    ;resolve global attributes ------------------------------

    attributes={name:'',datatype:'',length:0l}
    if inq.ngatts gt 0 then begin
    attributes=replicate(attributes,inq.ngatts)
    for a=0, inq.ngatts-1 do begin
     attn = ncdf_attname(cdfid, /global , a)
     attributes[a].name=attn
     att_stru=ncdf_attinq(cdfid,/global,attn)
     attributes[a].datatype=strupcase(att_stru.datatype)
     attributes[a].length=att_stru.length
    endfor

    for a=0,inq.ngatts-1 do begin
     ncdf_attget, cdfid, /global, attributes[a].name, value
     if strlowcase(attributes[a].datatype) eq 'char' then value=string(value)
     if a eq 0 then global_attributes = create_struct(attributes[a].name,value) else $
                    global_attributes = create_struct(global_attributes,attributes[a].name,value)
    endfor
    endif

    ;close ncdf file -----------------------------------------

    ncdf_close, cdfid

    ;merge variables / attributes into single structure ------
    
    if ~isa(variables) then variables = !null

    if inq.ngatts gt 0 then data=create_struct(global_attributes,variables) else $
    data=variables

    return, data

end