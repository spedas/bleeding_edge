;+
;PROCEDURE: delta_data, n1,n2
;PURPOSE:
;   Creates a tplot variable that is the derivative of a tplot variable.
;INPUT: n1  tplot variable names (strings)
;
;Keywords:
; newname = the name of the tplot variable in which output should be
;    stored. This will produce an error if you use this option with globbing.
; nsmooth = If this keyword is set smoothing will be performed.  The
;           number you set this keyword equal to is the width of the smoothing 
;           to be applied to the data.  It is the same as the
;           width argument to the idl smooth procedure. To get an explanation of
;           how this keyword works please see the idl documentation for the
;           'width' keyword to the idl 'smooth' procedure.
; suffix = the suffix to be applied to the input data.  Use this if you
;          want to call this procedure on multiple tplot variables
;          simultaneously.
; replace = set this keyword if you want to replace the original
;           variables with the new values
; display_object = Object reference to be passed to dprint for output.
;
; Examples:
;
;
; $LastChangedBy:  $
; $LastChangedDate: 2008-04-28 13:27:07 -0700 (Mon, 28 Apr 2008) $
; $LastChangedRevision: 2851 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/branches/tdas_4_00/idl/themis/common/thm_config.pro $
;
;-
PRO delta_data,names,newname=newname,nsmooth=nsmth,suffix=suffix,replace=replace, display_object=display_object, modulo=modulo

ns = tnames(names,n)

;validate keywords and set defaults
if n_elements(ns) gt 1 && keyword_set(newname) then begin
  message,'Cannot call deriv_data on multiple tplot variables and use the newname keyword at the same time'
endif

if keyword_set(replace) && keyword_set(suffix) then begin
  message,'Replace and suffix are mutually exclusive keywords'
endif 

if n_elements(suffix) EQ 0 then begin
  suffix = '_delta'
endif

if keyword_set(replace) then begin
   suffix = ''
endif
 
for i=0,n-1 do begin
  n1 = ns[i]
  get_data,n1,data=d,dlimits=dl

  if not keyword_set(d)  then begin
     msg = 'data not defined! '+n1
     dprint, verbose = verbose, dlevel = 2, msg, display_object=display_object
     continue
  endif
  if(n_elements(d.x) Lt 3) then begin
     msg = 'not enough time elements for derivative: '+n1
     dprint, verbose = verbose, dlevel = 2, msg, display_object=display_object
     continue
  endif

  if ~keyword_set(newname) then begin
     nout = n1+suffix
  endif else begin
     nout = newname
  endelse

  if keyword_set(nsmth) then begin
     d.x = smooth(d.x,nsmth < (n_elements(d.x)-1),/nan,/edge_truncate)
     for j=0, n_elements(d.y[0,*])-1 do begin
       d.y[*,j] = smooth(d.y[*,j],nsmth < (n_elements(d.y[*,j])-1),/nan,/edge_truncate)
     endfor
  endif

  ;for state derived quantities, guarantee that the metadata properly reflects derivative number  
  str_element,dl,'data_att.st_type',st_type,success=s
  
  if s then begin
    if st_type eq 'pos' then begin
      str_element,dl,'data_att.st_type','vel',/add
    endif else if st_type eq 'vel' then begin
      str_element,dl,'data_att.st_type','acc',/add
    endif
  endif
  
  ;append correction to units
  ;also check y axis subtitle for unit reference
  str_element,dl,'data_att.units',units,success=s
  if s then begin
    dl.data_att.units += '/s'
    str_element,dl,'ysubtitle', yst, success=s2
    if s2 then begin
      split = stregex(yst, '(.*\['+units+')(\].*)', /subexp,/extract)
      if split[0] ne '' then begin
        dl.ysubtitle = split[1]+'/s'+split[2]
      endif
    endif
  endif

;  y = double(d.y)
;  if ndimen(d.y) eq 1 then y = deriv(d.x,double(d.y))
;  if ndimen(d.y) eq 2 then $
;     for j=0,dimen2(d.y)-1 do y[*,j] = deriv(d.x,d.y[*,j])
;
  y = d.y 
  if ndimen(d.y) eq 1 then y = y - shift(y,1)
  IF ndimen(d.y) eq 2 then y = y - shift(y,1,0)
  if keyword_set(modulo) then y = y mod modulo

  store_data,nout,data={x:d.x,y:y},dlimits=dl
endfor
return
end
