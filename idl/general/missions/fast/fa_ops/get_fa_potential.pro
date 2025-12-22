;+
; NAME: GET_FA_POTENTIAL
;
; PURPOSE:
;    To obtain the spacecraft potential for FAST in fa_fields
; format. Calls FF_POTENTIAL to do the bulk of the work. 
;
; CALLING SEQUENCE: pot = get_fa_potential(time1c, time2c, NPTS=npts,
;                         START=st, EN=en, PANF=pf, PANB=pb, ALL = all,
;                         STORE = store, STRUCTURE = struct, SPIN = spin,
;                         REPAIR = repair)  
; 
; INPUTS: T1, T2: start and stop times, in seconds since 1970 or
;         YYYY-MM-DD/HH:MM:SS. 
;       
; KEYWORD PARAMETERS: All applicable keywords from GET_FA_FIELDS.
;
; OUTPUTS: If /STORE is not set set, a standard fields structure
;          containing the potential in volts in COMP1 is returned. If
;          STORE is set, a tplot string handle is returned.
;
; RESTRICTIONS: The environment variable FAST_CALIBRATE must be 1.
;               Why not do the following:
;
;                  alias fastsdt   'setenv FAST_CALIBRATE 1; sdt' 
;
;                        in your .cshrc file? 
;
;
; EXAMPLE: pot = get_fa_potential(t1,t2)
;          pdqplot,pot
;          OR...
;          tplot,get_fa_potential(t1,t2,/store)
;
;
; MODIFICATION HISTORY: written April '97 by Bill Peria 
;
;-
;       @(#)get_fa_potential.pro	1.13 10/02/97     UCB SSL

function get_fa_potential,time1c, time2c, NPTS=npts, START=st, EN=en, $
                          PANF=pf, PANB=pb, ALL = all, STORE = store, $
                          STRUCTURE = struct, SPIN = spin, REPAIR = repair

offset = 3.60   ; calibrations for v58
gain = -2.7645

data_name = 's/c potential'

crap = {data_name:data_name,valid:0L}
catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    help
    help,/source
    struct = crap
    if keyword_set(store) then begin
        catch,/cancel
        return,''
    endif else begin
        catch,/cancel
        return,crap
    endelse
endif

;
; get RAW quantities!!
;

if defined(time1c) then time1 = time1c
if defined(time2c) then time2 = time2c

req_dqds = ['V5-V8_S','V8_S','V1-V4_S','V4_S']
if missing_dqds(req_dqds) ne 0 then begin
    message,'SDT setup is not complete...',/continue
    return,crap
endif

v58 = get_fa_fields('V5-V8_S',time1, time2, NPTS=npts, START=st, EN=en, $
                          PANF=pf, PANB=pb, ALL = all,/quiet, REPAIR = repair)
v8 = get_fa_fields('V8_S',time1, time2,/quiet, REPAIR = repair)
v14 = get_fa_fields('V1-V4_S',time1,time2,/quiet, REPAIR = repair)
v4 = get_fa_fields('V4_S',time1,time2,/quiet, REPAIR = repair)

if not (v58.valid and  $
        v8.valid and  $
        v14.valid and  $
        v4.valid) then begin
    message,'Error getting V5-V8, V8, V1-V4, or V4...can''t get ' + $
      'potential...',/continue
    return,crap
endif

pot = ff_potential(v58,v8,v14,v4,/save_mem) 


if defined(spin) then begin
    fa_fields_spin_ave,pot,/box,center=spin
endif

if keyword_set(store) then begin
    return_name = 's/c potential'
    store_data,return_name,data={x:pot.time,y:pot.comp1}, $
      dlim={xstyle:1,ytitle:'s/c potential !C!C' + $
            '('+strcompress(pot.units_name,/remove_all)+')'}
    ret = return_name
    struct = pot
endif else begin
    ret = temporary(pot)
endelse

return,ret
end
