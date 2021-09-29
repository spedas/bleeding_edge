;+
;NAME: DSC_SET_YTITLE
;
;DESCRIPTION:
; Sets sensible default ytitle for DSCOVR tplot variables
;
;INPUT:
; TVAR: TPLOT variable - either string or TPLOT variable number
;
;KEYWORDS: (Optional)
; METADATA=: Metadata structure to mine for sensible title information.
;	             If omitted, use the dlimits structure returned for TVAR
; VERBOSE=:  Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;
;OUTPUTS: 
; TITLE=: A named variable that will hold the ytitle string that has been set 
;
;EXAMPLE:
;		dsc_set_ytitle,'dsc_h1_fc_V_GSE',title=vtitle
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_set_ytitle.pro $
;-

PRO DSC_SET_YTITLE,TVAR,METADATA=md,TITLE=title,VERBOSE=verbose

COMPILE_OPT IDL2, HIDDEN

dsc_init
rname  = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose

if (tvar eq !NULL) then begin
	dprint,dlevel=1,verbose=verbose,rname+': You must supply a TPLOT variable. No ytitle set.'
	return
endif

dprint,dlevel=4,verbose=verbose,rname+': Setting title for tvar= ',tvar
tvar = ((isa(tvar,/int,/scalar)&&~isa(tvar,/BOOLEAN)) || isa(tvar,/string,/scalar)) ? tnames(tvar) : ''	
if tvar eq '' then begin
	dprint,dlevel=1,verbose=verbose,rname+': Argument is not a valid TPLOT variable'
	return
endif

title = tvar	;set ytitle to variable name if nothing better found
case tvar of
	'dsc_orbit_J2000_POS':    title = 'S/C Position (J2000)'
	'dsc_orbit_J2000_VEL':    title = 'S/C Velocity (J2000)'
	'dsc_orbit_GSE_POS':      title = 'S/C Position (GSE)'
	'dsc_orbit_MOON_GSE_POS': title = 'Moon Position (GSE)'
	'dsc_h0_mag_B1GSE':       title = 'B (GSE)'
	'dsc_h0_mag_B1SDGSE':     title = 'B_SIGMA (GSE)'
	'dsc_h0_mag_B1RTN':       title = 'B (RTN)'
	'dsc_h0_mag_B1SDRTN':     title = 'B_SIGMA (RTN)'
	'dsc_h1_fc_V':            title = 'V Magnitude'
	'dsc_h1_fc_V_GSE':        title = 'V (GSE)'
	else: begin
			if isa(md,'UNDEFINED') then get_data,tvar,dlimits=md $
				else begin
					if ~isa(md,'STRUCT') then begin
						dprint,dlevel=2,verbose=verbose,rname+': Metadata is not a structure. Using variable defaults'
						get_data,tvar,dlimits=md
					endif
			endelse
			haslabel = 0
			if tag_exist(md,'labels') then begin
				if size(md.labels,/n_dim) eq 0 then haslabel = 1
			endif
			if haslabel then begin
				if title.Matches('orbit') and ~md.labels.Matches('Moon') $
					then title = 'S/C '+md.labels.Trim() $
				else title=md.labels.Trim()
			endif else begin
				if tag_exist(md,'cdf') then $
					if tag_exist(md.cdf,'vatt') then $
						if tag_exist(md.cdf.vatt,'lablaxis') then title=md.cdf.vatt.lablaxis.Trim()	$
						else dprint,dlevel=2,verbose=verbose,rname+": No ytitle information for '"+title+"'. Using variable name." $
					else dprint,dlevel=2,verbose=verbose,rname+": No ytitle information for '"+title+"'. Using variable name." $
				else dprint,dlevel=2,verbose=verbose,rname+": No ytitle information for '"+title+"'. Using variable name."
			endelse
		end	
endcase

if title.Matches('( J2000| GSE| GCI| RTN)') then begin
	matchstr = title.Extract('( J2000| GSE| GCI| RTN)')
	foreach mtch,matchstr do title = title.Replace(matchstr,' ('+matchstr.Trim()+')')
endif
dprint,dlevel=4,verbose=verbose,rname+": Setting ytitle for '"+tvar+"' to '"+title+"'"

options,/def,tvar,ytitle=title
END