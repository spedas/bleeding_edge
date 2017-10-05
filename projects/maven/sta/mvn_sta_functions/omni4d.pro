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

function omni4d,inpdat,bins=bins,mass=mass            

; needs fixing -- should not sum flux -- should average 

dat = inpdat
units = dat.units_name
if size(/type,dat) ne 8 then return,0
if dat.valid eq 0 then return,{valid:0}
if dat.nmass eq 1 and dat.nbins eq 1 then return,dat


tags = ['project_name','spacecraft','data_name','apid','units_name','units_procedure','valid','quality_flag',  $
	'time','end_time', 'delta_t', 'integ_t', $ 
	'md', 'mode', 'rate', 'swp_ind', 'mlut', 'att', $
	'nenergy', 'nbins', 'ndef' ,'nanode', 'geom_factor', 'nmass', 'mass', $
	'charge', 'sc_pot',$
	'magf','quat_sc','quat_mso','pos_sc_mso']

extract_tags,omni,dat,tags=tags

	omni.nbins = 1 					

if keyword_set(bins) eq 0 then bins = replicate(1b,dat.nbins)
ind = where(bins,count)
if count eq 0 then return,omni

norm = count

	str_element,/add,omni, 'theta',0.
	str_element,/add,omni, 'dtheta',90.
	str_element,/add,omni, 'phi',0.
	str_element,/add,omni, 'dphi',360.
	str_element,/add,omni, 'domega',2.^.5*2.*!pi


if keyword_set(mass) then omni.nmass = dat.nmass else omni.nmass = 1

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
	str_element,/add,omni, 'gf'      ,total(dat.gf[*,ind],2)
	str_element,/add,omni, 'eff'     ,total(dat.eff[*,ind],2)/norm
	str_element,/add,omni, 'dead'    ,total(dat.dead[*,ind]*dat.dead[*,ind],2)/total(dat.dead[*,ind],2)

endif else if ndimen(dat.data) eq 2 and dat.nbins eq 1 then begin

	str_element,/add,omni, 'denergy' ,reform(dat.denergy[*,0])
	str_element,/add,omni, 'energy'  ,reform(dat.energy[*,0])
	str_element,/add,omni, 'bins'    ,1
	str_element,/add,omni, 'bins_sc' ,1
	str_element,/add,omni, 'data'    ,total(dat.data[*,*],2)
	str_element,/add,omni, 'cnts'    ,total(dat.cnts[*,*],2)
	str_element,/add,omni, 'bkg'     ,total(dat.bkg[*,*],2)
	str_element,/add,omni, 'gf'      ,total(dat.gf[*,*],2)/dat.nmass
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
	str_element,/add,omni, 'gf'      ,total(total(dat.gf[*,ind,*],3),2)/dat.nmass
	str_element,/add,omni, 'eff'     ,total(total(dat.eff[*,ind,*],3),2)/dat.nmass/norm
	str_element,/add,omni, 'dead'    ,reform(total(dat.dead[*,ind,0]*dat.dead[*,ind,0],2))/reform(total(dat.dead[*,ind,0],2))

endif

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
	str_element,/add,omni, 'gf'      ,total(dat.gf[*,ind,*],2)
	str_element,/add,omni, 'eff'     ,total(dat.eff[*,ind,*],2)/dat.nbins
	str_element,/add,omni, 'dead'    ,total(dat.dead[*,ind,*]*dat.dead[*,ind,*],2)/total(dat.dead[*,ind,*],2)

endif

endelse

return,omni
end






