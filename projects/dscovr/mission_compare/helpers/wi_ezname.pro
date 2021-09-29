;+
;NAME: WI_EZNAME
;
;DESCRIPTION:
; Given a shortcut string or string array, returns the full TPLOT variable name(s)
; of the relevant WIND variable.  
; Using shortcut strings implies GSE coordinate system.
;
;INPUTS:
; VARIN: Scalar or array of one of the shortcut strings recognized for WIND.  
;          'bx','by','bz','bgse','b','bphi','btheta',
;          'vx','vy','vz','vgse','v','np,'vth','alpha'
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
;		fn = wi_ezname('vx')
;		tn = wi_ezname(['v','Np','VTH'])
;		tplot,fn
;		tplot,tn
;		
;CREATED BY: Ayris Narock (ADNET/GSFC) 2018
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/mission_compare/helpers/wi_ezname.pro $
;-
FUNCTION WI_EZNAME,VARIN,HELP=help,VERBOSE=verbose
COMPILE_OPT IDL2

istp_init
rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!istp.verbose

supported = [ $
	'bx','by','bz','bgse','b','bphi','btheta',$
	'vx','vy','vz','vgse','v', 'vphi','vtheta','np','vth','alpha' $
	]
	
if keyword_set(help) then begin
	dprint,dlevel=2,verbose=verbose,rname+": Returning the supported Shortcut Strings."
	return,supported
endif
if ~isa(varin,/string) then varin='' else varin=varin.ToLower()
names = []

for i=0,varin.length-1 do begin
	case varin[i] of
		'bx'	: name = 'wi_h0_mfi_B3GSE_x'
		'by'	: name = 'wi_h0_mfi_B3GSE_y'
		'bz'	: name = 'wi_h0_mfi_B3GSE_z'
		'bgse': name = 'wi_h0_mfi_B3GSE'
		'b' 	: name = 'wi_h0_mfi_B3GSE_F2'
		'bphi'		: name = 'wi_h0_mfi_B3GSE_PHI'
		'btheta'	: name = 'wi_h0_mfi_B3GSE_THETA'
		'vx'	: name = 'wi_swe_V_GSE_x'
		'vy'	: name = 'wi_swe_V_GSE_y'
		'vz'	: name = 'wi_swe_V_GSE_z'
		'vgse': name = 'wi_swe_V_GSE'
		'v' 	:	name = 'wi_swe_V_GSE_F2'
		'vphi': name = 'wi_swe_V_GSE_PHI'
		'vtheta' : name = 'wi_swe_V_GSE_THETA'
		'np'	: name = 'wi_swe_Np'
		'vth'	: name = 'wi_swe_THERMAL_SPD'
		'alpha' : name = 'wi_swe_Alpha_Percent'
		else	: begin
			name = '' 
			dprint,dlevel=2,verbose=verbose,rname+": '"+varin[i].toString()+"' not recognized"
			end
	endcase
	names = [names,name]
endfor

if (names.length eq 1) then return,name else return,names
END
