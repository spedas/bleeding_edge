function spp_fld_tmlib_item_nelem, item_hash, sid

  nelem = 1l

  if item_hash.HasKey('nblk') then nelem = long((item_hash)['nblk'])

  if item_hash.HasKey('nelem') and nelem EQ 1l then begin

    if valid_num(item_hash['nelem']) then begin

      nelem = long((item_hash)['nelem'])

    endif else begin

      err = tm_get_item_i4(sid, (item_hash)['nelem'], nelem, 1, n_returned)
      dprint, (item_hash)['name'], ' ', (item_hash)['nelem'], err, nelem, dlevel = 4
;      err = tm_get_item_i4(sid, 'avg_period_raw', ppp, 1, n_returned)
;      print, err, ppp

    endelse

  endif

  ;  if nelem NE 1 then begin
  ;
  ;    print, nelem
  ;
  ;  endif

  if (item_hash)['name'] EQ 'dbm_data' then begin ;

    err = tm_get_item_i4(sid, 'dbm_nsamples', dbm_nsamples, 1, n_returned)

    dprint, nelem, dbm_nsamples, dlevel = 4

  endif

;  if (nelem NE 512) and (nelem NE 32) and (nelem NE 1) then stop

  return, nelem


end