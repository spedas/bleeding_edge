PRO sppeva_pref_import, strct_default, strct_saved
  compile_opt idl2
  tn = tag_names(!SPPEVA)
  idx = where(tn eq strct_default,ct)
  if ct gt 0 then begin
    i = idx[0]
    tn_default = tag_names(!SPPEVA.(i))
    tn_saved   = tag_names(strct_saved)
    jmax = n_elements(tn_saved)
    for j=0,jmax-1 do begin; for each element in strct_saved
      idx = where(tn_default eq tn_saved[j], ct2); look for the corresponding element in !SPPEVA.(i)
      k = idx[0]
      if ct2 gt 0 then begin; if found
        !SPPEVA.(i).(k) = strct_saved.(j); import
      endif
    endfor
  endif
END