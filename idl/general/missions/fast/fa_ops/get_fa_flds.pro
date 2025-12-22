;+
; NAME: GET_FA_FLDS
;
; PURPOSE: To store raw FAST fields quantities for TPLOT
;
; CALLING SEQUENCE:   get_fa_fields,dqd,[ time1, time2,
;                   NPTS=npts, START=st, EN=en, PANF=pf, PANB=pb,
;                   ALL = all, CALIBRATE = calibrate, STORE = store]
; 
; INPUTS:  DQD - a string containing a valid Data Quantity Descriptor
;                 to pass on to SDT. If SDT doesn't recognize the DQD,
;                 an error message is sent to the screen, and an
;                 invalid status is returned to IDL. The file
;                 FastDQD.doc, in the directory
;                 /disks/fast/software/integration/docs, contains all
;                 the current DQD information for FAST. The Unix
;                 command:  
;
;                     grep DataQuantity $FASTHOME/FastDQD.doc,
;
;                 will produce a (long!) list of valid DQD's, which you
;                 could redirect into a file for future reference. 
;
;
;
; OPTIONAL INPUTS:
;
;
;	time1 			This argument gives the start time from
;	        		which to take data, or, if START or EN keywords
;				are non-zero, the length of time to take data.
;				It may be either a string with the following
;				possible formats:
;					'YY-MM-DD/HH:MM:SS.MSC'  or
;					'HH:MM:SS'     (use reference date)
;				or a number, which will represent seconds
;				since 1970 (must be a double > 94608000.D), or
;				a hours from a reference time, if set.
;
;				Time will always be returned as a double
;				representing the actual data start time found 
;				in seconds since 1970.
;
;	time2			The same as time1, except it represents the
;				end time.
;
;				If the NPTS, START, EN, PANF or PANB keywords 
;				are non-zero, then time2 will be ignored as an
;				input parameter.
;
;
; KEYWORD PARAMETERS:
;
;       CALIBRATE: If set, causes calibrated data to be returned, if
;                  possible. Otherwise, raw data are returned,
;                  *unless* the environment variable FAST_CALIBRATE is
;                  set to 1, i.e. setenv FAST_CALIBRATE 1 . 
;
;       STORE: Meaningless, always set.
;
;       STRUCTURE: A named variable in which the data structure
;                  described above can be returned, if desired (for
;                  example, if STORE is set). 
;
;       SPIN: If defined, causes the data to be returned at once per
;             spin resolution, at a phase equal to the value of SPIN
;             in degrees. 
;
;       YBINS: If nonzero, two dimensional fields quantities are
;              returned with this many frequency bins. 
;
;       Setting the CALIBRATE keyword causes the procedure name in
;       DAT.UNITS_PROCEDURE to be called. 
;
;  
;	Other keywords determine data time selection as given in the 
;	following truth table (NZ == non-zero):
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
;	No other combination of keywords is allowed.
;
; RESTRICTIONS:    The data corresponding to DQD must already be on
; screen, having been plotted by SDT.  
;
;
; OUTPUTS: A TPLOT quantitiy, with the name DQD, is stored. 
;
;
; EXAMPLE: get_fa_flds,'Mag1dc_S',/all
;
;
;
; MODIFICATION HISTORY: written 3-October-1996 by Bill Peria UCB/SSL
;
;-
pro get_fa_flds,dqd,time1, time2, NPTS=npts, START=st, EN=en,      $
                       PANF=pf, PANB=pb, ALL = all, CALIBRATE = $
                calibrate, STORE = store, STRUCTURE = struct, $
                SPIN = spin, YBINS = ybins, BACKGROUND = background, $
                DEFAULT = default, REPAIR = repair
                

store = 1

if (get_fa_fields(dqd,time1, time2, NPTS=npts, START=st, EN=en,      $
                       PANF=pf, PANB=pb, ALL = all, CALIBRATE = $
                       calibrate, STORE = store, STRUCTURE = struct, $
                       SPIN = spin, YBINS = ybins, REPAIR =repair, $
                       DEFAULT = default))(0) eq '' then begin
    message,'Can''t get '+string(dqd),/continue
endif

return
end


