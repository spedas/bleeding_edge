;	@(#)despin.pro	1.43	
function modsin,phi,nparams
twopi = 2.d*!dpi
fourpi = 2.d*twopi


nparams = 6                     ; two amplitudes, two linear growths,
                                ; and an offset, in that order
;
; the following expression gives spin phase (pp) with numbers of order 1,
; and is guaranteed to not have a wrap in it, as long as modsin is
; called with a spin's worth of data or less.
;
phi0 = double(median(phi))
pp = (phi-phi0) + (phi0 mod twopi)
pplin = phi - phi0
npp = n_elements(pp)

basis = dblarr(npp,nparams)
basis(*,0) = cos(pp)
basis(*,1) = sin(pp)
basis(*,2) = pplin*cos(pp)
basis(*,3) = pplin*sin(pp)
basis(*,4) = 1.0d
basis(*,5) = pplin

return,float(basis)
end
;
;
;
function despin,tecall,ecall,tbcall,bcall,bspincall, $
                ts,ex,ez,bx,bz,by,spin_angle,b2call,hires=hires

magtol = 1.3                    ; 1.+ fractional half-width deviation
dirtol = 1.3                    ; from dipole for FAC identification
min_fitpts = 5                  ; minimum number of points for poly_fits
equiv_noise = 50                ; 50 nT, rough combination of measurement
                                ; noise, calibration noise, inverse
                                ; filter noise, and physical noise!
nsvd = 6
ang_offset = 52.02d/double(!radeg) ; angle between v58 and mag3
fnan = !values.f_nan
dnan = !values.d_nan
r_e = 6376.                     ; km, Earth's radius

te = tecall
tb = tbcall
e = ecall
b = bcall
bspin = bspincall

twopi = 2.d*!dpi
w0 = get_fa_spin_rate(tb,b)
w0 = double(w0)
spin_per0 = twopi/w0
half_width = .55 * spin_per0

if find_handle('spin_times') eq 0 then begin
    message,'WARNING! spin_times have not yet been stored...',/continue
    nts = long(w0*(max(te)-min(te))/twopi)
    ts = te(0) + twopi/w0*dindgen(nts)
    ws = get_fa_spin_rate(tb,b,/precise,phase=phi)
endif else begin
    get_data,'spin_times',data=tss
    ts = tss.x
    phi = tss.phi
    tphi = tss.tphi
endelse

this_interval = where((ts ge (te(0)+!dpi/w0)) and (ts le $
                                                   (max(te)-!dpi/w0)),nti)
if nti lt 2 then return,0

ts = ts(this_interval)

nts = n_elements(ts)

starts = ts - half_width
stops  = ts + half_width

egood = where((te ge min(starts)) and (te le max(stops)),negood)
bgood = where((tb ge min(starts)) and (tb le max(stops)),nbgood)
if (nbgood gt 0) and (negood gt 0) then begin
    e = ecall(egood)
    b = bcall(bgood)
    te = tecall(egood)
    tb = tbcall(bgood)
    
    bord = sort(tb)
    eord = sort(te)
    te = te(eord)
    e = e(eord)
    tb = tb(bord)
    b = b(bord)
endif else begin
    message,'No E,B overlap during currently stored spin_times --> ' + $
      'unable to despin!',/continue
    return,0
endelse

ephi = interp(phi,tphi,te)-ang_offset
bphi = interp(phi,tphi,tb)

ec = fltarr(nsvd,nts)
bc = fltarr(nsvd,nts)
byc = fltarr(nsvd,nts)

bsig = 0.
for i=0,nts-1l do begin
    bp = where((tb ge starts(i)) and (tb le stops(i)),nbp)
    
    if (nbp gt 1) then begin
        t1 = max(tb(bp),min=t0)
        this_fit = fltarr(nbp)
        weight = 1./(fltarr(nbp) + equiv_noise)
        if ((t1-t0) gt spin_per0) then begin
            bc(*,i) = $
              svdout(bphi(bp),b(bp),nsvd,funct='modsin',chisq=bsig, $
                     yfit = this_fit, weight=weight)
        endif else begin
            bc(*,i) = fnan
        endelse
        
        byc(*,i) = $
          svdout(bphi(bp),bspin(bp),nsvd,funct='modsin',chisq=bysig, $
                 yfit = this_yfit, weight=weight)
        
        if (bsig gt (nbp-nsvd)) then begin
            bc(*,i) = fnan
            byc(*,i) = fnan
        endif
    endif else begin
        bc(*,i) = fnan
        byc(*,i) = fnan
    endelse
    
    ep = where((te ge starts(i)) and (te le stops(i)),nep)
    if nep gt 1 then begin
        ec(*,i) = $
          svdfit(ephi(ep),e(ep),nsvd,funct='modsin')
    endif else begin
        ec(*,i) = fnan
    endelse
endfor


;
; if bc's are NaN'd, also NaN the ec's...
;
not_nan = where((bc(0,*) eq bc(0,*)) and (bc(1,*) eq bc(1,*)),nnn)
is_nan  = where((bc(0,*) ne bc(0,*)) or  (bc(1,*) ne bc(1,*)),nin)

if nnn lt 3 then begin
    message,'No valid DC data...all NaN!',/continue
    return,0
endif
;
; Now use orbit data to find maximum allowable d/dt's for the B field
; magnitude and direction (sun phase). Use this info to identify any
; FAC regions. 
;
get_data,'B_model',data=bmodels,index=ibmod
if ibmod eq 0 then begin
    message,'Need to have called get_fa_orbit with /ALL',/continue
    return,0
endif

b1 = spline(bmodels.x-ts(0),reform(bmodels.y(*,0)),ts-ts(0),.01)
b2 = spline(bmodels.x-ts(0),reform(bmodels.y(*,1)),ts-ts(0),.01)
b3 = spline(bmodels.x-ts(0),reform(bmodels.y(*,2)),ts-ts(0),.01)

bmodmag = sqrt(b1^2+b2^2+b3^2)

;
; compute dipole derivative estimates...
;
db_dt = deriv(ts,bmodmag)
; 
; compute approximate rate of change of direction...for small angles
; it's magn(cross-product)/dot-product / spin period
;
i0  = lindgen(nts-1l)
i1  = i0+1l
b10 = b1(i0)
b20 = b2(i0)
b30 = b3(i0)
b11 = b1(i1)
b21 = b2(i1)
b31 = b3(i1)

c10 = sqrt((b21*b30 - b20*b31)^2 + (b11*b30 - b10*b31)^2 + (b11*b20 - b10*b21)^2)
d10 = b11*b10 + b21*b20 + b31*b30 
tht = abs(c10/d10)              ; really abs(tan(tht)), but tht is
                                ; small...
tht = [tht(0)-(tht(1)-tht(0)),tht]
ddir0 = tht / spin_per0

dlinamp = ((bc(3,*)*bc(1,*)+bc(2,*)*bc(0,*))/bmodmag)*w0 ; no, really!
;
; define b0dir, the sun phase of the spin fitted field, and unwrap it... 
;
b0dir = fltarr(nts)
b0dir(*) = fnan
b0dir(not_nan) = reform(atan(bc(1,not_nan),bc(0,not_nan)))
;
; Unwrap the drifting main field direction...this is the best way I
; found to do it. There are only a few hundred spin times to loop
; thru. 
; 
max_wraps = 5

two_n_pi = twopi * (dindgen(2L*max_wraps+1L)-double(max_wraps))
for i=1,nnn-1 do begin
    dist = abs([b0dir(not_nan(i))+two_n_pi]-b0dir(not_nan(i-1l)))
    closest = where(dist eq min(dist))
    b0dir(not_nan(i)) = b0dir(not_nan(i))+two_n_pi(closest)
endfor

ddir = deriv(ts,b0dir)
;
;
; compute magnitudes of spin-fitted fields
;
emag = fltarr(nts)
bmag = fltarr(nts)
emag(not_nan) = reform(sqrt(ec(0,not_nan)^2 + ec(1,not_nan)^2))
bmag(not_nan) = reform(sqrt(bc(0,not_nan)^2 + bc(1,not_nan)^2 + $
                            byc(4,not_nan)^2))

by = reform(byc(4,*))
spin_angle = fltarr(nts)
spin_angle(*) = fnan
coeffs = poly_out(not_nan,asin(by(not_nan)/bmag(not_nan)),2)
spin_angle(not_nan) = poly_eval(not_nan, coeffs)
;
; test for wild data...FAC's, glitches, aliens, whatever...
;
wild = bytarr(nts)
;                 (dlinamp(not_nan) gt db_dt(not_nan)*magtol) or $ 
;                 (dlinamp(not_nan) lt db_dt(not_nan)/magtol) or $
;                 (abs(ddir(not_nan)) gt abs(ddir0(not_nan))*dirtol) or $
;                 (abs(ddir(not_nan)) lt abs(ddir0(not_nan))/dirtol) or $

wild(not_nan) = ((bmag(not_nan) gt bmodmag(not_nan)*magtol) or  $
                 (bmag(not_nan) lt bmodmag(not_nan)/magtol) or  $
                 (abs(by(not_nan)) gt $
                  abs(bmodmag(not_nan)*sin(spin_angle(not_nan))*magtol)) or $
                 (abs(by(not_nan)) lt $
                  abs(bmodmag(not_nan)*sin(spin_angle(not_nan))/magtol)))
if nin gt 0 then wild(is_nan) = 1 ; NaN's are also wild...
;
; define the FAC indices, indexes to where the data is wild, and also
;    define the NOT_FAC indices...
;
fac = where((wild eq 1),nfac)
not_fac = where(wild ne 1,nnfac)

if nnfac lt min_fitpts then begin
    message,'All data appear to be FAC!',/continue
    return,0
endif
;
; identify survey speeds...separate fits must be done for each speed...
;
get_data,'speeds',data=speeds,index=ispeed
while (ispeed eq 0) do begin 
    message,'Speeds not loaded, calling ' + $
      'LOAD_FIELDS_MODEBAR...',/continue
    load_fields_modebar
    get_data,'speeds',data=speeds,index=ispeed
endwhile

speed = speeds.speeds(this_interval)
slow = where(speed eq 'slow',nslow)
fast = where(speed eq 'fast',nfast)
back = where(speed eq 'back',nback)

;
; define scaled times for use in polynomial fits...t_fit excludes wild
; data, t_eval allows all...
;
tran = max(ts) - min(ts)
t_fit = (ts(not_fac)-ts(0))/tran
t_eval = (ts - ts(0))/tran
;
; fit a polynomial to b0dir, the main field direction. Each survey
; speed is handled separately; a piece-wise polynomial...
;
b0dir_fit = fltarr(nts)
b0dir_fit(*) = fnan
if nslow gt 0 then begin
    fp = where(wild(slow) ne 1,nfp)
    if nfp gt min_fitpts then begin
        fitpick = slow(fp)
        b0dir_fit(slow) = $
          poly_eval(t_eval(slow),poly_out(t_eval(fitpick),b0dir(fitpick),4))
    endif
endif
if nfast gt 0 then begin
    fp = where(wild(fast) ne 1,nfp)
    if nfp gt min_fitpts then begin
        fitpick = fast(fp)
        b0dir_fit(fast) = $
          poly_eval(t_eval(fast),poly_out(t_eval(fitpick),b0dir(fitpick),4))
    endif
endif
if nback gt 0 then begin
    fp = where(wild(back) ne 1,nfp)
    if nfp gt min_fitpts then begin
        fitpick = back(fp)
        b0dir_fit(back) = $
          poly_eval(t_eval(back),poly_out(t_eval(fitpick),b0dir(fitpick),4))
    endif
endif
if nin gt 0 then begin
    b0dir_fit(is_nan) = fnan
endif

;
; In the case where we are not in a particular survey speed for long
; enough to get a fit, there will be new NaN's in b0dir_fit which were
; not present in bc, and these need to be accounted for by appending
; to FAC and IS_NAN, and adjusting NOT_FAC and NOT_NAN, etc.,
; accordingly. 
;
b0dir_nans = where(b0dir_fit ne b0dir_fit,nb0dn)
if nb0dn ne nin then begin
    is_nan = b0dir_nans
    nin = nb0dn
    not_nan = where(b0dir_fit eq b0dir_fit,nnn)
    if nnn lt min_fitpts then begin
        message,'Can''t fit main field direction...all NaN!',/continue
        return,0
    endif
    wild(is_nan) = 1
    fac = where((wild eq 1),nfac)
    not_fac = where(wild ne 1,nnfac)
    if nnfac lt min_fitpts then begin
        message,'Can''t fit main field direction...all FAC!',/continue
        return,0
    endif
    tran = max(ts) - min(ts)
    t_fit = (ts(not_fac)-ts(0))/tran
    t_eval = (ts - ts(0))/tran
endif

;
; now that we have a model for the sun phase of B0, we can subtract
; this direction from the directions indicated by the spinfit
; data. This residual direction (mag phase) is the one appropriate to
; the summary plot coord system.
;
edir = fltarr(nts)
bdir = fltarr(nts)
edir(*) = fnan
bdir(*) = fnan
edir(not_nan) = reform(atan(ec(1,not_nan),ec(0,not_nan))) - b0dir_fit(not_nan)
bdir(not_nan) = reform(atan(bc(1,not_nan),bc(0,not_nan))) - b0dir_fit(not_nan)
;
; define the spin plane fields by resolving the magnitudes into
; components using bdir and edir...
;
ez = fltarr(nts)
ex = fltarr(nts)
bz = fltarr(nts)
bx = fltarr(nts)
ez(*) = fnan
ex(*) = fnan
bz(*) = fnan
bx(*) = fnan
ez(not_nan) = float(emag(not_nan)*cos(edir(not_nan)))
ex(not_nan) = float(emag(not_nan)*sin(edir(not_nan)))
bz(not_nan) = float(bmag(not_nan)*cos(bdir(not_nan)))
bx(not_nan) = float(bmag(not_nan)*sin(bdir(not_nan)))
;
;  subtract the best 2nd order polynomial, to get a simulated dB...
;
bxfit = fltarr(nts)
bzfit = fltarr(nts)
byfit = fltarr(nts)
bxfit(*) = fnan
bzfit(*) = fnan
byfit(*) = fnan
;
; bxfit should be nearly a zero line...
;
bxfit(not_nan) = poly_eval(t_eval(not_nan),poly_out(t_fit,bx(not_fac),2))
;
; bzfit should go like bmodmag...
;
bzfit(not_nan) = poly_eval(t_eval(not_nan), $
                           poly_out(t_fit,bz(not_fac)/bmodmag(not_fac),2) $
                          )*bmodmag(not_nan)
;
; byfit should go like bmodmag*sin(spin_angle)
;
byfit(not_nan) = poly_eval(t_eval(not_nan), $
                           poly_out(t_fit, $
                                    by(not_fac)/ $
                                    (bmodmag(not_fac)*sin(spin_angle(not_fac))),2) $
                          )*bmodmag(not_nan)*sin(spin_angle(not_nan))


bx(not_nan) = bx(not_nan) - bxfit(not_nan)
bz(not_nan) = bz(not_nan) - bzfit(not_nan)
by(not_nan) = by(not_nan) - byfit(not_nan)

spin_angle = abs(spin_angle * !radeg)
;
; HOORAY!!
;

return,1
end

