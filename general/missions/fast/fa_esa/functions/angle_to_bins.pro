;+
;FUNCTION:	angle_to_bins(dat,an,EBIN=ebin)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_eesa_surv, get_eesa_burst, etc.
;	an:	fltarr(2),	2D - min,max pitch angle limits (0-360 deg) 
;		fltarr(2,2),	3D - array of (theta,phi) angle values 
;				theta min,max (0,0),(1,0) -90<theta<90, thmin<thmax
;				phi   min,max (0,1),(1,1)   0<phi<360
;KEYWORD:
;	EBIN	int		optional, energy bin corresponding to "an"
;				used when angles depend upon energy bin
;PURPOSE:
;	Returns the angle "bins" array defined by "an" limits
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:
;	96-4-25		J.McFadden
;	96-8-27		J.McFadden	Changed algorithm to include (mod 360.) and
;					handle arbitrary order in dat.theta or dat.phi
;-
function angle_to_bins,dat,an,EBIN=ebin2

if dat.valid eq 0 then begin
  print,'Invalid Data'
  return, !values.f_nan
endif

if keyword_set(ebin2) and dimen(ebin2) ne 1 then begin
	print,' Error: ebin must be an integer!'
	return,!values.f_nan
endif

if keyword_set(ebin2) then ebin=ebin2 else ebin=fix(dat.nenergy/2)

if ndimen(an) le 1 then begin
	andim=dimen1(an)
	if andim ne 2 then begin
		print,'Error in angle_to_bins: dimen1(an) must equal 2'
		return,!values.f_nan
	endif else begin
		theta = reform(dat.theta(ebin,*))
		theta = 360.*(theta/360.-floor(theta/360.))
		th = 360.*(an/360.-floor(an/360.))
		if th(0) lt th(1) then begin
			bins = theta ge th(0) and theta lt th(1)
		endif else if th(0) gt th(1) then begin
			bins = theta ge th(0) or theta lt th(1)
		endif else if an(0) ne an(1) then begin
			bins = bytarr(dat.nbins)
			bins(*)=1
		endif else begin
			bins = bytarr(dat.nbins)
			tmp=min(abs(abs(abs(theta-th(0))-180.)-180.),indmin)
			bins(indmin)=1
		endelse
		return,bins
	endelse
endif else begin
	andim=dimen1(an)
	if andim ne 2 then begin
		print,'Error in angle_to_bins: dimen1(an) must equal 2'
		return,!values.f_nan
	endif else begin
		theta = reform(dat.theta(ebin,*))
		th = reform(an(*,0))
		if th(0) gt th(1) or th(0) lt -90. or th(1) gt 90. then begin
			print,'Error in angle_to_bins: -90. <= theta <= 90.'
			return,!values.f_nan
		endif
		phi   = reform(dat.phi(ebin,*))
		phi   = 360.*(phi/360.-floor(phi/360.))
		ph = reform(an(*,1))
		ph = 360.*(ph/360.-floor(ph/360.))
		if th(0) ne th(1) then begin
			if ph(0) lt ph(1) then begin
				bins = (phi ge ph(0) and phi lt ph(1)) and (theta ge th(0) and theta lt th(1))
			endif else if ph(0) gt ph(1) then begin
				bins = (phi ge ph(0) or phi lt ph(1)) and (theta ge th(0) and theta lt th(1))
			endif else if an(0,1) ne an(1,1) then begin
				bins = (theta ge th(0) and theta lt th(1))
			endif else begin
				bins = bytarr(dat.nbins)
				tmp=min(abs(abs(abs(phi-ph(0))-180.)-180.),indmin)
				phmin = phi(indmin)
				bins = (phi eq phmin) and (theta ge th(0) and theta lt th(1))
			endelse
		endif else begin
			tmp=min(abs(theta-th(0)),indmin)
			thmin=theta(indmin)
			if ph(0) lt ph(1) then begin
				bins = (phi ge ph(0) and phi lt ph(1)) and (theta eq thmin)
			endif else if ph(0) gt ph(1) then begin
				bins = (phi ge ph(0) or phi lt ph(1)) and (theta eq thmin)
			endif else if an(0,1) ne an(1,1) then begin
				bins = (theta eq thmin)
			endif else begin
				bins = bytarr(dat.nbins)
				tmp=min((abs(abs(phi-ph(0))-180.)-180.)^2+(theta-th(0))^2,indmin)
				bins(indmin)=1
			endelse
		endelse
		return,bins
	endelse
endelse

end
