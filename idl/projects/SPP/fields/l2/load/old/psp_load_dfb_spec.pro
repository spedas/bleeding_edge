pro psp_load_dfb_spec, ac_dc, files = files

  ac_dc = strlowcase(ac_dc)

  if ac_dc NE 'ac' and ac_dc NE 'dc' then begin
    
    dprint, dlevel = 1, 'Must specify AC or DC when calling PSP_LOAD_DFB_SPEC' 
    
    return
    
  endif
  
  if n_elements(files) GT 0 then begin

    cdf2tplot, files, prefix = 'psp_fld_dfb_' + ac_dc + '_', verbose=4, /get_support

    dfb_spec_tnames = tnames('psp_fld_dfb_' + ac_dc + '_spec*', dfb_spec_tnames_n)

    for i = 0, dfb_spec_tnames_n - 1 do begin

      dfb_spec_tname = dfb_spec_tnames[i]

      get_data, dfb_spec_tname, al = al, data = data

      options, dfb_spec_tname, 'ylog', 1
      options, dfb_spec_tname, 'no_interp', 1

      options, dfb_spec_tname, 'ztitle', al.cdf.vatt.units
      options, dfb_spec_tname, 'ysubtitle', 'Hz'
      options, dfb_spec_tname, 'ytitle', 'DFB!C' + strupcase(ac_dc) + ' SPEC!C' + $
        strupcase(strmid(al.cdf.vatt.fieldnam, 7))
      options, dfb_spec_tname, 'yrange', minmax(data.v)
      options, dfb_spec_tname, 'ystyle', 1

    endfor

  end

end