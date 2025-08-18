;+
;NAME:
;  getxy
;PURPOSE:
;  Routine that uses the cursor to select points.
;-
pro getxy,x,y  $
  ,psym = psym $
  ,norm = norm $
  ,device = device $
  ,continue = cont


if (!d.flags and 128) eq 0 then begin
  message,/info,"Sorry, can't read the cursor with current device ("+!d.name+")"
  return
endif

if n_elements(psym) eq 0 then psym = -1
!ERR = 0
;x = 0
;y = 0
n = 0
count = 0
wi & print,'Left click on Plot to select points,  right click to quit'
while !ERR ne 4 do begin
   cursor,px,py,/down,norm=norm,device=device
   if !err eq 1 then begin
       if count eq 0 then begin
           x = px
           y = py
       endif else begin
           x = [x,px]
           y = [y,py]
       endelse
       plots,px,py,psym = psym,continue=n,norm=norm,device=device
       if keyword_set(cont) then n = n+1
       count = count+1
       print,px,py
   endif

endwhile
end
