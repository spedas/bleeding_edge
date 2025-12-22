;+
; NAME: FA_FIELDS_UNITS
;
;
;
; PURPOSE: To perform units conversions for the FAST fields
; instruments. Calls Bob Ergun's fastcal library. 
;
; CALLING SEQUENCE: fa_fields_units,data,VERBOSE=VERBOSE, $
;					DATA_HEADER=DATA_HEADER
;                         The times series values     
;                         contained in the DATA structure will have
;                         their units converted. Time series must be
;                         designated by structure tags "COMP*", where
;                         "*" is 1, 2, 3, etc. The string new_units
;                         contains the name of whatever units the data
;                         are returned in, i.e. it might be the same
;                         as the old units!
;                         
;
; INPUTS: A structure called DATA is passed in. It must contain :
;              - a tag called 'DATA_NAME', which must contain a valid
;                SDT DQD. 
;              - a tag beginning with 'COMP', like 'COMP1', which
;                contains time series data. 
;              - a tag called 'UNITS_NAME' which contains the units
;                currently in use for DATA.COMP*
;              - a tag called CALIBRATED, which indicates whether or
;                not there's any calibrating to do!
;       
; KEYWORD PARAMETERS:  	VERBOSE - if set, tells the user what's been
;                                converted 
;			DATA_HEADER - Generally, its a good idea to
;				fill in the data_header. If it is not
;				filled in, defaults will be used which
;				could result in improper calibrations.
;				DATA_HEADER should be 10 or 14 bytes.
;
; OUTPUTS: The with structure DATA, perhaps with some rescaled parts.
;
;
; SIDE EFFECTS: Those parts of DATA which contain time series data
; will be rescaled according to the calibration information encoded in
; the fastcal library. 
;
; RESTRICTIONS: Structure tags "comp*", "start_time", "data_name", and
; "units_name", and "valid"  are required. For 2d structures, DSP and SFA,
; structure tags 'yaxis' and 'yaxis_units' are required.
;
; MODIFICATION HISTORY: Originally written 5-July-1996 by Bill Peria,
; Space Scienes Lab, UCBerkeley
; 
; 96-10-26	REE 	Major rewrite. No new_units and scale.
; 96-11-05	REE 	Modifed to accomodate DSP, SFA, and time series.
;			Still needs FPA (Frequency/Phase/Amplitude) structures.
; 			Still needs MAG, WPC, and HFQ structures.
;-

pro fa_fields_units,data, verbose=verbose, data_header = data_header
;
; Make sure DATA is a structure...
;
catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    catch,/cancel
    return
endif

if idl_type(data) ne 'structure' then begin
    message,' Input structure is not a structure!',/continue
    catch,/cancel
    return
endif
; 
; Check for required structure tags...
;
reqtags = $
  ['start_time','comp*','data_name','units_name','valid','calibrated','time']
IF (missing_tags(data,reqtags,absent=absent) gt 0) then BEGIN
    message,'missing tags!',/continue
    catch,/cancel
    return
ENDIF 

verbose = keyword_set(verbose)
if data.calibrated then begin
    if verbose then message,'data are already calibrated...',/continue
    catch,/cancel
    return
endif

; Check if data is valid.
IF (data.valid eq 0) then BEGIN
    message,data.data_name+' data is not valid... no units conversion ' + $
      'performed.',/continue
    catch,/cancel
    return
ENDIF

; Start changes added by REE 10/26/96.

; Check if data_header is set.
IF n_elements(data_header) ge 10 then BEGIN
    if n_elements(data_header) eq 14 then data_header = data_header(4:13)
    data_header= byte(data_header(0:9))
ENDIF else BEGIN
    message,'DATA_HEADER is missing. Assuming fields modes 16 - 63.', $
	/continue
    data_header=0;
ENDELSE

; Determine the data type.
data_type_list = ['flt','sfa', 'dsp', 'hfq', 'mag', 'wpc', 'fpa', 'mac']
dqd_name = strlowcase(data.data_name)
data_struc_type = where(strmid(dqd_name,0,3) eq data_type_list)
data_struc_type = data_struc_type(0)

; Special case for 'mag*ac'
IF ( (data_struc_type eq 4) and (strmid(dqd_name,4,2) eq 'ac') ) then BEGIN
    data_struc_type = 7
    make_data_double,data		 	; MagAC must be double.
ENDIF

; Make structure in range.
if (data_struc_type lt 0) or $
   (data_struc_type gt 7) then data_struc_type=0
data_struc_type = long(data_struc_type)		; ARG3

; Check for 2-d tags.
IF (data_struc_type eq 1) or (data_struc_type eq 2) then BEGIN
    two_d_tags = ['yaxis', 'yaxis_units']
    bad_2d_tags = (missing_tags(data,two_d_tags) gt 0)
    IF (bad_2d_tags) then BEGIN
        message,'missing 2d tags!',/continue
        catch,/cancel
        return
    ENDIF
ENDIF 

; Check for Mag tags.
IF data_struc_type eq 4 then BEGIN
    mag_tags = ['comp1', 'comp2', 'comp3']
    IF (missing_tags(data,mag_tags) gt 0) then BEGIN
        message,'missing mag tags! Need comp1, comp2, and comp3.',/continue
        catch,/cancel
        return
    ENDIF
ENDIF 

; Set up for call_fastcal
pass_data_name  = data.data_name		; ARG 0
epoch_time      = double(data.start_time)	; ARG 1
units_y         = bytarr(32) 			; ARG 5  
units_z         = bytarr(32)	 		; ARG 6  
data_ptr2 = 0					; ARG 8
data_ptr3 = 0					; ARG 9
data_ptr4 = 0					; ARG 10

; START LOOP FOR COMPONENTS - COMP1, COMP2, ...
tags = strlowcase(tag_names(data))
data_tag_spots = where(strmid(tags,0,4) eq 'comp',ndts)
FOR  i=0, (ndts-1) do BEGIN

    CASE data_struc_type(0) OF

    0: BEGIN					; *** TIME SERIES structure ***
        raw_data = $
	    float(data.(data_tag_spots(i)))
	; ARG 2
	npts     = long(n_elements(raw_data))	; ARG 4

        ; Set up data header BBF, HSBM gain = 1.
        IF n_elements(data_header) lt 10 then BEGIN
            data_header = bytarr(10)		; ARG 7
            data_header(6) = 3	; BBF  gain = 1.
            data_header(8) = 12	; HSBM gain = 1.
            data_header(0) = 7  ; Svy/Hsbm high speed.
        ENDIF 
    END

    1: BEGIN					; *** SFA structure ***
        ; Set up SFA structure. See FastCalData_struc.h. 
        raw_data = data.(data_tag_spots(i))	; ARG 2
	npts = long(n_elements(raw_data)/256)	; ARG 4
        data_ptr2 = dblarr(256)			; ARG 8
        data_ptr3 = dblarr(256)			; ARG 9

        ; Set up data header for inc=1, stp=0, gain = 1.
        IF n_elements(data_header) lt 10 then BEGIN
            data_header = bytarr(10)		; ARG 7
            data_header(1) = 5
            data_header(2) = 3
        ENDIF
    END

    2: BEGIN					; *** DSP structure ***
        ; Set up DSP structure. See FastCalData_struc.h. 
        freq = dblarr(512) 
        raw_data = data.(data_tag_spots(i))	; ARG 2
	npts = long(n_elements(raw_data)/512)	; ARG 4
        data_ptr2 = dblarr(512)			; ARG 8
        data_ptr3 = dblarr(512)			; ARG 9
        if n_elements(data_header) lt 10 then $
	    data_header = bytarr(10)		; ARG 7
    END

     3: BEGIN					; *** HFQ structure ***
        message,data.data_name+' HFQ cannot be calibrated in IDL yet... ' + $
		'no units conversion performed.',/continue
        catch,/cancel
        return
    END
  
     4: BEGIN					; *** MagDC structure ***
	; Set up MagDC structure.
        i = fix(ndts); Set i to end. All Mag components handled at once.
        raw_data = float(data.comp1)		; ARG 2
	npts = long(n_elements(raw_data))	; ARG 4
        data_ptr2 = float(data.comp2)		; ARG 8
        data_ptr3 = float(data.comp3)		; ARG 9
        data_ptr4 = double(data.time)		; ARG 10
        if n_elements(data_header) lt 10 then $
	    data_header = bytarr(10)		; ARG 7

    END

     5: BEGIN					; *** WPC structure ***
        message,data.data_name+' WPC cannot be calibrated in IDL yet... ' + $
		'no units conversion performed.',/continue
        catch,/cancel
        return
    END

     6: BEGIN					; *** FPA structure ***
        message,data.data_name+' FPA cannot be calibrated in IDL yet... ' + $
		'no units conversion performed.',/continue
        catch,/cancel
        return
    END

     7: BEGIN					; *** MagAC structure ***

        raw_data = double(data.(data_tag_spots(i)))	; ARG 2
	npts     = long(n_elements(raw_data))	; ARG 4
        if n_elements(data_header) lt 10 then $
	    data_header = bytarr(10)		; ARG 7
        data_ptr2 = data.time			; ARG 8
    END


    ENDCASE

    ; Make call to call_fastcal() - c library.
    status = call_external( 'libfastfieldscals.so', $
		'call_fastcal', $
		pass_data_name, $		; ARG 0
		epoch_time, $			; ARG 1
		raw_data, $			; ARG 2
		data_struc_type, $		; ARG 3
		npts, $				; ARG 4
		units_y, $		; ARG 5
		units_z, $		; ARG 6
		data_header, $			; ARG 7
		data_ptr2, $			; ARG 8
		data_ptr3, $			; ARG 9
		data_ptr4)			; ARG 10

    ; Reconstruct the data.
    IF (status gt 0) then BEGIN
        message,'Calibration of ' + data.data_name + ' successful.', /cont

        CASE data_struc_type(0) OF

        0: BEGIN				; *** TIME SERIES structure ***
            data.(data_tag_spots(i)) = raw_data
            data.units_name = string(units_y)
            data.calibrated = 1
        END

        1: BEGIN				; *** SFA structure ***
            data.(data_tag_spots(i)) = raw_data
            data.units_name = string(units_z)
            data.yaxis_units = string(units_y)
            data.calibrated = 1
	    data.yaxis = (data_ptr2 + data_ptr3) / 2.0
        END

        2: BEGIN				; *** DSP structure ***
            data.(data_tag_spots(i)) = raw_data
            data.units_name = string(units_z)
            data.yaxis_units = string(units_y)
            data.calibrated = 1
	    data.yaxis = (data_ptr2 + data_ptr3) / 2.0
        END

        4: BEGIN				; *** MagDC structure ***
            data.comp1 = raw_data
            data.comp2 = data_ptr2
            data.comp3 = data_ptr3
            data.time  = data_ptr4
            data.units_name = string(units_y)
            data.calibrated = 1
        END

        7: BEGIN				; *** MagAC structure ***
            data.(data_tag_spots(i)) = raw_data
            data.units_name = string(units_y)
            data.calibrated = 1
        END

        ENDCASE

    ENDIF else BEGIN
        if verbose then message,' error in fastcal library, email ' + $
              'ree@ssl.berkeley.edu!',/continue
    ENDELSE

ENDFOR
catch,/cancel
return
end
