;+
;NAME: DSC_DELETEVARS
;
;DESCRIPTION:
; Deletes all DSCOVR data variables from TPLOT
;
;KEYWORDS: (Optional)
; ALL=: Delete both DSCOVR variables and any time shifted variables
; BASE=:  Delete all variables with the DSCOVR standard prefix (will delete time shifted DSCOVR variables)
; SHIFTVARS=: Delete all time-shifted single and compound variables - Not just DSCOVR vars.
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;
;EXAMPLE:
;		dsc_deletevars
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_deletevars.pro $
;-

PRO DSC_DELETEVARS,BASE=base,SHIFTVARS=shiftvars,ALL=all,VERBOSE=verbose

	COMPILE_OPT IDL2
	
	dsc_init
	rname = dsc_getrname()
	if not isa(verbose,/int) then verbose=!dsc.verbose
	
	if keyword_set(all) then begin
		base = 1
		shiftvars = 1
	endif else begin
		shiftvars = keyword_set(shiftvars) ? 1 : 0
		base = keyword_set(base) ? 1 : ~shiftvars ? 1 : 0
	endelse

	dprint,dlevel=4,verbose=verbose,rname+': Deleting tplot variables- '

	if base then begin
		foreach name,tnames('dsc_*') do begin
			dprint,dlevel=4,verbose=verbose,"   "+name
		endforeach

		store_data,delete='dsc_*'
	endif
	
	if shiftvars then begin
		foreach name,tnames('*SHIFT*') do begin
			dprint,dlevel=4,verbose=verbose,"   "+name
		endforeach
		store_data,delete='*SHIFT*'
	endif
END
