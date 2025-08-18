; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-07-07 17:11:41 -0700 (Mon, 07 Jul 2025) $
; $LastChangedRevision: 33434 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ncdf_read.pro $
; $ID: $


function swfo_ncdf_read,filenames=filenames,def_values=def_values,verbose=verbose,num_recs=num_recs,force_recdim=force_recdim,recdimname=recdimname

  dat = !null
  nfiles = n_elements(filenames)
  if nfiles gt 1 then begin
    dat_all = dynamicarray()
    for i=0,nfiles-1 do begin
      filename = filenames[i]
      dat_i = swfo_ncdf_read(filename=filename,def_values=def_values,force_recdim=force_recdim)
      dat_all.append,dat_i
    endfor
    return,dat_all.array
  endif

  filename = filenames[0]
  dprint,dlevel=2,verbose=verbose,'Reading: '+file_info_string(filename)
  if ~file_test(filename) then begin
    dprint,'Skipping ',filename,verbose=verbose,dlevel=1
    return,!null
  endif
  id =  ncdf_open(filename)  ;,/netcdf4_format

  inq= ncdf_inquire(id)
  
  
  ;printdat,inq
  if inq.ndims eq 0 then begin
    ncdf_close,id
    dprint,'Invalid dimensions in file: ',filename
    return,!null
  endif
  dim_sizes = replicate(-1L,inq.ndims)
  dim_names = replicate("???",inq.ndims)
  for did=0,inq.ndims-1 do begin
    ncdf_diminq,id,did,name,dimsize
    dim_sizes[did] = dimsize
    dim_names[did] = name
    dprint,dlevel=3,verbose=verbose,did,"  ",name,dimsize
  endfor
  
  if ~isa(recdimname,/string) then recdimname = 'dim_time'
  w = where(dim_names eq recdimname,/null)
  if isa(w) then inq.recdim = w[0]

  if isa(force_recdim) then inq.recdim = force_recdim   ; cluge to fix annoying definition of swfo L0 files

  if ~keyword_set(def_values) then begin
    def_values = dictionary()
    def_values['DOUBLE'] = !values.d_nan
    def_values['FLOAT'] = !values.f_nan
    def_values['INT'] = 0
    def_values['CHAR'] = ''
    def_values['UINT'] = 0u
    def_values['LONG'] = 0L
    def_values['ULONG'] = 0uL
    def_values['ULONG64'] = 0uLL
    def_values['LONG64'] = 0LL
    def_values['BYTE'] = 0B
    def_values['UBYTE'] = 0B
    def_values['STRING'] =''
  endif

  if inq.recdim ne -1 then begin
    num_recs = dim_sizes[inq.recdim]  ;number of records of the unlimited variable
  endif else num_recs = 0

  dat0 = !null
  vartypes = strarr(inq.nvars)  ; for latter ID of char arrays
  for vid=0,inq.nvars-1 do begin
    vinq = ncdf_varinq(id,vid)
    ;printdat,vinq

    ; get the datatype, ndims, and dim:
    vid_dtype = vinq.datatype
    vid_ndims = vinq.ndims
    vid_dim = vinq.dim

    ; pull the expected null value:
    val = def_values[vid_dtype]

    ; log the datatype
    vartypes[vid] = vid_dtype

    ; Decrement the ndims for CHAR -- ignore first
    ; entry that describes the # of bits (length of the string)
    if vid_dtype eq 'CHAR' then  vid_ndims = vid_ndims - 1

    if vid_ndims eq 0 then begin    ;scalers
      dat0 = create_struct(dat0,vinq.name,val)
    endif  else begin
      w = where(vid_dim ne inq.recdim,/null)  ;get the dimensions that do not vary in time
      dim_novary = vid_dim[w]
      dim = dim_sizes[dim_novary]
      ; Skip the first axis for CHAR
      if vid_dtype eq 'CHAR' then dim = dim[1:-1]
      if keyword_set(dim) then val = replicate(val,dim)
      dat0 = create_struct(dat0,vinq.name,val)
    endelse
  endfor

  ; Make # recs of the dat0 for dat or set to dat
  if num_recs gt 0 then dat = replicate(dat0,num_recs) else dat = dat0

  ; Fill in the structure:
  for vid=0, inq.nvars-1 do begin
    ncdf_varget,id,vid,values

    ; varget returns string fields as a byte array
    ; needs to be converted into string:
    if vartypes[vid] eq 'CHAR' then values = string(values)

    dat.(vid) = values

  endfor

  ncdf_close,id
  return,dat
end

