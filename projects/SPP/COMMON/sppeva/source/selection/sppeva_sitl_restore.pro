PRO sppeva_sitl_restore
  compile_opt idl2

  tn=tnames()
  var = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr')
  idx = where(strmatch(tn,var),ct)
  if ct gt 0 then begin
    msg = 'There is already a selection in SPP EVA.'
    msg = [msg, "Overwrite it with the selection you're about to restore?"]
    answer = dialog_message(msg,/question,/center)
    suffix = strmatch(answer,'Yes') ? '' : '_copy'
  endif else suffix = ''

  sppeva_sitl_csv2tplot, status=status, suffix=suffix
  
  if status eq 4 then begin
    sppeva_load, paramlist=paramlist, /get_paramlist
    sppeva_plot, paramlist, parent_xsize=parent_xsize
  endif
END
