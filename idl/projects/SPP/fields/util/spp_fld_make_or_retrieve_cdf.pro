;+
;
; This program is outdated, and in nearly every case it is simpler and easier
; to use 'spp_fld_load' (or, equivalently, 'psp_fld_load') instead.
;
; Kept around for backward compatibility with some old routines.
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2024-11-12 10:43:29 -0800 (Tue, 12 Nov 2024) $
; $LastChangedRevision: 32943 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/spp_fld_make_or_retrieve_cdf.pro $
;
;-

pro spp_fld_make_or_retrieve_cdf, $
  apid_name, $
  make = make, $
  load = load, $
  filenames = filenames, $
  lusee = lusee
  compile_opt idl2

  if keyword_set(make) then begin
    if ~keyword_set(lusee) then begin
      if (getenv('HOSTNAME')).contains('lucem') then lusee = 1 else lusee = 0
    endif
    spp_fld_make_cdf_l1, apid_name, load = load, lusee = lusee
  endif else if getenv('HOSTNAME') eq 'spfdata2' then begin
    if strmid(apid_name, 0, 3) eq 'dfb' and apid_name ne 'dfb_hk' then begin
      final_underscore = strpos(apid_name, '_', /reverse_search)

      apid_name = strmid(apid_name, 0, final_underscore) + $
        strmid(apid_name, final_underscore + 1)
    endif
    spp_fld_load, type = apid_name, level = 1
  endif else begin
    remote_site = 'http://sprg.ssl.berkeley.edu/data/spp/data/sci/fields/staging/l1/'

    get_timespan, ts

    if strmid(apid_name, 0, 3) eq 'dfb' and apid_name ne 'dfb_hk' then begin
      final_underscore = strpos(apid_name, '_', /reverse_search)

      apid_name = strmid(apid_name, 0, final_underscore) + $
        strmid(apid_name, final_underscore + 1)
    endif

    if apid_name eq 'dcb_ssr_telemetry' then apid_name = 'dcb_s\sr_telemetry'
    if apid_name eq 'rfs_hfr_cross' then apid_name = 'rfs_hfr_cros\s'

    files = file_retrieve(apid_name + '/YYYY/MM/spp_fld_l1_' + apid_name + '_YYYYMMDD_v??.cdf', $
      local_data_dir = getenv('PSP_STAGING_DIR'), $
      remote_data_dir = remote_site, no_update = 0, $
      trange = time_string(ts, tformat = 'YYYY-MM-DD/hh:mm:ss'), $
      user_pass = getenv('PSP_STAGING_ID') + ':' + getenv('PSP_STAGING_PW'))

    valid_files = where(file_test(files) eq 1, valid_count)

    if valid_count gt 0 then filenames = files[valid_files]

    if keyword_set(load) then begin
      if valid_count gt 0 then begin
        spp_fld_load_l1, files[valid_files], varformat = '*'
      end
    endif
  endelse
end