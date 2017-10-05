
;  .run
function omega,t
;return, .5+t*0
return,5*10.^(-.7*cos(.04*t))
;return,5*10.^(-.7*cos(.04*t))
end

;  .run
function wave1,t,x
dx = x
w = omega(t)
wa = sqrt(total(([w,1]*x)^2))
dx[0] = x[1]
dx[1] = -(w*w)*x[0]
return,dx
end

n = 60000
dt = .005d

;   .run
t = dblarr(n)
x = dblarr(n)
x0 = [1d,0d]
t0 = 0d

for i=0l,n-1 do begin
  x0 = rk4(x0,wave1(t[i],x0),t0,dt,'wave1',/double)
  x[i] = x0[0]
  t[i] = t0
  t0 = t0+dt
endfor


;plot,t,x
amp = 1/sqrt(omega(t)/omega(t[0]))
oplot,t,amp,col=3
x1 = x/amp
plot,t,x1

skip = 8
skip = 1
ind = lindgen(n/skip)*skip

daughter = 1
w = wavelet(x1[ind],dt*skip,pad=2,period=period,/ver,coi=coi,daughter=daughter,wavenum=k)
;  w = wavelet2(x1[ind],dt*skip,pad=2,period=period,/ver,prang=dt*skip*[10,4000],param=param)

ylim,lim,1,1,1
options,lim,no_interp=1
;box,lim
scale = replicate(1,n_elements(ind)) # period
specplot,t[ind],1/period,abs(w)^2/scale,lim=lim
oplot,t[ind],1/(2*!pi/omega(t[ind]))
oplot,t[ind],1/coi

;  x1 = x1+ shift(x1,fix(n/3))

end

