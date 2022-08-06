; $LastChangedBy: ali $
; $LastChangedDate: 2022-08-05 15:10:39 -0700 (Fri, 05 Aug 2022) $
; $LastChangedRevision: 30999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ncdf_create.pro $
; $ID: $


pro swfo_ncdf_create,dat,filename=ncdf_filename,verbose=verbose

  if ~isa(dat,'struct') then begin
    dprint,dlevel=1,verbose=verbose,'No data structure provided to save into file: '+ncdf_filename
    return
  endif

  file_mkdir2,file_dirname(ncdf_filename)
  id =  ncdf_create(ncdf_filename,/clobber,/netcdf4_format)  ;,/netcdf4_format

  tid = ncdf_dimdef(id, 'DIM_TIME', /unlimited)
  dat0=dat[0]
  types = hash()
  types[1] = 'byte'
  types[2] = 'short'
  types[3] = 'long'
  types[4] = 'float'
  types[5] = 'double'
  types[12] = 'ushort'  ; 16 bit
  types[13] = 'ulong'   ; 32 bit
  types[15] = 'uint64'

  if !version.RELEASE lt '8.7' then begin
    dprint,dlevel=0 ,'Warning this version of IDL does not seem to support unsigned integers'
    dprint,dlevel=0 ,'   Converting to signed ints'
    types[12] = 'short'  ;  Netcdf doesn't seem to accept ushort and ulong (despite documentation) - Therefore these types are redefined as signed values
    types[13] = 'long'
    types[15] = 'int64'
  endif

  tags = tag_names(dat0)
  for i=0,n_elements(tags)-1 do begin
    dd = size(/struct,dat0.(i) )
    type_struct=create_struct(types[dd.type],1)
    if dd.n_dimensions eq  0 then begin   ; scalers
      vid = ncdf_vardef(id,tags[i],tid,_extra=type_struct)
      dprint,dlevel=3,tags[i],'  ',dd.type_name,dd.type,'   ',types[dd.type],vid
    endif else begin   ; vectors
      if dd.n_dimensions gt 1 then message,'Not allowed yet!'
      dimname = 'DIM_' + tags[i]   ;+strtrim(dd.n_elements,2)
      did = ncdf_dimdef(id, dimname, dd.n_elements)
      vid = ncdf_vardef(id,tags[i],[did,tid],_extra= type_struct)
      dprint,dlevel=3,tags[i],'  ',dd.type_name,dd.type,'   ',types[dd.type],vid,did
    endelse
  endfor

  ncdf_control,id,/endef
  for i=0,n_elements(tags)-1 do begin
    dd = dat.(i)
    ; if size(/n_dimen,dd) eq 2 then dd = transpose(dd)
    ncdf_varput,id,tags[i],dd
  endfor
  ncdf_close,id

  dprint,dlevel=2,verbose=verbose,'Created file: '+file_info_string(ncdf_filename)

end
