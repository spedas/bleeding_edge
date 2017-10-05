pro spp_fld_tmlib_init, server = server, test_cdf_dir = test_cdf_dir

  ; Set server

  if not keyword_set(server) then server = 'spffmdb.ssl.berkeley.edu'

  ; Set CDF directory

  cdf_dir = getenv('SPP_FLD_CDF_DIR')

  if cdf_dir EQ '' then begin

    cdf_dir = '~/data'

    dprint, 'Using ~/data to store CDFs', dlevel = 1
    dprint, 'Set environment variable SPP_FLD_CDF_DIR to use a different directory', dlevel = 1

  endif

  ; Set test CDF dir (to store all CDFs created during a particular test
  ; in the same directory for convenience)

  if ~keyword_set(test_cdf_dir) then test_cdf_dir = ''

  ; Set up system variable

  defsysv, '!SPP_FLD_TMLIB', exists = exists

  if not keyword_set(exists) then begin

    defsysv, '!SPP_FLD_TMLIB', {server:server, $
      cdf_dir:cdf_dir, $
      test_cdf_dir:test_cdf_dir}

  endif else begin

    !SPP_FLD_TMLIB.server = server
    !SPP_FLD_TMLIB.cdf_dir = cdf_dir
    !SPP_FLD_TMLIB.test_cdf_dir = test_cdf_dir

  end

  printdat, !SPP_FLD_TMLIB, /values, varname = '!spp_fld_tmlib'

  !p.background = !d.table_size - 1L
  !p.color = 0

  spp_fld_config

  ; Set up routines to load the DFB frequencies

  spp_fld_dfb_frequencies

end