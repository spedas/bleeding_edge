;+
;
; NAME:
;   lusee_load
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2022-09-01 14:36:30 -0700 (Thu, 01 Sep 2022) $
; $LastChangedRevision: 31067 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/lusee/lusee_load.pro $
;
;-

pro lusee_load, type = type, em_test = em_test

  if n_elements(type) EQ 0 then begin
    
    print, 'Specify type'
    
  endif

  if not keyword_set(em_test) then em_test = '20220811_lusee_scm_test'

  yyyy = em_test.SubString(0,3)
  mm   = em_test.SubString(4,5)

  test_dir = yyyy + '/' + mm + '/' + em_test + '/'

  remote_data_dir = 'http://research.ssl.berkeley.edu/data/spp/' + $
    'sppfldsoc/cdf_em_lusee/' + test_dir

  local_data_dir = root_data_dir() + 'lusee_em/' + em_test + '/'

  print, yyyy, mm

  l1_types = lusee_l1_filetypes(type)

  foreach l1_type, l1_types do begin

    l1_fmt = '/fields/l1/' + l1_type + $
      '/' + yyyy + '/' + mm + '/lusee_l1_' + $
      l1_type + '_' + yyyy + mm + '*_*_v??.cdf'

    source = spp_file_source(source_key='FIELDS')

    l1_files = file_retrieve(l1_fmt, $
      remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, $
      user_pass = getenv('FIELDS_USER_PASS'), /valid_only)

    if l1_files[0] NE '' then $
      spp_fld_load_l1, l1_files, varformat = varformat, $
      add_prefix = tname_prefix, add_suffix = tname_suffix, /lusee

  endforeach

end