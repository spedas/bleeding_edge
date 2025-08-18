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
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-04-12 11:07:59 -0700 (Wed, 12 Apr 2023) $
; $LastChangedRevision: 31736 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/makepng.pro $
;-
pro makepng,filename,multiple=multiple,close=close,ct=ct,no_expose=no_expose,  $
    mkdir=mkdir,window=window,suffix=suffix,timetag=timetag,verbose=verbose,transparent=transparent
    ;if keyword_set(close) then begin
    ;   write_gif,/close
    ;   return
    ;endif

    if not keyword_set(filename) then filename = 'plot'
    if n_elements(window) ne 0 then begin
      if n_elements(window) eq 1 && window eq -1 then begin
        device,window_state=windows
        window = where(windows,/null)
      endif
      if n_elements(window) gt 1 then begin
        for w=0,n_elements(window)-1 do begin
          makepng,filename+'_w'+strtrim(window[w],2),timetag=timetag,window=window[w],verbose=verbose
        endfor
        return
      endif
      wset,window
    endif
    if not keyword_set(no_expose) then  wi,window,verbose=0  ; wshow,icon=0
    if n_elements(ct) ne 0 then loadct2,ct  ;cluge!
    if keyword_set(timetag) then begin
        if timetag gt 2 then tt = timetag else tt = systime(1)
        suffix= time_string(local = timetag eq 1,tt,tformat='_YYYYMMDD_hhmmss')
    endif
    if not keyword_set(suffix) then suffix = ''
    if keyword_set(mkdir) then begin
        file_mkdir,file_dirname(filename)
    endif
    tvlct,r,g,b,/get
    if !d.name ne 'Z' then device,get_visual_name=vname else begin
;allow TrueColor in Z buffer, jimm, 2023-04-12
       device, get_pixel_depth = npix ;TrueColor wil have npix=24, dc = 0
       device, get_decomposed = dc
       if npix Eq 24 and dc Eq 0 then vname = 'TrueColor' $
       else vname = ' '
    endelse
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
        if keyword_set(transparent) then begin
          red = reform(im[0,*,*])
          grn = reform(im[1,*,*])
          blu = reform(im[2,*,*])
          whiteIndices = Where((red eq 255) and (grn eq 255) and (blu eq 255), count)
          s = Size(im, /DIMENSIONS)
          alpha = BytArr(s[1],s[2]) + 255B
          IF count GT 0 THEN alpha[whiteIndices] = 0 
          im = transpose([[[transpose(red)]], [[transpose(grn)]], [[transpose(blu)]],[[transpose(alpha)]]])
        endif  
        write_png,pngfile,im,r,g,b
    endif
    ;if !version.release ne '5.4' then $
    ;  write_gif,filename+'.gif',im,r,g,b,multiple=multiple
    if size(window,/type) lt 1 then window = !d.window
    dprint,verbose=verbose,dlevel=2,'Created PNG: '+file_info_string(pngfile)+' from window '+strtrim(window,2)
end
