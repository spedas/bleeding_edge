pro spp_fld_make_or_retrieve_cdf, $
  apid_name, $
  make = make, $
  load = load, $
  filenames = filenames

  if keyword_set(make) then begin

    spp_fld_make_cdf_l1, apid_name, load = load

  endif else begin

    get_timespan, ts

    ; The DFB APID definitions usually contain an underscore specifying which 
    ; waveform/spectra/bandpass channel is being sampled (e.g. dfb_wf_01) but
    ; the Level 1 CDF files don't have that underscore (e.g. dfb_wf01)

    if strmid(apid_name, 0, 3) EQ 'dfb' and apid_name NE 'dfb_hk' then begin

      final_underscore = strpos(apid_name, '_', /reverse_search)

      apid_name = strmid(apid_name, 0, final_underscore) + $
        strmid(apid_name, final_underscore + 1)

    endif

    psp_staging_id = getenv('PSP_STAGING_ID')

    if psp_staging_id EQ '' then psp_staging_id = getenv('USER')

    fileprefix = 'psp/data/sci/fields/staging/l1/'

    pathformat = apid_name + '/YYYY/MM/spp_fld_l1_' + $
      apid_name + '_YYYYMMDD_v??.cdf'

    spp_fld_load, type = apid_name, fileprefix = fileprefix, $
      pathformat = pathformat, /no_load, files = files, $
      level = 1, trange = time_string(ts, tformat = 'YYYY-MM-DD/hh:mm:ss')

    valid_files = where(file_test(files) EQ 1, valid_count)

    if valid_count GT 0 then filenames = files[valid_files]

    if keyword_set(load) then begin

      if valid_count GT 0 then begin

        spp_fld_load_l1, files[valid_files]

      end

    endif

  endelse

end
