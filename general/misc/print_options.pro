;+
;PROCEDURE: print_options
;PURPOSE:  controls postscript printing options
;KEYWORDS:
;  PORT:   print pages in portrait format (default)
;  LAND:   print pages in landscape format
;  BW:     Use black and white mode  (untested)
;  COLOR:  Use Color postscript (default)
;  XSIZE:  plot size dimension in the x direction
;  YSIZE:  plot size dimension in the y direction
;  UNITS:  plot size units (inches or cm)
;FUTURE OPTIONS:
;  Ecapsulated postscript format
;  changing plotting area
;HISOTRY:
; 4-apr-2008   cg, added optional keywords for postscript
;                  file size and file size units
;SEE ALSO:	"popen","pclose"
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	@(#)print_options.pro	1.16 97/05/30
;-


pro print_options,      $
  PORTRAIT=port,   $
  LANDSCAPE=land,   $
  BW = bw,     $
  COLOR=col,   $
  ASPECT=aspect,  $
  XSIZE=xsize, $
  YSIZE=ysize, $
  UNITS=units, $
  FONT= font,  $
  PRINTER=printer, $
  DIRECTORY=printdir

@popen_com.pro
; Set defaults:
if n_elements(portrait) eq 0 then portrait=1
if n_elements(in_color) eq 0 then in_color=1
if n_elements(printer_name) eq 0 then printer_name=''
if n_elements(print_directory) eq 0 then print_directory=''
if n_elements(print_font) eq 0 then print_font = 0
if n_elements(print_aspect) eq 0 then print_aspect = 0
inches = 1
x_papersize = 8.5
y_papersize = 11.
x_aspect = 8.
y_aspect = 10.5


if keyword_set(units) then Begin
  units = strcompress(/remove_all, units)
  if (units ne 'inches') then Begin
    inches=0
    x_papersize = x_papersize*2.54
    y_papersize = y_papersize*2.54
    if keyword_set(aspect) then Begin
      aspect = aspect*2.54
      x_aspect = x_aspect*2.54
      y_aspect = y_aspect*2.54
    endif
  endif
endif

if keyword_set(land)    then  portrait= 0
if keyword_set(port)    then  portrait= 1
if keyword_set(col)     then  in_color= 1
if keyword_set(bw)      then  in_color= 0
if n_elements(printer)  ne 0 then  printer_name=printer
if n_elements(printdir) ne 0 then  print_directory=printdir
if n_elements(font)     ne 0 then  print_font = font
if n_elements(aspect)   ne 0 then  print_aspect=aspect

if !d.name eq 'PS' then begin
  aspect = print_aspect
  if keyword_set(aspect) then begin
    if portrait then scale=(x_aspect < y_aspect/aspect) else scale=(y_aspect < x_aspect/aspect)
    s = [1.0,aspect] * scale
    if portrait then offs =[(x_papersize-s[0])/2,y_papersize-.5-s[1]] $
    else offs=[(x_papersize-s[1])/2,y_papersize-(y_papersize-s[0])/2]
    if inches then begin
      device,port=portrait,/inch,ysize=s[1],xsize=s[0],yoff=offs[1],xoff=offs[0]
    endif else begin
      device,port=portrait,ysize=s[1],xsize=s[0],yoff=offs[1],xoff=offs[0]
    endelse
  endif else begin
    if portrait then begin
      if not keyword_set(xsize) then xsize = 7.0
      if not keyword_set(ysize) then ysize = 9.5
      xoff= (x_papersize - xsize)/2
      yoff= (y_papersize - ysize)/2
    endif else begin
      if not keyword_set(xsize) then xsize = 9.5
      if not keyword_set(ysize) then ysize = 7.0
; The following lines were incorrect and gave the wrong margins for landscape plots
;      xoff= (x_papersize - xsize)/2
;      yoff= y_papersize - (y_papersize-ysize)/2
; Here are the corrected lines - mcfadden, 08-10-11
      xoff= (y_papersize - xsize)/2
      yoff= y_papersize - (x_papersize - ysize)/2

      if not(inches) then Begin
        xoff= (x_papersize - xsize)/2
        yoff= y_papersize - (y_papersize-ysize)/2
      endif
    endelse

    if inches then begin
      device,port=portrait,/inches,ysize=ysize,yoff=yoff,xsize=xsize,xoff=xoff
    endif else begin
      device,port=portrait,ysize=ysize,yoff=yoff,xsize=xsize,xoff=xoff
    endelse
  endelse
  if in_color then device,/color,bits=8  $
  else   device,color=0
  !p.font = print_font
endif

return
end



