pro swfo_load,make=make,trange=trange,types=types,current=current,datahash=datahash,resolution=resolution,file_hashes=file_hashes

  if keyword_set(make) then begin
    
    if make eq 2 then begin
      if ~keyword_set(trange) then trange = time_double(['2025 9 24','now'])
      res = 3600d  *24  ; 1 day
      days = floor(trange/res)
      ndays = trange[1] - trange[0] +1
      ;types = ['sc_100','sc_110','stis_hkp2','stis_sci','stis_nse','mag8','mag64']

      for day= days[0],ndays do begin
        tr= (day +[0,1]) *res 
        swfo_ccsds_frame_read,trange=tr,merge=0,reader=rdr,user_pass='davin:port'
        dh=!null
        
        swfo_load,/make,datahash=dh,types=types,resolution=res,file_hashes=rdr.dyndata
        foreach d,dh do begin
          d.size = 0      ;clear contents of dynamic arrays
        endforeach   ; data type
        dprint,time_string(tr)
        
      endfor   ; day
      stop
      return
    endif
    
    
    
    
    if ~keyword_set(datahash) then begin
      datahash= orderedhash()
      objs = swfo_apdat()
      foreach obj,objs do begin
        if keyword_set(obj.name) then begin
          datahash[obj.name] = obj.data
        endif
      endforeach
      datahash['file_hashes'] =file_hashes
    endif
    
 ;   if n_elements(trange) ne 2 then trange =[time_double('2025-9-23'),systime(1) ]   ;+ [-1,0] * 3600d *24 * current
;    n = n_elements(objs)
    foreach da,datahash,key do begin
      if isa(da,'dynamicarray') then begin
        if da.size gt 0 then begin
          dprint,key,' ',da.name,da.size
          da.ncdf_make_file,/append ,trange=trange,resolution=resolution
        endif
      endif
    endforeach
    return
  endif

  ;if ~keyword_set(current) then current=6
  if n_elements(trange) ne 2 then trange=timerange(trange)   ;systime(1) + [-1,0]*3600d*24*current

  if ~keyword_set(types) then begin
    types = ['sc_100','sc_110','stis_hkp2','stis_sci','stis_nse','mag8','mag64']
  endif

  if ~isa(datahash,'hash') then datahash=orderedhash()

  root_dir = root_data_dir()+'swfo/data/test/'
  foreach type,types do begin
    if datahash.haskey(type) then dynarray = datahash[type] else dynarray= !null
    da = swfo_ncdf_read(trange=timerange(trange),dynarray=dynarray,name=type,root_dir=root_dir)
    da.trim
    da.sort,/uniq
    dprint,da,da.name,da.size
    ;help,da
    store_data,'swfo_'+type,data=da,tagnames='*'
   
    datahash[type] = da
    
  endforeach




end
