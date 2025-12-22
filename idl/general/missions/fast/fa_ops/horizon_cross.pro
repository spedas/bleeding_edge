;
;  By default, this function returns the spin period as determined by the
;  horizon sensor. AttitudeCtrl (apid 1080) must be in SDT
;  already. There are no required inputs, but it will run faster if
;  you pass in att and orb. 
;
;
function horizon_cross, att, show = show, orb = orb, return_omega = $
                        return_omega, omega = whci,  $
                        suntimes = suntimes, phase = phase

if not defined(att) then att = get_fa_fields('AttitudeCtrl', calibrate=0)
if not defined(orb) then  $
  get_fa_orbit, att.time, /time, /no_store, struc = orb

tau0 = 5.07
twopi = 2.d*!dpi
setimes = att.comp10
estimes = att.comp12
;
; Compute the spin periods as seen by estimes and setimes. The
; corresponding spin rate is called wtot, because it includes both the
; spin of FAST and the apparent rotation due to orbital motion. 
;
nsmooth = 5
nse = long((setimes[nsmooth:*]-setimes[0:*])/tau0 + 0.5)
nes = long((estimes[nsmooth:*]-estimes[0:*])/tau0 + 0.5)

tau_se = (setimes[nsmooth:*] - setimes[0:*])/float(nse)
tau_es = (estimes[nsmooth:*] - estimes[0:*])/float(nes)
wtot = 0.5 * twopi * (1./tau_se + 1./tau_es)

if keyword_set(show) then begin
    plot,tau_se,/yno
    oplot,tau_es
endif
;
; So far so good, but there are still a total of nsmooth points
; unaccounted for. Do a poly extrapolation at each end to fill them
; in. 
;
nt = att.npts
nfp = 20
nbeg = nsmooth/2l
nend = nsmooth - nbeg
ndeg = 2                        ; quadratic

tsi_e = lindgen(nbeg)
tsi_f = nbeg + lindgen(nfp)
wsi_f = lindgen(nfp)
tei_e = nt - nend + lindgen(nend)
tei_f = nt - nend - nfp + lindgen(nfp) 
wei_f = nt - nfp + lindgen(nfp)
t0 = min(att.time[tsi_f], /nan) 
t1 = max(att.time[tei_f], /nan)

wtot_start = poly_eval(att.time[tsi_e]-t0, $
                       poly_fit(att.time[tsi_f]-t0, wtot[wsi_f], ndeg))
wtot_end = poly_eval(att.time[tei_e]-t1, $
                     poly_fit(att.time[tei_f]-t1, wtot[wei_f], ndeg))
wtot = [wtot_start, wtot, wtot_end]
;
; Now compute the rate at which the nadir rotates, and subtract it
; from wtot to get an HCI-based estimate of the spin rate. We subtract
; the absolute value of the nadir rotation rate, because FAST is
; anti-cartwheeling. 
;
fp = dblarr(nt, 3)
fv = fp

fp[*,0] = ff_interp(att.time, orb.time, orb.fa_pos[*,0], delt=100.d)
fp[*,1] = ff_interp(att.time, orb.time, orb.fa_pos[*,1], delt=100.d)
fp[*,2] = ff_interp(att.time, orb.time, orb.fa_pos[*,2], delt=100.d)
fv[*,0] = ff_interp(att.time, orb.time, orb.fa_vel[*,0], delt=100.d)
fv[*,1] = ff_interp(att.time, orb.time, orb.fa_vel[*,1], delt=100.d)
fv[*,2] = ff_interp(att.time, orb.time, orb.fa_vel[*,2], delt=100.d)

r = sqrt(total(fp^2,2))
v = sqrt(total(fv^2, 2))
vr = total(fp * fv, 2)/r
vtht = sqrt((v + vr)*(v  - vr))
wn = vtht / r

whci = wtot - wn

if keyword_set(show) then begin
    wsun = twopi/att.comp26
    plot,whci,/yno,xran=[0,100]
    oplot,wsun,color=!d.n_colors*0.6
endif

;
; Make sure space earth transition leads earth space, and by less
; than one spin period.  
; 

repeat begin
    dhci = estimes - setimes      ; should be positive
    neg = where(dhci lt 0, nneg)
    if nneg gt 0 then setimes[neg] = setimes[neg] - twopi/wtot
endrep until (nneg eq 0)

ntimes = (estimes + setimes)/2.d   ; the first-order correction vanishes,
                                ; and is pretty small anyway, so these
                                ; are the nadir times. 

;
; get sunline
;
store_data,'slgse',data={x:att.time, y: [[fltarr(att.npts)+1.], $
                                         [fltarr(att.npts)],  $
                                         [fltarr(att.npts)]]}
coord_trans,'slgse','slgei','GSEGEI'
get_data,'slgei',data=slgei
sunline = slgei.y
;
; get spin_axis
;
atime = att.start_time
fdf = get_fa_fdf_att(atime)
spin_axis = [[replicate(fdf.x,att.npts)], $
             [replicate(fdf.y,att.npts)], $
             [replicate(fdf.z,att.npts)]]
;
; get nadir
;
nadir = -fp / (r # replicate(1.,3)) ; unit vector from FAST!

diff = ang_from_a2b_about_s(nadir, sunline, spin_axis)

;
; put diff between 0 and twopi
;

repeat begin
    big = where(diff gt twopi, nbig) 
    if nbig gt 0 then diff[big] = diff[big] - twopi 
endrep until nbig eq 0
repeat begin 
    small = where(diff lt 0, nsmall) 
    if nsmall gt 0 then diff[small] = diff[small] + twopi 
endrep until nsmall eq 0

suntimes = ntimes + diff/whci

;   t0 is previous midnight.

t0 = str_to_time(strmid(time_to_str(att.time(0)),0,10))
tsamp = att.time - t0

phi_wrapped = (tsamp - suntimes)*whci

dphi = phi_wrapped[1:*] - phi_wrapped[0:*]
dt = tsamp[1:*]-tsamp[0:*]
nspins = [0l,long(dt*whci/twopi - dphi/twopi + 0.5)]

phi_jitter = phi_wrapped

for i=0,att.npts-1l do phi_jitter[i:*] = phi_jitter[i:*] + nspins*twopi

phi_jitter = phi_jitter - double(long(phi_jitter(0)/twopi)+1l)*twopi

if keyword_set(show) then begin
    plot,deriv(att.time,phi_jitter) ;,yran=[1.24,1.26]
    oplot,deriv(att.time,phi_jitter),psym=1
    oplot,whci, color=!d.n_colors*0.6
endif

phase = temporary(phi_jitter)
if keyword_set(return_omega) then return,whci else return, twopi/whci

end
