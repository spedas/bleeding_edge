;+
;NAME: DSC_GETRNAME
;
;DESCRIPTION
;	Returns the routine name of the calling function.
;	
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_getrname.pro $
;-

function dsc_getrname
	COMPILE_OPT IDL2

	info = scope_traceback(/structure)
	return,info[-2].routine
end