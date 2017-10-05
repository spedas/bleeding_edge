;+
;PROCEDURE:  makejpg, filename
;NAME:
;  makejpg
;PURPOSE:
;  Creates a jpg file from the currently displayed image.
;PARAMETERS:
;  filename   filename of jpg file to create.  Defaults to 'plot'. Note:
;             extension '.jpg' is added automatically
;KEYWORDS:
;  ct         Index of color table to load.  Note: will have global
;             consequences!
;  multiple   Does nothing.
;  close      Does nothing.
;  no_expose  Don't print index of current window.
;  mkdir      If set, make the parent directory/directories of the
;             file specified by filename.
;
;Restrictions:
;  Current device should have readable pixels (ie. 'x' or 'z')
;
;Based almost entirely on makepng by davin larson 
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2009-11-18 14:36:51 -0800 (Wed, 18 Nov 2009) $
;$LastChangedRevision: 6941 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/makejpg.pro $
;
;-
pro makejpg,filename,multiple=multiple,close=close,ct=ct,no_expose=no_expose,mkdir=mkdir,window=window

;if keyword_set(close) then begin
;   write_gif,/close
;   return
;endif
if n_elements(window) ne 0 then wset,window
if not keyword_set(no_expose) then  wi  ; wshow,icon=0
if n_elements(ct) ne 0 then loadct2,ct  ;cluge!
if not keyword_set(filename) then filename = 'plot'
if keyword_set(mkdir) then begin
   file_mkdir,file_dirname(filename)
endif
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

if !version.release eq '5.3' then $
  im = rotate(im,7)

im2 = bytarr([dimen(im),3])
im2[*,*,0] = r[im]
im2[*,*,1] = g[im]
im2[*,*,2] = b[im] 

write_jpeg,filename+'.jpg',im2,true=3

end
