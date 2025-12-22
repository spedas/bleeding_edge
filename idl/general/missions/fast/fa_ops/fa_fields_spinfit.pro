;+
; NAME: FA_FIELDS_SPINFIT
;
; PURPOSE: To perform fits to the data from FAST spin plane sensors. 
;
; CALLING SEQUENCE: status = fa_fields_spinfit(data,TIMES=ts,X=x,$
;                                     Y=y,MAG=mag, SUN = sun, STORE = store)
; 
; INPUTS: DATA - a structure of the type returned by GET_FA_FIELDS. 
;       
; KEYWORD PARAMETERS: TIMES - a named variable containing the center
;                     times of the spinfit intervals. 
;
;                     SLIDE - the time between fits, in fractions of a
;                     spin. The default is 1.0.
;
;                     INTERVAL - the length of time used for each fit,
;                     in units of the spin period. The default is 1.0. 
;
;                     X - a named variable in which the component of
;                     the spinfit field along the sensor axis, for a
;                     phase of zero, is returned. 
;
;                     Y - a named variable in which the component of
;                     the spinfit field perpendicular the sensor axis,
;                     for a phase of zero, is returned. The spin axis
;                     is equal to the cross product of the X and Y
;                     directions. 
; 
;                     MAG - set this to do the spinfit with respect to
;                     the background magnetic field. This is the default.
;
;                     SUN - set this to spinfit with respect to the
;                     Earth-Sun line. 
;
;                     STORE - set this to store the resulting spinfit
;                     fields for TPLOT. By default, this is set. 
;
;
; OUTPUTS: STATUS - If all goes well, 1 is returned, otherwise 0. 
;
; SIDE EFFECTS: If /STORE is set, or if neither X, Y or STORE is set,
;               a TPLOT store of the spinfit components is performed.
;
; RESTRICTIONS: If your data are poorly modeled by a sinusoid,
;               FA_FIELDS_SPINFIT will happily return nonsense. Severe
;               sun spiking in electric field data is one known
;               example of this. An algorithm to remove such spikes
;               (through the NOTCH tag in fields structures) is in the
;               works.
;
; EXAMPLE: if fa_fields_spinfit(v58data,/store,/mag) then begin
;              tplot,['V5-V8_S_mag',''V5-V8_S_mag_perp']
;          endif
;
;
;
; MODIFICATION HISTORY: Gathered together from summary plot routines,
;                       in celebration of the vernal equinox, 1997, by
;                       Bill Peria, UCB/SSL. 
;
;-
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
function fa_fields_spinfit,data, TIMES = ts, X = ex, Y = ey, MAG = $
                           mag, STORE = store, SLIDE = slide, INTERVAL $
                           = interval, NOTCH = notch, COEFFICENTS = $
                           ec, FUNCT = funct, SHOW = show

status = 0

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    print,'Error number is '+strcompress(string(err_stat),/remove_all)
    return,status
endif
catch,/cancel

if idl_type(data) ne 'structure' then begin
    message,'Input structure is not a structure!',/continue
    return,status
endif

if not data.valid then begin
    message,'Input data structure is not valid!',/continue
    return,status
endif

if missing_tags(data,['comp*','data_name'],absent=absent) ne 0 then $
  begin
    message,'Cannot do spin fit without some data and a known data ' + $
      'name!',/continue
    return,status
endif

if ((not defined(ex)) and $
    (not defined(ey)) and $
    (not keyword_set(store))) then begin
    message,'will perform TPLOT store of spin fit to ' + $
      ''+data.data_name+' data.',/continue  
    store = 1
endif 

if not defined(funct) then funct = 'modsin' ; default modified sinusoid

notched = missing_tags(data,'notch',/quiet) eq 0

nsvd = 6
ang_offset = 127.98d/double(!radeg) ; angle between v58 and s/c X-axis.
;ang_offset = fa_fields_ang_offsets(data)

if strpos(data.data_name,'V5-V8') lt 0 then begin
    message,'currently assumes V5-V8 sensor direction...you must look ' + $
      'up the angle offset for other sensors...',/continue
endif

fnan = !values.f_nan
dnan = !values.d_nan

twopi = 2.d*!dpi
root_two = sqrt(2.d)

phis = fa_fields_phase()
tphi = phis.time
if keyword_set(sun) then begin
    phi = phis.comp2            ; sun phase, 2nPi when sun sensor sees sun
endif else begin
    phi = phis.comp1            ; mag phase, 2nPi when s/c X is along B
endelse

phi = phi - double(long(phi(0)/twopi))*twopi ; bring near to zero...

te = data.time
ephi = interp(phi,tphi,te)+ang_offset
n2npi = long((max(phi)-min(phi))/twopi)
twonpi = dindgen(n2npi)*twopi
spin_times = interp(tphi,phi,twonpi)

spin_per0 = fa_mean(spin_times[1:*] - spin_times[0:*])
w0 = twopi / spin_per0
half_width = .5 * spin_per0

;
; define ts for use as the center times for spinfits. By default,
; times when spin phase = 2nPi are used. 
;
; If SLIDE is set, then ts is interpolated from spin times, with a
; spacing of SLIDE, in units of a spin period. 
;
if (not(defined(times)) and $
    not(keyword_set(slide)) and $
    not(keyword_set(interval))) then begin
    ts = spin_times
endif

if defined(times) then ts = times

if not keyword_set(slide) then slide = 1.0
if not keyword_set(interval) then interval = 1.0
half_width = spin_per0*interval/2.0d

if not defined(ts) then begin
    nts = long(float(n_elements(spin_times))/slide)
    if nts eq 0 then begin
        message,'specified SLIDE is too large!',/continue
        return,status
    endif
    pick = float(n_elements(spin_times)-1L)*findgen(nts)/float(nts-1L)
    ts = interpolate(spin_times,pick)
endif

this_interval = where((ts ge (te(0)+(0.5*twopi*interval)/w0)) and  $
                      (ts le (max(te)-(0.5*twopi*interval)/w0)),nti)
if nti lt 2 then return,status

ts = ts(this_interval)
nts = n_elements(ts)

start_times = ts - half_width
stop_times  = ts + half_width

start_indices = $
  ff_interp(start_times,data.time,lindgen(data.npts),delt=10.)
stop_indices = $
  ff_interp(stop_times,data.time,lindgen(data.npts),delt=10.)
start_indices = long(start_indices+0.5d)
stop_indices = long(stop_indices+0.5d)

ok = where((start_indices ge 0) and  $
           (start_indices lt data.npts) and $
           (stop_indices ge 0) and  $
           (stop_indices lt data.npts),nok)

ts = ts(ok)
start_indices = start_indices(ok)
stop_indices = stop_indices(ok)
n_indices = stop_indices - start_indices

good = select_range(te,min(start_times),max(stop_times),ngood)
if ((ngood gt 0) and (nok gt 0)) then begin
    e = data.comp1(good)
    te = te(good)
endif else begin
    message,'No data during currently stored spin_times --> ' + $
      'unable to spinfit!',/continue
    return,status
endelse

ec = fltarr(nsvd,nts)

edev = fltarr(nts)
esig = 0.
for i=0,nok-1l do begin
    if (n_indices(i) gt 1) then begin
        ep = start_indices(i) + lindgen(n_indices(i))
        t1 = max(te(ep),min=t0)
        this_fit = fltarr(n_indices(i))
        weight = 1.+fltarr(n_indices(i))
        if keyword_set(notch) then begin
            notches = ff_notch(data.data_name, Bphase=phi)
            zonk = where(data.notch(ep) eq 0b,nzonk)
            if nzonk gt 0 then weight(zonk) = 0.
        endif
        
        if ((t1-t0) gt half_width) then begin
            ec(*,i) = $
              svdout(ephi(ep),e(ep),nsvd,funct=funct,chisq=esig, $
                     yfit = this_fit, weight=weight)
            
            if keyword_set(show) then begin
                plot,ephi(ep),e(ep)
                oplot,ephi(ep),this_fit,color=!d.n_colors*0.6
                wait,1
            endif
            
            
            junk = moment(e(ep),sdev = sdev)
            if (sdev lt sqrt(total(ec(0:1,i)^2,1))/2.0) then begin
                message,'spinfit components are too large: ' + $
                  time_to_str(ts(i)),/continue 
                ec(*,i) = fnan
            endif
        endif else begin
            ec(*,i) = fnan
        endelse
    endif else begin
        ec(*,i) = fnan
    endelse
endfor


not_nan = where((ec(0,*) eq ec(0,*)) and (ec(1,*) eq ec(1,*)),nnn)
is_nan  = where((ec(0,*) ne ec(0,*)) or  (ec(1,*) ne ec(1,*)),nin)

if nnn lt 3 then begin
    message,'No valid '+strcompress(data.data_name,/remove_all)+' ' + $
      'data...all NaN!',/continue
    return,status
endif
;
; compute magnitudes of spin-fitted fields
;
emag = fltarr(nts)
emag(not_nan) = reform(sqrt(ec(0,not_nan)^2 + ec(1,not_nan)^2))

edir = fltarr(nts)
edir(*) = fnan
edir(not_nan) = reform(atan(ec(1,not_nan),ec(0,not_nan)))
;
; define the spin plane fields by resolving the magnitudes into
; components using edir...
;
ex = fltarr(nts)
ey = fltarr(nts)
ex(*) = fnan
ey(*) = fnan
ex(not_nan) = float(emag(not_nan)*cos(edir(not_nan)))
ey(not_nan) = float(emag(not_nan)*sin(edir(not_nan)))

if keyword_set(store) then begin
    sys = 'mag'
    if keyword_set(sun) then sys = 'sun'
    
    xname = data.data_name+'_'+sys
    yname = data.data_name+'_'+sys+'_perp'
    
    store_data,xname,data={x:ts,y:ex}
    store_data,yname,data={x:ts,y:ey}
endif

status = 1
;
; HOORAY!!
;
return,status
end
