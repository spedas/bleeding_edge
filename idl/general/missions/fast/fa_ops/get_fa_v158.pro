;+
; NAME: GET_FA_V158
;
; PURPOSE: - To synthesize and return a structure containing the
;          component of the DC electric field perpendicular to the
;          V5-V8 boom direction.
;
; CALLING SEQUENCE: v158 = get_fa_v158,t1, t2, NPTS=npts, START=st, EN=en, $
;                     PANF=pf, PANB=pb, ALL = all, STORE = store,
;                     STRUCTURE = v158s, SPIN = spin, REPAIR = repair,
;                     DEFAULT = default
;
; INPUTS: T1, T2 - times (strings or double precision seconds since 1970)
;       
; KEYWORD PARAMETERS: Just like GET_FA_FIELDS! Ok, with a couple
;                     exceptions. There's no such thing as
;                     uncalibrated data, for example.
;
; OUTPUTS: V158 - a fields-type structure, containing V1-(V5+V8)/2 in
;          mV/m, UNLESS store is set, and then you get the TPLOT
;          string handle.
;
; SIDE EFFECTS: If STORE is set, a quantity called 'V1-(V5+V8)/2' is
;               stored for TPLOT. 
;
; RESTRICTIONS:  V4_S, V8_S, V1-V4_S, and V5-V8_S must all be loaded
;               in to SDT. 
;
; EXAMPLE: v158 = get_fa_v158('1997-08-26/01:00','1997-08-26/01:05')
;
; MODIFICATION HISTORY: - Finally written 27-August-1997
;                       by Bill Peria, UCB/SSL
;
;-


function get_fa_v158,t1, t2, NPTS=npts, START=st, EN=en,      $
                     PANF=pf, PANB=pb, ALL = all, STORE = store, $
                     STRUCTURE = v158s,SPIN = spin, REPAIR = repair, $
                     DEFAULT = default, CUTOFF = cutoff
;
; The magic numbers for building up v158! From a quiet stretch of
; orbit 4009.
;
c4 = 31.98
c8 = -32.00
c14 = 0.935
c58 = -0.853

req_dqds = ['V4_S','V8_S','V1-V4_S','V5-V8_S']
if missing_dqds(req_dqds,/quiet,absent=absent) ne 0 then begin
    message,'The following quantities are missing:',/continue
    for i=0,n_elements(absent)-1 do print,absent(i)
    print,' '
    print,'Go fix SDT setup, then type .continue ...'
    stop
endif

calibrate = 1                   ; uncalibrated won't work!
quiet = 1                       ; supress warnings...
if not defined(repair) then repair = 1

v58s = get_fa_fields('V5-V8_S',t1, t2, NPTS=npts, START=st, EN=en,      $
                     PANF=pf, PANB=pb, ALL = all,  $
                     CALIBRATE = calibrate, SPIN = spin,  $
                     REPAIR = repair, DEFAULT = default, QUIET = quiet)

v4s = get_fa_fields('V4_S',t1, t2, CALIBRATE = calibrate, SPIN = spin,  $
                    REPAIR = repair, QUIET = quiet)

v8s = get_fa_fields('V8_S',t1, t2, CALIBRATE = calibrate, SPIN = spin,  $
                    REPAIR = repair, QUIET = quiet)

v14s = get_fa_fields('V1-V4_S',t1, t2, CALIBRATE = calibrate, SPIN = spin,  $
                    REPAIR = repair, QUIET = quiet)

if not (v58s.valid and $
        v14s.valid and $
        v4s.valid and $
        v8s.valid) then begin
    message,'Unable to get required data...don''t know ' + $
      'why...',/continue 
    return,{data_name:'V1-(V5+V8)/2',valid:0}
endif 

time = v58s.time

ps = fa_fields_phase()
bphi = ff_interp(time,ps.time,ps.comp1)

v58 = ff_interp(time, v58s.time, v58s.comp1,/spline,delt=1.)
v4 = ff_interp(time, v4s.time, v4s.comp1,/spline,delt=1.)
v8 = ff_interp(time, v8s.time, v8s.comp1,/spline,delt=1.)
v14 = ff_interp(time, v14s.time, v14s.comp1,/spline,delt=1.)

v158 = c4*v4 + c8*v8 + c14*v14 + c58*v58

npts = n_elements(time)
v158s = {data_name:		'V1-(V5+V8)/2', $
         valid:			1L, $
         project_name:		'FAST', $
         units_name:		'mV/m', $
         calibrated:		1L, $
         units_procedure:	'fa_fields_units', $
         start_time:		time(0), $
         end_time:		max(time), $
         time:			time, $
         npts:			npts, $
         streak_starts:		v58s.streak_starts, $
         streak_lengths:	v58s.streak_lengths, $
         streak_ends:		v58s.streak_ends, $
         notch:			bytarr(npts), $
         comp1: 			v158, $
         header_bytes:		bytarr(1)}

slow_nyq = 4.0                  ; slowest survey nyquist of which I'm aware...
cutoff = slow_nyq

fa_fields_filter,v158s,[0,slow_nyq]

if keyword_set(store) then begin
    fa_fields_store,v158s
    return, v158s.data_name
endif else begin
    return,v158s
endelse

end
