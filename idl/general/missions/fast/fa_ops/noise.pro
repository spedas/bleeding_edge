;+
; FUNCTION: NOISE, dqd_name
;
;
;
; PURPOSE: Produces the DSP noise level for a dqd. This is the noise
; 	   limit due to the ADC and DSP/ or SFA - NOT the sensor! 
;
; CALLING: dat = NOISE(dqd_name)
; 	   Pretty simple! 
;                         
;
; INPUTS: A valid SDT dqd name such as 'Dsp_V5-V8HG'
;       
; KEYWORD PARAMETERS:  	BASE: The minimum value.
;
; OUTPUTS: A IDL data structure.
;
; SIDE EFFECTS: Does not include sensor noise.
;
; INITIAL VERSION: REE 96_11_01
; MODIFICATION HISTORY: 
; Space Scienes Lab, UCBerkeley
; 
;-
function noise, dqd_name, BASE=BASE

; Check keywords.
if not keyword_set(base) then base=0;

; Determine if data type is 'sfa' or 'dsp'
data_type = strlowcase(dqd_name)
data_type = strmid(data_type,0,3)

; Do the DSP case first.
IF data_type eq 'dsp' then BEGIN
    test_data = fltarr(512) - 96.049311 + base
    test_freq = fltarr(512)
    test_time = double(1.0e9)
    test_st = double(0)
    test_end = double(1)
    data =  {DATA_NAME: 	dqd_name, 	$
    	    VALID:		1, 		$
	    UNITS_NAME:		'RAW',		$
	    YAXIS_UNITS:	'RAW',		$
	    CALIBRATED:		0,		$
	    UNITS_PROCEDURE: 	'fa_fields_units', $
	    START_TIME:		test_time,	$
	    END_TIME:		test_time,	$
	    YAXIS:		test_freq,	$
	    COMP1:		test_data,	$
	    TIME:		test_time }
ENDIF

; Do the SFA case.
IF data_type eq 'sfa' then BEGIN
    test_data = fltarr(256) + base
    test_freq = fltarr(256)
    test_time = double(1.0e9)
    test_st = double(0)
    test_end = double(1)
    data =  {DATA_NAME: 	dqd_name, 	$
    	    VALID:		1, 		$
	    UNITS_NAME:		'RAW',		$
	    YAXIS_UNITS:	'RAW',		$
	    CALIBRATED:		0,		$
	    UNITS_PROCEDURE: 	'fa_fields_units', $
	    START_TIME:		test_time,	$
	    END_TIME:		test_time,	$
	    YAXIS:		test_freq,	$
	    COMP1:		test_data,	$
	    TIME:		test_time }
ENDIF

fa_fields_units, data
if data.calibrated eq 1 then return, data
return, 0
end

