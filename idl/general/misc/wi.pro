;+
;PROCEDURE:     wi, wnum
;
;PURPOSE:   Switch or open windows.
;
;INPUT:
;   wnum - the window number.
;
;CREATED BY:    REE, 95-10-23
;completely rewritten by DEL 2006
;FILE: wi.pro
;VERSION: 1.6
;LAST MODIFICATION: 97/06/03
;-

pro wi, wnum , limits=lim,wsize=wsize,wposition=wposition,show=show,verbose=verbose, _extra=ex

;if data_type(lim) eq 8 then begin
;   str_element,lim,'window',value=wnum
;   if n_elements(wnum) eq 0 then return
;   if wnum lt 0 then return
;endif

if (!d.flags and 256) eq 0 then begin          ; device has no windows!
   dprint,dlevel=2,'Device has no windows!',/no_check_events
   if keyword_set(wsize) then begin
         device, set_resolution = wsize   
   endif
   return
endif

if n_elements(wnum) eq 0 then begin
   wnum=!d.window
   dprint,'Current window is: ',wnum,form='(a,i0)',verbose=verbose,dlevel=2,/no_check_events
endif

device,window_state=windows

s = windows[wnum > 0]

if s eq 1 then begin
   wset,wnum
   if not keyword_set(wsize) then wsize = [!d.x_size,!d.y_size]
   if wsize[0] ne !d.x_size or wsize[1] ne !d.y_size then s=0
endif

if s eq 0 then begin
      if keyword_set(wposition) then begin
          xpos = wposition[0]
          ypos = wposition[1]
      endif
      if keyword_set(wsize) then $
         window,wnum > 0,xsize=wsize[0],ysize=wsize[1],xpos=xpos,ypos=ypos,_extra=ex  $
      else  $
         window,wnum > 0,_extra=ex
endif

if keyword_set(show) then wshow

return
end
