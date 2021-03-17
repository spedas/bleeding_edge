;+
;PROCEDURE:  	copy_data,  oldnames, newnames
;PURPOSE:	to copy a data structure
;INPUT:
;	oldnames:	names associated with old data structure
;	newnames:	names associated with new data structure
;KEYWORDS:
;       LINK:   if set, then the data is not copied but is linked to the old
;                   name.
;
;SEE ALSO:	"get_data",
;		"store_data"
;
;CREATED BY:	Davin Larson
;$LastChangedBy: ali $
;$LastChangedDate: 2020-11-05 22:46:13 -0800 (Thu, 05 Nov 2020) $
;$LastChangedRevision: 29332 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/copy_data.pro $
;-
pro copy_data,oldnames,newnames,LINK=link,clone=clone,suffix=suffix
  names = tnames(oldnames,n)
  if ~keyword_set(suffix) then suffix='copy'
  if ~keyword_set(newnames) then newnames=names+'_'+suffix
  for i=0,n-1 do begin
    undefine,lim,data,dlim,ptr
    if keyword_set(clone) then begin
      get_data,names[i],ptr=ptr,lim=lim,dlim=dlim
      store_data,names[i]+clone,data=ptr,lim=lim,dlim=dlim
    endif else begin
      get_data,names[i],lim=lim,data=data,dlim=dlim
      if keyword_set(link) then data = oldnames
      store_data,newnames[i],lim=lim,data=data,dlim=dlim
    endelse
  endfor
  return
end




