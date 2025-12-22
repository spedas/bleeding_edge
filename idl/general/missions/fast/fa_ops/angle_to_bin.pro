;+
;FUNCTION:	angle_to_bin(dat,an)
;INPUT:	
;	dat:	structure,	2d data structure filled by get_fa_ees, get_fa_eeb, etc.
;	an:	real,fltarr(i),	2D - real or float array of pitch angle values 
;		fltarr(i,2),	3D - theta=fltarr(*,0), phi=fltarr(*,1)
;KEYWORD:
;	EBIN	int,intarr(i)	optional, energy bins corresponding to "an"
;				used when angles depend upon energy bin
;PURPOSE:
;	Returns the angle bin numbers in "dat" nearest to "an"
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:
;	96-4-23		J.McFadden
;	96-8-27		J.McFadden	Changed algorithm to include (mod 360.) and
;					handle arbitrary order in dat.theta or dat.phi
;	98-4-24		J.McFadden	Corrected typos in documentation
;-
function angle_to_bin,dat,an,EBIN=ebin2

if dat.valid eq 0 then begin
  print,'Invalid Data'
  return, !values.f_nan
endif

if ndimen(an) le 1 then begin
	andim=dimen1(an)
	if andim eq 0 then begin
		if not keyword_set(ebin2) then ebin=fix(dat.nenergy/2.) else ebin=ebin2
		theta=reform(dat.theta(ebin,*))
		theta = 360.*(theta/360.-floor(theta/360.))
		th = 360.*(an/360.-floor(an/360.))
		tmp=min(abs(abs(abs(theta-th)-180.)-180.),bin)
		return,bin
	endif else begin
		bin=intarr(andim)
		ebin=intarr(andim)
		if not keyword_set(ebin2) then ebin(*)=fix(dat.nenergy/2.) else ebin(*)=ebin2
		for a=0,andim-1 do begin
			theta = reform(dat.theta(ebin(a),*))
			theta = 360.*(theta/360.-floor(theta/360.))
			th = 360.*(an(a)/360.-floor(an(a)/360.))
			tmp=min(abs(abs(abs(theta-th)-180.)-180.),ab)
			bin(a)=ab
		endfor
		return,bin
	endelse
endif else begin
	andim=dimen1(an)
	if andim eq 0 then begin
		if not keyword_set(ebin2) then ebin=fix(dat.nenergy/2.) else ebin=ebin2
		theta=reform(dat.theta(ebin,*))
		th=an(0,0)
		if th lt -90. or th gt 90. then begin
			print,'Error in angle_to_bin: -90. <= theta <= 90.'
			return,!values.f_nan
		endif
		phi = reform(dat.phi(ebin,*))
		phi = 360.*(phi/360.-floor(phi/360.))
		ph=an(0,1)
		ph = 360.*(ph/360.-floor(ph/360.))
		tmp=min((abs(abs(phi-ph)-180.)-180.)^2+(theta-th)^2,bin)
		return,bin
	endif else begin
		bin=intarr(andim)
		ebin=intarr(andim)
		if not keyword_set(ebin2) then ebin(*)=fix(dat.nenergy/2.) else ebin(*)=ebin2
		for a=0,andim-1 do begin
			theta=reform(dat.theta(ebin(a),*))
			th=an(a,0)
			if th lt -90. or th gt 90. then begin
				print,'Error in angle_to_bin: -90. <= theta <= 90.'
				return,!values.f_nan
			endif
			phi = reform(dat.phi(ebin(a),*))
			phi = 360.*(phi/360.-floor(phi/360.))
			ph=an(a,1)
			ph = 360.*(ph/360.-floor(ph/360.))
			tmp=min((abs(abs(phi-ph)-180.)-180.)^2+(theta-th)^2,ab)
			bin(a)=ab
		endfor
		return,bin
	endelse
endelse

end
