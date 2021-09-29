;+
;NAME: DSC_GET_YLIMITS
;
;DESCRIPTION:  
; Calculates appropriate ylimits for a string array of TPLOT variables
; to be plotted in the same panel.
; 
;INPUT:  
; DATASTR: String array of TPLOT variables
; LIMITS:  Limits structure to be modified (usually the limits
;            structure of the TPLOT variable whose data
;            field is a string array of TPLOT variables)
; TRG:     Time range over which to calculate the limits (double[2])
;
;KEYWORDS: (Optional)
; BUFF:          Set to add a 10% buffer to yrange.  Default is exact to data min/max.
; COMP=:         Indicate with vector component to range over.  (int) Ignored for scalar variables.
; INCLUDE_ERROR: Set to include the data.dy in the range calculation
; VERBOSE=:      Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;
;OUTPUTS:
; LIMITS.yrange is created or modified.
; 
;EXAMPLES:
;		dsc_get_ylimits,'dsc_h0_mag_B1F1',limstr,trg
;		dsc_get_ylimits,'dsc_h1_fc_V_GSE_x',limstr,trg,/inc,/buff
;		
;		tn = dsc_ezname(['vx','vy','b','temp'])
;		dsc_get_ylimits,tn,limstr,trg,/buff	 ;All variables set to the same yrange
;
;NOTES:
; Adapted from TPLOT 'get_ylimits' procedure. 
;   -Added support for limit based on single component of a vector
;   -Added /BUFF flag for 10% buffer in y-range
;   -Added /INCLUDE_ERROR flag to include any 'dy' in the min/max calculations
;	
;ADAPTED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/misc/dsc_get_ylimits.pro $
;-

PRO DSC_GET_YLIMITS,DATASTR,LIMITS,TRG,COMP=comp,INCLUDE_ERROR=inc_err,BUFF=buff,VERBOSE=verbose

COMPILE_OPT IDL2

dsc_init
rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose

limits = []
miny = 0.
maxy = 0.
str_element,limits,'min_value',min_value
str_element,limits,'max_value',max_value
str_element,limits,'ylog',ytype

for i=0,n_elements(datastr)-1 do begin
	get_data,datastr[i],data=data,dtype=dtype
	if (dtype eq 3) and keyword_set(data) then begin
		dsc_get_ylimits,data,limstr,trg,comp=comp,include_err=inc_err,verbose=verbose ;don't add buffer repeatedly
		if miny ne maxy then begin
			if limstr.yrange[0] lt miny then miny = limstr.yrange[0]
			if limstr.yrange[1] gt maxy then maxy = limstr.yrange[1]
		endif else begin
			miny = limstr.yrange[0]
			maxy = limstr.yrange[1]
		endelse
	endif else if (dtype eq 1) and keyword_set(data) then begin
		good = where(finite(data.x),count)
		if count eq 0 then message,'No valid X data'
	
		ind = where(data.x[good] ge trg[0] and data.x[good] le trg[1],count)
		if count eq 0 then ind = indgen(n_elements(data.x)) else ind = good[ind]

		ysize = size(data.y) 
		if (ysize[0] eq 2 and comp ne !null) then begin
			if ~isa(comp,/int) then begin
				dprint,dlevel=1,verbose=verbose,rname+": Bad component"
				return
			endif else if (comp ge ysize[2]) then begin
				dprint,dlevel=1,verbose=verbose,rname+": Component out of range"
				return
			endif else begin
				if keyword_set(inc_err) and tag_exist(data,'dy') then $
					yrange = minmax([data.y[ind,comp]+data.dy[ind,comp],data.y[ind,comp]-data.dy[ind,comp]],posi=ytype, max=max_value,min=min_value) $
				else yrange = minmax(data.y[ind,comp],posi=ytype, max=max_value,min=min_value)
			endelse
		endif else begin
			if keyword_set(inc_err) and tag_exist(data,'dy') then $
				yrange = minmax([data.y[ind,*]+data.dy[ind,*],data.y[ind,*]-data.dy[ind,*]],posi=ytype, max=max_value,min=min_value) $
			else yrange = minmax(data.y[ind,*],posi=ytype, max=max_value,min=min_value)
		endelse

		if miny ne maxy then begin
			if yrange[0] lt miny then miny = yrange[0]
			if yrange[1] gt maxy then maxy = yrange[1]
		endif else begin
			miny = yrange[0]
			maxy = yrange[1]
		endelse
	endif
endfor

ybuff = keyword_set(buff) ? (maxy-miny)*.05 : 0	
str_element,limits,'yrange',[miny-ybuff, maxy+ybuff],/add

END
