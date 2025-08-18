;
; This code reorders the eigenvalues and eigenvectors of the temperature tensor, putting t_parallel last.
; This was pulled out into its own routine, and debug output added, to facilitate troubleshooting the eigenvector ordering -- the real code is still called
; inline in moments_3d. JWL


pro reorder_t3,t3,t3evec
  s = sort(t3)
  print,'sort order:', s
  mid=t3[s[1]]
  avg=(t3[s[0]] + t3[s[2]])/2.0
  print,'mid:',mid,'avg:',avg
  if mid lt avg then num=s[2] else num=s[0]
  print,'num:',num
  shft = ([-1,1,0])[num]
  print,'shift: shft'
  out_t3 = shift(t3,shft)
  out_t3evec = shift(t3evec,0,shft)
  print,'out_t3:', out_t3
  print,'out_t3evec',out_t3evec
end


;function moments_3d_omega_weights,th,ph,dth,dph ,order=order  ;, tgeom   inputs may be up to 3 dimensions
;
;dim = size(/dimen,th)
;if array_equal(dim,size(/dimen,ph)) eq 0 then message,'Bad Input'
;if array_equal(dim,size(/dimen,dth)) eq 0 then message,'Bad Input'
;if array_equal(dim,size(/dimen,dph)) eq 0 then message,'Bad Input'
;omega = dblarr([13,dim])
;
;; Angular moment integrals
;ph2 = ph+dph/2
;ph1 = ph-dph/2
;th2 = th+dth/2
;th1 = th-dth/2
;
;sth1 = sin(th1 *!dpi/180)
;cth1 = cos(th1 *!dpi/180)
;sph1 = sin(ph1 *!dpi/180)
;cph1 = cos(ph1 *!dpi/180)
;
;sth2 = sin(th2 *!dpi/180)
;cth2 = cos(th2 *!dpi/180)
;sph2 = sin(ph2 *!dpi/180)
;cph2 = cos(ph2 *!dpi/180)
;
;ip = dph * !dpi/180
;ict =  sth2 - sth1
;icp =  sph2 - sph1
;isp = -cph2 + cph1
;is2p = dph/2* !dpi/180 - sph2*cph2/2 + sph1*cph1/2
;ic2p = dph/2* !dpi/180 + sph2*cph2/2 - sph1*cph1/2
;ic2t = dth/2* !dpi/180 + sth2*cth2/2 - sth1*cth1/2
;ic3t = sth2 - sth1 - (sth2^3 - sth1^3) /3
;ictst = (sth2^2 - sth1^2) / 2
;icts2t = (sth2^3 - sth1^3)/3
;ic2tst = (-cth2^3 + cth1^3)/3
;icpsp = (sph2^2 - sph1^2) / 2
;
;omega[0,*,*,*] = ict    * ip
;omega[1,*,*,*] = ic2t   * icp
;omega[2,*,*,*] = ic2t   * isp
;omega[3,*,*,*] = ictst  * ip
;omega[4,*,*,*] = ic3t   * ic2p
;omega[5,*,*,*] = ic3t   * is2p
;omega[6,*,*,*] = icts2t * ip
;omega[7,*,*,*] = ic3t   * icpsp
;omega[8,*,*,*] = ic2tst * icp
;omega[9,*,*,*] = ic2tst * isp
;omega[10,*,*,*] = omega[1,*,*,*]
;omega[11,*,*,*] = omega[2,*,*,*]
;omega[12,*,*,*] = omega[3,*,*,*]
;
;;for i=0,12 do begin
;;    omega[i,*,*,*] /= tgeom
;;endfor
;
;return,omega
;
;end


;+
;FUNCTION:	moments_3d,data
;
;INPUT:
;	data:	structure,	3d data structure.  (i.e. see "GET_EL")
;	erange:
;	bins:
;
;PURPOSE:
;       Returns all useful moments as a structure
;
;KEYWORDS:
; dmoments: If set to a named varaible this will output a structure 
;           identical to the return structure but containing error 
;           esimates assuming an error of sqrt(N) for an initial
;           measurement of N counts (poisson distribution).
; unit_scaling: Input array specifying the values used to convert from
;               counts to the current units.  If not set, a unit conversion
;               will be called to determine the values instead.
; no_unit_conversion: Flag indicating that data is already in eflux and
;                     no unit conversion is required.
;
;These optional keywords control calculations:
;       ERANGE    intarr(2),   min,max energy bin numbers for integration.
;       BINS      bytarr(nbins), Angle bins for integration, see "EDIT3DBINS"
;
;CREATED BY:    Davin Larson
;LAST MODIFICATION: %E%
;$Id:$
;-
function moments_3d ,data,sc_pot=pot,magdir=magdir, $
   true_dens=tdens, $
   comp_sc_pot=comp_sc_pot, $
   pardens = pardens, $
   dens_only=dens_only, $
   ph_0_360=ph_0_360, $
   mom_only=mom_only, $
;   nodata=nodata, $
   dmoments=dmom, $
   unit_scaling=unit_scaling, $
   no_unit_conversion=no_unit_conversion, $
   add_moment = add_moment, $
   add_dmoment = add_dmoment, $
   domega_weights=domega_weight, $
   ERANGE=er, $
   format=momformat,  $
   BINS=bins,   $
   valid = valid

f = !values.f_nan
f3 = [f,f,f]
f6 = [f,f,f,f,f,f]
f33 = [[f3],[f3],[f3]]
d = !values.d_nan

if size(/type,momformat) eq 8 then mom = momformat else $
   mom = {time:d, sc_pot:f, sc_current:f, magf:f3, density:f, avgtemp:f, vthermal:f, $
     velocity:f3, flux:f3, Ptens:f6, mftens:f6,  $
     eflux:f3,  $
     qflux:f3, $
     t3:f3, symm:f3, symm_theta:f, symm_phi:f, symm_ang:f, $
     magt3:f3, erange:[f,f], mass:f, $
     valid:0}

if arg_present(dmom) then begin
  dmom = mom             ;for uncertainties, jmm, 12-apr-2011
endif

mom.valid = 0

if n_params() eq 0 then goto,skipsums
if size(/type,data) ne 8 then return,mom

valid = 0

if arg_present(dmom) then begin 
  if ~keyword_set(unit_scaling) then begin
    ;create a data structure with one count per angular and energy bin, for uncertainties, jmm, 12-apr-2011
    data3d1 = data
    data3d1 = conv_units(data3d1, "counts")
    data3d1.data[*] = 1
    data3d1 = conv_units(data3d1, "eflux")
    unit_scaling = data3d1.data
  endif
endif

;allow input from simplified data structures
if keyword_set(no_unit_conversion) then begin
  data3d = data
endif else begin
  data3d = conv_units(data,"eflux")		; Use Energy Flux
endelse


charge = data3d.charge

mom.time = data3d.time
mom.magf = data3d.magf

;ndim = size(/n_dimension,data.data)
;if ndim eq 1 then return,mom           ; step out for omni directional distributions

if data.valid eq 0 then return,mom

if not keyword_set(domega_weight) then $
    domega_weight = moments_3d_omega_weights(data3d.theta,data3d.phi,data3d.dtheta,data3d.dphi)

zero_e = where(data3d.energy Le 0.0, nzero)
If(nzero Gt 0) Then e = data3d.energy > 0.1 $     ;lower limit suggested by Jim McFadden, 2016-04-04
Else e = data3d.energy

nn = data3d.nenergy

if keyword_set(er) then begin
   err = 0 >  er < (nn-1)
   s = e
   s[*] = 0.
   s[err[0]:err[1],*] = 1.
   data3d.data= data3d.data * s
endif else err = [0,nn-1]

mom.erange=e[err,0]             ;jmm, 2016-04-04

;if keyword_set(bins) then begin
;   if ndimen(bins) eq 2 then w = where(bins eq 0,c)   $
;   else  w = where((replicate(1b,nn) # bins) eq 0,c)
;   if c ne 0 then data3d.data[w]=0
;endif
if keyword_set(bins) then message,/cont,'bins keyword ignored'
bins = data3d.bins
if size(/n_dimen,bins) eq 1 then bins = replicate(1,nn) # bins
w = where(data3d.bins eq 0,c)
if c ne 0 then data3d.data[w]=0

if n_elements(pot) eq 0 then str_element,data3d,'sc_pot',pot
if n_elements(pot) eq 0 then pot = 0.
if not finite(pot) then pot = 6.


if keyword_set(tdens) then begin
   pota = [3.,12.]
   m0 = moments_3d(data3d,sc_pot=pota[0],/dens_only)
   m1 = moments_3d(data3d,sc_pot=pota[1],/dens_only)
   dens = [m0.density,m1.density]
   for i=0,4 do begin
      yp = (dens[0]-dens[1])/(pota[0]-pota[1])
      pot = pota[0] - (dens[0]-tdens) / yp
      m0 = moments_3d(data3d,sc_pot=pot,/dens_only)
      dens = [m0.density,dens]
      pota = [pot,pota]
   endfor
 ;  print,pota
 ;  print,dens
endif


if keyword_set(comp_sc_pot) then begin
;   par = {v0:-1.9036d,n0:533.7d }
   for i=0,3 do begin
     m = moments_3d(data3d,sc_pot=pot,/dens_only)
;     print,pot,m.density
     pot = sc_pot(m.density )
   endfor
endif


mom.sc_pot = pot

;if size(/n_dimension,data3d.domega) eq 2 then domega = data3d.domega
;if size(/n_dimension,data3d.domega) eq 1 then domega = replicate(1.,nn) # data3d.domega

denergy = struct_value(data3d,'denergy')
if not keyword_set(denergy) then begin
   de_e = abs(shift(e,1) - shift(e,-1))/2./e
   de_e[0,*] = de_e[1,*]
   de_e[nn-1,*] = de_e[nn-2,*]
   de = de_e * e
endif else begin
   de = denergy
   de_e = de/e ;jmm, 2016-04-04
endelse

;double e, de, de_e, this should double everything
e = double(e)
de = double(de)
de_e = double(de_e)

;mom.erange=data3d.energy[[0,nn-1],0]

e_inf = (e + charge * pot) > 0.   ; Energy at infinity

weight = 0. > ((e + charge * pot)/de+.5) < 1.   ;??????
;weight = 0 > ((e + charge * pot)/de+.5)
;
;idx = where(~finite(weight),c)
;if c gt 0 then weight[idx] = 1.0

;dvolume =  de_e * domega_weight[0,*,*,*] * weight   ;bpif charge lt 0
data_dv = data3d.data * de_e * weight * domega_weight[0,*,*,*]

if arg_present(dmom) then begin
  data_dv1 = unit_scaling * de_e * weight * domega_weight[0,*,*,*] ;uncertainty, jmm, 12-apr-2011
endif

mom.mass = data3d.mass
mass = mom.mass

;Current calculation:

mom.sc_current = total(data_dv)

if arg_present(dmom) then begin
  dmom.sc_current = sqrt(total(data_dv*data_dv1)) ;uncertainty, jmm, 12-apr-2011
endif

;Density calculation:
dweight = sqrt(e_inf)/e
pardens = sqrt(mass/2.)* 1e-5 * data_dv * dweight
mom.density = total(pardens)   ; 1/cm^3

if arg_present(dmom) then begin
  pardens1 = sqrt(mass/2.)* 1e-5 * data_dv1 * dweight
  dmom.density = sqrt(total(pardens*pardens1)) ;uncertainty, jmm, 12-apr-2011
endif

;plot,sqrt(mass/2.) * total(pardens,2) * 1e-5,psym=10

if keyword_set(dens_only) then return,mom

;FLUX calculation

;sin_phi = sin(data3d.phi/!radeg)
;cos_phi = cos(data3d.phi/!radeg)
;sin_th  = sin(data3d.theta/!radeg)
;cos_th  = cos(data3d.theta/!radeg)
;cos2_th = cos_th^2
;cthsth  = cos_th*sin_th

;fwx = cos_phi * cos_th * e_inf / e
;fwy = sin_phi * cos_th * e_inf / e
;fwz = sin_th * e_inf / e
;
;parfluxx = data_dv * fwx
;parfluxy = data_dv * fwy
;parfluxz = data_dv * fwz
tmp = data3d.data * de_e * weight * e_inf / e

fx = total(tmp * domega_weight[1,*,*,*] )
fy = total(tmp * domega_weight[2,*,*,*] )
fz = total(tmp * domega_weight[3,*,*,*] )

mom.flux = [fx,fy,fz]     ; Units: 1/s/cm^2

if arg_present(dmom) then begin
  tmp1 = unit_scaling * de_e * weight * e_inf / e
  dfx = sqrt(total(tmp * tmp1 * domega_weight[1,*,*,*]^2 ))
  dfy = sqrt(total(tmp * tmp1 * domega_weight[2,*,*,*]^2 ))
  dfz = sqrt(total(tmp * tmp1 * domega_weight[3,*,*,*]^2 ))
  
  dmom.flux = [dfx,dfy,dfz]     ; Units: 1/s/cm^2
endif

;mom.flux = [fx,fy,fz] /1e5    ; Units: km/s/cm^3

;VELOCITY FLUX:

;vfww  = data_dv * e_inf^1.5 / e
;
;pvfwxx = cos_phi^2 * cos2_th          * vfww
;pvfwyy = sin_phi^2 * cos2_th          * vfww
;pvfwzz = sin_th^2                     * vfww
;pvfwxy = cos_phi * sin_phi * cos2_th  * vfww
;pvfwxz = cos_phi * cthsth             * vfww
;pvfwyz = sin_phi * cthsth             * vfww

tmp = data3d.data * de_e * weight * e_inf^1.5 / e
vfxx = total(tmp *   domega_weight[4,*,*,*] )
vfyy = total(tmp *   domega_weight[5,*,*,*] )
vfzz = total(tmp *   domega_weight[6,*,*,*] )
vfxy = total(tmp *   domega_weight[7,*,*,*] )
vfxz = total(tmp *   domega_weight[8,*,*,*] )
vfyz = total(tmp *   domega_weight[9,*,*,*] )


vftens = [vfxx,vfyy,vfzz,vfxy,vfxz,vfyz] * (sqrt(2/mass) * 1e5)

mom.mftens = vftens * mass / 1e10

if arg_present(dmom) then begin
  tmp1 = unit_scaling * de_e * weight * e_inf^1.5 / e
  dvfxx = sqrt(total(tmp * tmp1 * domega_weight[4,*,*,*]^2 ))
  dvfyy = sqrt(total(tmp * tmp1 * domega_weight[5,*,*,*]^2 ))
  dvfzz = sqrt(total(tmp * tmp1 * domega_weight[6,*,*,*]^2 ))
  dvfxy = sqrt(total(tmp * tmp1 * domega_weight[7,*,*,*]^2 ))
  dvfxz = sqrt(total(tmp * tmp1 * domega_weight[8,*,*,*]^2 ))
  dvfyz = sqrt(total(tmp * tmp1 * domega_weight[9,*,*,*]^2 ))

  dvftens = [dvfxx,dvfyy,dvfzz,dvfxy,dvfxz,dvfyz] * (sqrt(2/mass) * 1e5)

  dmom.mftens = dvftens * mass / 1e10
endif


; Energy flux (extra factor of energy)

tmp = data3d.data * de_e * weight * e_inf^2 / e
v2f_x = total(tmp * domega_weight[1,*,*,*] )
v2f_y = total(tmp * domega_weight[2,*,*,*] )
v2f_z = total(tmp * domega_weight[3,*,*,*] )
mom.eflux = [v2f_x,v2f_y,v2f_z]   ;* 2/mass * 1e5

if arg_present(dmom) then begin
  tmp1 = unit_scaling * de_e * weight * e_inf^2 / e
  dv2f_x = sqrt(total(tmp * tmp1 * domega_weight[1,*,*,*]^2 ))
  dv2f_y = sqrt(total(tmp * tmp1 * domega_weight[2,*,*,*]^2 ))
  dv2f_z = sqrt(total(tmp * tmp1 * domega_weight[3,*,*,*]^2 ))
  dmom.eflux = [dv2f_x,dv2f_y,dv2f_z]   ;* 2/mass * 1e5
endif

skipsums:        ; enter here to calculate remainder of items.

if size(/type,add_moment) eq 8 then begin
   mom.density = mom.density+add_moment.density
   mom.flux    = mom.flux   +add_moment.flux
   mom.eflux   = mom.eflux  +add_moment.eflux
   mom.mftens  = mom.mftens +add_moment.mftens
endif

if arg_present(dmom) && size(/type,add_dmoment) eq 8 then begin
   dmom.density = sqrt(dmom.density^2+add_dmoment.density^2)
   dmom.flux    = sqrt(dmom.flux^2   +add_dmoment.flux^2)
   dmom.eflux   = sqrt(dmom.eflux^2  +add_dmoment.eflux^2)
   dmom.mftens  = sqrt(dmom.mftens^2 +add_dmoment.mftens^2)
endif

if keyword_set(mom_only) then return,mom

mass = mom.mass

map3x3 = [[0,3,4],[3,1,5],[4,5,2]]
mapt   = [0,4,8,1,2,5]

; vf3x3  = vftens[map3x3]   ; units:   1/cm/s^2

mom.velocity = mom.flux/mom.density /1e5   ; km/s

if arg_present(dmom) then begin
  dmom.velocity = sqrt((dmom.flux/mom.density)^2+(mom.flux*dmom.density/mom.density^2)^2) /1e5
endif


; Heat flux moments -- derived from code contributed by Terry Liu
; 
; Terry's code has been modified to work with the units, scaling, and spacecraft potential handling in moments_3d, rather than the older 
; n_3d, j_3d, and v_3d routines.
; JWL 2025-07-10

eV_J = 1.602176634e-19  ; conversion from eV to J

mp=data3d.mass  ; mass units are eV/(km/sec)^2, for working with eflux units.  In these units, proton mass = 0.010453500
q = eV_J

v = sqrt(2d * data3d.energy/mp)  ; convert energy array to velocity (km/sec)

vx = v*cos(data3d.theta/180.*!pi)*cos(data3d.phi/180.*!pi) 
vy = v*cos(data3d.theta/180.*!pi)*sin(data3d.phi/180.*!pi)
vz = v*sin(data3d.theta/180.*!pi)

; Subtract bulk velocity to get thermal velocity, km/sec

wx=vx-mom.velocity[0]  
wy=vy-mom.velocity[1]
wz=vz-mom.velocity[2]

; thermal energy, eV
Eth=0.5*mp*(wx^2+wy^2+wz^2)

;Repurposed density calculation for integrating heat flux, original code made several calls to n_3d()

data_dvx = Eth*wx*data3d.data * de_e * weight * domega_weight[0,*,*,*]
data_dvy = Eth*wy*data3d.data * de_e * weight * domega_weight[0,*,*,*]
data_dvz = Eth*wz*data3d.data * de_e * weight * domega_weight[0,*,*,*]


dweight = sqrt(e_inf)/e
parqx = sqrt(mass/2.)* 1e-5 * data_dvx * dweight
parqy = sqrt(mass/2.)* 1e-5 * data_dvy * dweight
parqz = sqrt(mass/2.)* 1e-5 * data_dvz * dweight

; Conversion to output units
conv_mw = eV_J*1d12  ; output in mW/m^2
conv_ev = 1d05 ; output in eV/(cm^2-sec)


heat_x = conv_ev * total(parqx)
heat_y = conv_ev * total(parqy)
heat_z = conv_ev * total(parqz)

mom.qflux = [heat_x, heat_y, heat_z]

mf3x3 = mom.mftens[map3x3]

pt3x3 = mf3x3 - (mom.velocity # mom.flux) * mass /1e5
mom.ptens = pt3x3[mapt]

if arg_present(dmom) then begin
  dmf3x3 = dmom.mftens[map3x3]
  
  dpt3x3 = sqrt(dmf3x3^2 + (mom.velocity # dmom.flux)^2 * mass^2 /1e10 + $
                           (dmom.velocity # mom.flux)^2 * mass^2 /1e10)
  
  dmom.ptens = dpt3x3[mapt]
endif

t3x3 = pt3x3/mom.density

mom.avgtemp = (t3x3[0] + t3x3[4] + t3x3[8] )/3.  ; trace/3

if arg_present(dmom) then begin
  dt3x3 = sqrt((dpt3x3/mom.density)^2+(pt3x3*dmom.density/mom.density^2)^2)
  dmom.avgtemp = sqrt(dt3x3[0]^2 + dt3x3[4]^2 + dt3x3[8]^2 )/3.  ; trace/3
endif

mom.vthermal = sqrt(2.* mom.avgtemp/mass)

if arg_present(dmom) then begin
  dmom.vthermal = sqrt(dmom.avgtemp/(2.*mass*mom.avgtemp))
endif

tempt = t3x3[mapt]

good = finite(mom.density)
if (not good) or mom.density le 0 then return,mom

t3evec = double(t3x3) ;jmm, 6-aug-2013

trired,t3evec,t3,dummy
triql,t3,dummy,t3evec

;print,t3evec

if n_elements(magdir) ne 3 then magdir=[-1.,1.,0.]
magfn = magdir/sqrt(total(magdir^2))
s = sort(t3)
if t3[s[1]] lt .5*(t3[s[0]] + t3[s[2]]) then num=s[2] else num=s[0]

shft = ([-1,1,0])[num]
t3 = shift(t3,shft)
t3evec = shift(t3evec,0,shft)
dot =  total( magfn * t3evec[*,2] )

bmag = sqrt(total(mom.magf^2))
if finite(bmag) then begin
   magfn = mom.magf/bmag

   b_dot_s = total( (magfn # [1,1,1]) * t3evec , 1)
   dummy = max(abs(b_dot_s),num)

   rot = rot_mat(mom.magf,mom.velocity)
   magt3x3 = invert(rot) # (t3x3 # rot)
   mom.magt3 = magt3x3[[0,4,8]]
   dot =  total( magfn * t3evec[*,2] )
   mom.symm_ang = acos(abs(dot)) * !radeg
endif

if dot lt 0 then t3evec = -t3evec
mom.symm = t3evec[*,2]

magdir = mom.symm

xyz_to_polar,mom.symm,theta=symm_theta,phi=symm_phi ,ph_0_360=ph_0_360
mom.symm_theta = symm_theta
mom.symm_phi = symm_phi
mom.t3 = t3

valid = 1
mom.valid = 1

return,mom
end

