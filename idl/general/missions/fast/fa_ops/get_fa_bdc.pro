;+
; NAME: get_fa_bdc
;
; DESCRIPTION: returns a structure containing DC
; magnetic field survey data from the FAST magnetometer (UCLA). It
; must be the case that SDT is running, with Mag1dc, Mag2dc_S, and Mag3dc_S
; plotted on screen already. 
;
;    The returned structure looks like this:
;
;
;  DATA_NAME           STRING    ' '                 ; which mag quantities
;  VALID               INT       1                   ; Data valid flag
;  PROJECT_NAME        STRING    'FAST'              ; project name
;  UNITS_NAME          STRING    'nT'                ; Units of this data    
;  UNITS_PROCEDURE     STRING    'fa_fields_units'   ; Units conversion proc 
;  START_TIME          DOUBLE                        ; Start Time of sample  
;  END_TIME            DOUBLE                        ; End time of sample    
;  NPTS                INT                           ; Number of time samples
;  NCOMP               INT                           ; Number of components  
;  TIME                DOUBLE    Array(npts)         ; timetags              
;  COMP1               DOUBLE    Array(npts)         ;
;  COMP2               DOUBLE    Array(npts)         ; 
;  COMP3               DOUBLE    Array(npts)         ;
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
; CALLING SEQUENCE: mag  = get_fa_bdc(time1, time2, [NPTS=npts],
;                             [START=st | EN=en | PANF=panf | PANB =
;                             panb | ALL = all])
;
;
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to a number between 1 and 7. The number is determined by
;	interpreting the valid tags from each of the three long booms
;	as binary digits; mag1.valid is weighted 1, mag2.valid 2,
;	mag3.valid 4. Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_fa_bdc.pro	1.17 18 Jul 1996
; 	Originally written by	 Bill Peria,  University of 
; 	California at Berkeley, Space Sciences Lab.   July 22, 1996
;-
; CALLING SEQUENCE: mag = get_fa_bdc(time1, time2, [NPTS=npts],
;                             [START=st | EN=en | PANF=panf | PANB =
;                             panb | ALL = all])

function get_fa_bdc, time1, time2, npts=npts, start=st, en=en, $
                     panf=panf, panb=panb, all=all
b_units = 'nT'
get = 'get_'
sc = 'fa_'
dt = 'fields'
dqd = ['Mag1dc_S','Mag2dc_S','Mag3dc_S']
first_valid = 1
ctag = ['comp1','comp2','comp3']

bdc = {data_name:' ', $
       valid: 0, $
       project_name: 'FAST', $
       units_name: b_units, $
       units_procedure: 'fa_fields_units', $
       start_time: double(0), $
       end_time:double(0), $
       npts: long(0), $
       ncomp:long(0)}


nnpts = fltarr(3)
if keyword_set(npts) then begin
    nnpts(0:2) = npts
endif

cal = 0
mix_units = ''
for i=0,2 do begin
    if defined(time1) then time1s = time1 ; save time1 and time2, since        
    if defined(time2) then time2s = time2 ; GET_TS_FROM_SDT seems to modify its
                                ; inputs (!).                        

    mag  =  call_function(get+sc+dt,dqd(i),time1, time2, npts=nnpts(i), $
                          start=st, en=en,panf=panf, panb=panb, $
                          all=all) 
    if mag.valid then begin
        if not mag.calibrated then fa_fields_units,mag
        cal = cal + mag.calibrated
        mix_units = mix_units + ' ' + mag.units_name
        bdc.valid = bdc.valid + long(2^i)
        bdc.data_name = bdc.data_name + ' ' +mag.data_name
        bdc.ncomp = bdc.ncomp + 1
        if first_valid then begin
            first_valid = 0
            bdc = create_struct(bdc,'time',mag.time)
            bdc.start_time = mag.start_time
            bdc.end_time = mag.end_time
            bdc.npts = n_elements(mag.comp1)
            bdc.time = mag.time
        endif
        bdc = create_struct(bdc,ctag(i),mag.comp1)
    endif
endfor
bdc.data_name = strtrim(strcompress(bdc.data_name),2)
if ((cal gt 0) and (cal lt 3)) then bdc.units_name = mix_units
if (cal eq 0) then bdc.units_name = 'RAW'


if bdc.valid eq 0 then begin
    message,'No valid data found...is SDT running?',/continue
    bdc = {data_name:'N/A N/A N/A',  $
           valid: 0L}
endif

return,bdc
end







