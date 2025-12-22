;+
; NAME: FA_SHADOW
;
; PURPOSE: To compute when FAST is in shadow or sunlight.
;
; CALLING SEQUENCE: fa_shadow,t1,t2,USE=use NO_STORE=no_store, 
;                   DELTA_T = delta_t, STRUC = struc
; 
; OPTIONAL INPUTS: T1: start time in seconds since 1970, or as a
;                  string. If T1 is an array, then those times are
;                  used and T2 is ignored. 
;
;                  T2: end time 
;
;                  DELTA_T: time between points, ignored if T1 is an
;                           array, default is 20 seconds. 
;       
; KEYWORD PARAMETERS: USE: a TPLOT string handle pointing to a quantity
;                       from which to grab the timespan.
;
;                     NO_STORE: inhibits tplot storing.
;
;                     STRUC: a named variable in which the shadow info
;                            is returned.
;
;                     NO_CALL: inhibits the call to GET_FA_ORBIT. The
;                              quantity 'fa_pos' must already have
;                              been stored by a previous *appropriate*
;                              call to GET_FA_ORBIT.
;
;                     FOOTPOINT: if set, determines the sunlit
;                                condition of the footpoint of the
;                                field line threading FAST, instead of
;                                at the position of FAST.
; 
;
;   If none of these are defined, FA_SHADOW will use the currently
;   occurring orbit, and will do a tplot store. 
;
; OUTPUTS: A TPLOT quantity called 'sunlit?' is stored, which has
;          values of 0 or 1, labeled 'yes' and 'no' when plotted, and
;          the STRUC keyword contains the same information. 
;
; SIDE EFFECTS: If T1 or T2 is defined, then GET_FA_ORBIT is called
;               and previously stored orbit data will be over-written. 
;
; EXAMPLE: fa_shadow,use='ORBIT'
;           This will compute sun/shadow at those times when ORBIT is
;           currently stored. 
;
; MODIFICATION HISTORY: 23-April-1997 Bill Peria UCB/SSL
;
;-
;       @(#)fa_shadow.pro	1.23     04/16/03

pro fa_shadow, t1, t2, USE=use, NO_STORE=no_store, DELTA_T = delta_t, $
               STRUC = struc, NO_CALL = no_call, FOOTPOINT = footpoint

gfa_re = 6378.14                ; *the* radius of the earth according
                                ; to get_fa_orbit. 


limb_cross = 1.02d              ; effective size of shadow in units of
                                ; WGS '84 geoid radii. Found
                                ; empirically by looking for abrupt
                                ; change in change in spin rate. 

if idl_type(t1) eq 'string' then t1 = str_to_time(t1)
if idl_type(t2) eq 'string' then t2 = str_to_time(t2)

if not keyword_set(delta_t) then delta_t = 60.d

foot = keyword_set(footpoint)

if not keyword_set(no_call) then begin
    if defined(t1) then begin   ; need to call get_fa_orbit
        if n_elements(t1) gt 1 then time_array = t1
        if defined(time_array) then begin
            get_fa_orbit,time_array,/time_array,/no_store,struc=orb,all=foot
        endif else begin
            get_fa_orbit,t1,t2,delta_t=delta_t,/no_store,struc=orb,all=foot
        endelse
    endif else begin            ; use stored quantity or current orbit
        if defined(use) then begin
            get_data,use,data=duse,index=index
            if index gt 0 then begin
                get_fa_orbit,min(duse.x),max(duse.x), $
                  delta_t=delta_t,/no_store,struc=orb,all=foot
            endif else begin
                message,'Cannot find TPLOT quantitity: ' + $
                  ''+strcompress(string(use),/remove),/contiue
                return
            endelse
        endif else begin        ; current orbit
            if not get_fa_orbit_times(what_orbit_is(systime(1)),t1,t2) then $
              begin
                message,'Can''t get orbit times for current ' + $
                  'orbit...',/continue
                return
            endif
            get_fa_orbit,t1,t2,delta_t=delta_t,/no_store,struc=orb,all=foot
        endelse
    endelse
    if not keyword_set(footpoint) then begin
        store_data,'fs_fa_pos',data={x:orb.time,y:orb.fa_pos}
        coord_trans,'fs_fa_pos','fs_fa_pos_gse','GEIGSE'
        coord_trans,'fs_fa_pos','fs_fa_pos_geo','GEIGEO'
    endif else begin
        message,'footpoint!',/continue
        
; need GSE and GEO position of the footpoint. At this point, all we know is
; it's geocentric alt and geodetic latitude. Ugh. Use the
; approximation that geocentric and geodetic alt are the same. for
; this calculation, it will hopefully not be too critical. 
        gd_alt = replicate(100., n_elements(orb.alt))
        gd_lat = orb.flat
        geoc2geod, /inverse, gd_lat, gd_alt, gc_lat, gc_alt
        rf = gfa_re + gc_alt
        xf = rf * cos(orb.flng/!radeg) * cos(gc_lat/!radeg)
        yf = rf * sin(orb.flng/!radeg) * cos(gc_lat/!radeg)
        zf = rf * sin(gc_lat/!radeg)
        store_data,'fs_fa_pos_geo',data={x:orb.time,y:[[xf],[yf],[zf]]}
        coord_trans,'fs_fa_pos_geo','fs_fa_pos_gse','GEOGSE'
    endelse
endif else begin
    if find_handle('fa_pos') eq 0 then begin
        message,'Position information is not yet stored!',/continue
        return
    endif
    if not keyword_set(footpoint) then begin
        get_data,'fa_pos',data=oldfp
        store_data,'fs_fa_pos',data=oldfp
        coord_trans,'fs_fa_pos','fs_fa_pos_gse','GEIGSE'
        coord_trans,'fs_fa_pos','fs_fa_pos_geo','GEIGEO'
    endif else begin
        message,'footpoint!',/continue
        
        if not defined(orb) then begin 
            get_data,'fa_pos',data=oldfp
            get_fa_orbit,oldfp.x,/time,/no_store,struc=orb,/all
        endif
        
        gd_alt = replicate(100., n_elements(orb.alt))
        gd_lat = orb.flat
        geoc2geod, /inverse, gd_lat, gd_alt, gc_lat, gc_alt
        rf = gfa_re + gc_alt
        xf = rf * cos(orb.flng/!radeg) * cos(gc_lat/!radeg)
        yf = rf * sin(orb.flng/!radeg) * cos(gc_lat/!radeg)
        zf = rf * sin(gc_lat/!radeg)
        store_data,'fs_fa_pos_geo',data={x:orb.time,y:[[xf],[yf],[zf]]}
        coord_trans,'fs_fa_pos_geo','fs_fa_pos_gse','GEOGSE'
    endelse
endelse

get_data,'fs_fa_pos_geo',data=fpgeo
gclat = atan(fpgeo.y(*,2),sqrt(total(fpgeo.y(*,0:1)^2,2)))
biga = 6378.137                 ; km  WGS '84
bigb = 6356.752			; km
r_ell = biga*bigb/sqrt((bigb*cos(gclat))^2 + (biga^2*sin(gclat)^2))

get_data,'fs_fa_pos_gse',data=fpg
rho = sqrt(total(fpg.y(*,1:2)^2,2))/r_ell ; using ellipsoidal axis...

sun = where((rho ge limb_cross) or (fpg.y(*,0) gt 0.),nsun)
shade = where((rho lt limb_cross) and (fpg.y(*,0) lt 0.),nshade)

limb_distance = rho * double(-1 + 2*(fpg.y(*,0) gt 0.))

out = bytarr(n_elements(rho))

if (nsun gt 0) then out(sun) = 1b


time = fpg.x
nout = n_elements(out)
tchange = time(0)
state = out(0)
states = out(0)
last_change = 0L
changes = 0L
repeat begin
    next_change = (where(out(last_change:nout-1l) ne $
                         state,nchange))(0)+last_change 
    if nchange gt 0 then begin
        tchange = [tchange,time(next_change)]
        states = [states,out(next_change)]
        state = 1b - state
        last_change = next_change
        changes = [changes,next_change]
    endif
endrep until(nchange eq 0)

ntime = n_elements(time)
nchanges = n_elements(changes)

if nchanges gt 1 then begin
    tchange_refined = tchange
    width = 2L
    direc = fltarr(nchanges)
    for i=1,nchanges-1 do begin
        first = (changes(i)-width) > 0L
        last = (changes(i)+width) < (ntime-1L)
        direc(i) = float(out(last)) - float(out(first))
        tchange_refined(i) =  $
          ff_interp([limb_cross],rho(first:last),fpg.x(first:last), $
                    delt=2.d*delta_t)
    endfor

    ok = where(finite(tchange_refined),nok)
    if nok gt 0 then tchange(ok) = tchange_refined(ok)

    out = [out,out(changes(0:nchanges-2L)),out(changes(1:nchanges-1L))]
    time = [time,tchange(1:nchanges-1L)-1.d-06,tchange(1:nchanges-1L)+1d-06]
    limb_distance = [limb_distance,-limb_cross,-limb_cross]
    ord = sort(time)
    time = time(ord)
    limb_distance = limb_distance(ord)
    out = out(ord)
endif

struc = {time:time,sun:out,tchange:tchange,state:states, $
         limb_distance:limb_distance}

if not keyword_set(no_store) then begin
    store_data,'sunlit?',data={x:time,y:out}, $
      dlim={yrange:[-1,2],ystyle:1,yticks:3,ytickname:[' ','no','yes',' '], $
            ytickvalue:[-1,0,1,2],yticklen:-.0001}
endif

to_be_deleted = ['fs_fa_pos','fs_fa_pos_gse','fs_fa_pos_geo']
ntbd = n_elements(to_be_deleted)
for i=0,ntbd-1 do begin
    store_data,to_be_deleted(i),/delete
endfor

return
end


