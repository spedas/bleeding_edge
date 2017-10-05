;+
;PROCEDURE:  	copy_data,  oldname, newname
;PURPOSE:	to copy a data structure
;INPUT:	
;	oldname:	name associated with old data structure
;	newname:	name associated with new data structure
;KEYWORDS:
;       LINK:   if set, then the data is not copied but is linked to the old
;                   name.
;
;SEE ALSO:	"get_data", 
;		"store_data"
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION: copy_data.pro  1.10   97/05/20
;-
pro copy_data,oldnames,newname,LINK=link,clone=clone
names = tnames(oldnames,n)

for i=0,n-1 do begin
  undefine,lim,data,dlim,ptr
  if keyword_set(clone) then begin
      get_data,names[i],ptr=ptr,lim=lim,dlim=dlim
      store_data,names[i]+clone,data=ptr,lim=lim,dlim=dlim
  endif else begin
      get_data,names[i],lim=lim,data=data,dlim=dlim
      if keyword_set(link) then data = oldname
      store_data,newname,lim=lim,data=data,dlim=dlim
  endelse
endfor
return
end




