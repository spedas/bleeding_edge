;+
;PROCEDURE:  makepng, filename
;NAME:
;  makepng
;PURPOSE:
;  Creates a PNG file from the currently displayed image.
;PARAMETERS:
;  filename   filename of png file to create.  Defaults to 'plot'. Note:
;             extension '.png' is added automatically
;KEYWORDS:
;  ct         Index of color table to load.  Note: will have global
;             consequences!
;  multiple   Does nothing.
;  close      Does nothing.
;  no_expose  Don't print index of current window.
;  mkdir      If set, make the parent directory/directories of the
;             file specified by filename.
;  TIMETAG :  1 - Use current local time
;          :  2 - Use current GMT
;          :  >2  Use unix time
;  WINDOW  :  window number
;
;Restrictions:
;  Current device should have readable pixels (ie. 'x' or 'z')
;
;Created by:  Davin Larson
;FILE:  makepng.pro
;VERSION:  1.11
;LAST MODIFICATION:  02/11/06
;-
pro makepng,filename,multiple=multiple,close=close,ct=ct,no_expose=no_expose,  $
    mkdir=mkdir,window=window,suffix=suffix,timetag=timetag,verbose=verbose
    ;if keyword_set(close) then begin
    ;   write_gif,/close
    ;   return
    ;endif

    if n_elements(window) ne 0 then wset,window
    if not keyword_set(no_expose) then  wi,window,verbose=0  ; wshow,icon=0
    if n_elements(ct) ne 0 then loadct2,ct  ;cluge!
    if not keyword_set(filename) then filename = 'plot'
    if keyword_set(timetag) then begin
        if timetag gt 2 then tt = timetag else tt = systime(1)
        suffix= time_string(local = timetag eq 1,tt,tformat='_YYYYMMDD_hhmmss')
    endif
    if not keyword_set(suffix) then suffix = ''
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
        
        im = im1
    endif else im = tvrd()
    pngfile = filename+suffix+'.png'
    if !version.release eq '5.3' then begin
        write_png,pngfile,rotate(im,7),r,g,b
    endif else if !version.release ge '5.4' then begin
        write_png,pngfile,im,r,g,b
    endif
    ;if !version.release ne '5.4' then $
    ;  write_gif,filename+'.gif',im,r,g,b,multiple=multiple
    if size(window,/type) lt 1 then window = !d.window
    dprint,verbose=verbose,dlevel=2,'Created PNG: '+pngfile+'  from window '+strtrim(window,2)
end
