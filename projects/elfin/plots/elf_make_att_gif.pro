;+
;PROCEDURE:  elf_make_att_gif, filename
;NAME:
;  makegif
;PURPOSE:
;  Creates a GIF file from the currently displayed image. This is a modified version of 
;  makegif.pro that does not create a png file in addition to a gif file. This creates
;  only a gif file.  
;PARAMETERS:
;  filename   filename of gif file to create.  Defaults to 'plot'. Note:
;             extension '.gif' is added automatically
;KEYWORDS:
;  ct         Index of color table to load.  Note: will have global
;             consequences!
;  multiple   Write multiple gifs to a single file. Subsequent calls to
;             makegif with same filename argument will append to the file.
;             Use /close to close.
;  close      close the gif file.  Useful when writing multiple gifs to
;             a single file.  Does not write any image to the file.
;  no_expose  Don't print index of current window.
;
;Restrictions:
;  Current device should have readable pixels (ie. 'x' or 'z')
;
;Created by:  Davin Larson
;FILE:  makegif.pro
;VERSION:  1.11
;LAST MODIFICATION:  02/11/06
;-
pro elf_make_att_gif,filename,multiple=multiple,close=close,ct=ct,no_expose=no_expose
if keyword_set(close) then begin
   write_gif,/close
   return
endif
if not keyword_set(no_expose) then  wi  ; wshow,icon=0
if n_elements(ct) ne 0 then loadct2,ct  ;cluge!
if not keyword_set(filename) then filename = 'plot'
tvlct,r,g,b,/get
if !d.name ne 'Z' then device,get_visual_name=vname else vname = ' '
if vname eq 'TrueColor' then begin
  dim =1
  im1=tvrd(true=dim)
if 0 then begin
t = ((r *256l +g)*256 + b)
t = (( (r/8) *32l +(g/8))*32 + (b/8))
im2=im1/8
index = reform((im2[0,*,*] * 256l+ im2[1,*,*]) * 256 + im2[2,*,*])
index = reform((im2[0,*,*] * 32l+ im2[1,*,*]) * 32 + im2[2,*,*])
h = histogram(index)
w = where(h)
endif
  im =color_quan(im1,dim,r,g,b,get_trans=trans)
  reduce=1
  if keyword_set(reduce) then begin
    reduce_colors,im,v
    r=r[v]
    g=g[v]
    b=b[v]
  endif
endif else im = tvrd()
;if !version.release eq '5.3' then $
;  write_png,filename+'.png',rotate(im,7),r,g,b
;if !version.release ge '5.4' then $
;  write_png,filename+'.png',im,r,g,b
;if !version.release ne '5.4' then $
  write_gif,filename+'.gif',im,r,g,b,multiple=multiple


end
