;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2021-01-25 22:28:52 -0800 (Mon, 25 Jan 2021) $
; $LastChangedRevision: 29623 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/common/spp_fld_load_l1.pro $
;
;-

pro spp_fld_load_l1, filename, $
  load_procedure = load_procedure, $
  file_timerange = file_timerange, $
  varformat = varformat, $
  downsample = downsample, add_prefix = add_prefix, add_suffix = add_suffix

  defsysv, '!SPP_FLD_TMLIB', exists = exists

  if not keyword_set(exists) then spp_fld_tmlib_init

  ; Load only the global attributes

  cdf_vars = cdf_load_vars(filename[0], verbose = -1)

  if size(/type, cdf_vars) EQ 2 then return

  logical_source = cdf_vars.g_attributes.LOGICAL_SOURCE

  ; Cut off numbers at the end

  pos = stregex(logical_source,'[0-9]+$')

  if pos GE 0 and logical_source NE 'SPP_FLD_SC_HK_184' $
    and logical_source NE 'SPP_FLD_SC_HK_191' $
    and strmid(logical_source,0,13) NE 'SPP_FLD_EPHEM' then begin

    load_routine_prefix = strmid(logical_source, 0, pos)

    prefix = strlowcase(load_routine_prefix) + '_' + strmid(logical_source,pos) + '_'

  endif else begin

    load_routine_prefix = logical_source

    prefix = strlowcase(load_routine_prefix) + '_'

  endelse

  if not keyword_set(load_procedure) then $
    load_procedure = strlowcase(load_routine_prefix) + '_load_l1'

  if n_elements(add_prefix) GT 0 then prefix = add_prefix + prefix

  if n_elements(add_suffix) GT 0 then begin

    print, 'add_suffix not yet implemented for Level 1s'

  endif

  if n_elements(downsample) GT 0 then begin

    call_procedure, load_procedure, filename, prefix = prefix, varformat = varformat, $
      downsample = downsample

  endif else begin

    call_procedure, load_procedure, filename, prefix = prefix, varformat = varformat

  endelse

end
