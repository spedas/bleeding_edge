;+
;FUNCTION:  omni2d
;
;PURPOSE:  
;	Produces an energy or angle averaged data structure
;	Summing is over pitch angle or energy, default is pitch angle summing.
; 	This structure can be plotted with spec2d or pitch2d.
;
;KEYWORDS:
;	ANGLE:		intarr(n)		n=1 nearest angle to be summed
;						n=2 angle range to be summed
;						n>2 angle list to be summed
;	ARANGE:		intarr(2)		angle bin range to be summed
;	BINS   - 	bytarr(dat.nbins)	angle bins to be summed  
;	ENERGY:		fltarr(2)		energy range to be summed
;	ERANGE:		intarr(2)		energy bin range to be summed
;	EBINS:		bytarr(dat.nenergy)	energy bins to be summed
;
; NOTE:	If no keyword is set, then sum over all angle to form energy spectrum
;
;CREATED BY:	J.McFadden
;LAST MODIFICATION:  97-3-3
;MOD HISTORY
;		97/03/03	ANGLE,ARANGE,ENERGY,ERANGE,EBINS keywords added
;-

function omni2d,dat,  $
	ANGLE = an, $
	ARANGE = ar, $
	BINS = bins,     $
	ENERGY = en, $
	ERANGE = er, $
	EBINS = ebins


if data_type(dat) ne 8 then return,0
if dat.valid eq 0 then return,{valid:0}

; Sum over energies if ENERGY,ERANGE, or EBINS set

if keyword_set(en) then begin
	if dimen1(en) eq 1 then begin
		if en eq 1 then er=energy_to_ebin(dat,[0,max(dat.energy)]) else $
			er=energy_to_ebin(dat,en)
	endif else er=energy_to_ebin(dat,en)
endif
if keyword_set(er) then begin
	ebins=bytarr(dat.nenergy)
	if er(0) gt er(1) then er=reverse(er)
	ebins(er(0):er(1))=1
endif

if keyword_set(ebins) then begin
	tags = ['data_name','valid','project_name','units_name','units_procedure',  $
	  'time','end_time', 'integ_t',  'nbins','nenergy',  $
	     'mass','geom_factor']
	extract_tags,omni,dat,tags=tags
	ind = where(ebins,count)
	if count eq 1 then begin
		if ebins eq 1 then begin
			ind=indgen(dat.nenergy)
			count=dat.nenergy
		endif
	endif
	if count eq 0 then return,omni

	add_str_element,omni, 'data'   	,total(dat.data(ind,*),1)
	add_str_element,omni, 'energy' 	,total(dat.energy(ind,*),1)/count
	add_str_element,omni, 'theta' 	,total(dat.theta(ind,*),1)/count
	add_str_element,omni, 'denergy' ,total(dat.denergy(ind,*),1)
	add_str_element,omni, 'eff' 	,total(dat.eff(ind,*),1)/count
	add_str_element,omni, 'bins'   	,total(dat.bins(ind,*),1)/count
	add_str_element,omni, 'ddata'  	,sqrt(total(dat.data(ind,*),1) > .7)
	add_str_element,omni, 'gf'  	,total(dat.gf(ind,*),1)/count
	add_str_element,omni, 'dtheta'  ,total(dat.dtheta(ind,*),1)/count
	add_str_element,omni, 'eff'  	,total(dat.eff(ind,*),1)/count
	add_str_element,omni, 'dead'  	,dat.dead
	omni.integ_t = omni.integ_t*count
	omni.nenergy = 1

	return,omni
endif

; Sum over pitch angles

bins2=replicate(1b,dat.nbins)
if keyword_set(an) then begin
	if ndimen(an) gt 1 then begin
		print,'Error - angle keyword must be fltarr(n)'
	endif else begin
		if dimen1(an) eq 1 then bins2=angle_to_bins(dat,[an,an])
		if dimen1(an) eq 2 then bins2=angle_to_bins(dat,an)
		if dimen1(an) gt 2 then begin 
			ibin=angle_to_bin(dat,an)
			bins2(*)=0 & bins2(ibin)=1
		endif
	endelse
endif
if keyword_set(ar) then begin
	bins2(*)=0
	if ar(0) gt ar(1) then begin
		bins2(ar(0):nb-1)=1
		bins2(0:ar(1))=1
	endif else begin
		bins2(ar(0):ar(1))=1
	endelse
endif

if keyword_set(bins) then bins2=bins
tags = ['data_name','valid','project_name','units_name','units_procedure',  $
	  'time','end_time', 'integ_t',  'nbins','nenergy',  $
	     'mass','geom_factor']
extract_tags,omni,dat,tags=tags
ind = where(bins2,count)
if count eq 0 then return,omni

	add_str_element,omni, 'data'   	,total(dat.data(*,ind),2)
	add_str_element,omni, 'energy' 	,total(dat.energy(*,ind),2)/count
	add_str_element,omni, 'theta'  	,total(dat.theta(*,ind),2)/count
	add_str_element,omni, 'denergy'	,total(dat.denergy(*,ind),2)/count
	add_str_element,omni, 'eff'    	,total(dat.eff(*,ind),2)/count
	add_str_element,omni, 'bins'   	,total(dat.bins(*,ind),2)/count
	add_str_element,omni, 'ddata'  	,sqrt(total(dat.data(*,ind),2) > .7)
	add_str_element,omni, 'gf'   	,total(dat.gf(*,ind),2)/count
	add_str_element,omni, 'dtheta' 	,total(dat.dtheta(*,ind),2)
	add_str_element,omni, 'eff'  	,total(dat.eff(*,ind),2)/count
	add_str_element,omni, 'dead'  	,dat.dead
	omni.integ_t = omni.integ_t*count
	omni.nbins = 1
;	if dat.nbins eq 64 and dat.project_name eq 'FAST' and dat.data_name ne 'Tms Survey Proton' then begin
;		omni.integ_t=2.*omni.integ_t
;		omni.geom_factor=omni.geom_factor/2.
;	endif

return,omni

end

