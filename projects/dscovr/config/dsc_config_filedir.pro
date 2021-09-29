;+
;NAME: DSC_CONFIG_FILEDIR
;
;DESCRIPTION:
; Get the applications user directory for DSCOVR
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/config/dsc_config_filedir.pro $
;-


FUNCTION DSC_CONFIG_FILEDIR, APP_QUERY = app_query, _EXTRA=_extra

COMPILE_OPT IDL2
	readme_txt = ['Directory for configuration files for use by DSCOVR']

	if (keyword_set(app_query)) then begin
		tdir = app_user_dir_query('dsc', 'dsc_config', /restrict_os)
		if (n_elements(tdir) EQ 1) then tdir = tdir[0]
		RETURN, tdir
	endif else begin
		RETURN, app_user_dir('dsc', 'DSCOVR Configuration',$
			'dsc_config', $
			'DSCOVR configuration directory',$
			readme_txt, 1, /restrict_os)
	endelse

END

