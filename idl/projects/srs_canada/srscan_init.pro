;+
;PROCEDURE:  srscan_init
;
;PURPOSE:
;   Initializes system variables for the srs_canada project (!srs_canada).
;
;   The srs_canada project is an umbrella for ground-based instrumentation
;   operated by the Space Remote Sensing (SRS) group:
;   all-sky imagers (TREx RGB, and in the future TREx NIR/Blueline, SMILE ASI),
;   riometers, spectrographs, and more.
;
;   Data is downloaded from the archive at https://data.phys.ucalgary.ca
;   using its data distribution API; see srscan_api_config for the API
;   configuration.
;
;KEYWORDS:
;   reset:            reset !srs_canada to defaults (re-reads saved config)
;   local_data_dir:   override the local data cache directory for this session
;   remote_data_dir:  override the remote data URL (informational; downloads
;                     are driven by the srscan API layer)
;   no_color_setup:   skip spd_graphics_config color setup
;
;EXAMPLE:
;   srscan_init
;   print, !srs_canada.local_data_dir
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-10-14 09:44:38 -0700 (Wed, 14 Oct 2026) $
;$LastChangedRevision: 34972 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/srs_canada/srscan_init.pro $
;-
pro srscan_init, reset=reset, local_data_dir=local_data_dir, $
                 remote_data_dir=remote_data_dir, no_color_setup=no_color_setup

  defsysv, '!srs_canada', exists=exists
  if not keyword_set(exists) then begin
    defsysv, '!srs_canada', file_retrieve(/structure_format)
  endif

  if keyword_set(reset) then !srs_canada.init = 0

  if !srs_canada.init ne 0 then begin
    ; allow session overrides even when already initialized
    if keyword_set(local_data_dir) then $
      !srs_canada.local_data_dir = spd_addslash(local_data_dir)
    if keyword_set(remote_data_dir) then $
      !srs_canada.remote_data_dir = spd_addslash(remote_data_dir)
    return
  endif

  !srs_canada = file_retrieve(/structure_format)

  ; read saved values from the config file
  ftest = srscan_read_config()

  if (size(ftest, /type) eq 8) && ~keyword_set(reset) then begin
    !srs_canada.local_data_dir = ftest.local_data_dir
    !srs_canada.remote_data_dir = ftest.remote_data_dir
    !srs_canada.no_download = ftest.no_download
    !srs_canada.no_update = ftest.no_update
    !srs_canada.downloadonly = ftest.downloadonly
    !srs_canada.verbose = ftest.verbose
  endif else begin
    if keyword_set(reset) then begin
      print, 'Resetting srs_canada to default configuration'
    endif else begin
      print, 'No srs_canada config found...creating default configuration'
    endelse
    !srs_canada.local_data_dir = root_data_dir() + 'srs_canada'
    !srs_canada.remote_data_dir = 'https://data.phys.ucalgary.ca'
  endelse

  ; keyword overrides take precedence over config/defaults
  if keyword_set(local_data_dir) then !srs_canada.local_data_dir = local_data_dir
  if keyword_set(remote_data_dir) then !srs_canada.remote_data_dir = remote_data_dir

  !srs_canada.local_data_dir = spd_addslash(!srs_canada.local_data_dir)
  !srs_canada.remote_data_dir = spd_addslash(!srs_canada.remote_data_dir)

  ; on Windows root_data_dir() can return a doubled separator
  ; ('c:/data/' + path_sep() -> 'c:/data/\'); collapse '/\' to '/'
  p = strpos(!srs_canada.local_data_dir, '/\')
  while p ge 0 do begin
    !srs_canada.local_data_dir = strmid(!srs_canada.local_data_dir, 0, p + 1) + $
      strmid(!srs_canada.local_data_dir, p + 2)
    p = strpos(!srs_canada.local_data_dir, '/\')
  endwhile

  if file_test(!srs_canada.local_data_dir + '.master') then !srs_canada.no_server = 1

  if ~keyword_set(no_color_setup) then spd_graphics_config, colortable=colortable

  !srs_canada.init = 1

  printdat, /values, !srs_canada, varname='!srs_canada'

end
