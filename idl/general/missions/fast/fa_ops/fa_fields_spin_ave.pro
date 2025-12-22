;       @(#)fa_fields_spin_ave.pro	1.24     05/19/99
;+
; NAME: FA_FIELDS_SPIN_AVE
;
; PURPOSE: Performs spin averages on FAST fields structures
;
; CALLING SEQUENCE: fa_fields_spin_ave, data, BOX = box, SVD = svd,
;                   NOTCH = notch, CENTER = center,phase = phase,
;                   Sphase = sphase, MAG = mag, SUN = sun, SLIDE =
;                   slide, INTERVAL = interval, NAME = name
; 
; INPUTS: DATA - a FAST fields data structure, or an array (which must
;         then be sent along with a DQD, and a time or phase array. 
;       
; KEYWORD PARAMETERS: BOX -  DEFAULT. If non-zero, a boxcar average
;                     over BOX number of spins is performed. 
;
;                     SVD - OPTIONAL. if set, a spin-by-spin linear fit is
;                     performed and the spin-centered offsets are
;                     returned. 
;
;                     NOTCH - OPTIONAL. if set, ff_notch is called and
;                     the "bad" phases of the data are weighted zero.
;
;                     CENTER - OPTIONAL. the phase (mag or sun) in
;                     degrees at which the values in DATA are located
;                     after averaging. Has no effect if TIME is
;                     defined. Default is zero.
;
;                     PHASE -  an array of phases, defined any way the
;                     user wishes, except that they *must* be
;                     monotonically increasing, i.e. atan(by,bx) is no
;                     good for more than one spin. Also, the PHASE
;                     array must be of the same size as the data
;                     with which it will be paired. 
;
;                     FUNCT - if SVD is set, a string name of a model
;                     function for use by SVDFIT.
;
;                     MAG - DEFAULT if set, do average with respect to mag
;                     phase. 
;
;                     SUN - if set, do fit average with respect to sun
;                     phase. 
;
;                     STORE - if set, cause a TPLOT store of the
;                     spin-averaged data, and does not overwrite the
;                     input structure.
;
;                     INTERVAL - the period over which to perform each
;                     average, in units of one spin period. Default is
;                     1.0. 
;
;                     SLIDE - the time between succesive averages, in
;                     units of a spin period. Default is 1.0. 
;
;                     NAME - a string to use for the DATA_NAME in the
;                     returned structure or the TPLOT name of the
;                     stored quantity. 
;
;
; 
; OUTPUTS: DATA - the input structure is spin-averaged in place,
;          unless STORE is set.
;
; SIDE EFFECTS: the original data are averaged, and destroyed, unless
;               STORE is set.
;
; EXAMPLE: pot = get_fa_potential()
;          fa_fields_spin_ave,potential
;           
; MODIFICATION HISTORY: written 2-April-1997 by Bill Peria UCB/SSL
;
;-
pro fa_fields_spin_ave,data,BOX = box, SVD = svd, PHASE = phase, $
                       NOTCH = notch, CENTER = center, DQD = dqd, $
                       INTERVAL = interval, SLIDE = slide,  $
                       FUNCT = funct, MAG = mag, SUN = sun,  $
                       STORE = store, NAME = name

if idl_type(data) ne 'structure' then begin
    message,'Input structure is not a structure...',/continue
    return
endif

req_tags = ['data_name','comp*','valid','npts']
if missing_tags(data,req_tags,absent=absent,/quiet) ne 0 then begin
    message,'The following required tags are missing from the input ' + $
      'structure:',/continue
    print,absent
    return
endif

data_tags = strlowcase(tag_names(data))
ntags = n_elements(data_tags)
comps = where(strmid(data_tags,0,4) eq 'comp',nspots)

if not defined(interval) then interval = 1.0
if not defined(slide) then slide = 1.0
if not defined(spin) then spin = 0.0
if not defined(funct) then funct=''

interval = abs(interval)
slide = abs(slide)

box = not keyword_set(svd)
mag = not keyword_set(sun)

twopi = 2.d*!dpi
nom_spin_per = 5.06d            ; seconds
ws = twopi/nom_spin_per
half = 0.5d
gap_spins = 2000L               ; interpolation gap, in terms of spins 

if keyword_set(svd) then begin
    min_fit_pts = 10
endif else begin
    min_fit_pts = 2
endelse

if not keyword_set(svd) then begin
    nsvd = 1
endif else begin
    nsvd = 2
    if funct then begin
        basis = call_function(funct,data.time[0:1],nsvd)
        nsvd = n_elements(basis[0,*])
    endif
endelse

nan = replicate(!values.f_nan,nsvd)
;
; define spin phases, one way or another...
;
bogus = 0
if not defined(phase) then begin
    phase = fa_fields_phase()
    if not phase.valid then begin
        bogus = 1
    endif else begin
        overlap =  $
          (min(/nan,phase.time) le (min(/nan,data.time)+nom_spin_per)) and $
          (max(/nan,phase.time) ge (max(/nan,data.time)-nom_spin_per))
        if not overlap then begin
            message,'insufficient spin phase/data overlap...will use ' + $
              'bogus phase...',/continue
            bogus = 1
        endif else begin
            bphi = $
              ff_interp(data.time,phase.time,phase.comp1,delt=gap_spins*nom_spin_per)
            sphi = $ $
              ff_interp(data.time,phase.time,phase.comp2,delt=gap_spins*nom_spin_per)
            if mag then phi = bphi else phi = sphi
            tphi = data.time
        endelse
    endelse
endif else begin
    if idl_type(phase) eq 'structure' then begin
        message,'PHASE must be an array in this context',/continue
    endif
    if n_elements(phase) ne data.npts then begin
        message,'Number of elements in PHASE must match number in ' + $
          'DATA.'
        return
    endif
    phi = phase
    tphi = data.time
endelse

if bogus then begin 
    message,'cannot get phase, using bogus phase...',/continue
    phi = ws*(data.time-data.time[0])
    tphi = data.time
endif
;
; Make sure phi starts within 2Pi of zero...
;
nphi = n_elements(phi)
finphi = where(finite(phi))
phi = phi - double(long(phi[finphi[0]]/twopi))*twopi


;
; Phase is now defined. Now need to define boundary times for
; averages...first determine initial phase...
;
if not defined(center) then begin
    phib0 = phi[finphi[0]]
endif else begin
    center = center mod twopi
    phib0 = center - !dpi*interval
    while phib0 lt phi[finphi[0]] do phib0 = phib0 + twopi*slide
endelse
;
; now determine the number of SLIDE intervals that fit between PHIB0
; and the maximum phase, rounding *down*, requiring that the end
; intervals are complete.
;
phispan = max(/nan,phi) - (phib0 + twopi*interval)
if phispan lt 0 then begin
    message,'Your time span is too short...can''t spin average ' + $
      data.data_name+'...make INTERVAL shorter or get more data!',/continue
    return
endif

n_avg_int = long(phispan/(twopi*slide))

start_phases = phib0 + dindgen(n_avg_int)*slide*twopi
stop_phases  = start_phases + twopi*interval

;
; Interpolate start and stop indices using data_indices paired with
; phases...and also center times...
;
data_indices = lindgen(data.npts)
ok = where(finite(phi))
start_indices = $
  ff_interp(start_phases,phi[ok],data_indices[ok],delt=twopi*gap_spins) > 0.0
stop_indices  = ff_interp(stop_phases, $
                          phi[ok],data_indices[ok],delt=twopi*gap_spins) < float(nphi)
start_indices = long(start_indices) ; round down
stop_indices = long(stop_indices) ; round down

center_phases = (start_phases + stop_phases)/2.d
center_times = ff_interp(center_phases,phi[ok],tphi[ok],delt=twopi*gap_spins)
ncts = n_elements(center_times)

n_indices = stop_indices - start_indices

cdata = make_array(type=data_type(data.(comps[0])),nsvd,ncts)
cdata[*] = !values.f_nan

weights = fltarr(data.npts)+1.
if keyword_set(notch) then begin
    if bogus then begin
        message,'Notching with a bogus phase is probably not ' + $
          'a good idea...skipping the notcher...',/continue
        goto,skip_notch
    endif
    
    if idl_type(data) eq 'structure' then begin
        dqd = data.data_name
    endif else begin
        if not defined(dqd) then begin
            message,'You must define a DQD!',/continue
        endif
    endelse
    
    if defined(bphi) and defined(sphi) then begin
        notches = ff_notch(dqd, Bphase=bphi, Sphase=sphi)
    endif else begin
        if mag then begin
            notches = ff_notch(dqd, Bphase=phi)
        endif else begin
            notches = ff_notch(dqd, Sphase=phi)
        endelse
    endelse
    
    if notches[0] eq -1 then begin
        notches = bytarr(data.npts)+1
        message,'No notching will be performed',/continue
    endif
    
    zonk = where(notches eq 0,nzonk)
    if (nzonk gt 0) then weights(zonk) = 0.0
endif

skip_notch:dummy='skip to here if NOTCH and no phase info'

first = 1
for spot=0,nspots-1l do begin
    for i=0l,n_avg_int-1l do begin
        if n_indices[i] ge min_fit_pts then begin
            dp = start_indices[i] + lindgen(n_indices[i])
            dfit = data.(comps[spot])[dp]
            yfit = fltarr(n_indices[i])
            if keyword_set(svd) then begin
                dfit = data.(comps[spot])[dp]
                yfit = fltarr(n_indices[i])
                tfit = data.time[dp]-center_times[i]
                if keyword_set(funct) then begin
                    cdata[*,i] = $
                      svdout(tfit,dfit,nsvd,yfit=yfit,weight=weights[dp], $
                             funct=funct, used=used)
                endif else begin
                    cdata[*,i] = $
                      svdout(tfit,dfit,nsvd,yfit=yfit,weight=weights[dp], $
                             used=used)
                endelse
                
            endif else begin
                cdata[0,i] = fa_mean(weights[dp]*data.(comps[spot])[dp]) $
                  *float(n_indices[i])/total(weights[dp],/nan)
            endelse
        endif else begin
            cdata[*,i] = nan
        endelse
    endfor
    
    if first then begin
        first = 0
        skip_tags = ['streak_starts','streak_lengths','notch','time', $
                     'start_time','end_time','streak_ends',data_tags[comps]]

        newdata = create_struct(data_tags[0],data.(0))
        for i=1,ntags-1 do begin
            if (where(data_tags[i] eq skip_tags))[0] lt 0 then begin
                newdata = create_struct(newdata,data_tags[i],data.(i))
            endif
        endfor
        newdata = $
          create_struct(newdata,['time','start_time','end_time','comp1'], $
                        center_times,min(/nan,center_times),max(/nan,center_times), $
                        reform(cdata[0,*]))
    endif else begin
        newdata = create_struct(newdata,data_tags[comps[spot]],reform(cdata[0,*]))
    endelse
endfor

newdata.npts = ncts
newdata.start_time = center_times[0]
newdata.end_time = center_times[ncts-1l]

if not defined(name) then begin
    if keyword_set(svd) then begin
        newdata.data_name = data.data_name + '_svd'
    endif else begin
        newdata.data_name = data.data_name + '_ave'
    endelse
endif else begin
    newdata.data_name = name
endelse

if keyword_set(store) then begin
    fa_fields_store,newdata
endif else begin
    data = temporary(newdata)
endelse


return
end
