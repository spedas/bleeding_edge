; Chop off a tplot-variable so that |D.y| < max
PRO eva_cap, sname, max=max; sname can be, for example, 'thb_fgs_gsm'
  if ~keyword_set(max) then max=100.0
  get_data,  sname,data=D,limit=limit,dlimit=dlimit
  sz=size(D,/type)
  if sz eq 8 then begin
    index = where(abs(D.y) gt max)
    if (index[0] ne -1) then D.y[index] = float('NaN')
    store_data,sname,data={x:D.x,y:D.y},limit=limit, dlimit=dlimit
  endif
END
