;Purpose: Wraps an integer around specified boundss.
;Example: intwrap(31,[0,31]) returns 31
;		  intwrap(32,[0,31]) returns 0
;		  intwrap(33,[0,31]) returns 1
;		  intwrap(34,[0,31]) returns 2
;		  Etc...
;Update History: Written by Dillon Wong.
;				 Last modified on June 9, 2010.
;				 Unnecessary error checking removed on June 9, 2010.
;Notes: Routine should work with nonintegers too, but don't count on it.
;		Routine might be more efficient if redesigned to use MOD.

function intwrap,num,bounds

nvalue=num
ltarray=0
gtarray=0

while (ltarray[0] NE -1) OR (gtarray[0] NE -1) do begin
	
	ltarray=where(nvalue LT bounds[0])
	gtarray=where(nvalue GT bounds[1])
	
	if ltarray[0] NE -1 then nvalue[ltarray]+=bounds[1]-bounds[0]+1
	if gtarray[0] NE -1 then nvalue[gtarray]+=bounds[0]-bounds[1]-1
	
endwhile

return,nvalue

end