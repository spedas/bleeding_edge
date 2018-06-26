;+
;FUNCTION:  omni4d
;PURPOSE:  produces an omnidirectional spectrum structure by summing
; over the non-zero bins in the keyword bins.
; this structure can be plotted with "spec3d"
;
;CREATED BY:	McFadden from omni3d.pro
;LAST MODIFICATION:	14/01/31
;
; WARNING:  This is a very crude structure; use at your own risk.
;-

function omni4d,inpdat,bins=bins,mass=ms,m_int=mi            

; needs fixing -- should not sum flux -- should average 

dat = inpdat
units = dat.units_name
if size(/type,dat) ne 8 then return,0
if dat.valid eq 0 then return,{valid:0}
if dat.nmass eq 1 and dat.nbins eq 1 then return,dat

att = dat.att_ind
mode = dat.mode
ndef = dat.ndef
nenergy = dat.nenergy

rad = (total(dat.pos_sc_mso^2))^.5 
if rad gt (3386.+100.) then alt = (rad-3386.) else alt=300.			; default allows tf_att to be true when pos_sc_mso is not loaded
tf_att = (((alt lt 500.) and (att ge 1)) or ((mode eq 1) or (mode eq 2))) and (dat.nbins eq 64)

tags = ['project_name','spacecraft','data_name','apid','units_name','units_procedure','valid','quality_flag',  $
	'time','end_time', 'delta_t', 'integ_t', $ 
	'mode', 'rate', 'swp_ind', 'mlut_ind', 'eff_ind', 'att_ind', $
	'nenergy', 'nbins', 'ndef' ,'nanode', 'geom_factor', 'dead1', 'dead2','dead3',$
	'nmass', 'mass', 'charge', 'sc_pot',$
	'magf','quat_sc','quat_mso','pos_sc_mso']

extract_tags,omni,dat,tags=tags

	omni.nbins = 1 
	omni.integ_t = dat.integ_t * ndef				

if keyword_set(ms) then begin
	if n_elements(ms) eq 1 then count=0 else ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then dat.data[ind]=0.
	if count ne 0 then dat.cnts[ind]=0.
	omni.nmass = 1
endif else omni.nmass = dat.nmass
	nmass=omni.nmass

	dtheta = (max(dat.theta)-min(dat.theta))*(dat.ndef+1)/dat.ndef
	dphi = 360.

; this sections could be improved so that when the bins keyword is set, dphi and dtheta represent the correct solid angle

if not keyword_set(bins) then begin			
	bins = replicate(1b,dat.nbins)
	bins2 = replicate(1b,dat.nbins)
	if tf_att then begin			; if tf_att, assume all counts in 3 anodes in ram direction
		bins2[*]=0b
		if mode eq 1 then ind2=[29,30] else ind2=[25,26,29,30,33,34]
		bins2[ind2]=1b
		nbins2=n_elements(ind2)
		dphi = 67.5 * nbins2/6.
		dtheta = dtheta/2.
	endif
endif else begin
	bins2=bins
	if tf_att then begin			; if tf_att, assume all counts in 3 anodes in ram direction
		bins2[*]=0b
		if mode eq 1 then ind2=[29,30] else ind2=[25,26,29,30,33,34]
		bins2[ind2]=1b
		nbins2=n_elements(ind2)
		dphi = 67.5 * nbins2/6.
		dtheta = dtheta/2.
	endif
endelse

	str_element,/add,omni, 'theta',reform(fltarr(nenergy,nmass))
	str_element,/add,omni, 'dtheta',reform(reform(replicate(dtheta,nenergy*nmass),nenergy,nmass))
	str_element,/add,omni, 'phi',reform(fltarr(nenergy,nmass))
	str_element,/add,omni, 'dphi',reform(reform(replicate(dphi,nenergy*nmass),nenergy,nmass))
		domega=4.*!pi*(dphi/360.)*sin(dtheta/!radeg/2.)
	str_element,/add,omni,  'domega',reform(reform(replicate(domega,nenergy*nmass),nenergy,nmass))
	
ind = where(bins,count)
ind2 = where(bins2,count2)

if count eq 0 then return,omni

norm = count

if omni.nmass eq 1 then begin

; the following line may need fixing
	if dat.apid eq 'C8' then str_element,/add,omni,'mass_arr',min(dat.mass_arr) else str_element,/add,omni,'mass_arr',1.

if ndimen(dat.data) eq 2 and dat.nbins gt 1 then begin

	str_element,/add,omni, 'denergy' ,reform(dat.denergy[*,0])
	str_element,/add,omni, 'energy'  ,reform(dat.energy[*,0])
	str_element,/add,omni, 'bins'    ,1
	str_element,/add,omni, 'bins_sc' ,1
	str_element,/add,omni, 'data'    ,total(dat.data[*,ind],2)
	str_element,/add,omni, 'cnts'    ,total(dat.cnts[*,ind],2)
	str_element,/add,omni, 'bkg'     ,total(dat.bkg[*,ind],2)
	str_element,/add,omni, 'gf'      ,total(dat.gf[*,ind2],2)/ndef
	str_element,/add,omni, 'eff'     ,total(dat.eff[*,ind],2)/count
	str_element,/add,omni, 'dead'    ,total(dat.dead[*,ind]*dat.dead[*,ind],2)/total(dat.dead[*,ind],2)

endif else if ndimen(dat.data) eq 2 and dat.nbins eq 1 then begin

	str_element,/add,omni, 'denergy' ,reform(dat.denergy[*,0])
	str_element,/add,omni, 'energy'  ,reform(dat.energy[*,0])
	str_element,/add,omni, 'bins'    ,1
	str_element,/add,omni, 'bins_sc' ,1
	str_element,/add,omni, 'data'    ,total(dat.data[*,*],2)
	str_element,/add,omni, 'cnts'    ,total(dat.cnts[*,*],2)
	str_element,/add,omni, 'bkg'     ,total(dat.bkg[*,*],2)
	str_element,/add,omni, 'gf'      ,total(dat.gf[*,*],2)/dat.nmass/ndef
	str_element,/add,omni, 'eff'     ,total(dat.eff[*,*],2)/dat.nmass
	str_element,/add,omni, 'dead'    ,reform(dat.dead[*,0])

endif else if ndimen(dat.data) eq 3 then begin

	str_element,/add,omni, 'denergy' ,reform(dat.denergy[*,0,0])
	str_element,/add,omni, 'energy'  ,reform(dat.energy[*,0,0])
	str_element,/add,omni, 'bins'    ,1
	str_element,/add,omni, 'bins_sc' ,1
	str_element,/add,omni, 'data'    ,total(total(dat.data[*,ind,*],3),2)
	str_element,/add,omni, 'cnts'    ,total(total(dat.cnts[*,ind,*],3),2)
	str_element,/add,omni, 'bkg'     ,total(total(dat.bkg[*,ind,*],3),2)
	str_element,/add,omni, 'gf'      ,total(total(dat.gf[*,ind2,*],3),2)/dat.nmass/ndef
	str_element,/add,omni, 'eff'     ,total(total(dat.eff[*,ind,*],3),2)/dat.nmass/count
	str_element,/add,omni, 'dead'    ,reform(total(dat.dead[*,ind,0]*dat.dead[*,ind,0],2))/reform(total(dat.dead[*,ind,0],2))

endif
	if not keyword_set(mi) then mi=1.
	str_element,/add,omni, 'mass_arr',reform(reform(replicate(mi,nenergy*nmass),nenergy,nmass))

endif else begin

if ndimen(dat.data) eq 2 then begin

	return,dat

endif else if ndimen(dat.data) eq 3 then begin

	str_element,/add,omni, 'denergy' ,reform(dat.denergy[*,0,*],dat.nenergy,dat.nmass)
	str_element,/add,omni, 'energy'  ,reform(dat.energy[*,0,*],dat.nenergy,dat.nmass)
	str_element,/add,omni, 'mass_arr',reform(dat.mass_arr[*,0,*],dat.nenergy,dat.nmass)
	str_element,/add,omni, 'tof_arr' ,reform(dat.tof_arr[*,0,*],dat.nenergy,dat.nmass)
	str_element,/add,omni, 'twt_arr' ,reform(dat.twt_arr[*,0,*],dat.nenergy,dat.nmass)
	str_element,/add,omni, 'bins'    ,1
	str_element,/add,omni, 'bins_sc' ,1
	str_element,/add,omni, 'data'    ,total(dat.data[*,ind,*],2)
	str_element,/add,omni, 'cnts'    ,total(dat.cnts[*,ind,*],2)
	str_element,/add,omni, 'bkg'     ,total(dat.bkg[*,ind,*],2)
	str_element,/add,omni, 'gf'      ,total(dat.gf[*,ind2,*],2)/ndef
	str_element,/add,omni, 'eff'     ,total(dat.eff[*,ind,*],2)/count
	str_element,/add,omni, 'dead'    ,total(dat.dead[*,ind,*]*dat.dead[*,ind,*],2)/total(dat.dead[*,ind,*],2)

	if keyword_set(mi) then omni.mass_arr[*]=mi
endif

endelse

return,omni
end






