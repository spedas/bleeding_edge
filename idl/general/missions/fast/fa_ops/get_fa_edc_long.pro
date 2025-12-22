;+
; NAME: get_fa_edc_long
;
; DESCRIPTION: returns, as best it can, a structure containing DC
; electric field survey data from the FAST booms (1-4, 5-8, 9-10). It
; must be the case that SDT is running, with V1-4, 5-8, and 9-10
; plotted on screen already. In the case where, for example, sphere 9
; is in voltage mode, then an array containing IEEE NaN, plus a
; leading zero, will be returned in place of V9-10. 
;
;    The returned structure looks like this:
;
;
;  DATA_NAME           STRING    ' E1-4 E5-8 E9-10'  ; which 'E' quantities
;  VALID               INT       1                   ; Data valid flag
;  PROJECT_NAME        STRING    'FAST'              ; project name
;  UNITS_NAME          STRING    'mV/m'              ; Units of this data    
;  UNITS_PROCEDURE     STRING    'fa_fields_units'   ; Units conversion proc 
;  START_TIME          DOUBLE                        ; Start Time of sample  
;  END_TIME            DOUBLE                        ; End time of sample    
;  NPTS                INT                           ; Number of time samples
;  NCOMP               INT                           ; Number of components  
;  TIME                DOUBLE    Array(npts)         ; timetags              
;  E14                 DOUBLE    Array(npts)         ;
;  E58                 DOUBLE    Array(npts)         ; 
;  E910                DOUBLE    Array(npts)         ;
;      
; |ALL |NPTS |START| EN  |PANF |PANB |selection                  |use time1|use time2|
; |----|-----|-----|-----|-----|-----|---------------------------|---------|---------|
; | NZ |  0  |  0  |  0  |  0  |  0  | start -> end              |  X      |  X      |
; | 0  |  0  |  0  |  0  |  0  |  0  | time1 -> time2            |  X      |  X      |
; | 0  |  0  |  NZ |  0  |  0  |  0  | start -> time1 secs       |  X      |         |
; | 0  |  0  |  0  |  NZ |  0  |  0  | end-time1 secs -> end     |  X      |         |
; | 0  |  0  |  0  |  0  |  NZ |  0  | pan fwd from time1->time2 |  X      |  X      |
; | 0  |  0  |  0  |  0  |  0  |  NZ | pan back from time1->time2|  X      |  X      |
; | 0  |  NZ |  0  |  0  |  0  |  0  | time1 -> time1+npts       |  X      |         |
; | 0  |  NZ |  NZ |  0  |  0  |  0  | start -> start+npts       |         |         |
; | 0  |  NZ |  0  |  NZ |  0  |  0  | end-npts -> end           |         |         |
;
;	Any other combination of keywords is not allowed.
;
;
; CALLING SEQUENCE: e_long = get_fa_edc_long(time1, time2, [NPTS=npts],
;                             [START=st | EN=en | PANF=panf | PANB =
;                             panb | ALL = all])
;
;
;
; CURRENT PROBLEMS: It's not clear what to do if the time bases for
; the different data quantities are not the same. Right now, the times
; returned are those of the first available DQD, in order [V1-V4,
; V5-V8, V9-V10].  Yikes! Also, no indication of mode is returned...
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to a number between 1 and 7. The number is determined by
;	interpreting the valid tags from each of the three long booms
;	as binary digits; v14.valid is weighted 1, v58.valid 2,
;	v910.valid 4. Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_fa_edc_long.pro	1.18 07/23/96
; 	Originally written by	 Bill Peria,  University of 
; 	California at Berkeley, Space Sciences Lab.   June '96
;-
; CALLING SEQUENCE: e_long = get_fa_edc_long(time1, time2, [NPTS=npts],
;                             [START=st | EN=en | PANF=panf | PANB =
;                             panb | ALL = all])

function get_fa_edc_long, time1, time2, npts=npts, start=st, en=en, $
                          panf=panf, panb=panb, all=all
;
;The POSS* string arrays list the possible SDT DQD's which might be
;available at a given time, from each of the 3 booms. The PRIORITIES
;array gives the order in which to try the possibilities. In the
;future we may wish to set PRIORITIES according to an input keyword. 
;
e_units = 'mV/m'
get = 'get_'
sc = 'fa_'
dt = 'fields'

priorities = [0,1,2]
poss14  = ['V1-V4_S','V1-V4_16K','V1-V4_4K','N/A']
poss58  = ['V5-V8_S','V5-V8_16K','V5-V8_4K','N/A']
poss910 = ['V9-V10_S','V9-V10_16K','V9-V10_4K','N/A']
np14  = n_elements(poss14)-1    ; one less than number of elements,
np58  = n_elements(poss58)-1    ; because then when a DQD is not
np910 = n_elements(poss910)-1   ; available, I can use the loop exit
                                ; index to stick 'N/A' into the ouput
                                ; structure. 

if keyword_set(npts) then begin
    npts14 = npts
    npts58 = npts
    npts910 = npts
endif

if defined(time1) then time1s = time1 ; save time1 and time2, since        
if defined(time2) then time2s = time2 ; GET_TS_FROM_SDT seems to modify its
                                ; inputs (!).                        

i14 = -1
i=0
repeat begin
    dqd = poss14(priorities(i))
    if defined(time1s) then time1 = time1s
    if defined(time2s) then time2 = time2s
    
    v14  =  call_function(get+sc+dt,dqd,time1, time2, npts=npts14, $
                          start=st, en=en,panf=panf, panb=panb, $
                          all=all) 
    if v14.valid then i14  = i
    i = i + 1
endrep until (v14.valid or (i eq np14))
if (i eq np14) then i14 = i


i58 = -1
i=0

repeat begin
    dqd = poss58(priorities(i))
    if defined(time1s) then time1 = time1s
    if defined(time2s) then time2 = time2s
    
    v58  =  call_function(get+sc+dt,dqd,time1, time2, npts=npts58, $
                          start=st, en=en,panf=panf, panb=panb, $
                          all=all)
    if v58.valid then i58  = i
    i = i + 1
endrep until (v58.valid or (i eq np58))
if (i eq np58) then i58 = i


i910 = -1
i=0
repeat begin
    dqd = poss910(priorities(i))
    if defined(time1s) then time1 = time1s
    if defined(time2s) then time2 = time2s
    
    v910  =  call_function(get+sc+dt,dqd,time1, time2, npts=npts910, $
                           start=st, en=en,panf=panf, panb=panb, $
                           all=all)
    if (v910.valid eq 1) then i910  = i
    i = i + 1
endrep until ((v910.valid eq 1) or (i eq np910))
if (i eq np910) then i910 = i

if (v14.valid) then begin
    if (not v14.calibrated) then fa_fields_units,v14
endif
if (v58.valid) then begin
    if (not v58.calibrated) then fa_fields_units,v58
endif
if (v910.valid) then begin
    if (not v910.calibrated) then fa_fields_units,v910
endif

if (v14.calibrated and v58.calibrated and v910.calibrated) then begin
    elong_units = e_units
endif else begin
    if not (v14.calibrated or v58.calibrated or v910.calibrated) then begin
        elong_units = 'RAW'
    endif else begin
        elong_units = v14.units_name +' '+v58.units_name+' ' $
          +v910.units_name
    endelse
endelse

valarr = [v14.valid,v58.valid,v910.valid]
good = where(valarr ne 0,ngood)
bad = where(valarr eq 0,nbad)
names = strupcase(poss14(i14)+' '+poss58(i58)+' '+poss910(i910))

if (ngood gt 0) then begin      ; *something* was valid
    case min(good) of
        0:begin
            time = v14.time
            start_time = v14.start_time
            end_time = v14.end_time
            npts = npts14
        end
        1:begin
            time = v58.time
            start_time = v58.start_time
            end_time = v58.end_time
            npts = npts58
        end
        2:begin
            time = v910.time
            start_time = v910.start_time
            end_time = v910.end_time
            npts = npts910
        end
    endcase
    
    elong = {data_name:names, $
             valid: long(total([1,2,4]*valarr)),$
             project_name: 'FAST', $
             units_name: elong_units, $
             units_procedure: 'fa_fields_units', $
             start_time:start_time, $
             end_time:end_time, $
             npts:npts14, $
             ncomp:long(total(valarr)), $
             time:v14.time}

    if v14.valid then begin
        elong = create_struct(elong,'comp1',v14.comp1)
    endif
    if v58.valid then begin
        elong = create_struct(elong,'comp2',v58.comp1)
    endif
    if v910.valid then begin
        elong = create_struct(elong,'comp3',v910.comp1)
    endif
endif else begin                ; nothing was valid
    message,'No valid data found...is SDT running?',/continue
    elong = {data_name:names,  $
             valid: 0L}
endelse

return,elong
end







