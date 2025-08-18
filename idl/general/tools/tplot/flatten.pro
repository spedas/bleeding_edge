pro flatten,handle,tavg,newname=newname,average=avg,nsmooth=nsmooth

for hi=0,n_elements(handle)-1 do begin
name = tnames(handle[hi])
if (n_elements(tavg) ne 2) or (n_elements(name) lt 1) then begin
   ctime,t,vname=n,np=2
   if n_elements(name) eq 0 then name=n(0)
endif else t = time_double(tavg)

if n_elements(name) gt 1 then begin
  for i=0,n_elements(name)-1 do   flatten,name[i],t
  return
endif



get_data,name,dat=dat,lim=lim
if size(/type,newname) ne 7 then newname= name+'_flat'

ind = where(dat.x gt t(0) and dat.x lt t(1),nd)
if keyword_set(nsmooth) then begin
  avg = smooth(dat.y,[nd,1],/nan)
  dprint,'smooth interval= ',nd
endif else begin
  avg = total(dat.y(ind,*),1,/nan) / total(finite(dat.y(ind,*)),1)
  avg = (replicate(1.,dimen1(dat.y)) # avg)
endelse
dat.y = dat.y/ avg
store_data,newname,dat={x:dat.x, y:dat.y, v:dat.v}, $
        dlim={ystyle:1, spec:1, ylog:1, panel_size:2.}

endfor

end
