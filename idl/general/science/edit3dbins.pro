;+
;PROCEDURE:  edit3dbins,dat,bins
;PURPOSE:   Interactive procedure to produce a bin array for selectively
;    turning angle bins on and off.  Works on a 3d structure (see
;    "3D_STRUCTURE" for more info)
;
;INPUT:
;   dat:  3d data structure.  (will not be altered)
;   bins:  a named variable in which to return the results.
;KEYWORDS:
;   EBINS:     Specifies energy bins to plot.
;   SUM_EBINS: Specifies how many bins to sum, starting with EBINS.  If
;              SUM_EBINS is a scalar, that number of bins is summed for
;              each bin in EBINS.  If SUM_EBINS is an array, then each
;              array element will hold the number of bins to sum starting
;              at each bin in EBINS.  In the array case, EBINS and SUM_EBINS
;              must have the same number of elements.
;SEE ALSO:  "PLOT3D_NEW" and "PLOT3D_OPTIONS"
;CREATED BY:	Davin Larson
;FILE: edit3dbins.pro
;VERSION:  1.14
;LAST MODIFICATION: 98/01/16
;-
pro edit3dbins,dat,bins,lat,lon, $
  spectra= spectralim,   $
  EBINS=ebins,           $
;  SPEC_WINDOW=spwindow,  $
  SUM_EBINS=sum_ebins, $
  tbins=tbins, $
  classic=classic,$
  log=log

; We expect dat to be a structure (type=8). If no times are selected, dat
; could be 0 (not a structure), so we need to check its type first.
if (size(dat,/type) NE 8) then begin
  dprint, 'Invalid data'
  return
endif

; Now that we're sure it's a structure, check whether it's flagged as valid.
if(dat.valid eq 0) then begin
  dprint, 'Invalid data'
  return
endif

str_element,spectralim,'bins',bins
options,spectralim,psym=-4

nb = dat.nbins
n_e= dat.nenergy
phi = total(dat.phi,1)/n_e
theta = total(dat.theta,1)/n_e

;  Convert from flow direction to look direction
;phi = phi-180.
;theta =  - theta

if keyword_set(ebins) then ebins=ebins(0)  $
else ebins=0

if keyword_set(sum_ebins) then sum_ebins=sum_ebins(0) $
else sum_ebins=dat.nenergy

;switched plot3d to plot3d_new to avoid name conflict in IDL 8.1
plot3d_new,dat,lat,lon,ebins=ebins,sum_ebins=sum_ebins,tbins=tbins,log=log

state = ['off','on']
colorcode = [!p.background,!p.color]

if n_elements(bins) ne dat.nbins then bins = bytarr(nb)+1
lab=strcompress(indgen(dat.nbins),/rem)
xyouts,phi,theta,lab,align=.5,COLOR=colorcode(bins)

str_element,spectralim,'bins',bins,/add


if keyword_set(classic) then begin

  print, 'ON: Button1;    OFF: Button2;   QUIT: Button3'
  cursor,ph,th
  button = !err
  while button ne 4 do begin
    if th ge 1000. then goto, ctnu
    pa = pangle(theta,phi,th,ph)
    minpa = min(pa,b)
    current = bins(b)
    bins(b) = button eq 1
    if current ne bins(b) then begin
      print,ph,th,b,'  ',state(bins(b))
      xyouts,phi(b),theta(b),lab(b),align=.5,COLOR=colorcode(bins(b))
      if keyword_set(spectralim) then begin
         w = !d.window
         wi,w+1
         spectralim.bins = bins
         spec3d,dat,lim=spectralim
         wi,w
         ;switched plot3d to plot3d_new to avoid name conflict in IDL 8.1
         plot3d_new,dat,lat,lon,ebins=ebins,sum_ebins=sum_ebins,/setlim,tbins=tbins,log=log
      endif
    endif
  ctnu:
    cursor,ph,th
    button = !err
  endwhile

endif else begin

  ;new version used for mac compatitiblity.  Right click is difficult on mac, middle click even harder.  
  ;This version supports exit with right click and double click, rather than middle click.  
  print, 'ON/OFF: Left Click;    QUIT: Double Click or Right Click'
  cursor,ph,th, /up  ;check for complete click
  button = !mouse.button
  mouse_time = 0ul
  double_click_lim = 350 ;time is measured in milliseconds
  while (ulong(!mouse.time)-mouse_time) gt double_click_lim and button ne 4 do begin  ;quit if right button
;    help,/str,!mouse
    mouse_time = ulong(!mouse.time)
    if ~(th ge 1000.) then begin
      if button eq 1 then begin  ;flip bin if left button
        pa = pangle(theta,phi,th,ph)
        minpa = min(pa,b)
        bins(b) = ~(bins(b) eq 1) ; flip bin on/off
        print,ph,th,b,'  ',state(bins(b))
        xyouts,phi(b),theta(b),lab(b),align=.5,COLOR=colorcode(bins(b))
        if keyword_set(spectralim) then begin
           w = !d.window
           wi,w+1
           spectralim.bins = bins
           spec3d,dat,lim=spectralim
           wi,w
           ;switched plot3d to plot3d_new to avoid name conflict in IDL 8.1
           plot3d_new,dat,lat,lon,ebins=ebins,sum_ebins=sum_ebins,/setlim,tbins=tbins,log=log
        endif
      endif
    endif
    cursor,ph,th, /up  ;recheck
    button = !mouse.button
  endwhile
  
;  help,/str,!mouse
  
  ;if exit with a double click, then toggled the flipped bin back 
  ;This is because a double click will inevitably accidentally toggle a bin with the first click
  if (ulong(!mouse.time)-mouse_time) le double_click_lim then begin
   pa = pangle(theta,phi,th,ph)
   minpa = min(pa,b)
   bins(b) = ~(bins(b) eq 1) ; flip bin on/off
   xyouts,phi(b),theta(b),lab(b),align=.5,COLOR=colorcode(bins(b))
  end

endelse

return
end
