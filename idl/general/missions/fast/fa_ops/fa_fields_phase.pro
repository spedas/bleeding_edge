;+
;FUNCTION:   FA_FIELDS_PHASE, spin_phase, freq=freq
;                      
;PURPOSE:   Returns structure with smoothed B_phase as COMP1 and
;           Sun_phase as COMP2 in radians. 
; 
;INPUT:   
;       spin_phase - NOT NEEDED. PROGRAM WILL GET IF NOT SUPPLIED.
;                    Fast DQD = 'SMPhase_FieldsSurvey0' stucture.
;
; KEYWORDS: 
;       FREQ - Smoothing frequency. Default = 0.01. Set to 0 for no
;       smooth.
;
;       PRECISE - if set, uses housekeeping data (dqd is
;       'AttitudeCtrl') to produce jitter-free sun phase, and then mag
;       phase from GET_FA_ORBIT B_model calculation. 
;
;       SPIN_AXIS - a named variable in which an estimate of the spin
;       axis will be returned. Meaningless if /PRECISE is not set.
;
; USE: phase = fa_fields_phase()
;
; RETURN: Fields structure with smoothed B_phase and Sun_phase in radians.
;
;CREATED BY:    REE, 97-03-03
;FILE:  fa_fields_phase.pro
;VERSION:  @(#)fa_fields_phase.pro	1.35 09/30/98 UCB SSL
;LAST MODIFICATION:  
;-
;
; SKIP DOWN TO "MAIN PROGRAM"...
;
pro sun_mag_diff,time,ang,diff,pder
;
; given three GSE angles (spin axis polar, azimuth, and sun sensor
; mismount), computes the expected difference between sun and mag
; phase, using the IGRF as returned by GET_FA_ORBIT. Sun and mag phase
; are the projections of the earth-sun line and the IGRF into the
; dynamic spin plane, i.e. the one perpendicular to the dynamic spin
; axis. 
;
common bp,tb,bfit
twopi = 2.d *!dpi

if not (defined(tb) and defined(bfit)) then begin
    do_basis: message,'setting up basis funcs...',/continue
    
    t1 = min(time,/nan,max=t2)

    get_fa_orbit,t1-600.d,t2+600.d,/all,/no_store,struc=orb
    bmod = orb.b_model
    bmag = sqrt(total(bmod^2,2))
    bhat =  bmod / [[bmag],[bmag],[bmag]]

    store_data,'bhat gei',data={x:orb.time,y:bhat}
    coord_trans,'bhat gei','bhat gse','GEIGSE'
    get_data,'bhat gse',data=bhatgse

    tb = orb.time
    bfit = fltarr(n_elements(orb.time),3)
    bfit(*,0) = bhatgse.y(*,0)
    bfit(*,1) = bhatgse.y(*,1)
    bfit(*,2) = bhatgse.y(*,2)
    
    store_data,'bhat gei',/delete
    store_data,'bhat gse',/delete
endif

if not((min(tb) lt min(time)) and (max(tb) gt max(time))) then goto,do_basis

ntime = n_elements(time)
b1 = dblarr(ntime)
b2 = b1
b3 = b1

; Must re-interpolate each time as number of points is reduced by
; outlier rejection.

b1 = ff_interp(time,tb,bfit(*,0),delt=400.,/spline)
b2 = ff_interp(time,tb,bfit(*,1),delt=400.,/spline)
b3 = ff_interp(time,tb,bfit(*,2),delt=400.,/spline)


; The spin axis rotates about 1 degree/day in GSE. 

omegah = 1.99102d-07  ; radians per sec of inertial spin axis in GSE
phih = omegah*(time-tb(0))
cosphih = cos(phih)
sinphih = sin(phih)

s = [sin(ang(0))*cos(ang(1)),sin(ang(0))*sin(ang(1)),cos(ang(0))]
s1 = s(0)*cosphih - s(1)*sinphih
s2 = s(1)*cosphih + s(0)*sinphih
s3 = replicate(s(2),ntime)

sb = s1*b1+s2*b2+s3*b3

hp1 = 1.d - s1^2
hp2 = -s1*s2    
hp3 = -s1*s3    
bp1 = b1 - s1*sb
bp2 = b2 - s2*sb
bp3 = b3 - s3*sb

hpxbp = [[hp2*bp3 - hp3*bp2], $ 
         [hp3*bp1 - hp1*bp3], $ 
         [hp1*bp2 - hp2*bp1]]    

hpxbpnorm = sqrt(total(hpxbp^2,2))
oops = where(total(hpxbp * [[s1],[s2],[s3]],2) gt 0.,noops)
if noops gt 0 then hpxbpnorm(oops) = -hpxbpnorm(oops)

diff = unwrap(atan(hpxbpnorm,(b1 - s1*sb))) + ang(2)

return
end
;
;---------------MAIN PROGRAM!
;
function fa_fields_phase, spin_phase, FREQ=freq, PRECISE = precise, $
                          SPIN_AXIS = spin_axis, TEST = test

common heat, tphi, ang_rad, day_frac, sunlit
forward_function curvout

twopi = 2.d*!dpi
crap = {data_name:'BS phase',valid:0L}
nom_spin_per = 5.07

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    catch,/cancel
    return,crap
endif
catch,/cancel
;
; The first section grabs the phase information from the 1032
; packets. This stuff has processor jitter in it, but is ok for many
; purposes. The data need to be unwrapped and converted to
; radians. Also, the agreed-upon zero phase is chosen. 
;

; First Check if spin_phase is given.
if idl_type(spin_phase) ne 'structure' then begin
    spin_phase = get_fa_fields('SMPhase_FieldsSurvey0',/all,/repair)
endif
if not spin_phase.valid then begin
    message,'Need to have spin phase loaded in SDT: ',/continue 
    print,'Add Plot -> Fields Survey -> 1032-spinPhase'
; "undefine" invalid spin_phase for successive calls...
    spin_phase = 0
    return,crap
endif

npts = spin_phase.npts

; Set up B_phase
B_phase = dblarr(spin_phase.npts)
B_phase = spin_phase.comp3*1024.d + spin_phase.comp1 + spin_phase.comp2/4.d

; Set up S_phase
S_phase = dblarr(spin_phase.npts)
S_phase = spin_phase.comp3*1024.d + spin_phase.comp1

; Remove roll over - phase should continuously increase.
; Note that this subroutine is written for translation to C. Not 
; optimized for IDL.
FOR i = 1l, npts-1 do BEGIN
    dt = spin_phase.time(i)-spin_phase.time(i-1)

                                ; If there is a big time gap, restart the phase.
    IF (dt LT 1000.0*5) then BEGIN 

        diff = ( B_phase(i) - B_phase(i-1) ) - (dt/5.0)*1024. + 512.
        if diff LT 0 then $
          B_phase(i) = B_phase(i) + long( -diff/1024 ) * 1024. + 1024.
        while (diff GT 1024.) DO BEGIN
            B_phase(i) = B_phase(i) - 1024.0
            diff = ( B_phase(i) - B_phase(i-1) ) - (dt/5.0)*1024. + 512.
        endwhile

        diff = ( S_phase(i) - S_phase(i-1) ) - (dt/5.0)*1024. + 512.
        if diff LT 0 then $
          S_phase(i) = S_phase(i) + long( -diff/1024 ) * 1024. + 1024.
        WHILE (diff GT 1024.) DO BEGIN
            S_phase(i) = S_phase(i) - 1024.0
            diff = ( S_phase(i) - S_phase(i-1) ) - (dt/5.0)*1024. + 512.
        ENDWHILE


    ENDIF
ENDFOR

; Change into radians.
B_phase = B_phase*!dpi*2.d/1024.d + !dpi ; add pi so that it means
                                ; "angle between s/c X and B".
S_phase = S_phase*!dpi*2.d/1024.d
;
; Make return structure. Hack off points from either end which are not
; part of contiguous streaks. 
;
first_point = spin_phase.streak_starts(0)
last_point = max(spin_phase.streak_ends)
ppick = lindgen(last_point-first_point+1L) + first_point

start_time = spin_phase.time(first_point)
end_time = spin_phase.time(last_point)
depth = lonarr(2)+1L

phase_out =     {DATA_NAME: 		'B_phase',		$
                  DATA_NAME2:		'S_phase', 		$
                  VALID:		1, 			$
                  PRECISE:              0,			$
                  PROJECT_NAME:		'FAST', 		$
                  UNITS_NAME:		'radians',		$
                  CALIBRATED:		1,			$
                  UNITS_PROCEDURE: 	'',	 		$
                  START_TIME:		start_time,		$
                  END_TIME:		end_time,		$
                  NPTS:		n_elements(ppick),	$
                  NCOMP:		2,			$
                  DEPTH:		depth,			$
                  TIME:		spin_phase.time(ppick),	$
                  COMP1:		B_phase(ppick),		$
                  COMP2:		S_phase(ppick) }

;
; Check FREQ keyword, and low pass filter if set.
;
if n_elements(freq) EQ 0 then f=double(0.01) else f=freq
if (f NE 0) and not keyword_set(precise) then begin
;error check for single data point, to bypass catch, jmm,2025-04-01
   if n_elements(phase_out.time) le 1 then begin
      message,/info,'Not enough phase points'
      crap = {data_name:'BS phase',valid:0L}
      return, crap
   endif
   fa_fields_filter,phase_out,[0.0,0.1]
endif
;
; Now comes the part called by setting /PRECISE. Note that the program
; falls back on the 1032-phase if it fails to do PRECISE for any
; reason. 
; 
if keyword_set(precise) then begin
    min_timespan = 3600.        ; at least one hour of data required
    
    att = get_fa_fields('AttitudeCtrl',/all,/repair)
    if not att.valid then begin
        message,'need to have AttitudeCtrl loaded by ' + $
          'SDT...any DQD from Add Plot -> AttitudeCtrl will do the ' + $
          'job.',/continue
        catch,/cancel
        return,phase_out
    endif

    if (att.end_time - att.start_time) lt min_timespan then begin
        message,'Insufficient time span for /PRECISE phase ' + $
          'stuff...',/continue
        return,phase_out
    endif
    
;   Use the AttitudeCtrl packet (att) info to get some noisy sun phase data.
;   This first bit just gets the spin period (sun) along with the
;   integer number of spins between sun pulses. The variables SUNTIMES
;   and MAGTIMES, from att.comp2 and att.comp6, contain the time of
;   the most recent sun pulse or mag-x measured-field-alignment. They
;   use the previous midnight for an origin.
    
;   t0 is previous midnight.
    
    t0 = str_to_time(strmid(time_to_str(att.time(0)),0,10))
    
    tphi = att.time
    suntimes = att.comp2
    oopsie_dayz = where(suntimes gt (tphi-t0),n_oops)
    if n_oops gt 0 then begin
        suntimes(oopsie_dayz) = suntimes(oopsie_dayz) + 86400.d
    endif
    
    delta_sun = suntimes(1:*) - suntimes(0:*)
    delta_sun = [delta_sun(0),delta_sun]
    objper = att.comp26
    nspinsbetween = fix(delta_sun/objper + 0.5d)
    spin_per = delta_sun / double(nspinsbetween)
    
;   Determine if and when FAST is in shadow, and fit the spin period
;    (sun) during this time to the infamous ad-hoc accidental
;    "blackbody" cooling model. It seems to be true that the spin
;    period raised to the 3/2 power is a linear function of time,
;    although blackbody radiation actually gives a different power,
;    which does not fit the spin rate data very well. So, I made a
;    serendipitous error in derivation here.
    
    fa_shadow,tphi,/no_store,struc=sun
    enter_shade = where(sun.state eq 0,nesh)
    enter_sun   = where(sun.state eq 1,nesu)
    if nesh gt 0 then begin
        two_thirds = 2.d/3.d
        t_enter_shade = sun.tchange(enter_shade)
        t_enter_sun = sun.tchange(enter_sun)
        some_exits = where(t_enter_sun gt t_enter_shade(0),nse)
        if nesh gt 1 then begin
            if nse gt 0 then begin
                t_exit_shade = t_enter_sun(some_exits)
            endif
            if nse ne nesh then begin
                if defined(t_exit_shade) then begin
                    t_exit_shade = [t_exit_shade,max(sun.time)]
                endif else begin
                    t_exit_shade = max(sun.time)
                endelse
            endif
        endif else begin
            if (n_elements(sun.tchange)-1) gt enter_shade(0) then begin
                t_exit_shade = t_enter_sun(some_exits)
            endif else begin
                t_exit_shade = max(sun.time)
            endelse
        endelse
        
        ncsh = 3L
        csh = dblarr(ncsh,nesh)
        for i=0,nesh-1l do begin
            pick = select_range(tphi,t_enter_shade(i),t_exit_shade(i),npick)
            if npick gt 0 then begin
                tspan = max(tphi(pick))-min(tphi(pick))
                tfit = (tphi(pick)-tphi(pick(0)))/tspan
                tm32 = (spin_per(pick))^(-1.5)
                tm32fit = tm32
                csh(*,i) = svdfit2(tfit,tm32,ncsh,yfit=tm32fit)
                spfit = tm32fit^(-two_thirds)
                spin_per(pick) = spfit
            endif
            if defined(shade) then begin
                shade = [shade,pick]
            endif else begin
                shade = pick
            endelse
        endfor
    endif 
    
;   Using the newly computed semi-smooth spin period, integrate to get
;   a well-shaped (often!) version of the sun phase.
;
;   careful about NaN's....
    
    sp_nan = where(finite(spin_per eq 0), nsn)
    if nsn gt 0 then begin
        sp_ok = where(finite(spin_per eq 1))
        spin_per(sp_nan) = ff_interp(att.time(sp_nan),  $
                                     att.time(sp_ok),  $
                                     spin_per(sp_ok), delt=100.d)
    endif
    
    ws = twopi/spin_per
    phi = int_up_to(tphi,ws,/adams)
    nphi = n_elements(phi)
    
;   Finally get the jittery phase data promised above...
    
    nspins = fix(phi/twopi)
    phi_wrapped = (tphi-t0-suntimes)*ws
    phi_jitter = phi_wrapped + nspins*twopi
    
    phi_jitter = phi_jitter - double(long(phi_jitter(0)/twopi)+1l)*twopi
    ddiff = unwrap(phi - phi_jitter)
    ind = dindgen(nphi)/double(nphi)
    
;   Find where we are to close to the limb...
    
    too_near = .03              ; about 200 km of atmosphere...
    for i=1,n_elements(sun.tchange)-1 do begin
        limbdiff = sun.limb_distance + 1.0d 
        close = where((limbdiff lt 0.d) and  $
                      (limbdiff gt -too_near),nclose)
        if not defined(limb) then begin
            if nclose gt 0 then limb = close
        endif else begin
            if nclose gt 0 then limb = [limb,close]
        endelse
    endfor
    
;   now fit Legendre polynomials to the difference between integrated
;   spin period and jittery phase. Former has correct shape
;   (precision) latter has no drift (accuracy). I mucked around a lot
;   with unweighting the limb...never made much difference. 
    
    sunweight = 1./(dblarr(nphi) + .1)
    if defined(limb) then begin
        sunweight(limb) = 0.01*sunweight(limb)
    endif
    
    phiscale = 2.0d*(phi-phi(0))/(max(phi)-min(phi))-1.0d
    ddiffc = svdout(phiscale,ddiff,10,yfit=drift,funct='legendre', $
                weight=sunweight, show=test)
    
;   Remove the fitted drift....

    phi = phi - drift
    
    
;   Show some diagnostic plots for those not already asleep...
    
    if keyword_set(test) then begin
        store_data,'ddiff',data={x:tphi,y:median(ddiff,13)}, $
          dlimit={ynozero:1,color:!d.n_colors*.9}
        store_data,'drift',data={x:tphi,y:drift}
        store_data,'ws',data={x:tphi,y:ws}, dlimit={ynozero:1}
        wsname = 'ws'
        if defined(shade) then begin
            store_data,'ws_shade',data={x:tphi(shade),y:ws(shade)}, $
              dlimit={ynozero:1,psym:1,color:!d.n_colors*.6}
            wsname = 'wscomb'
            store_data,wsname,data=['ws','ws_shade']
        endif
        
        store_data,'compare',data=['ddiff','drift']
        get_fa_orbit,min(tphi),max(tphi),/all
        fa_shadow,/no_call,struc=sun
        store_data,'limb',data={x:sun.time,y:sun.limb_distance}
        timespan,min(tphi),max(tphi)-min(tphi),/second

        tplot,['sunlit?','limb','compare',wsname]
        
        print,'ddiffc = ',ddiffc
    endif

; Modeling of difference between sun and mag phases. In GSE coords,
; the sun line is very simple, and the expected difference between sun
; and mag phase can be contructed from a combination (unfortunately
; nonlinear) of the model field components. The undetermined
; coefficients are a refinement of the spin axis, although I don't use
; the refinement anywhere. I just check to make sure it's
; small...usually it's been a fraction of a degree.
    
    ang_offset = 82.16/!radeg   ; radians between sun and mag
    ang_offset2 = 16.19/!radeg  ; radians between mag and s/c X
    
    magtimes = att.comp6
    oopsie_dayz = where(magtimes gt (tphi-t0),n_oops)
    if n_oops gt 0 then begin
        magtimes(oopsie_dayz) = magtimes(oopsie_dayz) + 86400.d
    endif

    delta_mag = magtimes(1:*) - magtimes(0:*)
    delta_mag = [delta_mag(0),delta_mag]
    mnspinsbetween = fix(delta_mag/objper + 0.5d)
    mag_spin_per = delta_mag / double(mnspinsbetween)
    wm = twopi / mag_spin_per
    magphi = int_up_to(tphi,wm)
    
    nmspins = fix(magphi/twopi)
    mag_phi_wrapped = (tphi-t0-magtimes)*wm
    magphi = mag_phi_wrapped + nmspins*twopi

    pdiff = unwrap(magphi - phi - ang_offset)
    
;   PDIFF is the measured difference between sun and mag phase. 
    
;   Now get the FDF spin axis and use it to start CURVEFIT. The
;   function SUN_MAG_DIFF, which is called by CURVEFIT, actually takes
;   *angles* for inputs. Two angles define the spin axis orientation,
;   while a third allows some slop in the mounting of the sun sensor:
;   initally set to ANG_OFFSET. 
    
    atime = tphi(0)
    fdf = get_fa_fdf_att(atime)
    store_data,'ffp_spin axis GEI', $
      data={x:[atime],y:[[fdf.x],[fdf.y],[fdf.z]]}
    coord_trans,'ffp_spin axis GEI','ffp_spin axis GSE','GEIGSE'
    get_data,'ffp_spin axis GSE',data=sgse
    
    tdiff = tphi
    
    sigma_phi = 1.d-01
    weights = 1.0/(dblarr(n_elements(tdiff))+sigma_phi^2)
    sax = [sgse.y(0),sgse.y(1),sgse.y(2)]
    ang=dblarr(3)
    ang(0) = acos(sax(2))
    ang(1) = atan(sax(1),sax(0))
    ang(2) = 0.0                ; maybe the sun sensor is mounted straight! 
    
    ang0 = ang
    phase_diff = curvout(tdiff,pdiff,weights, $
                          ang,sigma, $
                          funct='sun_mag_diff',/noderiv, $
                          show=test, used=used, max_toss=0.75)
    

    spin_axis = [sin(ang(0))*cos(ang(1)), $
                 sin(ang(0))*sin(ang(1)), $
                 cos(ang(0))]
    store_data,'ffp_sax_gse',data={x:tdiff(0),y:spin_axis}
    coord_trans,'ffp_sax_gse','ffp_sax_gei','GSEGEI'
    get_data,'ffp_sax_gei',data=ffpsax
    spin_axis = [ffpsax.y(0),ffpsax.y(1),ffpsax.y(2)]
    
    if keyword_set(test) then begin
        print,transpose(sgse.y)
        print,[sin(ang(0))*cos(ang(1)),sin(ang(0))*sin(ang(1)),cos(ang(0))]
        print,'sigma of angles:  ',sigma*!radeg
        print,'change in angles: ',(ang-ang0)*!radeg
        print,total(sax^2)
        plot,tdiff-tdiff(0),phase_diff - pdiff
        oplot,(tdiff-tdiff(0))(used),(phase_diff-pdiff)(used),psym=1
        stop
    endif

    
    if total(abs(ang-ang0)) gt 0.2 then begin
        message,'Spin axis adjustment too large!!',/continue
        print,'ang0 = ',ang0 * !radeg,'degrees'
        print,'ang = ',ang *!radeg,'degrees'
    endif
    
;
; done with pdiff modeling
;    
    phase_out.comp1 = ff_interp(phase_out.time, tphi, $
                           phi + phase_diff - ang_offset, $
                           delt=1000., /spline) - ang_offset2
    
    phase_out.comp2 = ff_interp(phase_out.time,tphi, $
                           phi-ang_offset, $
                           delt=1000.,/spline) - ang_offset2
    
    
    to_be_deleted = ['ffp_spin axis GSE','ffp_spin axis GEI', $
                     'ffp_sax_gse','ffp_sax_gei']
    for i=0,n_elements(to_be_deleted)-1 do begin
        store_data,to_be_deleted(i),/delete
    endfor
    
    phase_out.precise = 1
endif

; Whew!

return, phase_out

END
