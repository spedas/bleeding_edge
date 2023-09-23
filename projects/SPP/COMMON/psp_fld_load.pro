;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2023-09-19 16:04:38 -0700 (Tue, 19 Sep 2023) $
; $LastChangedRevision: 32108 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/psp_fld_load.pro $
;
;-

pro psp_fld_load, trange = trange, type = type, $
  files = files, $
  fileprefix = fileprefix, $
  tname_prefix = tname_prefix, $
  tname_suffix = tname_suffix, $
  pathformat = pathformat, $
  varformat = varformat, $
  level = level, $
  longterm_ephem = longterm_ephem, $
  get_support = get_support, $
  no_load = no_load, $
  no_staging = no_staging, $
  use_staging = use_staging, $
  version = version
  compile_opt idl2

  if n_elements(level) eq 0 then level = 2

  ; Default is not to use the 'staging' directory unless specifically
  ; requested (use_staging keyword set)

  if n_elements(no_staging) eq 0 then no_staging = 1

  spp_fld_load, trange = trange, type = type, $
    files = files, $
    fileprefix = fileprefix, $
    tname_prefix = tname_prefix, $
    tname_suffix = tname_suffix, $
    pathformat = pathformat, $
    varformat = varformat, $
    level = level, $
    longterm_ephem = longterm_ephem, $
    get_support = get_support, $
    no_load = no_load, $
    no_staging = no_staging, $
    use_staging = use_staging, $
    version = version
end