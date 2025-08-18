;+
;NAME: DSC_READ_CONFIG
;
;DESCRIPTION:
; Reads the dsc_config file
;
;REQUIRED INPUTS:
; none (filename is hardcoded, 'dsc_config.txt', and is put in a folder
; given by the routine 'dsc_config_filedir', that uses the IDL routine
; app_user_dir to create/obtain it:
; 	e.g. (Windows)
; 	C:\Users\anarock\.idl\dsc\dsc_config-4-win32
;
;KEYWORD ARGUMENTS (OPTIONAL):
; VERBOSE=:	Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
; 
;KEYWORD OUTPUTS (Optional):
; HEADER=:	Named variable to hold the config file header information
; 
;OUTPUT:
; Returns a structure with the changeable fields of the !dsc
; structure
;       
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/config/dsc_read_config.pro $
;-

FUNCTION DSC_CONFIG_TEMPLATE

COMPILE_OPT IDL2, HIDDEN
	anan = fltarr(1) & anan[0] = 'NaN'
	ppp = {VERSION:1.00000,$
			DATASTART:3l, $
			DELIMITER:61b, $
			MISSINGVALUE:anan[0], $
			COMMENTSYMBOL:';', $
			FIELDCOUNT:2l, $
			FIELDTYPES:[7l,7l], $
			FIELDNAMES:['FIELD1','FIELD2'], $
			FIELDLOCATIONS:[0l,15l], $
			FIELDGROUPS:[0l,1l]}

	RETURN, ppp
END

FUNCTION DSC_READ_CONFIG, HEADER = hhh, VERBOSE=verbose

	COMPILE_OPT IDL2
	dsc_init
	if not isa(verbose,/int) then verbose=!dsc.verbose

	otp = -1    ; return -1 if fails to find config file

	; first step, get the filename
	dir = dsc_config_filedir(/app_query)
	if (dir[0] NE '') then begin
	
		; check for trailing characters
		ll = strmid(dir, strlen(dir)-1,1)
		if (ll EQ '/' or ll EQ '\') then filex = dir+'dsc_config.txt' $
			else filex = dir + PATH_SEP() + 'dsc_config.txt'

		; does the file exist?
		if (file_search(filex) NE '') then begin
			template = dsc_config_template()
			fff = file_search(filex)
			strfx = read_ascii(filex, template=template, header=hhh)
			if (size(strfx, /type) EQ 8) then begin
				otp = create_struct(strtrim(strfx.field1[0], 2), $
									strtrim(strfx.field2[0], 2), $
									strtrim(strfx.field1[1], 2), $
									strtrim(strfx.field2[1], 2), $
									strtrim(strfx.field1[2], 2), $
									strtrim(strfx.field2[2], 2))
				for j=3, n_elements(strfx.field1)-1 do $
					str_element, otp, strtrim(strfx.field1[j],2), $
						fix(strfx.field2[j]), /add
			endif
		endif
	endif
	
	; check for path separators, add if necessary
	temp_string = strtrim(!dsc.local_data_dir, 2)
	ll = strmid(temp_string, strlen(temp_string)-1, 1)
	if ~(ll EQ '/' OR ll EQ '\') then temp_string = temp_string + PATH_SEP()
	!dsc.local_data_dir = temporary(temp_string)

	temp_string = strtrim(!dsc.remote_data_dir, 2)
	ll = strmid(temp_string, strlen(temp_string)-1, 1)
	if ~(ll EQ '/' or ll EQ '\') then temp_string = temp_string + '/'
	!dsc.remote_data_dir = temporary(temp_string)

	RETURN, otp
END
