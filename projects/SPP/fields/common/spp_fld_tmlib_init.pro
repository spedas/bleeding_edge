;+
; NAME:
;   SPP_FLD_TMLIB_INIT
;
; PURPOSE:
;   Initializes TMlib configuration for loading PSP/FIELDS data.  TMlib
;   configuration information is stored in an IDL system variable,
;   !SPP_FLD_TMLIB.
;
;   Also calls routines which ensure that several helper functions (for
;   example, functions which define frequencies for FIELDS spectral data
;   products) are available for IDL to call.
;
; INPUTS:
;   SERVER: Address of the TMlib server.
;   TEST_CDF_DIR: The CDF creation routines save CDF files into a directory
;     defined by the environment variable SPP_FLD_CDF_DIR.  If the TEST_CDF_DIR
;     keyword is also set, any CDF files created will also be saved to that
;     directory.
;
; EXAMPLE:
;
;   spp_fld_tmlib_init, server = 'spffmdb.ssl.berkeley.edu'
;
; CREATED BY:
;   pulupa
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2019-05-10 13:38:20 -0700 (Fri, 10 May 2019) $
; $LastChangedRevision: 27215 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_tmlib_init.pro $
;-

pro spp_fld_tmlib_init, server = server, test_cdf_dir = test_cdf_dir, daily = daily

  ; Set server

  if not keyword_set(server) then server = 'spffmdb.ssl.berkeley.edu'

  ; Set CDF directory

  if n_elements(daily) EQ 0 then begin
    cdf_dir = getenv('SPP_FLD_CDF_DIR')
  endif else begin
    cdf_dir = getenv('SPP_FLD_DAILY_DIR')
  endelse

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

  ; spp_fld_config

  ; Set up routines to load the DFB frequencies

  spp_fld_dfb_frequencies

end