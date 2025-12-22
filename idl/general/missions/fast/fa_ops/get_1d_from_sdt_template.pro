;+
; FUNCTION:
; 	 get_<_satellite_>_<_inst_>
;
; DESCRIPTION:
;
;	This is a template function to be used to build get_* routines to get 
;	1-D multidimensional type data from the SDT program shared memory buffers.
;	Where modifications should be made, they are indicated by strings
;	such as: <_xxxx_>.  Comments should be keeped up as well, which
;	we find to be the most time consuming part.  This template is setup
;	to support the FAST/WIND/CLUSTER/POLAR data analysis software.  One may
;	want to return a completely different format
;
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    '<_your-data-name_>'  ; Data Quantity name
;	   VALID         INT       1                     ; Data valid flag
;	   PROJECT_NAME  STRING    '<_yourProject_>'     ; project name
;	   UNITS_NAME    STRING    '<_unitsOfData_>'     ; Units of this data
;	   UNITS_PROCEDURE  STRING '<_unitsProcedure_>'  ; Units conversion proc
;	   NROWS         INT       nrows                 ; Number of rows in array
;	   TIME          DOUBLE    8.0118726e+08         ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08         ; End time of sample
;          CALIBRATED    INT       calibrated            ; flags calibrated data
;          CALIBRATED_UNITS STRING units                 ; calibrated units string
;	   DATA          _Type_    array(nrows)          ; Data component 1
;	   NMINMAX       INT       nminmax               ; number of arr-desc.           
;	   MIN1          DOUBLE    array(nminmax)        ; min array descriptors
;	   MAX1          DOUBLE    array(nminmax)        ; max array descriptors
;	   MASS          DOUBLE    <_mass-off-entity_>   ; Particle Mass
;	   GEOMFACTOR    DOUBLE    <_your-geom-factor_>  ; Bin GF
;	   HEADER_BYTES  BYTE      Array(25)	         ; Header bytes
;	
; CALLING SEQUENCE:
;
; 	data = get_<_satellite_>_<_inst_> (time, [START=start | EN=en | ADVANCE=advance |
;				RETREAT=retreat])
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
; KEYWORDS:
;
;	START			If non-zero, get data from the start time
;				of the data instance in the SDT buffers
;
;	EN			If non-zero, get data at the end time
;				of the data instance in the SDT buffers
;
;	ADVANCE			If non-zero, advance to the next data point
;				following the time input
;
;	RETREAT			If non-zero, retreat (reverse) to the previous
;				data point before the time input
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_1d_from_sdt_template.pro	1.2 07/12/96
; 	Originally written by Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   June '96
;-

FUNCTION get_<_satellite_>_<_inst_>, inputTime, START=start, EN=en, ADVANCE=advance,  $
                         RETREAT=retreat

   dat = get_md_from_sdt ('<_yourDataName_>', <_yourSatelliteCode_>, TIME=inputTime,    $
                          START = start, EN = en, ADVANCE = advance, RETREAT=retreat)

   IF NOT dat.valid THEN          RETURN, {data_name: 'Null', valid: 0}
   
   ; get data values into correct dimensions here

   inputTime = dat.time 
   data_name = dat.data_name
   units_name = '<_unitsOfData_>'
   units_procedure = '<_unitsProcedure_>'
   data = FLOAT (REFORM (dat.values, dat.dimsizes(0), dat.dimsizes(1)))
   mass = <_mass-off-entity_> 
   geomfactor = <_your-geom-factor_>
   eff = REPLICATE (1., dat.dimsizes(0))          ;<_Set correctly if you can_>

   ; get the header bytes for this time

   hdr_time = inputTime
   hdr_dat = <_your_header_byte_get_routine_> (hdr_time)

   IF hdr_dat.valid EQ 0 THEN BEGIN
      print, 'Error getting Header bytes for this packet.  Bytes will be nil.'
      header_bytes = BYTARR(<_number_of_bytes_in_your_header_>)
   ENDIF ELSE BEGIN
      header_bytes = hdr_dat.bytes
   ENDELSE

   ; load up the data into IDL data structs

   RETURN,  {data_name:	data_name, 						      $
              valid: 		1, 						      $
              project_name:	'<_yourProject_>',				      $
              units_name: 	units_name, 					      $
              units_procedure: units_procedure, 				      $
              time: 		inputTime, 					      $
              end_time: 	dat.endTime, 				      	      $
              integ_t: 		(dat.endTime - inputTime)/dat.dimsizes(0), 	      $
              calibrated:	calibrated,     				      $
              calibrated_units:	calibrated_units,			  	      $
              nbins: 		dat.dimsizes(1), 				      $
              nenergy: 		dat.dimsizes(0), 				      $
              data: 		data, 						      $
	      min1:             dat.min1 					      $
	      max1:             dat.max1 					      $
              eff: 		eff, 						      $
              mass: 		mass, 						      $
              geomfactor: 	geomfactor, 					      $
              header_bytes: 	header_bytes}

END 
