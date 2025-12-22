;+
; FUNCTION:
; 	 get_<_satellite_>_<_inst_>
;
; DESCRIPTION:
;
;	This is a template function to be used to build get_* routines to get 
;	time series type data from the SDT program shared memory buffers.
;	Where modifications should be made, they are indicated by strings
;	such as: <_xxxx_>.  Comments should be keeped up as well, which
;	we find to be the most time consuming part.
;
;	At structure of the following format is returned:
;
;	   DATA_NAME     STRING    '<_yourDataName_>'  ; Data Quantity name
;	   VALID         INT       1                   ; Data valid flag
; 	   PROJECT_NAME  STRING    '<_yourProject_>'   ; project name
; 	   UNITS_NAME    STRING    '<_unitsOfData_>'   ; Units of this data
; 	   UNITS_PROCEDURE  STRING '<_unitsProcedure_>'; Units conversion proc
;	   START_TIME    DOUBLE    8.0118726e+08       ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08       ; End time of sample
;	   NPTS          INT       npts                ; Number of time samples
;	   NCOMP         INT       <_NumberOfDataComp_>; Number of components
;	   DEPTH         INT       <_DepthOfEachComp_> ; depth of component(s)
;          TIME          DOUBLE    Array(npts)         ; timetags
;          CALIBRATED    INT       calibrated          ; flags calibrated data
;          CALIBRATED_UNITS STRING units               ; calibrated units string
;	   DATA1         <_Type_>  Array(npts,<_depth(0)_>); Data component 1
<_ Here, enter a data spec for each component in this data set _>
;	   DATA2         <_Type_>  Array(npts,<_depth(1)_>); Data component 2
;	   DATA3         <_Type_>  Array(npts,<_depth(2)_>); Data component 3
<_ .. _>
;	   DATAn         <_Type_>  Array(npts,<_depth(n-1)_>); Data component 4
;	   HEADER_BYTES  BYTE      Array(1)	       ; Header bytes (not implemented)
;	   
;	
; CALLING SEQUENCE:
;
; 	data = get_<_satellite_>_<_inst_> (time1, time2, [NPTS=npts], [START=st | EN=en |
;				PANF=panf | PANB = panb])
;
; ARGUMENTS:
;
;	time1 			This argument gives the start time from
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
;	time2			The same as time1, except it represents the
;				end time.
;
;				If the NPTS, START, EN, PANF or PANB keywords 
;				are non-zero, THEN time2 will be ignored as an
;				input paramter.
; KEYWORDS:
;
;	Data time selection is determined from the keywords as given in the 
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
;	Any other combination of keywords is not allowed.
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;	@(#)get_ts_from_sdt_template.pro	1.9 07/12/96
; 	Originally written by	 Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Jan '96
;-

FUNCTION get_<_satellite_>_<_inst_>, time1, time2, NPTS=npts, START=st, EN=en,   $
                      PANF=pf, PANB=pb, ALL=all

   dat = get_ts_from_sdt ('<_yourDataName_>', <_yourSatelliteCode_>,      $
                          t1 = time1, t2 = time2, NPTS = npts,            $
                          START=st, EN=en, PANF=panf, PANB=panb, ALL=all)

   IF NOT dat.valid THEN          RETURN, {data_name: 'Null', valid: 0}
   
   ; load up the data into IDL data structs

   ret = 								  $
     {data_name:	dat.data_name, 					  $
       valid: 		dat.valid,					  $
       project_name:	'<_yourProject_>', 				  $
       units_name: 	'<_unitsOfData_>',				  $
       values_procedure: '<_unitsProcedure_>', 				  $
       start_time:	dat.start_time,					  $
       end_time:	dat.end_time, 					  $
       npts:		dat.npts, 					  $
       ncomp:		dat.ncomp, 					  $
       depth:		dat.depth,					  $
       time:		dat.time,					  $
       calibrated:	calibrated,     				  $
       calibrated_units:	calibrated_units,			  $
       data1:		dat.comp1, 					  $
<_ below here, delete unused components: _>
       data2:		dat.comp2, 					  $
       data3:		dat.comp3, 					  $
       data4:		dat.comp4, 					  $
       data5:		dat.comp5, 					  $
       data6:		dat.comp6, 					  $
       data7:		dat.comp7, 					  $
       data8:		dat.comp8, 					  $
       data9:		dat.comp9, 					  $
       data10:		dat.comp10, 					  $
       data11:		dat.comp11, 					  $
       data12:		dat.comp12, 					  $
       data13:		dat.comp13, 					  $
       data14:		dat.comp14, 					  $
       data15:		dat.comp15, 					  $
       data16:		dat.comp16, 					  $
       data17:		dat.comp17, 					  $
       data18:		dat.comp18, 					  $
       data19:		dat.comp19, 					  $
       data20:		dat.comp20, 					  $
       header_bytes:	BYTARR(1)}

   RETURN,  ret
END 
