;	@(#)get_fa_spin_rate.pro	1.17	
;+
; NAME: GET_FA_SPIN_RATE
;
; PURPOSE: Computes the spin rate and phase (sun).
;
; CATEGORY: attitude, despinning
;
; CALLING SEQUENCE: wspin = get_fa_spin_rate(tmag,mag)
;                    by default, a single number estimate of the spin
;                    rate is returned. It's not very precise, but
;                    may be ok for some things.  
; 
; INPUTS: TMAG : the time column for the magnetometer data being used
;         to estimate spin rate. Must be in seconds since 1970 if
;         /PRECISE is set, for compatibility with FAST spin/mag phase
;         quantities.
;
;         MAG: the mag data. I generally use Mag3dc. If you don't pass
;              in any mag data, the program attempts to load it from
;              SDT. 
;	
; KEYWORD PARAMETERS: PRECISE: if set, then the spin phase quantity
;                     (dqd is SMPhase_FieldsSurvey0) is extracted and
;                     used in conjunction with the MAG data to
;                     determine spin rate. An array of spin rates
;                     (w.r.t. the sun line) is returned. 
;
;                     ONE_ONLY: same as default. Inhibits PRECISE. 
;
;                     PHASE: a named variable in which the spin phase
;                            is returned. By default, w.r.t. sun
;                            line. 
;
; OUTPUTS: wspin : the spin rate, either crude or precise w.r.t. the sun.
;
; OPTIONAL OUTPUTS: PHASE: w.r.t. sun, through keyword. 
;
; SIDE EFFECTS: if PRECISE  is set, spin phase quantities are
;               extracted from SDT.
;
; RESTRICTIONS: Need SDT running, with spin phase and mag data loaded,
;               if PRECISE is set or mag data is not passed in.
;
;
; MODIFICATION HISTORY: written in October of 1996 by Bill Peria, UCB/SSL
;
;-

function get_fa_spin_rate,tc,xc,precise = precise,one_only = one_only $
                          ,phase=phase
twopi = 2.0d*!dpi
sp_units = twopi/1024.d
mp_units = twopi/4096.d
spin_per_nominal = 5.03 ; seconds

maxdt = 35.0

ntc = n_elements(tc)
if ntc lt 10 then begin
    m3_valid = 0
    if ntc eq 0 then begin
        m3 = get_fa_fields('Mag3dc_S',/all,/cal)
        m3_valid = m3.valid
    endif
    if not m3_valid then return,!values.d_nan
    tc = m3.time
    xc = m3.comp1
endif

if not keyword_set(precise) or  $
  keyword_set(one_only) then begin
    two_spins = where((tc-tc(0)) lt 10.d,nts)
    if nts lt 5 then begin
        message,'not enough mag data to compute spin rate...',/continue
        return,!values.f_nan
    endif
    t = tc(two_spins)
    x = xc(two_spins)
    x = smooth(x,3)-median(x)
endif else begin
    t = tc
    x = smooth(xc,3)-median(xc)
endelse

dx = deriv(t,x)
ddx = deriv(t,dx)

ax = abs(x)
nz = where(ax gt median(ax)/100.)

;w0 = sqrt(-median(ddx(nz)/x(nz)))
;if (w0 ne w0) then 
w0 = twopi/spin_per_nominal

if not keyword_set(precise) or keyword_set(one_only) and $
   ((w0 ne 0.0) and (w0 eq w0)) then begin
    return,w0
endif else begin
    if keyword_set(one_only) or not keyword_set(precise) then begin
        return,twopi/spin_per_nominal
    endif
    
    ps = get_fa_fields('SMPhase_FieldsSurvey0',/all)
    if ps.valid then begin
        smallmax = min([max(tc),max(ps.time)])
        bigmin = max([min(tc),min(ps.time)])
        good = where((ps.time ge min(t)) and (ps.time le max(t)),ngood)
        if ((smallmax ge bigmin) and (ngood gt 0)) then begin
            tphi = ps.time(good)
            phi = ps.comp1(good) * sp_units
        endif else begin
            message,'Can''t do precise stuff, no overlap between spin ' + $
              'phase and mag',/continue
            return,-1
        endelse
    endif else begin
        message,'Couldn''t get spin phase from SDT...',/continue
        return,-1
    endelse
;
;   first check dt's and reject bad ones. 
;
    nphi = n_elements(phi)
    dt = fltarr(nphi)
    dt(1:nphi-1l) = tphi(1:nphi-1l)-tphi(0:nphi-2l)
    dt(0) = dt(1)
    good = where(dt lt maxdt,ngood)
    nphi = ngood
    
    if (ngood gt 0) then begin
        tphi = tphi(good)
        phi = phi(good)
        ord = sort(tphi)
        tphi = tphi(ord)
        phi=phi(ord)
    endif else begin
        message,'HELP! All the dt''s are too big!!'
    endelse
    
    dphi = fltarr(nphi)
    dt = fltarr(nphi)
    
    dphi(1:nphi-1l) = phi(1:nphi-1l)-phi(0:nphi-2l)
    dphi(0) = dphi(1)
    dt(1:nphi-1l) = tphi(1:nphi-1l)-tphi(0:nphi-2l)
    dt(0) = dt(1)
    
    neg = where(dphi lt 0,nneg)
    if nneg gt 0 then begin
        dphi(neg) = dphi(neg) +twopi
    endif
    
    nr = double(fix(w0*dt/twopi))
    wspin = (dphi+twopi*nr)/dt
    
    dphi_true = dphi+twopi*nr
    dumdelt = findgen(nphi)
    phi_true = int_up_to(dumdelt,dphi_true) + phi(0)
    phi_diff = (phi_true mod twopi) - phi
    wrapped = where(abs(phi_diff) gt !pi,nw)
    if nw gt 0 then begin
        pos = where(phi_diff(wrapped) gt 0,npos)
        neg = where(phi_diff(wrapped) lt 0,nneg)
        if npos gt 0 then phi_diff(wrapped(pos)) = $
          phi_diff(wrapped(pos)) + twopi
        if nneg gt 0 then phi_diff(wrapped(neg)) = $
          phi_diff(wrapped(neg)) - twopi
    endif 
        
    phi_true = phi_true - fa_mean(phi_diff)
    
    phase = $
      poly_eval(t-tphi(0),poly_fit(tphi-tphi(0),phi_true,3)) + phi_true(0)
    
    w = deriv(t,phase)
endelse

if keyword_set(precise) then return,w
return,median(w)

end


