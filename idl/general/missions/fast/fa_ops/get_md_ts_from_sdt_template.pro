;+
; FUNCTION:
; 	 get_<_satellite_>_<_inst_>
;
; DESCRIPTION:
;
;	This is a template function to be used to build get_* routines
;	to get a time series of multi-dimensional type data from the SDT
;	program shared memory buffers.  The coder should look at the 
;	get_<x>d_from_sdt_from_std_template.pro files for info on
;	handling your data for each sample.
;
;	Where modifications should be made, they are indicated by strings
;	such as: <_xxxx_>.  Comments should be keeped up as well, which
;	we find to be the most time consuming part.
;
;	At structure of the following format is returned:
;
;	   DATA_NAME     STRING    '<_your-data-name_>'  ; Data Quantity name
;	   VALID         INT       1                     ; Data valid flag
;	   PROJECT_NAME  STRING    '<_yourProject_>'     ; project name
;	   UNITS_NAME    STRING    '<_unitsOfData_>'     ; Units of this data
;	   UNITS_PROCEDURE  STRING '<_unitsProcedure_>'  ; Units conversion proc
;	   START_TIME    DOUBLE    8.0118726e+08         ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08         ; End time of sample
;	   NPTS          INT       npts                  ; Number of time samples
;	   NDIMS         INT       ndims(rows,cols,echs) ; size of each dimension
;	   TIMES         DOUBLE    array(double)         ; Timetags of samples
;	   END_TIMES     DOUBLE    array(double)         ; End timetags of samples
;          CALIBRATED    INT       calibrated            ; flags calibrated data
;          CALIBRATED_UNITS STRING units                 ; calibrated units string
;	   DATA          _Type_    array(ndims)          ; Data component 1
;	   NMINMAX       INT       nminmax               ; number of arr-desc.           
;	   MIN1          DOUBLE    array(nminmax(0))     ; min array descriptors
;	   MAX1          DOUBLE    array(nminmax(0))     ; max array descriptors
<_ below here, delete unused MIN/MAX array descriptors based upon the number of dims: _>
;	   MIN2          DOUBLE    array(nminmax(1))     ; min array descriptors
;	   MAX2          DOUBLE    array(nminmax(1))     ; max array descriptors
;	   MIN3          DOUBLE    array(nminmax(1))     ; min array descriptors
;	   MAX3          DOUBLE    array(nminmax(1))     ; max array descriptors
;	
; CALLING SEQUENCE:
;
; 	data = get_<_satellite_>_<_inst_> (time1, time2, [NPTS=npts], [START=st | EN=en |
;				PANF=panf | PANB = panb], STIDX=stidx)
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
; |ALL |NPTS |START| EN  |STIDX|PANF |PANB |selection            |use time1|use time2|
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
;
;	@(#)get_md_ts_from_sdt_template.pro	1.1 03/26/97
; 	Originally written by	 Jonathan M. Loran,  University of 
; 	California at Berkeley, Space Sciences Lab.   Mar '97
;-

FUNCTION get_<_satellite_>_<_inst_>, time1, time2, NPTS=npts, START=st, EN=en,   $
                      PANF=pf, PANB=pb, ALL=all, STIDX=stidx

   dat = get_md_ts_from_sdt ('<_yourDataName_>', <_yourSatelliteCode_>,      $
                             t1 = time1, t2 = time2, NPTS = npts,            $
                             START=st, EN=en, PANF=panf, PANB=panb,          $
                             ALL=all, STIDX=stidx)

   IF NOT dat.valid THEN          RETURN, {data_name: 'Null', valid: 0}
   
   ; load up the data into IDL data structs

<_Note that other things should be done here to interpret the array descriptors_>
<_see the get_<x>d_from_std_templates.pro files for examples                   _>

   ret = 								  $
     {data_name:	dat.data_name, 					  $
       valid: 		dat.valid,					  $
       project_name:	'<_yourProject_>', 				  $
       units_name: 	'<_unitsOfData_>',				  $
       values_procedure: '<_unitsProcedure_>', 				  $
       start_time:	dat.start_time,					  $
       end_time:	dat.end_time, 					  $
       npts:		dat.npts, 					  $
       ndims:		dat.ndims,					  $
       time:		dat.time,					  $
       calibrated:	calibrated,     				  $
       calibrated_units:	calibrated_units,			  $
       data:            dat.data,     					  $
       nminmax: 	dat.nminmax,     				  $
       min1:		dat.min1,     					  $
       max1:		dat.max1,     					  $
<_ below here, delete unused MIN/MAX array descriptors based upon the number of dims: _>
       min2:		dat.min2,     					  $
       max2:		dat.max2,     					  $
       min3:		dat.min3,     					  $
       max3:		dat.max3}     					  $

   RETURN,  ret
END 
