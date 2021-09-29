;+
;NAME: PSP_SWP_READ_CONFIG
;
;DESCRIPTION:
; Reads the psp_sweap_config file
;
;REQUIRED INPUTS:
; none (filename is hardcoded, 'psp_sweap_config.txt', and is put in a folder
; given by the routine 'psp_swp_config_filedir', that uses the IDL routine
; app_user_dir to create/obtain it:
; 	e.g. (Windows)
; 	C:\Users\anarock\.idl\psp_sweap\psp_sweap_config-4-win32
;
;KEYWORD ARGUMENTS (OPTIONAL):
; VERBOSE=:	Integer indicating the desired verbosity level.  
;           Defaults to !psp_sweap.verbose
; 
;KEYWORD OUTPUTS (Optional):
; HEADER=:	Named variable to hold the config file header information
; 
;OUTPUT:
; Returns a structure with the changeable fields of the !psp_sweap
; structure
;       
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-10-27 12:50:05 -0700 (Tue, 27 Oct 2020) $
; $LastChangedRevision: 29302 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/L3i/config/psp_swp_read_config.pro $
;-

FUNCTION PSP_SWP_CONFIG_TEMPLATE

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

FUNCTION PSP_SWP_READ_CONFIG, HEADER = hhh, VERBOSE=verbose

	COMPILE_OPT IDL2
	psp_swp_init
	if not isa(verbose,/int) then verbose=!psp_sweap.verbose

	otp = -1    ; return -1 if fails to find config file

	; first step, get the filename
	dir = psp_swp_config_filedir(/app_query)
	if (dir[0] NE '') then begin
	
		; check for trailing characters
		ll = strmid(dir, strlen(dir)-1,1)
		if (ll EQ '/' or ll EQ '\') then filex = dir+'psp_sweap_config.txt' $
			else filex = dir + PATH_SEP() + 'psp_sweap_config.txt'

		; does the file exist?
		if (file_search(filex) NE '') then begin
			template = psp_swp_config_template()
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
	temp_string = strtrim(!psp_sweap.local_data_dir, 2)
	ll = strmid(temp_string, strlen(temp_string)-1, 1)
	if ~(ll EQ '/' OR ll EQ '\') then temp_string = temp_string + PATH_SEP()
	!psp_sweap.local_data_dir = temporary(temp_string)

	temp_string = strtrim(!psp_sweap.remote_data_dir, 2)
	ll = strmid(temp_string, strlen(temp_string)-1, 1)
	if ~(ll EQ '/' or ll EQ '\') then temp_string = temp_string + '/'
	!psp_sweap.remote_data_dir = temporary(temp_string)

	RETURN, otp
END
