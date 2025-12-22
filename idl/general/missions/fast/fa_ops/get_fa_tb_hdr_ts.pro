;+
; FUNCTION:
; 	 GET_FA_TB_HDR_TS
;
; DESCRIPTION:
;
;	function to load FAST TEAMS burst header data from the SDT program
; 	shared memory buffers.
;
;	At structure of the following format is returned:
;
;	   DATA_NAME     STRING 'Tms_Burst_Packet_Hdr' ; Data Quantity name
;	   VALID         INT       1                   ; Data valid flag
; 	   PROJECT_NAME  STRING    'FAST'              ; Project name
; 	   UNITS_NAME    STRING    'Raw'               ; Units of this data
; 	   VALUES_PROCEDURE  STRING '<NONE>'           ; Name of proc to
;						       ; (Not implemeted)
;	   START_TIME    D OUBLE    8.0118726e+08       ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08       ; End time of sample
;	   NPTS          INT       npts                ; Number of timesamples
;                                                      ; get values from hdr
;	   TIME          DOUBLE    8.0118726e+08       ; Start Time of sample
;	   BYTES         BYTE      Array(86)	       ; Header bytes
;	   
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tb_hdr_ts (t1,t2,NPTS=npts,START=st, EN=en, PANF=pf, $
;                               PANB=pb, ALL=all, IDXST=idxst )
;
; ARGUMENTS:
;
;	time 			This argument gives a time handle from which
;				to take data from.  It may be either a string
;				with the following possible formats:
;					'YY-MM-DD/HH:MM:SS.MSC'  or
;					'HH:MM:SS'     (use reference date)
;				or a number, which will represent seconds
;				since 1970 (must be a double > 94608000.D), or
;				a hours from a reference time, if set.
;
;				time will always be returned as a double
;				representing the actual data time found in
;				seconds since 1970.
; KEYWORDS:
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
;
;	Any other combination of keywords is not allowed.
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;  Routine patched together from others fro multiple data point by manfred boehm, 
;  starting May 21.
FUNCTION get_fa_tb_hdr_ts, inputTime, endTime, NPTS=npts,START=st, EN=en, $
 PANF=pf, PANB=pb, ALL=all, IDXST=idxst 

   t1=inputTime
   t2=endTime   ; not used

   dat = get_ts_from_sdt ('Tms_Burst_Packet_Hdr', 2001, T1=t1, T2=t2,  $
       NPTS=npts, START=st, EN=en, PANF=pf,PANB=pb, ALL=all, IDXST=idxst ) 

   IF dat.valid EQ 0 THEN BEGIN
      RETURN, {data_name: 'Null', valid: 0}
      
   ENDIF ELSE BEGIN

      ; set return values 

      data_name = 'Tms_Burst_Packet_Hdr'
      units_name = 'Raw'
      values_procedure = '<NONE>'
      inputTime = dat.time
  ;    bytes = dat.comp1
       calibrated=0
       calibrated_units='none'
      
   ENDELSE 
      
   ; load up the data into IDL data structs

   dat = 								  $
     {data_name:	data_name, 					  $
       valid: 		1, 						  $
       project_name:	'FAST', 					  $
       units_name: 	units_name, 					  $
       values_procedure: values_procedure, 				  $
       start_time:	dat.start_time,					  $
       end_time:	dat.end_time, 					  $
       npts:		dat.npts, 					  $
       ncomp:		dat.ncomp, 					  $
       depth:		dat.depth,					  $
       time:		dat.time,					  $
       calibrated:	calibrated,     				  $
       calibrated_units:	calibrated_units,			  $
      
       bytes:		dat.comp1}

   RETURN,  dat
END 
