;+
;PROCEDURE:
;   find_interval
;   
;PURPOSE:
;   This routine looks for intervals of consecutive indices in an index array
;    and determines start and end index of each interval.
;    
;INPUT:
;  index:  index array usually from where function
;
;OUTPUT:
;  istart: index of first element of an interval
;  iend  : index of last element of an interval
;
;AUTHOR:
;v1.0 S.Frey 12-30-03
;-
pro find_interval,index,istart,iend 

  index=index[uniq(index,sort(index))]
  diff=index-shift(index,1)
  temp=where(diff gt 1,count)
  if count ne 0 then begin
   temp=[0,temp]
   diff2=(temp-shift(temp,1))[1:*]
  endif else begin
   temp=0
   diff2=n_elements(index)
  endelse
  istart=index[temp]
  iend=index[temp+diff2-1]
  if index[n_elements(index)-1] ge istart[n_elements(istart)-1] and $
     index[n_elements(index)-1] ne iend[n_elements(iend)-1]   then $
     iend=[iend,index[n_elements(index)-1]]

end