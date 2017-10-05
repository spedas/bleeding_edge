;+
; NAME:	RBSP_LOAD_EFW_ESVY_MGSE
;
; SYNTAX:
;   rbsp_load_efw_esvy_mgse,probe='a'
;   rbsp_load_efw_esvy_mgse,probe='a',/no_spice_load
;
; PURPOSE:	Loads EFW ESVY data and despins using SPICE via rbsp_uvw_to_mgse.pro
;
;			The MGSE coordinate system is defined:
;				Y_MGSE=-W_SC(GSE) x Z_GSE
;				Z_MGSE=W_SC(GSE) x Y_MGSE
;				X_MGSE=Y_MGSE x Z_MGSE
;			where W_SC(GSE) is the spin axis direction in GSE.
;
;			This is equivalent to the GSE coordinate system if the spin axis
;			lies along the X_GSE direction.
;
; KEYWORDS:
;	probe = 'a' or 'b'  NOTE: single spacecraft only, does not accept ['a b']
;		NOTE: defaults to probe='a'
;	/no_spice_load - skip loading/unloading of SPICE kernels
;		NOTE: This assumes spice kernels have been manually loaded using:
;			rbsp_load_spice_predict ; (optional)
;			rbsp_load_spice_kernels ; (required)
;	/debug - prints debugging info
;	/qa - load the QA test file instead of standard L1 file
; bad_probe -> integer indicating a bad probe.
;
;
; NOTES:
;
; HISTORY:
;	1. Created Nov 2012 - Kris Kersten, kris.kersten@gmail.com
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2017-04-05 10:09:53 -0700 (Wed, 05 Apr 2017) $
;   $LastChangedRevision: 23110 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_efw_esvy_mgse.pro $
;
;-


pro rbsp_load_efw_esvy_mgse,probe=probe,no_spice_load=no_spice_load,$
	debug=debug,qa=qa,bad_probe=bad_probe

	etype='esvy'

	date = timerange()
	date = strmid(time_string(date[0]),0,10)

	; check probe keyword
	if ~keyword_set(probe) then begin
		message,"Probe keyword not set. Using default probe='a'.",/continue
		probe='a'
	endif else begin
		probe=strlowcase(probe) ; this turns any data type to a string
		if probe ne 'a' and probe ne 'b' then begin
			message,"Invalid probe keyword. Using default probe='a'.",/continue
			probe='a'
		endif
	endelse

;	; see if survey data is loaded
;	enames=''
;	enames=tnames('rbsp'+probe+'_efw_'+etype)
;	if enames[0] eq '' then noedata=1b else noedata=0b
;
;	; load survey, housekeeping if we're missing E or SC_Spin* data
;	if noedata then $
;		rbsp_load_efw_waveform, probe=probe, datatype=etype, type='cal', $
;			coord='uvw',/noclean

	; force reload of esvy in uvw coordinates without cleaning

	if ~keyword_set(bad_probe) then begin
		if ~keyword_set(qa) then rbsp_load_efw_waveform, probe=probe, datatype=etype, type='cal', $
			coord='uvw',/noclean
		if keyword_set(qa) then rbsp_load_efw_waveform, probe=probe, datatype=etype, type='cal', $
			coord='uvw',/noclean,/qa
	endif else rbsp_efw_create_esvy_uvw_from_vsvy,date,probe,bad_probe



	if ~keyword_set(no_spice_load) then begin
		rbsp_load_spice_predict
		rbsp_load_spice_kernels
	endif

	rbsp_uvw_to_mgse,probe,'rbsp'+probe+'_efw_'+etype,debug=debug,/no_spice_load


	if ~keyword_set(no_spice_load) then begin
		rbsp_load_spice_predict,/unload
		rbsp_load_spice_kernels,/unload
	endif

end
