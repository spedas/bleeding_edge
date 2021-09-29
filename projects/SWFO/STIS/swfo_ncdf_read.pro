; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-08-29 01:20:38 -0700 (Sun, 29 Aug 2021) $
; $LastChangedRevision: 30265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ncdf_read.pro $
; $ID: $




function swfo_ncdf_read,filename=filename,def_values=def_values
  id =  ncdf_open(filename)  ;,/netcdf4_format
  dat = !null

  inq= ncdf_inquire(id)
 ; printdat,inq
;stop
  dim_sizes = replicate(-1L,inq.ndims)
  dim_names = replicate("???",inq.ndims)
  for did=0,inq.ndims-1 do begin
    ncdf_diminq,id,did,name,dimsize
    dim_sizes[did] = dimsize
    dim_names[did] = name
    dprint,dlevel=3,verbose=verbose,did,"  ",name,dimsize
  endfor
  
  if ~keyword_set(def_values) then begin
    def_values = dictionary()
    def_values['DOUBLE'] = !values.d_nan
    def_values['FLOAT'] = !values.f_nan
    def_values['INT'] = 0
    def_values['UINT'] = 0u
    def_values['LONG'] = 0L
    def_values['ULONG'] = 0uL
    def_values['ULONG64'] = 0uLL
    def_values['BYTE'] = 0B
  endif
  
  if inq.recdim ne -1 then begin
    num_recs = dim_sizes[inq.recdim]   ; number of records of the unlimited variable    
  endif else    num_recs = 0

  dat0 = !null
  for vid=0,inq.nvars-1 do begin
    vinq = ncdf_varinq(id,vid)
 ;   printdat,vinq
    val = def_values[vinq.datatype]
    if vinq.ndims eq 0 then begin            ; scalers
      dat0 = create_struct(dat0,vinq.name,val)
    endif  else begin
      w = where(vinq.dim ne inq.recdim,/null)               ; get the dimensions that do not vary in time
      dim_novary = vinq.dim[w]
      dim = dim_sizes[dim_novary]
      if keyword_set(dim) then val = replicate(val,dim)
      dat0 = create_struct(dat0,vinq.name,val)
    endelse
  endfor
  
  dat = replicate(dat0,num_recs)
  
  for vid=0, inq.nvars-1 do begin
    ncdf_varget,id,vid,values
    dat.(vid) = values
  endfor
  ncdf_close,id
  return,dat
end





