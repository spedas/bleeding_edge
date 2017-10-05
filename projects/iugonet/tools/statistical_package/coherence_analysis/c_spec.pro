 pro c_spec, xx,yy,tim_secs,coh,phase, thres=thres
if n_elements(thres) eq 1 then thres = 0.9
mask_x = xx
mask_y = yy

mask_x(*) = 1
mask_y(*) = 1

miss = where(xx ge 998.)
if miss(0) ne -1 then  mask_x(miss)  = 0
miss = where(yy ge 998.)
if miss(0) ne -1 then  mask_y(miss)  = 0

ntim = n_elements(xx(*,0))
nh   = n_elements(xx(0,*))
rat_x  = total(mask_x,1)/ntim
rat_y  = total(mask_y,1)/ntim


fx = complexarr(ntim/2+1,nh)
fy = complexarr(ntim/2+1,nh)

;print,ntim,nh,rat_x,fx

xx1=fft(xx)
yy1=fft(yy)
for i=0,nh/2 do begin
    append_array,xx2,xx1(i)
    append_array,yy2,yy1(i)
endfor

for i=0,nh-1 do begin
    fx(*,i) = ffft2(xx(*,i),tim_secs)
    fy(*,i) = ffft2(yy(*,i),tim_secs)
endfor

x_p   = abs(fx)^2; *per
y_p   = abs(fy)^2; *per

nomiss = where(rat_x ge thres and rat_y ge thres,nnomiss)
if nomiss(0) ne -1 then begin
    x_s  = total(x_p(*,nomiss),1) /nnomiss
    y_s  = total(y_p(*,nomiss),1) /nnomiss
endif

xy_r = conj(fx)*fy

;xy1=complexarr(n_elements(xy_r))
;xy1(0)=0.5*xy_r(0)+0.5*xy_r(1)
;for i=1,n_elements(xy_r)-2 do begin 
;    xy1(i)=0.25*xy_r(i-1)+0.5*xy_r(i)+0.25*xy_r(i+1)
;endfor
;xy1(n_elements(xy_r)-1)=0.5*xy_r(n_elements(xy_r)-2)+0.5*xy_r(n_elements(xy_r)-1)
xy1=smooth(xy_r,3)

nomiss = where(rat_x ge thres and rat_y ge thres,nnomiss)
if nomiss(0) ne -1 then begin
    xy_e = total(xy_r(*,nomiss),1) /nnomiss
endif
xy_s = abs(xy1)

kxy = float(xy1)
qxy = -imaginary(xy1)
x_p=smooth(x_p,3)
y_p=smooth(y_p,3)

coh   = xy_s/sqrt(x_p*y_p)
phase = atan(qxy,kxy)

end
