;+
; FUNCTION:
; 	 GET_FA_TSOP_HDR
;
; DESCRIPTION:
;
;	function to load FAST TEAMS HO survey header data from the SDT program
; 	shared memory buffers.
;
;	At structure of the following format is returned:
;
;	   DATA_NAME     STRING 'Tms_HO_Survey_Packet_Hdr'; Data Quantity name
;	   VALID         INT       1                   ; Data valid flag
; 	   PROJECT_NAME  STRING    'FAST'              ; Project name
; 	   UNITS_NAME    STRING    'Raw'               ; Units of this data
; 	   VALUES_PROCEDURE  STRING '<NONE>'           ; Name of proc to
;						       ; (Not implemeted)
;                                                      ; get values from hdr
;	   TIME          DOUBLE    8.0118726e+08       ; Start Time of sample
;	   BYTES         BYTE      Array(86)	       ; Header bytes
;	   
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tsop_hdr (time)
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
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_fa_tsop_hdr.pro	1.3 12 Jul 1996
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   June '95
;-

FUNCTION get_fa_tsop_hdr, inputTime

   dat = get_ts_1p_from_sdt ('Tms_HO_Survey_Packet_Hdr', 2001, inputTime) 

   IF dat.valid EQ 0 THEN BEGIN
      RETURN, {data_name: 'Null', valid: 0}
      
   ENDIF ELSE BEGIN

      ; set return values 

      data_name = 'Tms_HO_Survey_Packet_Hdr'
      units_name = 'Raw'
      values_procedure = '<NONE>'
      inputTime = dat.time 
      bytes = dat.comp1
      
   ENDELSE 
      
   ; load up the data into IDL data structs

   dat = 								  $
     {data_name:	data_name, 					  $
       valid: 		1, 						  $
       project_name:	'FAST', 					  $
       units_name: 	units_name, 					  $
       values_procedure: values_procedure, 				  $
       time: 		inputTime,					  $
       bytes:		bytes}

   RETURN,  dat
END 
