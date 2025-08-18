;+
;NAME: PSP_SWP_CONFIG_FILEDIR
;
;DESCRIPTION:
; Get the applications user directory for PSP SWEAP
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-10-27 12:50:05 -0700 (Tue, 27 Oct 2020) $
; $LastChangedRevision: 29302 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/L3i/config/psp_swp_config_filedir.pro $
;-


FUNCTION PSP_SWP_CONFIG_FILEDIR, APP_QUERY = app_query, _EXTRA=_extra

COMPILE_OPT IDL2
	readme_txt = ['Directory for configuration files for use by Parker Solar Probe']

	if (keyword_set(app_query)) then begin
		tdir = app_user_dir_query('psp_sweap', 'psp_sweap_config', /restrict_os)
		if (n_elements(tdir) EQ 1) then tdir = tdir[0]
		RETURN, tdir
	endif else begin
		RETURN, app_user_dir('psp_sweap', 'Parker Solar Probe SWEAP Configuration',$
			'psp_sweap_config', $
			'Parker Solar Probe SWEAP configuration directory',$
			readme_txt, 1, /restrict_os)
	endelse

END

