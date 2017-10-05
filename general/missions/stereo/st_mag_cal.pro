function st_mag_cal,x,parameter=par,probe=probe
if not keyword_set(par) then begin
  if size(/type,probe) ne 7 then probe= ''
  if probe eq 'b' then begin
    rot = reform([1.0019827d, -0.0028700850, -0.00060321601, 0.0066352947, 1.0079380, -0.0059000393, 0.0098349958, -0.0026420171, 1.0023719],3,3)
    del =  [-43.40000d, 19.900000d, -38.0d]  ; good for 2007-9-25
;    del =  [-43.6d, 20.2d, -38.100000d]  ; good for 2007-7-25
;    del =  [-41.1d, 21.6d, -36.7d]  & rot = identity(3,/double) ; good for ???? 2007-9-25

  endif else if probe eq 'a' then begin
    rot = identity(3,/double)
    del = dblarr(3)
  endif else begin
    rot = identity(3,/double)
    del = dblarr(3)
  endelse
  par = {func:'st_mag_cal', del:del, rot:rot ,probe:probe}
endif

if n_params() eq 0 then return, par

dim = size(/dimens,x)
if n_elements(dim) eq 2 then delta= replicate(1,dim[0]) # par.del else delta = par.del
y = x - delta
y = par.rot ## y

return,y

end






function st_mag_cal2,x,parameter=par

if not keyword_set(par) then par = {func:'st_mag_cal2',qnorm:1, del:[0d,0d,0d], q:[1d,0d,0d,0d] }

if par.qnorm then par.q /= sqrt(total(par.q^2))    ; force normalization
if n_params() eq 0 then return, par

dim = size(/dimens,x)
if n_elements(dim) eq 2 then delta= replicate(1,dim[0]) # par.del else delta = par.del

y = x - delta
y = quaternion_rotation(y,par.q)
return,y
end


;if not keyword_set(tscal) then $
   ctime,tscal
timebar,tscal
if not keyword_set(stx_) then  stx_ = 'st'+probe+'_'
b0 = tsample(stx_+'UV_B_SC',tscal,times=t0)
b1 = tsample(stx_+'B_SC',tscal,times=t1)
printdat,b0,b1,t0,t1
dprint,minmax(t0-t1)
par = st_mag_cal(probe=probe)
;par = st_mag_cal2()

;;par.q=[1,0,0,0]
;fit,b0,b1,param=par ,nam='del'

fit,b0,b1,param=par

;store_data,'b0',data={x:t0,y:b0} , dlim={colors:'bgr'}
;store_data,'b1',data={x:t1,y:b1} , dlim={colors:'bgr'}
store_data,'B_residual',data={x:t1,y: b1-func(b0,param=par)},dlim={colors:'bgr'}


end


