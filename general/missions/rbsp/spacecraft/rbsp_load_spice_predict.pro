;+
; NAME: RBSP_LOAD_SPICE_PREDICT
;
; SYNTAX:
;   rbsp_load_spice_predict
;   rbsp_load_spice_predict,/unload
;
; PURPOSE:  Loads/unloads the most recent RBSP SPICE predicted attitude and
;			ephemeris kernels found in local RBSP data directories:
;				$LOCAL_DATA_DIR/MOC_data_products/RBSP?/*_predict/
;			Predicted attitude files are retrieved from the remote data
;			server if available.
;
; KEYWORDS:
;	/all - loads all predict kernels, rather than only the most recent
;	/unload - unloads kernel files
;	/no_download - skips automatic download
;
; NOTES:
;	Access to RBSP predicted ephemeris kernels is restricted.  The
;	$LOCAL_DATA_DIR/MOC_data_products/RBSP?/ephemeris_predict/ directories must
;	be populated manually.
;
; HISTORY:
;	11/2012, created - Kris Kersten, kris.kersten@gmail.com
;
; VERSION:
;   $LastChangedBy: kersten $
;   $LastChangedDate: 2013-05-07 09:53:04 -0700 (Tue, 07 May 2013) $
;   $LastChangedRevision: 12292 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/spacecraft/rbsp_load_spice_predict.pro $
;
;-


pro rbsp_load_spice_predict, all=all, unload=unload, $
		no_download=no_download

	rbsp_spice_init
	
	if ~icy_test() then return
	
	if ~keyword_set(no_download) and ~keyword_set(unload) then begin
		relpathnames='MOC_data_products/RBSP?/attitude_predict/*'
		tempfiles=file_retrieve(relpathnames, _extra=!rbsp_spice)
	endif

	aattitude=file_search(!rbsp_spice.local_data_dir+ $
							'/MOC_data_products/RBSPA/attitude_predict/*',$
							/expand_tilde, count=aacount)
	battitude=file_search(!rbsp_spice.local_data_dir+ $
							'/MOC_data_products/RBSPB/attitude_predict/*',$
							/expand_tilde, count=bacount)
	aephemeris=file_search(!rbsp_spice.local_data_dir+ $
							'/MOC_data_products/RBSPA/ephemeris_predict/*',$
							/expand_tilde, count=aecount)
	bephemeris=file_search(!rbsp_spice.local_data_dir+ $
							'/MOC_data_products/RBSPB/ephemeris_predict/*',$
							/expand_tilde, count=becount)
	
	if keyword_set(all) then files=[aattitude,battitude,aephemeris,bephemeris] $
		else files=[aattitude[0>(aacount-2):0>(aacount-1)], $
					battitude[0>(bacount-2):0>(bacount-1)], $
					aephemeris[0>(aecount-2):0>(aecount-1)], $
					bephemeris[0>(becount-2):0>(becount-1)]]
	
	files=files[where(files ne '',fcount)]


	if fcount gt 0 then begin
		if keyword_set(unload) then begin
			cspice_unload,files
			message,'Unloaded '+string(fcount,format='(I0)')+ $
					' predict kernels.',/continue
		endif else begin
			cspice_furnsh,files
			message,'Loaded '+string(fcount,format='(I0)')+ $
					' predict kernels.',/continue
		endelse
	endif else message,'Predict kernels not found.',/continue
	
end