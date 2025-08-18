;+
; PROCEDURE:
;       mex_marsis_crosshairs2
; PURPOSE:
;       Modified version of crosshairs.pro for extracting Tce
; CREATED BY:
;       Yuki Harada on 2024-01-19
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro mex_marsis_crosshairs2,x,y,color=color,legend=legend,dot_cursor=dot,fix=fix,$
     silent=silent,nolegend=nolegend,nselected=ndp,to_device=to_device,$
     oneclick=oneclick,lastbutton=lastbutton,lastpoint=lastpoint

common crosscom, x0, y0

ok = 1
oneclick = keyword_set(oneclick)
to_data= ~keyword_set(to_device)
if keyword_set(fix) then begin
  device,set_graphics=3,/cursor_cross
  return
endif
if keyword_set(dot) then begin  ;change the cursor to a dot
  curs=intarr(16)
  curs(14)=2^9
  mask=curs
  mask([13,15])=2^9
  mask(14)=mask(14)+2^8+2^10
  device,cursor_image=curs,cursor_mask=mask,cursor_xy=[1,1]
endif
if not keyword_set(nolegend) then leg  = 1 else leg  = 0
if not keyword_set(silent)   then prin = 1 else prin = 0

device, get_graphics = old, set_graphics = 6  ;Set xor
if not keyword_set(color) then color = !d.n_colors -1
if not keyword_set(legend) then $
  legend = [!d.x_size-22*!d.x_ch_size,!d.y_size-6*!d.y_ch_size] $
else legend = convert_coord(legend(0),legend(1),/data,/to_dev)

flag  = 0

if ~keyword_set(lastpoint) then begin
  x0 = !d.x_size/2                ;crosshairs initially in middle of window
  y0 = !d.y_size/2
endif

data = convert_coord(x0,y0,/dev,to_data=to_data,to_device=to_device)
pys = replicate(!values.f_nan,20)
for i=2,10 do begin
   xydev = convert_coord(data[0],data[1]*i,/data,/to_device)
   pys[i] = round(xydev[1])
endfor
button = 0
goto, middle
wshow
;nselected = 0

while ok do begin
  old_button = button
  cursor, xd, yd, 2, /dev         ;Wait for a button
  data = convert_coord(xd,yd,/dev,to_data=to_data,to_device=to_device)
  pys = replicate(!values.f_nan,20)
  for i=2,10 do begin
     xydev = convert_coord(data[0],data[1]*i,/data,/to_device)
     pys[i] = round(xydev[1])
  endfor
  button = !MOUSE.BUTTON
  lastbutton = button
  x0 = xd
  y0 = yd
  if (!MOUSE.BUTTON eq 1) and (old_button eq 0) then begin
    if flag eq 0 then begin
      x = data(0)
      y = data(1)
      flag = 1
    endif else begin
      x = [x,data(0)]
      y = [y,data(1)]
    endelse
    ndp = n_elements(x)
    numstr = strcompress(string('(',ndp,')'),/re)
    if prin then $
      print,numstr,x(ndp-1),y(ndp-1),format='(a8,3x,"x: ",g,"      y: ",g)'

    if (oneclick) then ok = 0
  endif
  plots,[0,!d.x_size-1],[py,py], color=color, /dev, thick=1, lines=0 
  for i=2,10 do plots,[0,!d.x_size-1],[pys2[i],pys2[i]], color=color, /dev, thick=1, lines=0
  plots,[px,px],[0,!d.y_size-1], color=color, /dev, thick=1, lines=0
  if leg then begin
    xyouts,legend[0],legend[1],                  s1, color=color, /dev, size=1.4
    xyouts,legend[0],legend[1] - 3*!d.y_ch_size, s2, color=color, /dev, size=1.4
  end
  empty
  if !MOUSE.BUTTON eq 2 then begin ;move legend
    legend = [xd,yd]
  endif

  if ((!MOUSE.BUTTON eq 4) or (not ok)) then begin       ;Quitting
    device,set_graphics = old, cursor_cross = dot
    return
  endif

middle:

  px = x0
  py = y0
  pys2 = pys
  plots,[0,!d.x_size-1],[py,py], color=color, /dev, thick=1, lines=0
  for i=2,10 do plots,[0,!d.x_size-1],[pys2[i],pys2[i]], color=color, /dev, thick=1, lines=0
  plots,[px,px],[0,!d.y_size-1], color=color, /dev, thick=1, lines=0
  s1 = string('x:',data(0))
  s2 = string('y:',data(1))
  if leg then begin
    xyouts,legend[0],legend[1],                  s1, color=color, /dev, size=1.4
    xyouts,legend[0],legend[1] - 3*!d.y_ch_size, s2, color=color, /dev, size=1.4
  end
  empty
  wait, .01                      ;be nice!
endwhile
end
