; $LastChangedBy: davin-mac $
; $LastChangedDate: 2026-02-17 22:04:16 -0800 (Tue, 17 Feb 2026) $
; $LastChangedRevision: 34166 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ncdf_read.pro $
; $ID: $


function swfo_ncdf_read,  dynarray=dynarray, filenames=filenames $
  ,def_values=def_values $
  ,verbose=verbose,num_recs=num_recs  $
  ,force_recdim=force_recdim $
  ,recdimname=recdimname $
  ,varnames = varnames , not_varnames=not_varnames

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

  if ~isa(recdimname,/string) then recdimname = 'dim_time'


  if ~isa(dynarray,'dynamicarray') then dynarray = dynamicarray()

  if ~dynarray.dict.haskey('filehashes') then dynarray.dict.filehashes = orderedhash()


  ;dat = !null
  nfiles = n_elements(filenames)

  
  
  

  for i=0,nfiles-1 do begin

    filename = filenames[i]
    dat = !null
    dprint,dlevel=2,verbose=verbose,'Reading: '+file_info_string(filename)
    if ~file_test(filename) then begin
      dprint,'Skipping ',filename,verbose=verbose,dlevel=3
      continue
    endif
    id =  ncdf_open(filename)  ;,/netcdf4_format

    inq= ncdf_inquire(id)

    if inq.ndims eq 0 then begin
      ncdf_close,id
      dprint,'Invalid dimensions in file: ',filename,dlevel=2
      continue
    endif
    dim_sizes = replicate(-1L,inq.ndims)
    dim_names = replicate("???",inq.ndims)
    for did=0,inq.ndims-1 do begin
      ncdf_diminq,id,did,name,dimsize
      dim_sizes[did] = dimsize
      dim_names[did] = name
      dprint,dlevel=3,verbose=verbose,did,"  ",name,dimsize
    endfor

    w = where(strlowcase(dim_names) eq recdimname,/null)
    if isa(w) then inq.recdim = w[0]

    if isa(force_recdim) then inq.recdim = force_recdim   ; cluge to fix annoying definition of swfo L0 files

    if inq.recdim ne -1 then begin
      num_recs = dim_sizes[inq.recdim]  ;number of records of the unlimited variable
    endif else num_recs = 0

    dat0 = !null
    vartypes = strarr(inq.nvars)  ; for latter ID of char arrays
    vidnums = intarr(inq.nvars)
    ntags = 0
    for vid=0,inq.nvars-1 do begin
      vinq = ncdf_varinq(id,vid)
      
      if isa(varnames,/string) && ~strfilter(vinq.name, varnames,/byte,delimiter=' ',/fold_case) && (vinq.name ne 'TIME') then continue
      if isa(not_varnames,/string) && strfilter(vinq.name, not_varnames,/byte,delimiter=' ',/fold_case) && (vinq.name ne 'TIME') then continue
     
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
      vidnums[ntags++] = vid
    endfor

    ; Make # recs of the dat0 for dat or set to dat
    if num_recs gt 0 then dat = replicate(dat0,num_recs) else dat = dat0

    ; Fill in the structure:
    if 1 then begin
      for n = 0,ntags-1 do begin
        vid = vidnums[n]
        ncdf_varget,id,vid,values
  
        ; varget returns string fields as a byte array
        ; needs to be converted into string:
        if vartypes[vid] eq 'CHAR' then values = string(values)

        dat.(n) = values
      endfor
    endif else begin
      for vid=0, inq.nvars-1 do begin
        ncdf_varget,id,vid,values

        ; varget returns string fields as a byte array
        ; needs to be converted into string:
        if vartypes[vid] eq 'CHAR' then values = string(values)

        dat.(vid) = values

    endfor
    endelse

    ncdf_close,id
    ;  if isa(dynarray,'dynamicarray' then begin
    ;    dynarray.append,dat
    ;  endif else begin
      
    dynarray.append, dat

  endfor

  return,dynarray

  ; endelse
end

