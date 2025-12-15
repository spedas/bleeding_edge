; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-12-10 09:47:58 -0800 (Wed, 10 Dec 2025) $
; $LastChangedRevision: 33913 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ncdf_create.pro $
; $ID: $


pro swfo_ncdf_create,dat,filename=ncdf_filename,verbose=verbose,global_atts=global_atts,ncdf_template=ncdf_template,append=append

  if keyword_set(global_atts) then begin
    gkeys = global_atts.keys()
  endif

  if ~isa(ncdf_filename,/string) then ncdf_filename = 'temp'



  if ~isa(dat,'struct') then begin
    dprint,dlevel=1,verbose=verbose,'No data structure provided to save into file: '+ncdf_filename
    return
  endif else begin
    dat0=dat[0]
    tags = tag_names(dat0)
  endelse

  file_mkdir2,file_dirname(ncdf_filename)
  if keyword_set(ncdf_template) then begin
    file_copy,ncdf_template,ncdf_filename

  endif else begin

    if keyword_set(append) then begin
      if file_test(ncdf_filename) then begin
        dat_da = swfo_ncdf_read(filenames = ncdf_filename)
        dat_old =dat_da.array
        if ~isa(dat_old) || array_equal( dat_old.time,dat.time) then begin
          dprint,dlevel=2,'No new : "'+ncdf_filename+'"  Skipping append'
          return
        endif
        if n_tags(/length,dat) ne n_tags(/length,dat_old) then begin
          dprint,'New format for ncdf_filename'
        endif
        dat_new = replicate(dat[0],n_elements(dat_old))
        struct_assign,dat_old,dat_new,/verbose
        ;        if array_equal(dat_new.time,dat.time) && n_tags(/length,dat_old then begin
        ;          dprint,dlevel=2,'No new data for file: '+ncdf_filename+'  Skipping append'
        ;          return
        ;        endif
        dat = [dat_new,dat]
        s= sort(dat.time)
        dat = dat[s]
        u= uniq(dat.time)
        dat = dat[u]
      endif
    endif
    id =  ncdf_create(ncdf_filename,/clobber,/netcdf4_format)  ;,/netcdf4_format

    tid = ncdf_dimdef(id, 'DIM_TIME', /unlimited)
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

    n_structs = n_elements(dat)
    for i=0,n_elements(tags)-1 do begin
      dd = size(/struct,dat0.(i) )
      if ~types.haskey(dd.type) then begin
        dprint,dlevel=3,'skipping ',tags[i]+'  '+dd.type_name
        continue
      endif
      type_struct=create_struct(types[dd.type],1)
      case dd.n_dimensions of
;        0: begin
;          dprint,'scaler structure not tested yet'
;          dd.dimensions[0]=1
;          dd.n_dimensions = 1
;          dimids = tid
;        end
        0: begin
          dimids = tid
          chunk = n_structs
        end
        1: begin
          dimname = 'DIM_' + tags[i]
          did = ncdf_dimdef(id, dimname, dd.dimensions[0])
          dimids = [did,tid]
          chunk = [dd.dimensions[0], n_structs]
        end
        else:  message, 'Not allowed yet!'
      endcase
      ;chunk = dd.dimensions[0:dd.n_dimensions-1]
      vid = ncdf_vardef(id,tags[i],dimids,_extra= type_struct,chunk_dimen = chunk)
      dprint,dlevel=3,tags[i],'  ',dd.type_name,dd.type,'   ',types[dd.type],dimids,chunk

    endfor
    
    ncdf_control,id,/endef
    dprint,dlevel=3,'Done with ncdf define for ',ncdf_filename

  endelse

  for i=0,n_elements(tags)-1 do begin
    dd = size(/struct,dat0.(i) )
    if ~types.haskey(dd.type) then begin
      dprint,dlevel=3,'skipping ',dd.type_name
      continue
    endif
    dati = dat.(i)
    ;if size(/n_dimen,dati) eq 2 then dati = transpose(dati)
    ncdf_varput,id,tags[i],dati
    dprint,dlevel=3,tags[i],size(dati)
  endfor
  dprint,dlevel=3,'Done with varput(s)'
  ncdf_close,id


  dprint,dlevel=2,verbose=verbose,'Created file: '+file_info_string(ncdf_filename)

end
