pro despike_density,dens,mode
nom_spin_per = 5.06             ; seconds

half = 0.55                     ; 10% overlap
min_fit_pts = 10
nsvd = 2                        ; lines
nan = replicate(!values.f_nan,nsvd)
twopi = 2.d*!dpi

; The following notch info is correct for Ne6 with no phase shift...

notch_starts = [0.,  2.9, 6.1  ]
notch_stops =  [1.9, 5.1, twopi]
phase_shift = fltarr(dens.npts)


nmodes = mode.npts
for i=0,nmodes-1 do begin
    if i lt nmodes-1 then begin
        mode_range = select_range(dens.time, mode.time(i), $
                                  mode.time(i+1),nmr)
    endif else begin
        mode_range = select_range(dens.time, mode.time(i), $
                                  dens.end_time,nmr)
    endelse
    if nmr gt 0 then begin
        case mode.dqds(i) of
            'NE6_S': phase_shift(mode_range) = 0.
            'NE2_S': phase_shift(mode_range) = 90.
            'NE9_S': phase_shift(mode_range) = 0.
            'NONE':  phase_shift(mode_range) = 0.
            else: begin
                phase_shift = 0.
                message,'Unrecognized density DQD: ' + $
                  ''+dens.data_name+'...',/continue
            end
        endcase
    endif
endfor

if find_handle('spin_times') ne 0 then begin
    get_data,'spin_times',data=st
    if ((min(st.x) le dens.start_time + nom_spin_per) and  $
        (max(st.x) ge dens.start_time - nom_spin_per)) then begin
        ts = st.x
        nspins = n_elements(ts)
    endif
endif

if not defined(nspins) then begin
    nspins = long((dens.end_time-dens.start_time)/nom_spin_per) 
    ts = dens.start_time + nom_spin_per*(dindgen(nspins)+0.5d)
endif
in_range = select_range(ts,dens.start_time,dens.end_time,nspins)
ts = ts(in_range)

start_times = ts - nom_spin_per*half
stop_times  = ts + nom_spin_per*half

start_indices = interp(lindgen(dens.npts),dens.time,start_times)
stop_indices =  interp(lindgen(dens.npts),dens.time,stop_times)
start_indices = long(start_indices+0.5d)
stop_indices = long(stop_indices+0.5d)

ok = where((start_indices ge 0) and  $
           (start_indices lt dens.npts) and $
           (stop_indices ge 0) and  $
           (stop_indices lt dens.npts),nok)

start_indices = start_indices(ok)
stop_indices = stop_indices(ok)
n_indices = stop_indices - start_indices

cdens = make_array(type=data_type(dens.comp1),nsvd,nspins)
cdens(*) = !values.f_nan
phase = fa_fields_phase()

phi = ff_interp(dens.time,phase.time,phase.comp1)

weights = fltarr(dens.npts)+1.
twonpi = (phi + phase_shift) mod twopi

for j=0,n_elements(notch_starts)-1 do begin
    wp = select_range(twonpi,notch_starts(j),notch_stops(j),nwp)
    if nwp gt 0 then weights(wp) = 0.
endfor

for i=0,nok-1l do begin
    if n_indices(i) gt min_fit_pts then begin
        dp = start_indices(i) + lindgen(n_indices(i))
        weight = weights(dp)
        tfit = dens.time(dp)-ts(i)
        dfit = dens.comp1(dp)
        yfit = fltarr(n_indices(i))

        cdens(*,i) = $
          svdout(tfit,dfit,nsvd,yfit=yfit,weight=weight,used=used)
    endif else begin
        cdens(*,i) = nan
    endelse
endfor


tags = strlowcase(tag_names(dens))
ntags = n_elements(tags)
dspot = (where(tags eq 'comp1'))(0)
tspot = (where(tags eq 'time'))(0)

dens.npts = nspins
dens.start_time = ts(0)
dens.end_time = ts(nspins-1l)

skip_tags = ['streak_starts','streak_lengths','notch','time','comp1', $
             'streak_ends','repaired']

newdens = create_struct(tags(0),dens.(0))
for i=1,ntags-1 do begin
    if (where(tags(i) eq skip_tags))(0) lt 0 then begin
        newdens = create_struct(newdens,tags(i),dens.(i))
    endif
endfor
newdens = create_struct(newdens,['time','comp1'],ts,reform(cdens(0,*)))

dens = temporary(newdens)
return
end

;+
; NAME: GET_DENSITY
;
; PURPOSE: To bring the appropriate density data into IDL from SDT
;
; CALLING SEQUENCE: density = get_density(time1,time2)
; 
; INPUTS: See documentation for GET_FA_FIELDS
;
; OUTPUTS: Either a structure or a TPLOT string handle, containing the
;          density data. 
;
; KEYWORDS: Same as GET_FA_FIELDS. 
;
; MODIFICATION HISTORY: Written January 1997 by Bill Peria UCB/SSL
;                     - added SVD based de-spiker, used when /SPIN is
;                     set, provides spin period resolution
;                     data. 25-Mar-97 BP
; 
;
;-
;	@(#)get_density.pro	1.15	
function get_density, time1, time2, NPTS=npts, START=st, EN=en,      $
                      PANF=pf, PANB=pb, ALL = all, CALIBRATE = $
                      calibrate, STORE = store, STRUCTURE = struct, $
                      SPIN = spin, REPAIR = repair

crap = {data_name:'DENSITY',valid:0L}
catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    struct = crap
    if keyword_set(store) then begin
        catch,/cancel
        return,''
    endif else begin
        catch,/cancel
        return,crap
    endelse
endif
catch,/cancel

if defined(time1) then tm1 = time1
if defined(time2) then tm2 = time2
if defined(npts) then nmpts =  npts

mode = get_fields_mode(tm1, tm2, NPTS=nmpts, START=st, EN=en,      $
                       PANF=pf, PANB=pb, ALL = all)

if not mode.valid then begin
    message,'Unable to determine mode, will use NE6_S',/continue
    dqds = 'NE6_S'
    mode = create_struct(mode,'npts',1)
endif else begin
    dqd_choices = ['NE6_S','NE2_S','NE9_S','NONE']
    dqds = dqd_choices(byte(mode.comp1)/64b) ; two MSB's determine which
                                ; sphere to use. 
endelse

mode = create_struct(mode, 'dqds', dqds)


if mode.npts eq 1 then begin
    ret =  get_fa_fields(dqds(0), time1,time2, NPTS=npts, START=st, EN=en,$
                         PANF=pf, PANB=pb, ALL = all, CALIBRATE = $
                         calibrate)
endif else begin
    first_good_mode = min(where(byte(mode.comp1)/64b ne 3b,nfgm))
    if (first_good_mode lt 0) then return,crap
    
    if defined(time1) then begin
        t1 = time1
    endif else begin
        t1 = mode.time(first_good_mode)
    endelse
    
    if defined(time2) then begin
        t2 = time2
    endif else begin
        if first_good_mode lt mode.npts-1l then begin
            t2 = mode.time(first_good_mode+1l)
        endif else begin
            t2 = mode.end_time
        endelse
    endelse
    
    if t2 le mode.time(first_good_mode) then return,crap
    
            
    ret0 =  get_fa_fields(dqds(first_good_mode), t1,t2,  $
                          CALIBRATE = calibrate)
    
    ret =  create_struct('data_name',            'DENSITY',            $
                         'valid',                ret0.valid,           $
                         'project_name',         ret0.project_name,    $
                         'units_name',           ret0.units_name,      $
                         'calibrated',           ret0.calibrated,      $
                         'units_procedure',      'fa_fields_units',    $
                         'start_time',           ret0.start_time)
    
    npts = ret0.npts
    time = ret0.time
    streak_starts = ret0.streak_starts
    streak_lengths = ret0.streak_lengths
    streak_ends = ret0.streak_ends
    comp1 = ret0.comp1
    
    tmp = temporary(ret0)
    for i=first_good_mode+1l,mode.npts-1l do begin
        if (i eq (mode.npts-1l)) then begin
            t1 = mode.time(i)
            if defined(time2) then begin
                t2 = time2
            endif else begin
                jnk = get_fa_fields(dqds(i),/en,npts=2)
                if jnk.valid then t2 = jnk.end_time
            endelse
        endif else begin
            t1 = mode.time(i)
            t2 = mode.time(i+1l)
        endelse
        
        if dqds(i) ne 'NONE' then begin
            tmp = get_fa_fields(dqds(i), t1,t2, CALIBRATE = $
                                calibrate, /REPAIR)
            
            if tmp.valid then begin
                tmp.comp1[0] = !values.f_nan
                tmp.comp1[tmp.npts-1l] = !values.f_nan
                npts = npts + tmp.npts
                time = [time,tmp.time]
                streak_starts = [streak_starts,tmp.streak_starts]
                streak_ends = [streak_ends,tmp.streak_ends]
                streak_lengths = [streak_lengths,tmp.streak_lengths]
                comp1 = [comp1,tmp.comp1]
            endif            
        endif
    endfor
    
    ret = create_struct(ret, $
                        'end_time',		tmp.end_time, 	 $
                        'npts',			npts, 		 $
                        'ncomp',		1L, 		 $
                        'depth',		1L,		 $
                        'time',			time,		 $
                        'streak_starts',	streak_starts,	 $
                        'streak_lengths',	streak_lengths,	 $
                        'streak_ends',		streak_ends,	 $
                        'repaired',		tmp.repaired,	 $
                        'notch',		bytarr(npts)+1b, $
                        'comp1',		comp1,		 $
                        'header_bytes',		bytarr(1))
endelse


if keyword_set(spin) and ret.valid then despike_density,ret,mode

if keyword_set(store) then begin
    return_name = 'DENSITY'
    store_data,return_name,data = {x:ret.time,y:ret.comp1}, $
      dlimit={ytitle:return_name+'  ('+ret.units_name+')', $
              ylog:1}
    ret = return_name
endif


return,ret

end
