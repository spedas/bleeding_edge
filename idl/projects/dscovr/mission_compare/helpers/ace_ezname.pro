;+
;NAME: ACE_EZNAME
;
;DESCRIPTION:
; Given a shortcut string or string array, returns the full TPLOT variable name(s)
; of the relevant ACE variable.  
; Using shortcut strings implies GSE coordinate system.
;
;INPUTS:
; VARIN: Scalar or array of one of the shortcut strings recognized for ACE.  
;          'bx','by','bz','bgse','b','bphi','btheta',
;          'v','np','temp' 
;          Case is ignored.
;          Vector values are in GSE.
;
;KEYWORDS:
; HELP:     Set to return an array of the supported shortcut strings
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose 
; 						
;OUTPUT:
; String or string array containing the full TPLOT varible name(s). Will return '' if passed
; unsupported fields.
;
;EXAMPLES:
;		fn = ace_ezname('bx')
;		tn = ace_ezname(['v','Np','Temp'])
;		tplot,fn
;		tplot,tn
;		
;CREATED BY: Ayris Narock (ADNET/GSFC) 2018
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/mission_compare/helpers/ace_ezname.pro $
;-
FUNCTION ACE_EZNAME,VARIN,HELP=help,VERBOSE=verbose
COMPILE_OPT IDL2

istp_init
rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!istp.verbose

supported = [ $
	'bx','by','bz','bgse','b','bphi','btheta',$
	'v','np','temp' $
	]	
if keyword_set(help) then begin
	dprint,dlevel=2,verbose=verbose,rname+": Returning the supported Shortcut Strings."
	return,supported
endif
if ~isa(varin,/string) then varin='' else varin=varin.ToLower()
names = []

;TODO - outside here, store as a dictionary and just reference
for i=0,varin.length-1 do begin
	case varin[i] of
		'bx'	: name = 'ace_k0_mfi_BGSEc_x'
		'by'	: name = 'ace_k0_mfi_BGSEc_y'
		'bz'	: name = 'ace_k0_mfi_BGSEc_z'
		'bgse': name = 'ace_k0_mfi_BGSEc'
		'b' 	: name = 'ace_k0_mfi_BGSEc_F2'
		'bphi'		: name = 'ace_k0_mfi_BGSEc_PHI'
		'btheta'	: name = 'ace_k0_mfi_BGSEc_THETA'
		'v' 	:	name = 'ace_k0_swe_Vp'
		'np'	: name = 'ace_k0_swe_Np'
		'temp'	: name = 'ace_k0_swe_Tpr'
		else	: begin
			name = '' 
			dprint,dlevel=2,verbose=verbose,rname+": '"+varin[i].toString()+"' not recognized"
			end
	endcase
	names = [names,name]
endfor

if (names.length eq 1) then return,name else return,names
END
