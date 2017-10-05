;+
; NAME:
;     LMN_TRANSFORM_CRIB
;
; PURPOSE:
;	This code shows anatomy of the LMN transform, so essentially this is dissected gsm2lmn
;	routine with hand-picked solar wind input. It projects the LMN base vectors onto the XY (GSM)
;	plane at the points of magnetopause boundary for different levels of Z (smooth line - Z=0,
;	dotted - Z=-10, dashed - Z=15 (Earth radii). The LMN orts are plotted in the sequence N-M-L,
;	so, if you see that the green one overshadows the red, that means that the green vector 
;	screens part of the red vector (you look from atop of the Z axis).
;
; CATEGORY:
;	Crib
;
; CALLING SEQUENCE:
;	lmn_transform_crib
;
; INPUTS:
;	none
;
; KEYWORDS: none
;
; PARAMETERS: none; image parameters are set in the code
;
; OUTPUTS:
;	graphic file mpfig.ps (color postscript)
;
; DEPENDENCIES: CDAWlib files DeviceOpen.pro and DeviceClose.pro.
;
; MODIFICATION HISTORY:
;	Written by:	Vladimir Kondratovich 2008/01/30
;-
;
; THE CODE BEGINS:


function equ,t
  compile_opt hidden
  common eqrhs,rhs,alpha
  const=exp(alpha*alog(2.))
  diff=const*sin(t)/exp(alpha*alog(1.+cos(t)))-rhs
  return,diff
end



PRO lmn_transform_crib

common eqrhs,rhs,alpha

;SW input:
dp=2.088; nPa
bz=0.; nT

;Shue et al. (1998) MP:
alpha = (0.58-0.007*bz)*(1+0.024*alog(dp))
r0=(10.22+1.29*tanh(0.184*(bz+8.14)))/exp(alog(dp)/6.6)

;for fun
yarr1=1.-2.*findgen(11)/10.
xarr1=sqrt(1.-yarr1^2)
yarr2=reverse(yarr1)
xarr2=fltarr(11)
yarr=[yarr1,yarr2]
xarr=[xarr1,xarr2]

;number of points to plot
nwing=14
npts=2*nwing+1

;we will plot 3 z-levels:
zarr=[0,-10,15]
linearr=[0,1,2]
nlines=n_elements(zarr)

;look for this file in your work directory after lmn_transform_crib finishes
nam='mpfig.ps'
deviceopen,1,/portrait,fileoutput=nam

red = [0,1,1,0,0,1]
green = [0,1,0,1,0,1]
blue = [0,1,0,0,1,0]
tvlct, 255 * red, 255 * green, 255 * blue

for j=0,nlines-1 do begin;+++++++++++++++++++++++++++++++++++++++++++++++++++++

  ;calculate X, Y, Z in GSM
  z0j=zarr(j)
  rhs=abs(z0j/r0)
  if rhs le 0.9 then t0=asin(rhs) else t0=1.5
  tt=newton(t0,'equ')
  th0=tt
  
  th=(findgen(nwing)+1)*!pi/18.+th0
  r1=r0*exp(alpha*alog(2./(1+cos(th))))
  ro=r0*exp(alpha*alog(2./(1+cos(th0))))
  r=[reverse(r1),ro,r1]
  
  x=fltarr(npts)
  x(nwing)=ro*cos(th0)
  x(0:nwing-1)=reverse(r1*cos(th))
  x(nwing+1:npts-1)=r1*cos(th)
  
  z=fltarr(npts)+z0j
  
  argu=r^2-z^2-x^2>0.
  y=sqrt(argu)
  y(0:nwing-1)=-y(0:nwing-1)
  
  vl=fltarr(npts,3)
  vm=fltarr(npts,3)
  vn=fltarr(npts,3)
  
  ;Transformation starts
  for i = 0, npts-1 do begin
     xi=x(i)
     yi=y(i)
     zi=z(i)
  
     theta=acos(xi/sqrt(xi^2+yi^2+zi^2));
     rho=sqrt(yi^2+zi^2)
     if rho gt 0. then begin
        tang1 = [0.,zi,-yi]
        tang2 = [xi,yi,zi]*alpha*sin(theta)/(1+cos(theta))+[-rho^2,xi*yi,xi*zi]/rho
        tang1 = tang1/sqrt(total(tang1^2));
        tang2 = tang2/sqrt(total(tang2^2));
        dN = crossp(tang1,tang2);
        dM = crossp(dN, [0,0,1])
        dM = dM/sqrt(total(dM^2))
        dL = crossp(dM, dN)
     endif else begin
        dN=[1.,0.,0.]
        dM=[0.,-1.,0.]
        dL=[0.,0.,1.]
     endelse
     transm = [[dL],[dM],[dN]]
  
     vl(i,*)=dL
     vm(i,*)=dM
     vn(i,*)=dN
  endfor
  
  ;the length of displayed LMN orts
  mult=1.
  xmin=min(x,max=xmax)
  ymin=min(y,max=ymax)
  
  if j eq 0 then begin
     plot, x, y, thick=1, charsize=1.3,line=linearr(j),$
        xrange=[xmin-mult, xmax+mult], xstyle = 8, ystyle = 8, $
        yrange=[ymin-mult, ymax+mult],$
        xtitle='X, GSM',ytitle='Y,  GSM',$
        title='LMN triades, L=green, M=blue, N=red',/noerase
     axis,0,0,xax=0,/data
     axis,0,0,0,yax=0,/data
     plots,xarr,yarr
     polyfill,xarr,yarr,color=1
     plots,-xarr,yarr
     polyfill,-xarr,yarr,color=0
  endif else begin
     oplot, x, y, thick=1,line=linearr(j)
  endelse
  
  for i=0,npts-1 do begin
     oplot,[x(i),x(i)+mult*vn(i,0)],[y(i),y(i)+mult*vn(i,1)],linestyle=0,color=2,thick = 3
     oplot,[x(i),x(i)+mult*vm(i,0)],[y(i),y(i)+mult*vm(i,1)],linestyle=0,color=4,thick = 3
     oplot,[x(i),x(i)+mult*vl(i,0)],[y(i),y(i)+mult*vl(i,1)],linestyle=0,color=3,thick = 3
  endfor

endfor;------------------------------------------------------------------------

deviceclose

print, 'lmn_transform_crib finished.'

end
