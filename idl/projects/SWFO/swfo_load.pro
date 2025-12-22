pro swfo_load,make=make,trange=trange,types=types,current=current,datahash=datahash,resolution=resolution,file_hashes=file_hashes,user_pass=user_pass


  if isa(user_pass,'string') then setenv,'SWFO_USER_PASS='+user_pass

  swfo_user_pass = getenv('SWFO_USER_PASS')
  
  pathname0 = 'swfo/data/test2/NCDF/$NAME$/DAY/YYYY/MM/$NAME$_YYYY-MM-DD.nc'



  source = {$
    remote_data_dir:'http://sprg.ssl.berkeley.edu/data/', $
    local_data_dir:root_data_dir(),  $
    master_file:'swfo/.master', $
    min_age_limit :100,$
    no_update : 0 ,$
    no_download :0 ,$
    user_pass:  swfo_user_pass, $
    resolution: 3600d*24  }

  if keyword_set(make) then begin
    
 
    if make eq 3 then begin
      message ,'Not ready yet'
      
    endif
    
    
    if make eq 2 then begin
      if ~keyword_set(trange) then trange = time_double(['2025 9 24','now'])
      if ~keyword_set(res) then res = 24*3600d  ;3600d
      ;res = 3600d  *24  ; 1 day
      tints = floor(time_double(trange)/res)
      nt = tints[1] - tints[0] +1
      ;types = ['sc_100','sc_110','stis_hkp2','stis_sci','stis_nse','mag8','mag64']

      for tint= tints[0],tints[1]+1 do begin
        tr= (tint +[0,1]) *res 
        swfo_ccsds_frame_read,trange=tr,merge=0,reader=rdr,user_pass=getenv('SWFO_USER_PASS')  
        dh=!null
        
        swfo_load,/make,datahash=dh,types=types,resolution=res,file_hashes=rdr.dyndata
        foreach d,dh do begin
          d.size = 0      ;clear contents of dynamic arrays
        endforeach   ; data type
        dprint,time_string(tr)
        
      endfor   ; day
      
      return
    endif           ; end of make eq 2
    
    
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
          da.ncdf_make_file,/append ,trange=trange,resolution=resolution, pathformat=pathname0
        endif
      endif
    endforeach
    return
  endif         ; End of make
  
  
  
  
  
;  Start of load
  
  
  

  ;if ~keyword_set(current) then current=6
  if n_elements(trange) ne 2 then trange=timerange(trange)   ;systime(1) + [-1,0]*3600d*24*current

  if ~keyword_set(types) then begin
    types = ['sc_100','sc_110','stis_hkp2','stis_sci','stis_nse','mag8','mag64']
  endif

  if ~isa(datahash,'hash') then datahash=orderedhash()
  
  source.local_data_dir = root_data_dir()  ; +'swfo/data/test2/'

  printdat,source

  tr = timerange(trange)
  
  foreach type,types do begin
    if datahash.haskey(type) then dynarray = datahash[type] else dynarray= dynamicarray(name=type)
    pathname = str_sub(pathname0,'$NAME$',type)
    files = file_retrieve(pathname,trange=tr,_extra=source)
    if 1 then begin
      pathname = str_sub(pathname0,'$NAME$', 'pb_'+type)
      pb_files = file_retrieve(pathname,trange=tr,_extra=source)
      files = [files,pb_files]
    endif
    da = swfo_ncdf_read(filenames = files,dynarray=dynarray)
    ;da = swfo_ncdf_read(trange=timerange(trange),dynarray=dynarray,name=type,root_dir=root_dir)
    da.trim
    da.sort,/uniq
    dprint,da,da.name,da.size
    ;help,da
    
    if keyword_set(store) then  store_data,'swfo_'+type,data=da,tagnames='*'
   
    datahash[type] = da
    
  endforeach
  
  
  dprint,'Computing L0b',dlevel=2
  l0b = swfo_stis_sci_level_0b(datahash=datahash)
  l0b_da = dynamicarray(l0b,name='stis_l0b',/nocopy)
  datahash['stis_l0b'] = l0b_da
  
  dprint,'Computing L1a',dlevel=2
  l1a_da =  dynamicarray(name='stis_l1a', swfo_stis_sci_level_1a(l0b_da.array) )
  datahash['stis_l1a'] = l1a_da
  
  dprint,'Computing L1b',dlevel=2
  l1b_da =  dynamicarray(name='stis_l1b', swfo_stis_sci_level_1b(l1a_da.array) )
  if keyword_set(1 || tplot_store) then begin
    store_data,'swfo_stis_l1b',data=l1b_da,tagnames='*'
    store_data,'swfo_stis_l1b',data=l1b_da,tagnames='*ION_FLUX',val='ION_ENERGY'
    store_data,'swfo_stis_l1b',data=l1b_da,tagnames='*ELEC_FLUX',val='ELEC_ENERGY'
  endif
  datahash['stis_l1b'] = l1b_da

  if 0 then begin
    dprint,'mag stuff'
    magda = datahash['mag8']
    mag = magda.array
    ddb = mag.raw_data

    nd = n_elements(mag)

    for i=0,5 do    mag.mag_data[i,*] = ishft( fix( ddb[i*9,*] * 256 + ddb[i*9+1,*] ), 1) / 2
    ;for i=0,5 do    mag.mag_data[i] =  fix(ddb[[1,0]+i*9,*]  ,0,nd)
    mag.mag_data *= ( [1,1,1,-1,1,-1] # replicate(1,nd) )
    magda.array = mag
    store_data,'mag8',data=magda,tagnam='*'
    
  endif
  
  dprint,'Done'
  ;stop

end
