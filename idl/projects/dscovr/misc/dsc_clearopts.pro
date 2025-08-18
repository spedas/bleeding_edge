;+
;NAME: DSC_CLEAROPTS
;
;DESCRIPTION:
; Clears non-default options from DSCOVR tplot variables.  
;	
;INPUTS:
; TN: Names or numbers of TPLOT variables to clear.  Will clear any valid variable, is
;       not limited to DSCOVR.  (INT/STRING) Scalar or Array.
;
;KEYWORDS: (Optional)
; ALL:      Set to clear options from all loaded DSCOVR variables.  Will override any arguments
;             passed in TN
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose 
;
;EXAMPLES:
;		dsc_clearopts,/all
;		dsc_clearopts,[3,5,12]
;		dsc_clearopts,'dsc_h0_mag_B1GSE'
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_clearopts.pro $
;-

PRO DSC_CLEAROPTS,tn,ALL=all,VERBOSE=verbose
	COMPILE_OPT IDL2

	dsc_init
	rname = dsc_getrname()
	if not isa(verbose,/int) then verbose=!dsc.verbose
	
	if keyword_set(all) then tn = tnames('dsc*')
	if (tn ne !null) then begin
		if isa(tn,/int) or isa(tn,/string) then begin
			foreach n,tn do begin
				if tnames(n) eq '' then begin
					dprint,dlevel=2,verbose=verbose,rname+': '+n.toString()+' -- INVALID Variable Identifier'
				endif else begin
					store_data,n,limits=0l
					dprint,dlevel=2,verbose=verbose,rname+': '+n+' -- Options cleared.'
				endelse
			endforeach
		endif else dprint,dlevel=2,verbose=verbose,rname+': INVALID Variable Identifiers.'
	endif else begin
		dprint,dlevel=2,verbose=verbose,rname+': No variables selected.'
		dprint,dlevel=2,verbose=verbose,rname+": Use 'dsc_clearopts,tn' OR 'dsc_clearopts,/all'"
	endelse
END
