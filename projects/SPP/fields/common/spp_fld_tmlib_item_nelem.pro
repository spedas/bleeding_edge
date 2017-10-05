function spp_fld_tmlib_item_nelem, item_hash, sid

  nelem = 1l

  if item_hash.HasKey('nblk') then nelem = long((item_hash)['nblk'])

  if item_hash.HasKey('nelem') and nelem EQ 1l then begin

    if valid_num(item_hash['nelem']) then begin

      nelem = long((item_hash)['nelem'])

    endif else begin

      err = tm_get_item_i4(sid, (item_hash)['nelem'], nelem, 1, n_returned)

    endelse

  endif

  ;  if nelem NE 1 then begin
  ;
  ;    print, nelem
  ;
  ;  endif

  if (item_hash)['name'] EQ 'dbm_data' then begin ;

    err = tm_get_item_i4(sid, 'dbm_nsamples', dbm_nsamples, 1, n_returned)

    print, nelem, dbm_nsamples

  endif

  return, nelem

end