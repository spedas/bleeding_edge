;+
;NAME: barrel_selecttimes.pro
;DESCRIPTION: use mouse to select a time interval from a lightcurve
;already plotted 
;
;REQUIRED INPUTS:
;x,y     x and y values of data plotted (lightcurve)
; 
;OPTIONAL INPUTS:
;color   color code for overplotting selected data
;
;OUTPUTS:
;subset       locations of selected data in the array
;subsetsize   length of array "subset"
;
;CALLS:  cursor
;
;NOTES: 
;
;STATUS: ok
;
;TO BE ADDED:
;might possibly add a mouse-free option later
;
;REVISION HISTORY:
;Version 3.0 DMS 9/9/13
;  change since version 2.9: removed xplot start and end (not used) 
;-


pro barrel_selecttimes,x,y,subset,subsetsize,color=color
if not keyword_set(color) then color=100

;select a subset
cursor,x1,y1,/down
cursor,x2,y2,/down
subset=where(x ge x1 and x le x2,subsetsize)

;overplot
if subsetsize gt 0 then begin
  oplot,x[subset],y[subset],color=color
endif else begin
  subset=-1
  print,'Failed to get a subset of data; remember to click from left to right.'
endelse

end


