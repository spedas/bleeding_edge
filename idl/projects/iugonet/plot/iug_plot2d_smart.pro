;+
; :PROCEDURE:
;    iug_plot2d_smart
;
; :PURPOSE:
;    Plot the solar image data obtained by the SMART telescope at the Hida Observatory, 
;      Kyoto Univ.
;
; :KEYWOARDS:
;    vn  : tplot variables for image data
;    col : number of column
;    row : number of row
;    start_time : start time of the images
;
; :EXAMPLES:
;    iug_plot2d_smart, 'smart_t1_p00', 3, 3, start_time='2005-08-03/05:00:00'
;
; :Author:
;    Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;    Satoru UeNo (E-mail: ueno@kwasan.kyoto-u.ac.jp)
;-

pro iug_plot2d_smart, vn, col, row, start_time=start_time 
  
  ;Check arguments
  npar = n_params()
  if npar lt 1 then return
  if strlen(tnames(vn[0])) eq 0 then return
  if npar eq 1 then begin & col=1 & row=1 & endif
  
  ;currently col and row should be equal to or less than 10 
  col = ( col < 10 ) 
  row = ( row < 10 )
  
  ;Obtain the data variable
  get_data, vn[0], data=d
  smt_time = d.x
  smt_dat = d.y 
  dat_idx_max = n_elements(smt_dat[*,0,0])-1
  
  ;Skip to the specified start time
  if ~keyword_set(start_time) then begin
    tr=timerange(trange)
    start_time=time_string(tr[0])
  endif
  index=where(smt_time ge time_double(start_time), cnt)
  if cnt eq 0 then begin
    message,'No data has been loaded after start_time.',/info
    return
  endif

  ;Window size
  xsize = 800L & ysize = 800L
  window, 0, xs=xsize, ys=ysize
  loadct,0 ; 2012-08-07 by SUN
  erase

  dxsize = fix( float(xsize) / col )
  dysize = fix( float(ysize) / row )
  
  img_idx = index[0]
  
  for j=0, row-1 do begin
    for i=0, col-1 do begin
      if img_idx gt dat_idx_max then break
      
      img = reform( smt_dat[img_idx,*,*] )
      ;tstr = time_string( smt_time[img_idx], tfor='hh:mm:ss')
      tstr = time_string( smt_time[img_idx])
      
      ;Origin of the image
      x0 = i * dxsize
      y0 = ysize - (j+1)*dysize
      
      ;Draw the image
      redimg = congrid(img,dxsize,dysize)
      tvscl, redimg, x0, y0, /device
      
      ;Annotate the time label
      xyouts, x0+dxsize/2.,y0+5, tstr, /device, charsize=1.5, color=255, $
	alignment=0.5
      
      img_idx ++
      
    endfor
  endfor
  
  return
end
