PRO sppeva_sitl_strct2tplot, s, var

  if s.Nsegs gt 0 then begin
    fom_x = 0.d0
    fom_y = 0.0
    for N=0,s.Nsegs-1 do begin
      fom_x = [fom_x, s.START[N], s.START[N], s.STOP[N], s.STOP[N]]
      fom_y = [fom_y, 0.        , s.FOM[N]  , s.FOM[N] , 0.       ]
      if s.START[N] gt s.STOP[N] then begin
        msg = "Start time > stop time ?"
        msg = [msg, "Check the "+strtrim(string(N),2)+"th segment"]
        msg = [msg, "between "+time_string(s.START[N])+' and '+time_string(s.STOP[N])]
        message,msg[0]
      endif
    endfor
    D = {x:fom_x[1:*], y:fom_y[1:*]}
  endif else begin
    D = {x:time_double(!SPPEVA.COM.STRTR), y:[0,0]}
  endelse

  str_element,/add,dl,'FOMstr',s
  store_data,var,data=D,lim=lim,dl=dl
  ylim,var,0,!SPPEVA.GENE.FOM_MAX_VALUE,0
  options,var,ystyle=1,constant=[5,10,15,20]; Don't just add yrange; Look at the 'fom_vax_value' parameter of eva_sitl_FOMedit
END