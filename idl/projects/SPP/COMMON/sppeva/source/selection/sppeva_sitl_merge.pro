PRO sppeva_sitl_merge
  compile_opt idl2

  var = strlowcase('spp_'+!SPPEVA.COM.MODE+'_fomstr')
  found = file_test(var+'.most-recent.'+!SPPEVA.COM.USER_NAME+'.csv')
  if found then begin
    msg = 'Would you like your most recent selections'
    msg = [msg,"to be merged with the selections you're about to import?"]
    answer = dialog_message(msg,/question,/center)
  endif else answer = 'No'


  files = dialog_pickfile(FILTER='*.csv',/multiple)
  
  if strlen(files[0]) eq 0 then begin
    print,'------'
    print,'File selection cancelled.'
    return
  endif
  
  if strmatch(answer,'Yes') then begin
    files = [files, var+'.most-recent.'+!SPPEVA.COM.USER_NAME+'.csv']
  endif
  
  sppeva_sitl_csv2tplot_multi, files, status=status, suffix=suffix

  if status eq 4 then begin
    sppeva_load, paramlist=paramlist, /get_paramlist
    sppeva_plot, paramlist, parent_xsize=parent_xsize
  endif
END
