;+
; FUNCTION:
; 	 GET_FA_IEB_TS
;
; DESCRIPTION:
;
;
;	function to load FAST I-esa burst data from the SDT program shared
;	memory buffers.  This is the time series version.  
;
;	An array of npts structures of the following format are returned:
;
;	   DATA_NAME     STRING    'Iesa Burst'        ; Data Quantity name
;	   VALID         INT       1                   ; Data valid flag
; 	   PROJECT_NAME  STRING    'FAST'              ; project name
; 	   UNITS_NAME    STRING    'Counts'            ; Units of this data
; 	   UNITS_PROCEDURE  STRING 'proc'              ; Units conversion proc
;	   TIME          DOUBLE    8.0118726e+08       ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08       ; End time of sample
;	   INTEG_T       DOUBLE    3.0000000           ; Integration time
;	   NBINS         INT       nbins               ; Number of angle bins
;	   NENERGY       INT       nnrgs               ; Number of energy bins
;	   DATA          FLOAT     Array(nnrgs, nbins) ; Data qauantities
;	   ENERGY        FLOAT     Array(nnrgs, nbins) ; Energy steps
;	   THETA         FLOAT     Array(nnrgs, nbins) ; Angle for bins
;	   GEOM          FLOAT     Array(nbins)        ; Geometry factor
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   EFF           FLOAT     Array(nnrgs)        ; Efficiency (GF)
;	   MASS          DOUBLE    0.0104389           ; Particle Mass
;	   GEOMFACTOR    DOUBLE    0.000272            ; Bin GF
;	   HEADER_BYTES  BYTE      Array(25)	       ; Header bytes
;	   INDEX         LONG      index               ; Data index, this pt. 
;	   ST_INDEX      LONG      st_idx              ; start index of arr
;	   EN_INDEX      LONG      en_idx              ; end index of arr
;	   NPTS          LONG      npts                ; array size
;	
; CALLING SEQUENCE:
;	data = get_fa_ieb_ts (t1, t2, [NPTS=npts], [START=st | EN=en | 
;				PANF=panf | PANB=panb | IDXST=startidx], 
;				CALIB=calib)
; ARGUMENTS:
;
;	t1 			This argument gives the start time from
;				which to take data, or, if START or EN keywords
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
;	t2			The same as time1, except it represents the
;				end time.
;
;				If the NPTS, START, EN, PANF or PANB keywords 
;				are non-zero, THEN time2 will be ignored as an
;				input paramter.
;
; KEYWORDS:
;
;	CALIB			If non-zero, caclulate geometry
;				factors for each bin instead of using 1.'s
;
;	Data time selection is determined from the keywords as given in the 
;	following truth table (NZ == non-zero):
;
; |ALL |NPTS |START| EN  |IDXST|PANF |PANB |selection            |use time1|use time2|
; |----|-----|-----|-----|-----|-----|-----|---------------------|---------|---------|
; | NZ |  0  |  0  |  0  |  0  |  0  |  0  | start -> end        |  X      |  X      |
; | 0  |  0  |  0  |  0  |  0  |  0  |  0  | time1 -> time2      |  X      |  X      |
; | 0  |  0  |  NZ |  0  |  0  |  0  |  0  | start -> time1 secs |  X      |         |
; | 0  |  0  |  0  |  NZ |  0  |  0  |  0  | end-time1 secs ->end|  X      |         |
; | 0  |  0  |  0  |  0  |  0  |  NZ |  0  | pan fwd from        |  X      |  X      |
; |    |     |     |     |     |     |     |   time1->time2      |         |         |
; | 0  |  0  |  0  |  0  |  0  |  0  |  NZ | pan back from       |  X      |  X      |
; |    |     |     |     |     |     |     |   time1->time2      |         |         |
; | 0  |  NZ |  0  |  0  |  0  |  0  |  0  | time1 -> time1+npts |  X      |         |
; | 0  |  NZ |  NZ |  0  |  0  |  0  |  0  | start -> start+npts |         |         |
; | 0  |  NZ |  0  |  NZ |  0  |  0  |  0  | end-npts -> end     |         |         |
; | 0  |  NZ |  0  |  0  |  NZ |  0  |  0  | st-index ->         |         |         |
; |    |     |     |     |     |     |     |   st_index + npts   |         |         |
;	Any other combination of keywords is not allowed.
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_fa_ieb_ts.pro	1.4 12/03/97
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Apr '97
;-

FUNCTION Get_fa_ieb_ts, t1, t2, NPTS=npts, START=st, EN=en,     $
                     PANF=pf, PANB=pb, ALL=all, IDXST=idxst, CALIB=calib

   raw = get_md_ts_from_sdt ('Iesa Burst', 2001, T1=t1, T2=t2,    $
                             START = st, EN = en, NPTS=npts,       $
                             PANF=pf, PANB=pb, ALL=all, IDXST=idxst)

   IF NOT raw.valid THEN   RETURN, {data_name: 'Null', valid: 0}
 
   ; return times

   t1 = raw.start_time
   t2 = raw.end_time

   ; get the header bytes 

   hdr_raw = get_ts_from_sdt ('Iesa_Burst_Packet_Hdr', 2001, NPTS=raw.npts, $
                              IDXST=raw.st_index)

   IF (hdr_raw.st_index NE raw.st_index ) OR $
      (hdr_raw.en_index NE raw.en_index ) THEN hdr_raw.valid = 0
      
   IF hdr_raw.valid EQ 0 THEN BEGIN
      print, '@(#)get_fa_ieb_ts.pro	1.4: Error getting Header bytes.  Bytes will be nil.'
      header_bytes = BYTARR(44, npts)
      got_header_bytes = 0
   ENDIF ELSE BEGIN
      header_bytes = hdr_raw.comp1
      got_header_bytes = 1
   ENDELSE

   dat = fill_fa_esa_from_ts_get(raw, 'Counts', header_bytes,   $
                                      got_header_bytes, CALIB=calib)
   dat.mass = 0.0104389
   dat.geomfactor = 0.000272

   ; blank out energy bin 0 (retrace bin)
   ; if header bit one in byte six is on, then we have a double
   ; retrace, so blank out e-bin 1 too

   dat.denergy(0,*,*) = 0.
   IF (where (2 AND header_bytes(6,*)))(0) NE -1 THEN  $
     dat.denergy(where (2 AND header_bytes(6,*))) = 0.

   dat.units_procedure = 'convert_esa_units2'

  ; load up the data into IDL data structs

   RETURN, dat

END 
