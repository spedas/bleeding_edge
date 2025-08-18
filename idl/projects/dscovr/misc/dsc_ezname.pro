;+
;NAME: DSC_EZNAME
;
;DESCRIPTION:
; Given a DSCOVR shortcut string or string array, returns the full TPLOT variable name(s).  
; Using shortcut strings implies GSE coordinate system.
;
;INPUTS:
; VARIN: Scalar or array of one of the shortcut strings recognized for DSCOVR.  
;          'bx','by','bz','bgse','b','bphi','btheta',
;          'vx','vy','vz','vgse','v','vphi','vtheta','np,','temp','vth',
;          'posx','posy','posz','pos'
;          Case is ignored.
;          Vector values are in GSE.
;
;KEYWORDS:
; CONF:     Set to return the compound variables containing the +-dy lines
;             if they are available.  
;             ie: dsc_ezname('np') --> 'dsc_h1_fc_Np'
;                 dsc_ezname('np',/conf) --> 'dsc_h1_fc_Np_wCONF'
;             where 'dsc_h1_fc_Np_wCONF' looks like:
;               17 dsc_h1_fc_Np_wCONF
;                 15   dsc_h1_fc_Np+DY
;                  3   dsc_h1_fc_Np
;                 16   dsc_h1_fc_Np-DY
; HELP:     Set to return an array of the supported shortcut strings
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose 
; 						
;OUTPUT:
; String or string array containing the full TPLOT varible name(s). Will return '' if passed
; unsupported fields.
;
;EXAMPLES:
;		fn = dsc_ezname('vx')
;		tn = dsc_ezname(['v','Np','Temp'])
;		tplot,fn
;		
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_ezname.pro $
;-
FUNCTION DSC_EZNAME,VARIN,CONF=conf,HELP=help,VERBOSE=verbose
COMPILE_OPT IDL2

dsc_init
rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose

supported = [ $
	'bx','by','bz','bgse','b','bphi','btheta',$
	'vx','vy','vz','vgse','v', 'vphi','vtheta','np','temp','vth', $
	'posx','posy','posz','pos']
if keyword_set(help) then begin
	dprint,dlevel=2,verbose=verbose,rname+": Returning the supported Shortcut Strings."
	return,supported
endif
conf = keyword_set(conf) ? 1 : 0
if ~isa(varin,/string) then varin='' else varin=varin.ToLower()
names = []

for i=0,varin.length-1 do begin
	case varin[i] of
		'bx'	: name = 'dsc_h0_mag_B1GSE_x'
		'by'	: name = 'dsc_h0_mag_B1GSE_y'
		'bz'	: name = 'dsc_h0_mag_B1GSE_z'
		'bgse': name = 'dsc_h0_mag_B1GSE'
		'b' 	: name = 'dsc_h0_mag_B1F1'
		'bphi'		: name = 'dsc_h0_mag_B1GSE_PHI'
		'btheta'	: name = 'dsc_h0_mag_B1GSE_THETA'
		'vx'	: begin
			name = 'dsc_h1_fc_V_GSE_x'
			if conf then name=name+'_wCONF'
			end
		'vy'	: begin
			name = 'dsc_h1_fc_V_GSE_y'
			if conf then name=name+'_wCONF'
			end
		'vz'	: begin
			name = 'dsc_h1_fc_V_GSE_z'
			if conf then name=name+'_wCONF'
			end
		'vgse': begin
			name = 'dsc_h1_fc_V_GSE'
			if conf then name=name+'_wCONF'
			end
		'v' 	:	name = 'dsc_h1_fc_V'
		'vphi' 	:	name = 'dsc_h1_fc_V_GSE_PHI'
		'vtheta' 	:	name = 'dsc_h1_fc_V_GSE_THETA'
		'np'	: begin
			name = 'dsc_h1_fc_Np'
			if conf then name=name+'_wCONF'
			end
		'temp': begin
			name = 'dsc_h1_fc_THERMAL_TEMP'
			if conf then name=name+'_wCONF'
			end
		'vth'	: begin
			name = 'dsc_h1_fc_THERMAL_SPD'
			if conf then name=name+'_wCONF'
			end
		'pos'	: name = 'dsc_orbit_GSE_POS'
		'posx': name = 'dsc_orbit_GSE_POS_x'
		'posy': name = 'dsc_orbit_GSE_POS_y'
		'posz': name = 'dsc_orbit_GSE_POS_z'
		else	: begin
			name = '' 
			dprint,dlevel=2,verbose=verbose,rname+": '"+varin[i].toString()+"' not recognized"
			end
	endcase
	names = [names,name]
endfor

if (names.length eq 1) then return,name else return,names
END
