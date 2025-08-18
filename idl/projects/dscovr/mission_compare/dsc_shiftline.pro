;+
;NAME: DSC_SHIFTLINE
;
;DESCRIPTION:
;	Time shift one or more lines of a given TPLOT plot and display
;	shift amount on right side label.
;
;KEYWORDS: (Optional)   
; DYINFO=:      Structure holding dsc_dyplot parameters, as returned in the OLD_DYINFO 
;                 keyword to that routine.  Use this to call dsc_dyplot with these parameters.
; DSCDY:        Set this to draw DSCOVR confidence intervals for relevant data in all panels.
;                 dsc_dyplot options are based on tags in each variable's options structure.  
;                 i.e., it calls dsc_dyplot with no keywords.
;                 Supercedes the DYINFO= keyword.
; NEWVARS=:     Returns the names of any new tplot variable names created during this call. 
; PANEL=:       Scalar or Array of indices describing which panels will be targets for 
;                 time shifting. (1-indexed like TPLOT). Default is all panels. (Int)
; RESET:        Set this to return selected lines to initial, un-shifted, state.
; SHIFTSTRING=: A string representing the desired time shift, formatted to comply with the
;                 'dsc_time_absolute' class:
;                   Format: '#d#h#m#s#ms'
;                   You may leave out unit id strings, but not repeat them:
;                      OK     '3h2m'
;                      NOT OK '3h45m13m'
;                   Numbers must all be positive integers, with the execption of the leading negative.
;                      OK     '3d4h23m16s400ms'
;                      OK '-23h'
;                      NOT OK '15h-4m'
;                      NOT OK '15.4m'
;                 
;                 If value passed in SHIFTSTRING is scalar, this shift will be used for all panels 
;                 affected by the DSC_SHIFTLINE call.  If value is an array, it must be the same size 
;                 as the number of panels in this call.  In that case, each shift corresponds to the 
;                 associated panel. (String)
;                 
;                 For Example: 
;
;                   dsc_shiftline,varpattern='dsc',shiftstring='30m'
;                   	-- will shift all DSCOVR lines forward by 30 minutes for all the panels.
;
;                   dsc_shiftline,varpattern='dsc',shiftstring=['30m','-4h'],panel=[1,2]
;                     -- will shift the DSCOVR line in the first panel 30 minutes forward
;                        and the DSCOVR line in the second panel backward by 4 hours.
;                     
; TVINFO=:      Structure containing TPLOT variables information - as returned
;                 from the 'new_tvar' keyword to tplot. 
;                 If not set uses that found in common 'tplot_vars'
; VARPATTERN=:  A regex pattern used to match the tplot variable name to shift.  
;                 If value is scalar, this pattern will be used for all panels affected by
;                 this call.  If value is array, it must be the same size as the number of 
;                 panels in this call.  In that case, each pattern corresponds to the associated
;                 panel. (String)
;                 
;                 For Example: Given a multi-panel plot, each panel holding both DSCOVR and WIND data
;                 
;                   dsc_shiftline,varpattern='dsc',shiftstring='30m'
;                   	-- will shift all DSCOVR lines forward by 30 minutes for all the panels.
;                   	
;                   dsc_shiftline,varpattern=['dsc','wi'],shiftstring='30m',panel=[1,2]
;                     -- will shift the DSCOVR line in the first panel and the WIND line in the second panel.
;                     
; VERBOSE=:     Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;					
;CREATED BY: Ayris Narock (ADNET/GSFC) 2018
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/mission_compare/dsc_shiftline.pro $
;-

PRO DSC_SHIFTLINE,TVINFO=tvinfo,PANEL=panel,VARPATTERN=varpattern,SHIFTSTRING=shiftstr,RESET=reset,VERBOSE=verbose, $
	DYINFO=dyinfo,DSCDY=dscdy,NEWVARS=newvars
	
	COMPILE_OPT IDL2
	
	@tplot_com.pro
	
	dsc_init
	rname = dsc_getrname()
	if not isa(verbose,/int) then verbose=!dsc.verbose
	newvars = []

	catch, err
	if err ne 0 then begin
		if err eq -539 then begin
			dprint,dlevel=1,verbose=verbose,rname+': Invalid TPLOT Window reference. A TPLOT window must be open before calling this procedure.'
		endif else dprint,dlevel=1,verbose=verbose,rname+': '+!ERROR_STATE.MSG
		catch,/cancel
		return
	endif
	
	; Keyword checks
	;; TVINFO
	if isa(tvinfo,'UNDEFINED') then tvinfo=tplot_vars
	np = n_elements(tvinfo.options.varnames)

	;; PANEL
	if (~isa(panel,'UNDEFINED') && ~isa(panel,/INTEGER)) then begin
			dprint,dlevel=1,verbose=verbose,rname+': PANEL must be integer type'
			return
	endif
	panel = isa(panel,'UNDEFINED') ? indgen(np) : panel-1
	if max(panel) ge np then begin
		dprint,dlevel=1,verbose=verbose,rname+': PANEL number must be between 1 and '+np.toString()
		return
	endif

	;; VARPATTERN
	if isa(varpattern,'UNDEFINED') then varpattern = '.'
	
	;; SHIFTSTR
	if isa(shiftstr,'UNDEFINED') then shiftstr = '0s'
	
nselected_pan = n_elements(panel)
scalar_patt = isa(varpattern,/scalar) ? 1 : (n_elements(varpattern) eq nselected_pan) ? 0 : -1
scalar_shft = isa(shiftstr,/scalar) ? 1 : (n_elements(shiftstr) eq nselected_pan) ? 0 : -1
if (scalar_patt eq -1 || scalar_shft eq -1) then begin
	dprint,dlevel=1,verbose=verbose,rname+': Check Kewords-  VARPATTERN, SHIFTSTRING must be scalar or match number of selected panels.'
	return
endif

for i=0,n_elements(panel)-1 do begin
	ix_patt = (scalar_patt) ? 0 : i
	ix_shft = (scalar_shft) ? 0 : i		
	newnames = []

	shft_inc_obj = obj_new('dsc_time_absolute',shiftstr[ix_shft])
	if shft_inc_obj eq !NULL then begin
		dprint,dlevel=1,verbose=verbose,rname+': Bad shift string- PANEL '+(1+panel[i]).toString()
	endif else begin
		if (keyword_set(reset) || shft_inc_obj.toSeconds() ne 0) then begin	
			matches = []
			ix_matches = []
			get_data,tvinfo.options.varnames[panel[i]],data=d,limit=limit0,dlimit=dlimit0
			if isa(d,/string,/array) then begin
				foreach vname,d,j do if vname.Matches(varpattern[ix_patt]) then ix_matches = [ix_matches,j]
				matches = d[ix_matches]
			endif else if tvinfo.options.varnames[panel[i]] then matches = [matches,tvinfo.options.varnames[panel[i]]]
	
			foreach line,matches do begin
				shft_obj = shft_inc_obj.Copy()
				refvar = line
				get_data,line,data=dataline,dlim=dlimit,lim=limit,alim=alimit
				if tag_exist(alimit,'shift') then begin
					extract_tags,shft_prev,alimit,tags='shift'
					refvar = shft_prev.shift.refvar
					shft_obj = shft_prev.shift.amount + shft_inc_obj
					get_data,refvar,data=dataline,dlim=dlimit,lim=limit,alim=alimit
				endif
	
				if keyword_set(reset) || shft_obj.toSeconds() eq 0 then begin
					newnames = [newnames,refvar]
				endif else begin
					shft_str = shft_obj.isNeg() ? '' : '+'
					shft_str = shft_str+shft_obj.toString(/compact)
	
					str_element,dataline,'x',dataline.x+shft_obj.toSeconds(),/add_rep
					if ~tag_exist(alimit,'labels') then str_element,alimit,'labels',' ',/add_rep
					str_element,dlimit,'labels',alimit.labels+'!C '+shft_str,/add_rep
					str_element,dlimit,'labflag',-1
					str_element,limit,'labels',/del
					store_data,refvar+'SHIFT'+shft_str,data=dataline,dlim=dlimit,lim=limit
					options,/def,refvar+'SHIFT'+shft_str,shift={refvar:refvar, amount:shft_obj}
					newnames = [newnames,refvar+'SHIFT'+shft_str]				
				endelse
	
			endforeach
		
			if ~isa(matches,/NULL) then begin
				;----handle both compound and single var panels
				if (isa(d,/string,/array)) then begin	;multi-var panel
					dnew = d
					dnew[ix_matches] = newnames
					prefix = 'W'+(tvinfo.settings.window).toString()+'SHIFT_'
					if (tvinfo.options.varnames[panel[i]]).Matches('^'+prefix) $
						then compound_varname = tvinfo.options.varnames[panel[i]] $
						else compound_varname = prefix+tvinfo.options.varnames[panel[i]]   
					str_element,limit0,'labflag',/del
					str_element,dlimit0,'labflag',-1,/add_rep
					store_data,compound_varname,data=dnew,dlimit=dlimit0,limit=limit0
					tvinfo.options.varnames[panel[i]] = compound_varname
					tvinfo.settings.varnames[panel[i]] = compound_varname
				endif else begin	;single-var panel
					tvinfo.options.varnames[panel[i]] = newnames
					tvinfo.settings.varnames[panel[i]] = newnames
				endelse
			endif else begin
				dprint,dlevel=2,verbose=verbose,rname+': No variable matches, Panel '+(1+panel[i]).toString()
			endelse
		endif
	endelse
	newvars = [newvars,newnames]
endfor
tvinfo.options.datanames[0] = tvinfo.options.varnames[*].Join(' ')
tplot,old_tvars=tvinfo
if keyword_set(dscdy) then dsc_dyplot $
else if isa(dyinfo) then dsc_dyplot,old_dyinfo=dyinfo

END

