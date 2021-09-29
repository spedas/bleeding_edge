PRO sppeva_load_reformat, tname, last_two_char
  compile_opt idl2
  
  tn = tnames(tname,ct)
  if ct eq 0 then return
  
  get_data, tname, data=DD, lim=lim, dl=dl
  
  ll = ['','','']
  
  if n_tags(dl) gt 0 then begin
    idx = where(tag_names(dl)  eq 'labels',ct)
    if ct eq 1 && n_elements(dl.labels) eq 3 then ll = dl.labels
  endif
  
  if n_tags(lim) gt 0 then begin
    idx = where(tag_names(lim) eq 'labels',ct)
    if ct eq 1 && n_elements(lim.labels) eq 3 then ll = lim.labels
  endif
  
  ysubtitle=''
  newlabel=''
  
  case last_two_char of
    '_m':begin
      pcolor = 0
      ysubtitle = '(mag)'
      Dnew = sqrt(DD.y[*,0]^2+DD.y[*,1]^2+DD.y[*,2]^2)
      newlabel = ' '
      end
    '_x':begin
      pcolor = 2
      Dnew = DD.y[*,0]
      newlabel = ll[0]
      end
    '_y':begin
      pcolor = 4
      Dnew = DD.y[*,1]
      newlabel = ll[1]
      end
    '_z':begin
      pcolor = 6
      Dnew = DD.y[*,2]
      newlabel = ll[2]
      end
    '_p':begin
      pcolor = 0
      ysubtitle = '(phi)'
      xyz_to_polar,tname,phi=phi
      get_data,phi,data=DDD
      Dnew = DDD.y
      newlabel = ' '
      end
    '_t':begin
      pcolor = 0
      ysubtitle = '(theta)'
      xyz_to_polar,tname,theta=theta
      get_data,theta,data=DDD
      Dnew = DDD.y
      newlabel = ' '
      end
    else:
  endcase
  
  
  ;--------------------
  ; NEW TPLOT VARIABLE
  ;--------------------
  tnn = tname+last_two_char
  store_data, tnn, data={x:DD.x,y:Dnew},lim=lim,dl=dl
  
  ;----------
  ; OPTIONS
  ;----------

  if strlen(newlabel)  gt 0 then options, tnn, labels=newlabel
  if strlen(ysubtitle) gt 0 then options, tnn, ysubtitle=ysubtitle

  case last_two_char of
    '_p':begin
      ylim, tnn, -180, 180, 0
      options, tnn, ystyle=1, constant=[-90,0,90]
      end
    '_t':begin
      ylim, tnn, -90, 90, 0
      options, tnn, ystyle=1, constant=[-45,0,45]
      end
    else:
  endcase

END
