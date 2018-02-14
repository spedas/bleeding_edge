pro spp_fld_make_cdf_l1, apid_name, $
  fileid = fileid, $
  varformat = varformat, $
  trange = trange, $
  filename = filename, $
  load = load

  if not keyword_set(apid_name) then return ; TODO: Better checking and error reporting

  spp_fld_cdf_timespan, trange = trange, success = ts_success, $
    filename_timestring = filename_timestring

  if ts_success NE 1 then return ; TODO: error reporting here

  data = spp_fld_load_tmlib_data(apid_name, $
    varformat = varformat, success = dat_success, $
    cdf_att = cdf_att, times = times, packets = packets, idl_att = idl_att)

  if dat_success NE 1 then begin

    if dat_success EQ -1 then dprint, 'No data found for ' + apid_name, dlevel = 2

    filename = ''

    return ; TODO: error reporting here

  endif

  ;
  ; Create the CDF file
  ;

  spp_fld_cdf_create, 1, 0, cdf_att, filename_timestring, $
    filename = filename, fileid = fileid

  ;
  ; Write the packets file
  ;

  packet_filename = strmid(filename,0,strlen(filename)-3) + 'dat'

  spp_fld_write_packet_file, packet_filename, packets

  ;
  ; Put data into the CDF file
  ;

  spp_fld_cdf_put_metadata, fileid, filename, cdf_att

  spp_fld_cdf_put_time, fileid, times.ToArray()

  spp_fld_cdf_put_depend, fileid, idl_att = idl_att

  spp_fld_cdf_put_data, fileid, data, /close


  ;
  ; If load keyword set, load file into tplot variables
  ;

  if keyword_set(load) then begin

    if file_test(filename) then begin

      spp_fld_load_l1, filename

      if !spp_fld_tmlib.test_cdf_dir NE '' then begin

        file_mkdir, !spp_fld_tmlib.test_cdf_dir

        file_copy, filename, !spp_fld_tmlib.test_cdf_dir, /over

      end

    end

    if file_test(packet_filename) then begin

      if !spp_fld_tmlib.test_cdf_dir NE '' then begin

        file_copy, packet_filename, !spp_fld_tmlib.test_cdf_dir, /over

      end

    end

  endif

end