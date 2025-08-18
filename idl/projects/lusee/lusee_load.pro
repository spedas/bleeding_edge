;+
;
; NAME:
;   lusee_load
;
; $LastChangedBy: pulupa $
; $LastChangedDate: 2023-09-28 13:18:16 -0700 (Thu, 28 Sep 2023) $
; $LastChangedRevision: 32147 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/lusee/lusee_load.pro $
;
;-

pro lusee_load, type = type, em_test = em_test
  compile_opt idl2

  if n_elements(type) eq 0 then begin
    print, 'Specify type'
  endif

  if not keyword_set(em_test) then begin
    remote_data_dir = 'http://research.ssl.berkeley.edu/data/spp/' + $
      'sppfldsoc/cdf_lusee/'

    local_data_dir = root_data_dir() + 'lusee/'

    yyyy = 'YYYY'
    mm = 'MM'
  endif else begin
    ; example em_test = '20220811_lusee_scm_test'

    yyyy = em_test.SubString(0, 3)
    mm = em_test.SubString(4, 5)

    test_dir = yyyy + '/' + mm + '/' + em_test + '/'

    remote_data_dir = 'http://research.ssl.berkeley.edu/data/spp/' + $
      'sppfldsoc/cdf_em_lusee/' + test_dir

    local_data_dir = root_data_dir() + 'lusee_em/' + em_test + '/'

    print, yyyy, mm
  endelse

  l1_types = lusee_l1_filetypes(type)

  foreach l1_type, l1_types do begin
    if l1_type.Contains('ss') then l1_type = l1_type.Replace('ss', 's\s')

    if keyword_set(em_test) then begin
      l1_fmt = '/fields/l1/' + l1_type + $
        '/' + yyyy + '/' + mm + '/lusee_l1_' + $
        l1_type + '_' + yyyy + mm + '*_*_v??.cdf'
      source = spp_file_source(source_key = 'FIELDS')

      l1_files = file_retrieve(l1_fmt, $
        remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
        user_pass = getenv('FIELDS_USER_PASS'), /valid_only)
    endif else begin
      l1_fmt = '/lusee/l1/' + l1_type + $
        '/YYYY/MM/lusee_l1_' + l1_type + '_YYYYMMDD_v??.cdf'

      src = spp_file_source(source_key = 'FIELDS')

      src.remote_data_dir = remote_data_dir

      l1_files = spp_file_retrieve(key = 'FIELDS', l1_fmt, trange = trange, source = src, $
        /last_version, daily_names = 1, /valid_only, $
        resolution = resolution, shiftres = 0, no_server = no_server)
    endelse

    if l1_files[0] ne '' then $
      spp_fld_load_l1, l1_files, varformat = varformat, $
      add_prefix = tname_prefix, add_suffix = tname_suffix, /lusee
  endforeach
end