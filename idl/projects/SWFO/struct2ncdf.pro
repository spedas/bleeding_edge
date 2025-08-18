;+
; name:
;   struct2ncdf.pro
;
; purpose:
;   writes predefined structures into ncdf-files.
;
; category:
;   file handling
;
; calling sequence:
;   struct2ncdf, ncdf_file, data
;
; input:
;   ncdf_file : string. full filepath of ncdf file to be written.
;   data : any structure.
;          some restrictions apply: so substructures and
;          no string-arrays are allowed.
;
;
; side effects:
;   existing files are overwritten.
;
; modification history:
;   andi christen, tu berlin, 23-aug-05, andreas.christen@tu-berlin.de
;-

pro struct2ncdf, ncdf_file, data

  ;create new file / overwrite exiting files ----------------

  cdfid  = ncdf_create(ncdf_file, /clobber)
  nvars=n_tags(data)
  names=tag_names(data)
  dimid=intarr(nvars,8)
  varid=intarr(nvars)

  ;define dimensions and variables --------------------------

  for v=0, nvars-1 do begin
    info=size(data.(v),/stru)
    for d=0, 7 do begin
      if info.dimensions[d] gt 0 or d eq 0 then begin
        if info.dimensions[d] gt 0 then thisdimid = ncdf_dimdef(cdfid, strupcase('a')+'_'+string(v,format='(i4.4)')+string(d,format='(i1.1)'),info.dimensions[d]) else $
          thisdimid = ncdf_dimdef(cdfid, strupcase('s')+'_'+string(v,format='(i4.4)')+string(d,format='(i1.1)'),1) ; scalar
        if d eq 0 then dimsetup=thisdimid else dimsetup=[dimsetup,thisdimid]
      endif
    endfor
    case strlowcase(info.type_name) of
      'byte'  : varid[v] = ncdf_vardef(cdfid,names[v],dimsetup,/byte)
      'int'   : varid[v] = ncdf_vardef(cdfid,names[v],dimsetup,/short)
      'uint'   : varid[v] = ncdf_vardef(cdfid,names[v],dimsetup,/ushort)
      'long'  : varid[v] = ncdf_vardef(cdfid,names[v],dimsetup,/long)
      'ulong'  : varid[v] = ncdf_vardef(cdfid,names[v],dimsetup,/ulong)
      'float' : varid[v] = ncdf_vardef(cdfid,names[v],dimsetup,/float)
      'double': varid[v] = ncdf_vardef(cdfid,names[v],dimsetup,/double)
      'string': begin
        if n_elements(dimsetup) ne 1 then message, 'error: string arrays are not allowed.'
        mod_dimsetup=ncdf_dimdef(cdfid, strupcase('ma')+'_'+string(v,format='(i4.4)')+string(d,format='(i1.1)'),strlen(data.(v)[0]))
        varid[v] = ncdf_vardef(cdfid,names[v],mod_dimsetup,/char)
      end
      else: message, 'error: data type '+info.type_name+' not supported.'
    endcase
  endfor

  ;put the file in data mode ---------------------------------

  ncdf_control, cdfid, /endef

  ;put data in parameter --------------------------------------

  for v=0, nvars-1 do begin
    ncdf_varput, cdfid, varid[v], data.(v)
  endfor

  ;close ncdf file -------------------------------------------

  ncdf_close, cdfid

end