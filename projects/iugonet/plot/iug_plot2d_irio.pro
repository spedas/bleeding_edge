;+
; :PROCEDURE:
;    iug_plot2d_irio, vn, col, row, start_time=start_time, $
;           step=step, valrng=valrng, flipns=flipns, flipew=flipew, $
;           oblique_cor=oblique_cor
;
; :PURPOSE:
;    Plot 2D image of the imaging riometer data obtained by NIPR. 
;    The data are mapped to 90km altitude in the magnetic coordinate.
;
; :KEYWOARDS:
;    vn  : tplot variables for image data
;    col : number of column
;    row : number of row
;    start_time : start time of the images
;    step: time step
;    valrng: minimal and maximal values for display (default: [0, 4])
;    flipns: set to flip in the North-South direction (default: top is north)
;    flipew: set to flip in the East-West direction (default: right is east)
;    oblique_cor: if set, CNA for the oblique beams is corrected by CNA*cos(ze).
;
; :EXAMPLES:
;    iug_plot2d_irio, 'nipr_irio_syo_cna', 3, 3, $
;                     start_time='2003-02-09/01:30', step=60
;
; :Author:
;    Y.-M. Tanaka (ytanaka at nipr.ac.jp)
;-

pro iug_plot2d_irio, vn, col, row, start_time=start_time, step=step, $
	valrng=valrng, flipns=flipns, flipew=flipew, oblique_cor=oblique_cor
  
  ;Check arguments
  npar = n_params()
  if npar lt 1 then return
  if strlen(tnames(vn[0])) eq 0 then return
  if npar eq 1 then begin & col=1 & row=1 & endif

  if ~keyword_set(step) then step=1
  if ~keyword_set(valrng) then valrng=[0.0, 4.0]
  
  ;currently col and row should be equal to or less than 10 
  col = ( col < 10 ) 
  row = ( row < 10 )

  ;altitude
  xrng=[-80, 80]
  yrng=[-80, 80]
  alt = 90.   ; altitude = 90km

  ;Obtain the data variable
  get_data, vn[0], data=d, lim=lim, dlim=dlim
  img_time = d.x
  img_data = d.y

  ;Get az and ze of imaging riometer
  pos=strpos(vn[0], '_', /reverse_search)
  prefix=strmid(vn[0], 0, pos)
  get_data, prefix+'_az', data=azdata
  get_data, prefix+'_ze', data=zedata
  sbeam=size(azdata.y[*,*,0])
  az = reform(azdata.y[*,*,0], sbeam[1], sbeam[2])
  ze = reform(zedata.y[*,*,0], sbeam[1], sbeam[2])

  xdat=alt*tan(ze*!PI/180.)*cos((90.-az)*!PI/180.)
  ydat=alt*tan(ze*!PI/180.)*sin((90.-az)*!PI/180.)

  ;Skip to the specified start time
  if ~keyword_set(start_time) then begin
    tr=timerange(trange)
    start_time=time_string(tr[0])
  endif
  index=where(img_time ge time_double(start_time), cnt)
  if cnt eq 0 then begin
    message,'No data has been loaded after start_time.',/info
    return
  endif

  idx_sta = index[0]
  idx_end = n_elements(img_data[*,0,0])-1

  ;Window
  !P.multi=[0, col, row]
  
  clmax = 256L
  clmin = 8L
  cnum = clmax-clmin

  idx=idx_sta
  for j=0, row-1 do begin
    for i=0, col-1 do begin
      if idx gt idx_end then break

      img = reform(img_data[idx,*,*])
      tstr = time_string(img_time[idx])

      ;Oblique beam correction
      if keyword_set(oblique_cor) then begin
         img=img*cos(ze*!PI/180.)
      endif

      ;Flip NS/EW
      if keyword_set(flipns) then begin
         img=reverse(img, 1)
         yttl='M.N.<-- [km] -->M.S.'
      endif else begin
         yttl='M.S.<-- [km] -->M.N.'
      endelse
      if keyword_set(flipew) then begin
         img=reverse(img, 2)
         xttl='M.E.<-- [km] -->M.W.'
      endif else begin
         xttl='M.W.<-- [km] -->M.E.'
      endelse

      lvls = valrng[0] + indgen(cnum)*(float(valrng[1]-valrng[0])/cnum)
      cols = clmin + indgen(cnum)
      img = (img > valrng[0])
      img = (img < valrng[1]) ; clmin <= color level <= clmax

      ;Contour plot
      contour, img, xdat, ydat, /fill, $
                c_colors = cols, levels = lvls, xstyle=1, ystyle=1, $
		xrange=xrng, yrange=yrng, /isotropic, $
                xtitle=xttl, ytitle=yttl, title=tstr

      ;Color scale
      str_element, lim, 'ztitle', val=ztitle, success=s
      if s eq 0 then ztitle = ''
      draw_color_scale, range=valrng, title=ztitle
       
      idx = idx + step
      
    endfor
  endfor

  return
end
