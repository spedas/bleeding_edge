FUNCTION tnames,s,n,index=ind,all=all,tplot=tplot , $
   create_time=create_time,trange=trange,dtype=dtype,dataquants=dataquants
;+
;FUNCTION:              names=tnames(s [,n])
;PURPOSE:
;                       Returns an array of "TPLOT" names
;                       This routine accepts wildcard characters.
;CALLING SEQUENCE:      nam=tnames('wi*') ; match tplot variables that start with 'wi'
;INPUTS:                s: a match string (ie.  '*B3*' )
;OPTIONAL INPUTS:       s: an array of indices for tplot variables
;KEYWORD PARAMETERS:
; INDEX:          named variable in which the  the indices are returned.
; TRANGE:         named variable in which the  start / end times are returned
; CREATE_TIME     named variable in which the  creation time is stored.
; TPLOT:          if set then returns only the variables plotted in the most recent call to TPLOT
; DATAQUANTS:     if set then it returns the entire array of current stored TPLOT data quantities.

;OUTPUTS:               a data name or array of data names
;OTHER OUTPUTS:         n: the number of matched strings
;COMMON BLOCKS:         tplot_com
;SIDE EFFECTS:          none
;EXAMPLE:               print,tnames('*wi*')
;VERSION:   1.8  @(#)tnames.pro  1.8 02/11/01
;copied from iton.pro
;CREATED BY:            Davin Larson   Feb 1999
;-
@tplot_com

if keyword_set(tplot) then begin
   s=''
   str_element,tplot_vars,'settings.varnames',s
;   s=tplot_vars.settings.varnames
   all=1
endif
ndq = n_elements(data_quants)-1
n = 0
ind = 0
if ndq le 0 then goto, done  ; no data
names = data_quants.name

if size(/type,s) eq 0 then s='*'  ; return all names

if size(/type,s) eq 7 then begin             ;input is a string to match
   if ndimen(s) eq 0 then sa=strsplit(s,' ',/extract) else sa=s
   if not keyword_set(all) then begin
      ind = strfilter(names[1:*],sa,count=n,/index) + 1
      goto, done
   endif else begin
     for i=0,n_elements(sa)-1 do begin
        sel = strfilter(names[1:*],sa[i],/index)
        ind = (i eq 0) ? sel : [ind,sel]
     endfor
     ind = ind+1
     w = where(ind gt 0,n)
     if n ne 0 then begin
       ind = ind[w]
       goto, done
     endif
     ind = 0
     goto, done
   endelse
endif

if size(/type,s) le 5 then begin
  i = round(s)
  w = where(i ge 1 and i le ndq,n)
  if n ne 0 then ind=i[w]
  goto, done
endif

done:

create_time=0
trange=0
dtype=0
if n eq 0 then  return,''
if n_elements(ind) eq 1 then ind=ind[0]
create_time = data_quants[ind].create_time
trange = data_quants[ind].trange
dtype = data_quants[ind].dtype
if keyword_set(dataquants) then return, data_quants[ind]
return,names[ind]

END
