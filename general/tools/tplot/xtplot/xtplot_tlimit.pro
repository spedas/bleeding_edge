; INPUT is the structure 'selected'. 'selected' contains the following information:
; selected.tL: start time of the selected time interval
; selected.tR: end   time of the selected time interval
; selected.xL: start position of the selected time interval in norm coord
; selected.xR: end   position of the selected time interval in norm coord
PRO xtplot_tlimit, selected
  tlimit,selected.tL, selected.tR, /silent
END