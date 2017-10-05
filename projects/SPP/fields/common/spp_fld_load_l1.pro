pro spp_fld_load_l1, filename

  defsysv, '!SPP_FLD_TMLIB', exists = exists

  if not keyword_set(exists) then spp_fld_tmlib_init

  ; Load only the global attributes

  cdf_vars = cdf_load_vars(filename, verbose = -1)

  logical_source = cdf_vars.g_attributes.LOGICAL_SOURCE

  ; Cut off numbers at the end

  pos = stregex(logical_source,'[0-9]+$')

  if pos GE 0 then begin

    load_routine_prefix = strmid(logical_source, 0, pos)

    prefix = strlowcase(load_routine_prefix) + '_' + strmid(logical_source,pos) + '_'

  endif else begin

    load_routine_prefix = logical_source

    prefix = strlowcase(load_routine_prefix) + '_'

  endelse

  load_procedure = strlowcase(load_routine_prefix) + '_load_l1'

  call_procedure, load_procedure, filename, prefix = prefix

end