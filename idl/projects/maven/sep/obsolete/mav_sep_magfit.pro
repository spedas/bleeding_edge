;  multipole_field: computes the magnetic field vector at any position given the magnetic
;  mulitpole moments up to fourth order

function multipole_field,pos,parameters=p,order=ord
mu0_4pi = 100d  ; dimensions = nT-m/A
mu0_4pi = 1d    ; dimensions = .01 nT-m/A
if not keyword_set(p) then begin
  if n_elements(ord) eq 0 then order=[0b,1b,1b,1b,1b]
  if n_elements(ord) eq 1 then order = bindgen(5) gt 0 and bindgen(5) le ord $
  else order = ord
  monopole = {m:0d}
  dipole = {Px:0d,Py:0d,Pz:0d}
  Quadrupole = {Qyy:0d,Qzz:0d,Qxy:0d,Qxz:0d,Qyz:0d}
  octupole={Oxxy:0d,Oxxz:0d,Oyyx:0d,Oyyz:0d,Ozzx:0d,Ozzy:0d,Oxyz:0d}
  Hexadecpole={Sxxyy:0d,Sxxzz:0d,Syyzz:0d,Sxxxy:0d,Sxxxz:0d,Syyyx:0d,Syyyz:0d,Szzzx:0d,Szzzy:0d}
  p = {order:byte(order)}
  if keyword_set(0) then p = struct(p,{dsp:[0.d,0d,0d]})
  if order[0]  then p = struct(p,monopole)
  if order[1]  then p = struct(p,dipole)
  if order[2]  then p = struct(p,quadrupole)
  if order[3]  then p = struct(p,octupole)
  if order[4]  then p = struct(p,hexadecpole)
endif

if n_elements(pos) eq 0 then return,p
dsp = [0d,0d,0d]
str_element,p,'dsp',dsp

x = pos[*,0] - dsp[0]
y = pos[*,1] - dsp[1]
z = pos[*,2] - dsp[2]

r = sqrt(x^2+y^2+z^2)
Bx = 0d *x
By = 0d *y
Bz = 0d *z

if p.order[0] ne 0 then begin
  Bx = p.m * x/r^3
  By = p.m * y/r^3
  Bz = p.m * z/r^3
endif

if p.order[1] ne 0 then begin
  Pr = p.Px*x + p.Py*y +p.Pz*z
  Bx = Bx+ (3*Pr*x/r^2 - p.Px)/r^3
  By = By+ (3*Pr*y/r^2 - p.Py)/r^3
  Bz = Bz+ (3*Pr*z/r^2 - p.Pz)/r^3
endif

if p.order[2]  ne 0 then begin
  Qxx = -p.Qyy - p.Qzz               ; matrix must have zero trace to insure DEL.B=0
  Qrr = Qxx*x^2 + p.Qyy*y^2 + p.Qzz*z^2 +2*p.Qxy*x*y + 2*p.Qxz*x*z + 2*p.Qyz*y*z
  Bx = Bx + (2.5*Qrr*x/r^2- (  Qxx*x + p.Qxy*y + p.Qxz*z))/r^5
  By = By + (2.5*Qrr*y/r^2- (p.Qxy*x + p.Qyy*y + p.Qyz*z))/r^5
  Bz = Bz + (2.5*Qrr*z/r^2- (p.Qxz*x + p.Qyz*y + p.Qzz*z))/r^5
endif

if p.order[3] ne 0 then begin
  Orrr = 6d * p.Oxyz *x*y*z
  Orrr = Orrr + p.Oxxy * (3d*x*x*y-y^3) + p.Oxxz*(3d*x*x*z-z^3)
  Orrr = Orrr + p.Oyyx * (3d*y*y*x-x^3) + p.Oyyz*(3d*y*y*z-z^3)
  Orrr = Orrr + p.Ozzx * (3d*z*z*x-x^3) + p.Ozzy*(3d*z*z*y-y^3)
  Orrx = p.Oyyx*(y^2-x^2) +p.Ozzx*(z^2-x^2)+2*p.Oxxy*x*y +2*p.Oxxz*x*z +2*p.Oxyz*y*z
  Orry = p.Oxxy*(x^2-y^2) +p.Ozzy*(z^2-y^2)+2*p.Oyyx*x*y +2*p.Oyyz*y*z +2*p.Oxyz*x*z
  Orrz = p.Oxxz*(x^2-z^2) +p.Oyyz*(y^2-z^2)+2*p.Ozzx*x*z +2*p.Ozzy*y*z +2*p.Oxyz*x*y

  Bx = Bx + (7d/6d * Orrr *x /r^2 - 0.5d * Orrx)/r^7
  By = By + (7d/6d * Orrr *y /r^2 - 0.5d * Orry)/r^7
  Bz = Bz + (7d/6d * Orrr *z /r^2 - 0.5d * Orrz)/r^7
endif

if p.order[4] ne 0 then begin
  Sxxxx = -p.Sxxyy-p.Sxxzz   ; del.B = 0
  Syyyy = -p.Sxxyy-p.Syyzz
  Szzzz = -p.Sxxzz-p.Syyzz
  Sxxyz = -p.Syyyz-p.Szzzy
  Syyxz = -p.Sxxxz-p.Szzzx
  Szzxy = -p.Syyyx-p.Sxxxy
  Srrrr = Sxxxx*x^4 + Syyyy*y^4 + Szzzz*z^4
  Srrrr = Srrrr +  6*(p.Sxxyy*x^2*y^2 + p.Sxxzz*x^2*y^2 + p.Syyzz*y^2*z^2)
  Srrrr = Srrrr + 12*(  Sxxyz*x^2*y*z +   Syyxz*y^2*x*z +   Szzxy*z^2*x*y)
  Srrrr = Srrrr +  4*(p.Sxxxy*x^3*y   + p.Sxxxz*x^3*z   + p.Syyyx*y^3*z  )
  Srrrr = Srrrr +  4*(p.Syyyz*y^3*z   + p.Szzzx*z^3*x   + p.Szzzy*z^3*y  )
  Srrrx = Sxxxx*x^3 + 3*p.Sxxyy*x*y^2 +3*p.Sxxzz*x*z^2 + 6*Sxxyz*x*y*z + 3*Syyxz*y^2*z + 3*Szzxy*z^2*y + 3*p.Sxxxy*x^2*y +3*p.Sxxxz*x^2*z + p.Syyyx*y^3 + p.Szzzx*z^3
  Srrry = Syyyy*y^3 + 3*p.Sxxyy*x^2*y +3*p.Syyzz*z^2*y + 3*Sxxyz*x^2*z + 6*Syyxz*x*y*z + 3*Szzxy*z^2*x + 3*p.Syyyx*y^2*x +3*p.Syyyz*y^2*z + p.Sxxxy*x^3 + p.Szzzy*z^3
  Srrrz = Szzzz*z^3 + 3*p.Sxxzz*x^2*z +3*p.Syyzz*y^2*z + 3*Sxxyz*x^2*y + 3*Syyxz*y^2*x + 6*Szzxy*x*y*z + 3*p.Szzzx*z^2*x +3*p.Szzzy*z^2*y + p.Syyyz*y^3 + p.Sxxxz*x^3
  Bx = Bx + (9*Srrrr*x/r^11 - 4*Srrrx/r^9)/24
  By = By + (9*Srrrr*y/r^11 - 4*Srrry/r^9)/24
  Bz = Bz + (9*Srrrr*z/r^11 - 4*Srrrz/r^9)/24
  ;  v=[x^4,y^4,z^4, x^2*y^2, x^2*z^2, y^2*z^2, x^2*y*z, y^2*x*z, z^2*x*y, x^3*y, x^3*z, y^3*x, y^3*z, z^3*x, z^3*y]
endif
return, mu0_4pi * [[bx],[by],[bz]]
end




; Returns the permanent and induced magnetic fields given the parameters p and background field B0
function perm_and_induced_field,r,B0,param=p,order=order,iorder=iorder
if not keyword_set(p) then begin
  if n_elements(order) eq 0 then order=2
  if n_elements(iorder) eq 0 then iorder=0
  pp= multipole_field(order=order)
  pi= multipole_field(order=iorder)
  p = {p:pp,i:{scale:100000.,x:pi,y:pi,z:pi}}
endif
if n_params() eq 0  then return,p
b = multipole_field(r,param=p.p)
if keyword_set(B0) then begin
   b = b + B0[0]/p.i.scale * multipole_field(r,param=p.i.x)
   b = b + B0[1]/p.i.scale * multipole_field(r,param=p.i.y)
   b = b + B0[2]/p.i.scale * multipole_field(r,param=p.i.z)

endif
return,b
end

;
;function set_zeros,a,epsilon
;if not keyword_set(epsilon) then epsilon = 1e-12
;w = where(abs(a) lt epsilon,n)
;if n gt 0 then a[w] = 0
;return,a
;end

;
;function  euler_rot_matrix,ev,rot_angle=rot_angle,set_angle=sa
;rot = dblarr(3,3)
;e=double(ev)
;if n_elements(sa) eq 1 then begin
;   e= e / sqrt(total(e^2))
;   e = sqrt((1-cosd(sa))/2) * e * sign(sa)
;endif
;e0 = sqrt( 1 - total(e^2) )
;e1 = e[0]
;e2 = e[1]
;e3 = e[2]
;rot[0,0] = e0^2+e1^2-e2^2-e3^2
;rot[0,1] = 2*(e1*e2 + e0*e3)
;rot[0,2] = 2*(e1*e3 - e0*e2)
;rot[1,0] = 2*(e1*e2 - e0*e3)
;rot[1,1] = e0^2-e1^2+e2^2-e3^2
;rot[1,2] = 2*(e2*e3 + e0*e1)
;rot[2,0] = 2*(e1*e3 + e0*e2)
;rot[2,1] = 2*(e2*e3 - e0*e1)
;rot[2,2] = e0^2-e1^2-e2^2+e3^2
;rot_angle = acos(e0^2-e1^2-e2^2-e3^2)*180/!dpi * sign(total(e*ev))
;return,set_zeros(rot,3e-16)
;end




function orientation_matrix,z_a,x_a
case 1 of
z_a eq  0 and x_a eq  0 :   rot = [[ 1, 0, 0],[ 0, 1, 0],[ 0, 0, 1]]

z_a eq  3 and x_a eq  1 :   rot = [[ 1, 0, 0],[ 0, 1, 0],[ 0, 0, 1]]
z_a eq  3 and x_a eq -1 :   rot = [[-1, 0, 0],[ 0,-1, 0],[ 0, 0, 1]]
z_a eq  3 and x_a eq  2 :   rot = [[ 0, 1, 0],[-1, 0, 0],[ 0, 0, 1]]
z_a eq  3 and x_a eq -2 :   rot = [[ 0,-1, 0],[ 1, 0, 0],[ 0, 0, 1]]

z_a eq -3 and x_a eq  1 :   rot = [[ 1, 0, 0],[ 0,-1, 0],[ 0, 0,-1]]
z_a eq -3 and x_a eq -1 :   rot = [[-1, 0, 0],[ 0, 1, 0],[ 0, 0,-1]]
z_a eq -3 and x_a eq  2 :   rot = [[ 0, 1, 0],[ 1, 0, 0],[ 0, 0,-1]]
z_a eq -3 and x_a eq -2 :   rot = [[ 0,-1, 0],[-1, 0, 0],[ 0, 0,-1]]

z_a eq  2 and x_a eq  1 :   rot = [[ 1, 0, 0],[ 0, 0,-1],[ 0, 1, 0]]
z_a eq  2 and x_a eq -1 :   rot = [[-1, 0, 0],[ 0, 0, 1],[ 0, 1, 0]]
z_a eq  2 and x_a eq  3 :   rot = [[ 0, 0, 1],[ 1, 0, 0],[ 0, 1, 0]]
z_a eq  2 and x_a eq -3 :   rot = [[ 0, 0,-1],[-1, 0, 0],[ 0, 1, 0]]

z_a eq -2 and x_a eq  1 :   rot = [[ 1, 0, 0],[ 0, 0, 1],[ 0,-1, 0]]
z_a eq -2 and x_a eq -1 :   rot = [[-1, 0, 0],[ 0, 0,-1],[ 0,-1, 0]]
z_a eq -2 and x_a eq  3 :   rot = [[ 0, 0, 1],[-1, 0, 0],[ 0,-1, 0]]
z_a eq -2 and x_a eq -3 :   rot = [[ 0, 0,-1],[ 1, 0, 0],[ 0,-1, 0]]

z_a eq  1 and x_a eq  2 :   rot = [[ 0, 1, 0],[ 0, 0, 1],[ 1, 0, 0]]
z_a eq  1 and x_a eq -2 :   rot = [[ 0,-1, 0],[ 0, 0,-1],[ 1, 0, 0]]
z_a eq  1 and x_a eq  3 :   rot = [[ 0, 0, 1],[ 0,-1, 0],[ 1, 0, 0]]
z_a eq  1 and x_a eq -3 :   rot = [[ 0, 0,-1],[ 0, 1, 0],[ 1, 0, 0]]

z_a eq -1 and x_a eq  2 :   rot = [[ 0, 1, 0],[ 0, 0,-1],[-1, 0, 0]]
z_a eq -1 and x_a eq -2 :   rot = [[ 0,-1, 0],[ 0, 0, 1],[-1, 0, 0]]
z_a eq -1 and x_a eq  3 :   rot = [[ 0, 0, 1],[ 0, 1, 0],[-1, 0, 0]]
z_a eq -1 and x_a eq -3 :   rot = [[ 0, 0,-1],[ 0,-1, 0],[-1, 0, 0]]
else: rot = findgen(3,3)

endcase

return,transpose(rot)
end


function mpfield1,dat,param=par,order=order,iorder=iorder

if not keyword_set(par) then begin
  p = perm_and_induced_field(order=order,iorder=iorder)
  datformat = {n:0,r:200.,phic:0.,z_a:3,x_a:1}
  par = struct({func:'mpfield1',file:'',num:0,rscale:100.,bscale:1., $
        datf:datformat,var:'phic',comps:[1,1,1],dpos:fltarr(3,3),  $
        B_offset:fltarr(3),B0:dblarr(3),euler:dblarr(3),euler_ang:0.,dphic:0d,chi:0.},p)
;  par.dpos = [[2.18,0,0],[0,0,0],[0,0,0]]   ; magnetometer  on its side,  all axes aligned
  par.dpos = [[0,0,0],[0,0,0],[0,0,2.18]]    ; magnetometer upright,  axes mixed  (x->-z ;  y->y ;  z->x)
endif

n= n_elements(dat)
if n eq 0 then return,par

if size(/type,dat) ne 8 then begin
    tempdat = replicate(par.datf,n_elements(dat))
    str_element,/add,tempdat,par.var,dat
    return,mpfield1(tempdat,param=par)
endif

euler_param = [0d,0d,0d]
str_element,par,'euler',euler_param
eulrot = euler_rot_matrix(euler_param)
;print,eulrot

b = dblarr(n,3)
for c=0,2 do begin     ;  c is the component of B
for i=0,n-1 do begin
  d = dat[i]

  rmag =  [d.r,0,0] + par.dpos[c,*]

  o_rotmat = orientation_matrix(d.z_a,d.x_a)

  cp = cosd(double(d.phic+par.dphic))
  sp = sind(double(d.phic+par.dphic))
  rot = set_zeros( [[cp,sp,0],[-sp,cp,0],[0,0,1]]  )

  rot1 = o_rotmat ## rot

  irot1 = transpose(rot1)

if abs(determ(irot1) - 1) gt .0001 then message,'Bad rotation'

  rmagprime = rot1 ## rmag
  b0p = rot1 ## par.B0
  bp = perm_and_induced_field(rmagprime/par.rscale,b0p,param=par)
  bp = irot1 ## bp
  bp = eulrot ## bp    ; correction matrix
  if d.z_a eq 0 then bp=0   ;
  bp = bp +par.B0      ; add DC field

  b[i,c] = bp[c]
endfor
endfor
wcomp = where(par.comps)
return,b[*,wcomp]/par.bscale
end


function mpfieldgrad,dat,param=p
if not keyword_set(p) then begin
  p = mpfield1()
  p.func = 'mpfieldgrad'
endif

run1 = where(dat.run eq 1)
b1 = mpfield1(dat[run1],param=p)

run2 = where(dat.run eq 2)
b2 = mpfield1(dat[run2],param=p)

db = b1-b2
return,db
end




pro plotfld,p0,lim=lim,mag=mag
p=p0
p.comps=[1,1,1]
if keyword_set(lim) then box,lim
xv = dgen()
bv = func(xv,param=p)
bx = bv[*,0] - (keyword_set(true) ? 0 : p.b_offset[0])
by = bv[*,1] - (keyword_set(true) ? 0 : p.b_offset[1])
bz = bv[*,2] - (keyword_set(true) ? 0 : p.b_offset[2])
oplot,xv,bx,col=2
oplot,xv,by,col=4
oplot,xv,bz,col=6
if keyword_set(mag) then begin
   oplot,xv,sqrt(bx^2+by^2+bz^2)
endif
end



function qmat,p
str_element,p,'Qyy',qyy
if n_elements(qyy) eq 0 then return,0
qxx= -p.qyy - p.qzz
q = [[qxx,p.qxy,p.qxz],[p.qxy,p.qyy,p.qyz],[p.qxz,p.qyz,p.qzz]]
return,q
end

function diagmat,q,eval=d
a = q
trired,a,d,e
triql,d,e,a
det = determ(a)
if det lt 0  then a = -a
;print,'Eigen Values=',d
;print,'Eigen Vectors='
;print,a
return,a
end


function quadmom,p,character=ch,rotmat=evec
q = qmat(p)
ch = 0.
if not keyword_set(q) then return,0
evec = diagmat(q,eval=eval)
;dprint,evec
det = determ(evec)
;printdat,det,eval
;dprint,(evec ## q) ## transpose(evec)

v = eval[sort(eval)]
qmom = v[2]-v[0]
ch = (v[0]-2*v[1]+v[2])/qmom

return,qmom/2
end


pro plot2meter,p0,dist=r,magnitude=mag
p=p0
p.b0 = 0
xlim,lim,-10,350
ylim,lim,-2,2
options,lim,ytitle='B (nT)',xtitle='Rotation Angle'
if not keyword_set(r) then r = 200.
box,lim
xv=dgen()
p.datf.r = r
p.var = 'phic'
!p.multi = [0,1,3]
col = [2,4,6]
axes =['X','Y','Z']
for a=1,3 do begin
  options,lim,title= 'Rotate around '+axes[a-1]+' axis'
  box,lim
  p.datf.z_a = a
  p.datf.x_a = a mod 3 + 1
  bv = func(xv,param=p)
  for i=0,2 do   oplot,xv,bv[*,i],col=col[i]
  if keyword_set(mag) then begin
     oplot,xv,sqrt(total(bv^2,2))
  endif

endfor
!p.multi = 0
end


function stepsize,x
y = alog(x)/alog(10)
n = floor(y)
dy = floor((y-n)*10)
ss = [1,1,1,2,2,2,2,5,5,5,5]
return,10d^n*ss[dy]
end





pro fieldmap,p0,radius=r,component=comp,rcomp=rcomp
if not keyword_set(r) then r = 200.
p=p0
xlim,lim,0,360
ylim,lim,-90,90
options,lim,title=string(/print,p.file,r,format='("File: ",A,"   Radius: ",f5.1," cm")')
options,lim,xtitle='Phi',ytitle='Theta'
box,lim
npx=1+16*4
npy=1+8*4
xv= dgen(npx,/x)
yv= dgen(npy,/y)
ph = xv # replicate(1,npy)
th = replicate(1,npx) # yv

x = cosd(th)*cosd(ph)
y = cosd(th)*sind(ph)
z = sind(th)
pos = r*[[x[*]],[y[*]],[z[*]]]

bv =  perm_and_induced_field(pos/p.rscale,[0.,0,0],param=p)

if n_elements(comp) ne 0 then f=bv[*,comp] else  f=sqrt(total(bv^2,2))

if keyword_set(rcomp) then f = bv[*,0]*x[*] + bv[*,1]*y[*] + bv[*,2]*z[*]

f = reform(f,npx,npy)

range = minmax(f)
dprint,dlevel=3,'range=',range
if n_elements(comp) eq 0 and keyword_set(rcomp) eq 0 then range[0] = 0
delta = stepsize((range[1]-range[0])/6)
range = round(range/delta) * delta
nlevels =  round((range[1]-range[0])/delta) + 1
levels = findgen(nlevels)*delta + range[0]
dprint,dlevel=3,minmax(levels),delta
col = bytescale(levels)
contour,f,xv,yv,levels=levels,/fill,/over,c_col=col
contour,f,xv,yv,levels=levels,c_labels=finite(levels) ,/over
options,lim,/noerase
box,lim
;string_out,p0.p,.2,.9
wshow
;help
end





pro plotpts,lim=lim,dat,p
if keyword_set(lim) then box,lim
str_element,dat,p.var,xv
oplot, col=2,ps=1,xv,dat.bx - (keyword_set(true) ? 0 : p.b_offset[0])
oplot, col=4,ps=7,xv,dat.by - (keyword_set(true) ? 0 : p.b_offset[1])
oplot, col=6,ps=4,xv,dat.bz - (keyword_set(true) ? 0 : p.b_offset[2])
end






pro fit_fields,dat,p,names=names,DY=DY,order=order,iorder=iorder,silent=silent,summary=summary

if not keyword_set(p) then   p = mpfield1(order=order,iorder=iorder)

w = where(dat.z_a eq 0,nw)
if nw eq 0 then w = indgen(n_elements(dat))
p.b_offset[0] = average(dat[w].bx)
p.b_offset[1] = average(dat[w].by)
p.b_offset[2] = average(dat[w].bz)

yd = [[dat.bx],[dat.by],[dat.bz]]
yd = yd[*,where(p.comps)]

if not keyword_set(names) then names = 'p b0'
fit,dat,yd,param=p,names=names,maxprint=20,dy=(n_elements(dy) eq 1)  ? dy+ y*0 : dy,silent=silent,chi2=chi2,result=res,fullnames=fullname,summary=summary ;,p_values=p_values,p_sigma=p_sigma
p.chi = sqrt(chi2)


end



pro fitbgrad,dat,p,names=names
run1  = where(dat.run eq 1)
run2 = where(dat.run eq 2)
d1 = dat[run1]
d2 = dat[run2]
help,run1,run2
db = [[d1.bx-d2.bx],[d1.by-d2.by],[d1.bz-d2.bz]]
if not keyword_set(names) then names='dphic p'
fit,dat,db,param=p,function='mpfieldgrad',names=names,fitv=dbf
i=findgen(n_elements(run1))
plot,[i,i,i],db,/nodat
oplot,dbf,/col
;stop
err = db-dbf
plot,[i,i,i],err,/nodat
w=where(d1.z_a eq 0)
for j=0,2 do begin
  oplot,i,err[*,j],col = j*2+2
  oplot,i[w],err[w,j],col=j*2+2,psym=4
  endfor
end


pro plotfit,dat,p,limit=lim,mag=mag,noerase=noerase
pt = p
rs = dat.r
rs = rs[uniq(rs,sort(rs))]

for ri=0,n_elements(rs)-1 do begin

    wr = where(dat.r eq rs[ri])
    ;datr=dat[where(dat.r eq rs[ri])]
    
    !p.multi=[0,2,3,0,1]
    
    n = n_elements(wr)
    yf = func(dat[wr],param=p)
    b_offset = replicate(1,n) #  p.b_offset
    yrange = max(abs(yf - b_offset)) * [-1,1]
    yrange = minmax([[dat[wr].bx],[dat[wr].by],[dat[wr].bz]]-b_offset)
    ;print,yrange
    xrange = [-10,360.]
    options,lim,yrange=yrange,xrange=xrange,/xstyle
    
    wi,ri+1
    
    z_a = [3,2,-1,-3,-2,1]
    x_a = [1,1,3, 1, 1, 3]
    np = n_elements(z_a)
    
    pt.datf.r = dat[wr[0]].r
    
    for i=0,np-1 do begin
    
        w = where(dat.z_a eq z_a[i] and dat.r eq rs[ri],nw)  ; and dat.x_a eq x_a[i],nw)
;        pt.datf.z_a = dat[w[0]].z_a
;        pt.datf.x_a = dat[w[0]].x_a
        pt.datf.z_a = z_a[i]
        pt.datf.x_a = x_a[i]
        
        plot,_extra=lim,charsize=1.4,/nodata,xrange,yrange,title=string(/print,'R=',pt.datf.r,'  Orientation axis = ',pt.datf.z_a,pt.datf.x_a),noerase=noerase
        oplot,[0,360],[0,0],linestyle=2
        ;print,!p.multi
        ;!p.multi[0] = 5-i
        plotfld,pt,mag=mag
        if nw gt 0 then begin
           d = dat[w[0]]
           pt.datf.r = d.r
           pt.datf.z_a = d.z_a
           pt.datf.x_a = d.x_a
           plotpts,dat[w],p
        endif
    
    endfor
endfor


!p.multi=0

wi,0
yd = [[dat.bx],[dat.by],[dat.bz]]
yf = func(dat,param=p)
dy = yd-yf
yrange = max(abs(dy)) * [-1,1]

i = indgen(n_elements(dat))
plot,/nodata,[i,i,i],dy,yrange=yrange,noerase=noerase,xmargin = [35,4],title=p.file
oplot,minmax(i),[0,0],linestyle=2
oplot,i,dy[*,0],col=2
oplot,i,dy[*,1],col=4
oplot,i,dy[*,2],col=6

w = where(dat.z_a eq 0,nw)
if nw ne 0 then begin
  oplot,w,dy[w,0],col=2,psym=4
  oplot,w,dy[w,1],col=4,psym=4
  oplot,w,dy[w,2],col=6,psym=4
endif
string_out,p.p,.02,.95
qm = quadmom( p.p ,charac=ch)

!p.multi=0

end




pro clean_runs,dat
str_element,dat,'run',runs
if not keyword_set(runs) then return
message,/info,'Cleaning data runs'
runs= runs[uniq(runs,sort(runs))]
nruns = n_elements(runs)
ave0 = average(dat[where(dat.z_a eq 0)])

;stop
for i = 0 ,nruns-1 do begin
  w0 = where(dat.run eq runs[i] and dat.z_a eq 0)
  wa = where(dat.run eq runs[i])
  ave = average(dat[w0])
  dat[wa].bx = dat[wa].bx - ave.bx + ave0.bx
  dat[wa].by = dat[wa].by - ave.by + ave0.by
  dat[wa].bz = dat[wa].bz - ave.bz + ave0.bz
endfor

end


function read_magfile,file,prn=prn,fpc=fpc,basename=basename,defrad=defrad
basename = file_basename(file)
print,basename
ext = strupcase(strmid(basename,2,/reve))
fpc = ext eq 'FPC'
prn = ext eq 'PRN'
txt = ext eq 'TXT'
if keyword_set(fpc) then begin
   filter = '*.fpc'
   format = {s:0l,Bx:0.,By:0.,Bz:0.}
endif
if  keyword_set(prn) then begin
   filter = '*.prn'
   filetags = 1
   ;format = {s:0l,Bx:0.,By:0.,Bz:0.,R:0.,Phic:0.,Z_A:0,X_A:0}
endif

if  keyword_set(txt) then begin
   filter = '*.txt'
   filetags = 1
endif

if not keyword_set(file) then file=dialog_pickfile(filter=filter)
dat0 = read_asc(file,format=format,tags=filetags)

clean_runs,dat0

dat = dat0

if keyword_set(fpc) then begin
  if not keyword_set(defrad) then defrad=30.
  bx = dat0.bz
  dat0.bz = -dat0.bx
  dat0.bx = bx

  dat = dat0
  str_element,/add,dat,'R',0.
  str_element,/add,dat,'PHIC',0.
  str_element,/add,dat,'Z_A',0l
  str_element,/add,dat,'X_A',0l
  str_element,/add,dat,'valid',1
  i1 = indgen(16) + 2
  dat.r = defrad
  dat[i1].phic = findgen(16)*22.5d
  dat[i1].z_a = 3
  dat[i1].x_a = 1
  if n_elements(dat) ge 40 then begin
    dat[i1+20].phic = findgen(16)*22.5d
    dat[i1+20].z_a = 2
    dat[i1+20].x_a = 1
  endif
  if n_elements(dat) ge 60 then begin
    dat[i1+40].phic = findgen(16)*22.5d
    dat[i1+40].z_a = -1
    dat[i1+40].x_a = 3
  endif
  if n_elements(dat) ge 80 then begin
    dat[i1+60].phic = findgen(16)*22.5d
    dat[i1+60].z_a = -3
    dat[i1+60].x_a = 1
  endif
  if n_elements(dat) ge 100 then begin
    dat[i1+80].phic = findgen(16)*22.5d
    dat[i1+80].z_a = -2
    dat[i1+80].x_a = 1
  endif
  if n_elements(dat) ge 120 then begin
    dat[i1+100].phic = findgen(16)*22.5d
    dat[i1+100].z_a = 1
    dat[i1+100].x_a = 3
  endif
  file_txt = str_sub(file,'.fpc','.txt')
  write_magfitfile,dat,file_txt 
endif

return,dat
end



pro write_magfitfile,dat,filename
    file_open,'w',filename,unit=u
    printf,u,tag_names(dat)
    for i=0,n_elements(dat)-1 do begin
      printf,u,dat[i],format ='(i3," ",3(f8.0," "),2(f6.1," "),3(i3," "))'
    endfor
    free_lun,u
end




function fitmagfile,file,p,fpc=fpc,prn=prn,names=names,dat=dat,silent=silent,iorder=iorder,order=order,defrad=defrad

if not keyword_set(order) then order=2
if not keyword_set(iorder) then iorder=1

dat = read_magfile(file,basename=basename,defrad=defrad)

p=0
if not keyword_set(p) then p=mpfield1(order=order,iorder=iorder)
p.file = basename
p.num = fix(strmid(basename,3,2))


if not keyword_set(names) then names='B0 p'

w = where(dat.valid ne 0)
fit_fields,dat[w],p,names=names,silent=silent,summary=sum
;  dat = dat[where(dat.z_a ne 0)]
plotfit,dat,p   ;,/mag
for i=0,n_elements(sum.p_names)-1 do print ,sum.p_names[i],sum.p_values[i],sum.p_sigma[i]
qm = quadmom( p.p ,charac=ch,rotmat=rotmat)
printdat,qm,ch
dprint,rotmat


;wshow
if 1 then begin
;printdat,p
rot_mat = euler_rot_matrix(p.euler,rot_angle=ra)
p.euler_ang = ra
if ra ne 0 then help,ra
endif
return,p

end




pro plot_dicomps,pall,range=range,used=used
wi,0
!p.multi=[0,1,2]
if not keyword_set(range) then range=5
plot,[-2,2.,!values.f_nan,0,0],[0,0,0,-2,2],xrange=[-range,range],yrange=[-range,range],xstyle=1,ystyle=1;,/nodata
oplot,pall.p.px,pall.p.pz,psym=1,col=5
oplot,-pall.p.px,-pall.p.pz,psym=4,col=5
xyouts,pall.p.px,pall.p.pz,strtrim(pall.num,2),align=.5,col=5
if not keyword_set(used) then w = where(pall.num ne 0,nw) else  $
w = where(array_union(pall.num,used) lt 0,nw)
if nw ne 0 then begin
  oplot,pall[w].p.px,pall[w].p.pz,psym=1,col=6
  oplot,-pall[w].p.px,-pall[w].p.pz,psym=4,col=6
  xyouts,pall[w].p.px,pall[w].p.pz,strtrim(pall[w].num,2),align=.5,col=6
endif

plot,[-2,2.,!values.f_nan,0,0],-88+[0,0,0,-2,2],xrange=[-range,range],yrange=[-range,range]-88,xstyle=1,ystyle=1;,/nodata
oplot,pall.p.px,pall.p.py,psym=1,col=5
oplot,-pall.p.px,-pall.p.py,psym=4,col=5
xyouts,pall.p.px,pall.p.py,strtrim(pall.num,2),align=.5,col=5
;w = where(array_union(pall.num,used) lt 0,nw)
if nw ne 0 then begin
  oplot,pall[w].p.px,pall[w].p.py,psym=1,col=6
  oplot,-pall[w].p.px,-pall[w].p.py,psym=4,col=6
  xyouts,pall[w].p.px,pall[w].p.py,strtrim(pall[w].num,2),align=.5,col=6
endif
wi,1
!p.multi=0
plot,/nodata,range*[-1,1],[0,n_elements(pall)/5],xstyle=1
psymb = 0
oplot,xb,histbins(pall.p.px   ,xb,bins=.2,range=[-range,range]),psy=psymb,col=2
oplot,xb,histbins(pall.p.py+88,xb,bins=.2,range=[-range,range]),psy=psymb,col=4
oplot,xb,histbins(pall.p.pz   ,xb,bins=.2,range=[-range,range]),psy=psymb,col=6
spcs = '               '
for i=0,n_elements(pall)-1 do print,pall[i].file+spcs,pall[i].num,pall[i].p,format="(a20, I3,'  ', 5(I2.1), 20(f9.4) )"
end





function rotate_magmom,pp,rot
rpp = pp
for i=0,n_elements(pp)-1 do begin
  p = pp[i]
  rp = p
  if p.order[1] then begin
    m1 = rotate_tensor([p.px,p.py,p.pz] , rot)
    rp.px=m1[0]
    rp.py=m1[1]
    rp.pz=m1[2]
  endif
  if p.order[2] then begin
    qxx = -p.qyy - p.qzz
    m2 = [[qxx,p.qxy,p.qxz],[P.qxy,p.qyy,p.qyz],[p.qxz,p.qyz,p.qzz]]
    m2 = rotate_tensor(m2,rot)
    rp.qyy = m2[1,1]
    rp.qzz = m2[2,2]
    rp.qxy = m2[0,1]
    rp.qxz = m2[0,2]
    rp.qyz = m2[1,2]
  endif
  if p.order[3] then message,'Code not completed'
  if p.order[4] then message,'Code not completed'
  rpp[i]=rp
endfor
return,rpp
end







function add_sst_magmoments,p1,p2
ang1 = 39.
ang2 = -65.
rot1 = euler_rot_matrix([0,1,0],set_angle=ang1)
rot2 = euler_rot_matrix([0,1,0],set_angle=ang2)

p = p1
pp1 = rotate_magmom(p1.p,rot1)
if keyword_set(p2) then begin
   pp2 = rotate_magmom(p2.p,rot2)
   pp1.px += pp2.px
   pp1.py += pp2.py
   pp1.pz += pp2.pz
   pp1.qyy += pp2.qyy
   pp1.qzz += pp2.qzz
   pp1.qxy += pp2.qxy
   pp1.qxz += pp2.qxz
   pp1.qyz += pp2.qyz
   pp1.file += ' & '+pp2.file
endif
p.p = pp1
return,p
end



pro plot_cagecomps,pall,range=range
wi,0
!p.multi=[0,1,2]
p = pall.p
n = n_elements(p)
if not keyword_set(range) then range=4

ang1 = 39.
ang2 = -65.
rotz = euler_rot_matrix([0,0,1],set_angle=180)
rot1 = euler_rot_matrix([0,1,0],set_angle=ang1)
rot2 = euler_rot_matrix([0,1,0],set_angle=ang2)

plot,[-2,2.,!values.f_nan,0,0],[0,0,0,-2,2],xrange=[-range,range],yrange=[-range,range],xstyle=1,ystyle=1;,/nodata
p = rotate_magmom(pall.p, rot1)
oplot,p.px,p.pz,psym=1,col=6
xyouts,p.px,p.pz,strtrim(pall.num,2),align=.5,col=6
p = rotate_magmom(pall.p, rot1 ## rotz)
oplot,p.px,p.pz,psym=2,col=6
xyouts,p.px,p.pz,strtrim(pall.num,2),align=.5,col=6
p = rotate_magmom(pall.p, rot2)
oplot,p.px,p.pz,psym=4,col=6
xyouts,p.px,p.pz,strtrim(pall.num,2),align=.5,col=6
p = rotate_magmom(pall.p, rot2 ## rotz)
oplot,p.px,p.pz,psym=5,col=6
xyouts,p.px,p.pz,strtrim(pall.num,2),align=.5,col=6

plot,[-2,2.,!values.f_nan,0,0],[0,0,0,-2,2],xrange=[-range,range],yrange=[-range,range],xstyle=1,ystyle=1;,/nodata
p = rotate_magmom(pall.p, rot1)
oplot,p.px,p.py,psym=1,col=6
xyouts,p.px,p.py,strtrim(pall.num,2),align=.5,col=6
p = rotate_magmom(pall.p, rot1 ## rotz)
oplot,p.px,p.py,psym=2,col=6
xyouts,p.px,p.py,strtrim(pall.num,2),align=.5,col=6
p = rotate_magmom(pall.p, rot2)
oplot,p.px,p.py,psym=4,col=6
xyouts,p.px,p.py,strtrim(pall.num,2),align=.5,col=6
p = rotate_magmom(pall.p, rot2 ## rotz)
oplot,p.px,p.py,psym=5,col=6
xyouts,p.px,p.py,strtrim(pall.num,2),align=.5,col=6

spcs = '               '
for i=0,n_elements(pall)-1 do print,pall[i].file+spcs,pall[i].num,pall[i].p,format="(a20, I3,'  ', 5(I2.1), 20(f9.4) )"
end





pro fieldmapm,p0,radius=r,component=comp,rcomp=rcomp
if not keyword_set(r) then r = 200.
p=p0
xlim,lim,0,360
ylim,lim,-90,90
options,lim,title=string(/print,p.file,r,format='("File: ",A,"   Radius: ",f5.1," cm")')
options,lim,xtitle='Phi',ytitle='Theta'
box,lim
npx=1+16*4
npy=1+8*4
xv= dgen(npx,/x)
yv= dgen(npy,/y)
ph = xv # replicate(1,npy)
th = replicate(1,npx) # yv

x = cosd(th)*cosd(ph)
y = cosd(th)*sind(ph)
z = sind(th)
pos = r*[[x[*]],[y[*]],[z[*]]]
str_element,p,'pos',delta_pos
str_element,p,'rot',rot
B0 = [0.,0.,0.]
if n_elements(rot) eq 9 then begin
  print,'rotating coordinates'
  help,pos
  pos = transpose(rot) ## pos
  help,pos
endif
if n_elements(delta_pos) eq 3 then begin
  print,'shifting coordinates'
  pos[*,0]  = pos[*,0] + delta_pos[0]
  pos[*,1]  = pos[*,1] + delta_pos[1]
  pos[*,2]  = pos[*,2] + delta_pos[2]
endif

bv =  perm_and_induced_field(pos/p.rscale,B0,param=p)

if n_elements(comp) ne 0 then f=bv[*,comp] else  f=sqrt(total(bv^2,2))

if keyword_set(rcomp) then f = (bv[*,0]*pos[*,0] + bv[*,1]*pos[*,1] + bv[*,2]*pos[*,2])/r


f = reform(f,npx,npy)

range = minmax(f)
print,'range=',range
if n_elements(comp) eq 0 and keyword_set(rcomp) eq 0 then range[0] = 0
delta = stepsize((range[1]-range[0])/6)
range = round(range/delta) * delta
nlevels =  round((range[1]-range[0])/delta) + 1
levels = findgen(nlevels)*delta + range[0]
print,minmax(levels),delta
col = bytescale(levels)
contour,f,xv,yv,levels=levels,/fill,/over,c_col=col
contour,f,xv,yv,levels=levels,c_labels=finite(levels) ,/over
options,lim,/noerase
box,lim
;string_out,p0.p,.2,.9
wshow
;help
end



;Beginning of program

pro mapmovie,p0
p = p0
add_str_element,p,'rot',identity(3,/double)
for ang=0d,180,2 do begin
   p.rot = euler_rot_matrix([1,0,0],set=ang)
   fieldmapm,p,/rcom
endfor
end




files = dialog_pickfile(/multiple,/must,filter=['*.fpc','*.prn','*.txt'],file=lastfile)
lastfile= files[0]
n= n_elements(files) * keyword_set(files)
files = files[sort(files)]
i = 0
pall=0
for i=0,n-1 do begin
  if i ne 0 and keyword_set(pse) then stop
  order = 2
  iorder=1
  p = fitmagfile(files[i],p,names=names,dat=dat,silent=silent,order=order,iorder=iorder,defrad=defrad)
  filename = p.file+ '-O'+strtrim(order,2)
  append_array,pall,p
  print,p.file+'                ',p.p,format="(a20 5(I3.1) 20(f9.4) )"
  wi,0
  makepng,filename+'.fit0'
  wi,1
  makepng,filename+'.fit'
  wi,6
  fieldmap,p,rad=30.
  makepng,filename+'.map'
  wi,7
  fieldmap,p,rad=400.
  makepng,filename+'.map2'

endfor

;stop
;wi,1
;makepng
;;used = [4,12,15,22,28,33,34,43,84,97,100,107 ]
;if n_elements(pall) gt 1 then begin
;   if keyword_set(cages) then plot_cagecomps,pall,range=range   $
;   else  plot_dicomps,pall,range=range,used=used
;endif
end



