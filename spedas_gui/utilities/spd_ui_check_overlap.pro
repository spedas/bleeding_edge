
;+
;NAME:
;  spd_ui_check_overlap
;
;PURPOSE:
;  Determins if any panels on the current
;   page are overlapping.
;  Prints message notifying user of those panels.
;
;CALLING SEQUENCE:
;  bool = spd_ui_check_overlap( panels, cwindow )
;
;INPUT:
;  panels: Array of current panel objects
;  cwindow: Current window(page) object
;
;OUTPUT:
;  1 if overlaps are found, 0 otherwise
;
;HISTORY:
;
;
;-

function spd_ui_check_overlap, panels, cwindow

    compile_opt idl2, hidden

;create grid to represent page
cwindow->getproperty, nrows=nrows, ncols=ncols
grid = strarr(ncols, nrows)

;loop over all panels
for i=0, n_elements(panels)-1 do begin

  if ~obj_valid(panels[i]) then continue

  ;get position and span data
  layout = panels[i]->getlayoutstructure()

  ;place the panel ID into the grid (use panel ID known to user)
  for j=0, layout.cspan-1 do begin
    for k=0, layout.rspan-1 do begin
      grid[ layout.col-1+j, layout.row-1+k ] +=' '+strtrim(long(i)+1,2)
    endfor
  endfor

endfor

;overlapping panels will be found where there's more than one ID (i.e. string w/ spaces)
x = where( stregex(strtrim(grid,2), '.* .*', /bool),c)
if c gt 0 then overlaps = grid[x]

;loop over any overlaps and drop their ID's into the output message
msg=''
for i=0, c-1 do begin
  ;skip duplicates
  x = where(overlaps eq overlaps[i], n)
  if (n gt 1) and (x[0] lt i) then continue

  ;current = strjoin(strsplit(overlaps[i],/reg,/ext),', ',/single)
  ;13-march-2012 lphilpott 
  ;Modifying so that it prints the panel names the user sees rather than an index into total number of panels
  ; overlapping panel numbers
  panelnums = strsplit(overlaps[i],/reg,/ext)
  for k=0, n_elements(panelnums)-1 do begin
    fullpanelname = panels[panelnums[k]-1]->constructPanelName()
    panelnameparts = strsplit(fullpanelname,'-',/extract) ; remove the name the user has given the panel (mainly because by default there is no name and in that case it looks silly)
    ; nb: not using array_concat below because paneloverlap needs to be reset for each set of conflicts
    if k eq 0 then paneloverlap = [strtrim(panelnameparts[0],2)] else paneloverlap = [paneloverlap,strtrim(panelnameparts[0],2)]
  endfor
  paneloverlapmsg = strjoin(paneloverlap,', ',/single)
  ;msg=[msg,'('+current+')']
  msg = [msg,'['+paneloverlapmsg+']']
endfor

if n_elements(msg) gt 1 then $
  ok = dialog_message('The following sets of panels are overlapping on the page and'+ $
                      ' must be moved before applying:  '+strjoin(msg[1:*], ',  '), $
                      /information, title='Panels overlapping')

;return boolean signifying if overlaps were found
return, (c gt 0)

end
