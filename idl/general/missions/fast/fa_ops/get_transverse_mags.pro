;
; THIS IS NOT THE MAIN PROGRAM!! SEE BELOW...
;
; This code is not really meant to be used by co-I's. UCLA_MAG_DESPIN
; is probably much better for your purpose. BP
;
;
pro unbend_axes,t, bx, by, bz, bmodel, s, vel, ilat
;
; The components bx, by, and bz, on input, are paired with unit
; vectors s and q, nb, respectively, and are returned paired with unit
; vectors sp and vp, and b_up. s, q, and nb are effectively "sensor
; directions" in despun coords, while sp, vp, and b_up are directions
; chosen for their convenience in studying currents.
;
; INPUT BASIS VECTORS:
;
; Unit vector s is given, q must be computed. q is the
; direction that the s/c X axis points, 1/4 spin after its
; near-alignment with B.  Another way to say it is that q is the
; direction of the s/c X axis when the mag phase is 90 degrees. This
; is true in both hemispheres, therefore it is not correct to change
; the sign of q, ever. 
; 
bhat = normn3(bmodel)
q = normn3(crossn3(s,bhat))
;
; nb must also be computed. It is the projection of bhat into the
; spin plane.
;
nb =  normn3(crossn3(crossn3(s, bhat), s))
;
; OUTPUT BASIS VECTORS:
;
; vp is the unit vector in the direction of the s/c velocity,
; projected into the plane perpendicular to B. In other words, vp
; defines the "along-track" direction. 
;
vp = normn3(crossn3(crossn3(bhat,vel), bhat))
;
; The cross-track direction is perpendicular to both the along-track
; direction vp and the model field bmodel. So, within a sign, the
; cross-track direction sp will be given by the cross-product of vp
; with bmodel. 
;
; The sign of sp is then chosen such that the cross-product of sp and
; vp gives a (roughly) upward unit vector. This is helpful when using
; the magnetic perturbations to compute currents, because then any
; particular convention chosen for taking the curl will then yield a
; number with a sign indicating upward or downward current. ilat is
; used to determine when to flip sp.
;
sp = normn3(crossn3(vp,bhat))
need_to_flip = where(ilat gt 0, nntf)
if nntf gt 0 then sp[need_to_flip,*] = -sp[need_to_flip,*]
;
; The 3rd output basis vector, b_up, is along the model field, whichever
; sign is closest to upwards.
;
b_up = bhat
if nntf gt 0 then b_up[need_to_flip,*] = -b_up[need_to_flip,*]
;
; compute matrix the safe way, and do the transformation.
;
a11 = total(s  * sp,   2)
a12 = total(q  * sp,   2)
a13 = total(nb * sp,   2)
a21 = total(s  * vp,   2)
a22 = total(q  * vp,   2)
a23 = total(nb * vp,   2)
a31 = total(s  * b_up, 2)
a32 = total(q  * b_up, 2)
a33 = total(nb * b_up, 2)

bxp = a11*bx + a12*by + a13*bz
byp = a21*bx + a22*by + a23*bz
bzp = a31*bx + a32*by + a33*bz
;
; Subtract the model field. bxp and byp are already perpendicular to the
; model field, so this is not really necessary. bzp is the component
; along the parallel field. May someday check to make sure that bz
; (after subtraction) is small. 
;
bx = bxp - total(bmodel * sp,   2)
by = byp - total(bmodel * vp,   2)
bz = bzp - total(bmodel * b_up, 2)

return
end
;
;
function get_transverse_mags,mdc,t1,t2,load_structure = $
                             load_structure, $
                             stefan = stefan, interval = interval, $
                             slide = slide, no_store = no_store, orb = $
                             orb

;
; LOAD_STRUCTURE - if set, causes the (pre-defined) MDC structure to
;                  be stored properly for use by
;                  CURRENT_DETECT. Useful for passing test data into
;                  these programs. The input data must be expressed in
;                  the spinning s/c frame.
;
; STEFAN -  if set, prevents spin averaging of mag data...data are
;          returned at full time resolution. 
;
; INTERVAL - width, in fraction of a spin period, of averaging
;            interval. 
;
; SLIDE - amount by which averaging interval moves between adjacent
;         output points, again in units of a spin period. 
;
;  To get one point per spin, with no overlap between points, set
;                  INTERVAL to 1.0 and SLIDE to 1.0. To get 5 points
;                  per spin, with 50% overlap, set INTERVAL to 0.2 and
;                  slide to 0.1. 
;

no_store = keyword_set(no_store)
dnan = !values.d_nan
if idl_type(mdc) ne 'structure' then begin
;
; get orbit data and set timespan
;
    if not (defined(t1) and defined(t2)) then begin
        dummy = get_sdt_timespan(dqd='MagDC',t1,t2)
    endif 
    
    get_fa_orbit,t1,t2,/all,/no_store,struc=orb
    
;
; get the mag data...
;
    mdc = fa_fields_magdc(t1=t1,t2=t2)
    ff_ptr_to_dat,mdc
    if not no_store then timespan,t1,t2-t1,/sec
;
; compute the spin phase...
;
    ps = fa_fields_phase(/precise,spin_axis=spin_axis)
;
; despin to the mean field
;
    phi = ff_interp(mdc.time,ps.time,ps.comp1,delt=100.)
    cphi = cos(phi)
    sphi = sin(phi)
    m1 = (mdc.comp1)*cphi - (mdc.comp2)*sphi
    m2 = (mdc.comp1)*sphi + (mdc.comp2)*cphi   
;
; knock out ridiculous values
;
;   first compute eps...
;
    bmag = $
      ff_interp(mdc.time,orb.time,sqrt(total(orb.b_model^2,2)), $
                delt=100.,/spline)
    eps = sqrt(m1^2+m2^2+mdc.comp3^2)/bmag - 1.d
    if not no_store then store_data,'eps',data={x:mdc.time, y:eps}
    
    max_m2 = 2000.
    max_eps = .02
    
    eps_oops = where((abs(eps) gt max_eps) or  $
                     (abs(m2) gt max_m2), neo)
    if neo gt 0 then begin
        m1(eps_oops) = dnan
        m2(eps_oops) = dnan
        mdc.comp3(eps_oops) = dnan
    endif
    
    if not no_store then store_data,'mag v',data={x:mdc.time,y:m2}

    mdc.comp1 = m1
    mdc.comp2 = m2
    
    if not defined(interval) then interval = 0.2
    if not defined(slide) then slide = interval
    if not keyword_set(stefan) then  $
      fa_fields_spin_ave,mdc,interval=interval,slide=slide,phase=phi
    
    bmodel =  $
      [[ff_interp(mdc.time,orb.time,orb.b_model[*,0],/spline,delt=60.d)], $
       [ff_interp(mdc.time,orb.time,orb.b_model[*,1],/spline,delt=60.d)], $
       [ff_interp(mdc.time,orb.time,orb.b_model[*,2],/spline,delt=60.d)]]

    fdf1 = get_fa_fdf_att(t1)
    fdf2 = get_fa_fdf_att(t2)
    spx = fdf1.x + (mdc.time-t1)*(fdf2.x - fdf1.x)/(t2-t1)
    spy = fdf1.y + (mdc.time-t1)*(fdf2.y - fdf1.y)/(t2-t1)
    spz = fdf1.z + (mdc.time-t1)*(fdf2.z - fdf1.z)/(t2-t1)
    
    spinax = [[spx],[spy],[spz]]
    
    fa_vel = dblarr(mdc.npts,3)
    fa_vel(*,0) = ff_interp(mdc.time,orb.time,orb.fa_vel(*,0),delt=100.)
    fa_vel(*,1) = ff_interp(mdc.time,orb.time,orb.fa_vel(*,1),delt=100.)
    fa_vel(*,2) = ff_interp(mdc.time,orb.time,orb.fa_vel(*,2),delt=100.)
    
    ilat = ff_interp(mdc.time,orb.time,orb.ilat,delt=100.)
    
;
; now transform these two components into true cross-track and
; along-track components in the plane perpendicular to B.  Presently,
; the two mags are not even orthogonal, and in the south, mag v has
; the wrong sign. UNBEND_AXES fixes all that.
;    
    m2 = mdc.comp2
    bsax = mdc.comp3            ; WATCH OUT!!!
    m1 = mdc.comp1
    
    unbend_axes, mdc.time, bsax, m2, m1, bmodel, spinax, fa_vel, ilat
    
    if not no_store then begin
        store_data,'bsax',data={x:mdc.time,y:bsax}
        store_data,'mag v',data={x:mdc.time,y:m2}
        store_data,'dB par',data={x:mdc.time, t:m1}
    endif
    
    mdc.comp2 = m2
    mdc.comp3 = bsax
    mdc.comp1 = m1
    
endif else begin
    message,'mag_data is already defined!!',/continue
endelse


if keyword_set(load_structure) then begin
    store_data,'mag v',data={x:mdc.time,y:mdc.comp2}
    
    bsax = mdc.comp3
    store_data,'bsax',data={x:mdc.time,y:bsax}
endif

return,mdc
end
