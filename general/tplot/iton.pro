FUNCTION iton,ind
;+
;NAME:                  iton
;PURPOSE:
;                       Convert an index or array of indicies to data names.
;                       This exits because it is not always reasonable to make
;                       a program tell the difference between a data array
;                       and an index array, and because not all programs
;                       accept indicies as inputs instead of data names.
;CALLING SEQUENCE:      names=iton(ind)
;INPUTS:                ind:  an index or array of indicies
;OPTIONAL INPUTS:       none
;KEYWORD PARAMETERS:    none
;OUTPUTS:               a data name or array of data names
;OPTIONAL OUTPUTS:      none
;COMMON BLOCKS:         tplot_com
;SIDE EFFECTS:          none
;EXAMPLE:               for i=6,13 do store_data,iton(6),/delete
;LAST MODIFICATION:     @(#)iton.pro	1.5 97/06/11
;CREATED BY:            Frank Marcoline
;-
@tplot_com
ndq = n_elements(data_quants)

if size(/type,ind) eq 0 then return,tplot_vars.options.varnames

if size(/type,ind) eq 7 then begin             ;input is a string to match
  a = where(strpos(data_quants.name,ind,0) ge 0,c)
  if c eq 0 then return,0
  return,data_quants[a].name
endif

nind = n_elements(ind)
a = where((ind LT 1) OR (ind GE ndq),count)
IF count GT 0 THEN BEGIN
  dprint, 'Data quantities ',a,' do not exist.
  return,strarr(nind)
ENDIF ELSE return,data_quants[ind].name
END
