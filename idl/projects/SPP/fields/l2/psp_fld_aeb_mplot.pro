pro psp_fld_aeb_mplot,xt,yt,dy,      $
  OVERPLOT = overplot,$
  OPLOT    = oplot,   $
  LABELS   = labels,  $ ;(array of) label(s) for the curve(s)
  LABPOS   = labpos,  $
  LABFLAG  = labflag, $
  COLORS   = colors,  $ ;(array of) color(s) for the curve(s)
  neg_colors = neg_colors, $
  BINS     = bins,    $
  DATA     = data,    $
  NOERRORBARS = noerrorbars,  $
  ERRORTHRESH = errorthresh,  $
  NOXLAB   = noxlab,  $ ;No xlabels are printed if set
  NOCOLOR  = nocolor, $ ;Colors not automatically generated if set
  LIMITS   = limits     ;structure containing miscellaneous keyword tags:values


  if size(/type, data) EQ 8 then begin

    x = data.x
    y = data.y

    str_element,limits,'datagap',dg
    if keyword_set(dg) then makegap,dg,x,y,dy=dy

    n = n_elements(x)

    if n GT 1 then begin

      x = (reform(transpose(rebin(x,n,2)),n*2))[1:-1]
      y = (reform(transpose(rebin(y,n,2)),n*2))[0:-2]

      data_new = {x:x, y:y}

    endif

  endif

  mplot,xt,yt,dy,      $
    OVERPLOT = overplot,$
    OPLOT    = oplot,   $
    LABELS   = labels,  $ ;(array of) label(s) for the curve(s)
    LABPOS   = labpos,  $
    LABFLAG  = labflag, $
    COLORS   = colors,  $ ;(array of) color(s) for the curve(s)
    neg_colors = neg_colors, $
    BINS     = bins,    $
    DATA     = data_new,    $
    NOERRORBARS = noerrorbars,  $
    ERRORTHRESH = errorthresh,  $
    NOXLAB   = noxlab,  $ ;No xlabels are printed if set
    NOCOLOR  = nocolor, $ ;Colors not automatically generated if set
    LIMITS   = limits     ;structure containing miscellaneous keyword tags:values


end