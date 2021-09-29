; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-08-29 01:20:38 -0700 (Sun, 29 Aug 2021) $
; $LastChangedRevision: 30265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ncdf_create.pro $
; $ID: $




pro swfo_ncdf_create,dat,filename=ncdf_filename

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
  types[12] = 'ushort'
  types[13] = 'ulong'
  types[15] = 'uint64'
  
 ; types[12] = 'short'  ;  Netcdf doesn't seem to accept ushort and ulong (despite documentation) - Therefore these types are redefined as signed values
 ; types[13] = 'long'
  

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
  
end


