;+
;FUNCTION:  sum4m
;PURPOSE:  produces an omnidirectional spectrum structure by summing
; over the non-zero bins in the keyword bins.
; this structure can be plotted with "spec3d"
;
;CREATED BY:	McFadden from omni4d.pro
;LAST MODIFICATION:	14/02/04
;
; WARNING:  This is a very crude structure; use at your own risk.
;-

function sum4m,inpdat,mass=ms,m_int=mi         

if not inpdat.valid then return,inpdat

dat = inpdat
units = dat.units_name
if size(/type,dat) ne 8 then return,0
if dat.valid eq 0 then return,{valid:0}
value=0 & str_element,dat,'nmass',value
	if value eq 0 then return,dat
	if value eq 1 and ndimen(dat.data) le 2 and dat.data_name ne 'C8 Energy-Angle-Mass' then return,dat

tags = ['project_name','spacecraft','data_name','apid','units_name','units_procedure','valid',  $
	'quality_flag','time','end_time', 'delta_t', 'integ_t', $ 
	'md', 'mode', 'rate', 'swp_ind', 'mlut_ind', 'eff_ind', 'att_ind', $
	'nenergy', 'nbins', 'ndef' ,'nanode', 'geom_factor','dead1','dead2','dead3','nmass', 'mass', $
	'charge', 'sc_pot',$
	'magf','quat_sc','quat_mso','pos_sc_mso']

extract_tags,omni,dat,tags=tags

	nbins = dat.nbins
	nenergy = dat.nenergy
	omni.nmass = 1

if keyword_set(ms) then begin
	ind = where(dat.mass_arr lt ms[0] or dat.mass_arr gt ms[1],count)
	if count ne 0 then dat.data[ind]=0.
	if count ne 0 then dat.cnts[ind]=0.
endif

if keyword_set(mi) then omni.mass = mi*dat.mass 
	str_element,/add,omni, 'mass_arr',reform(reform(replicate(1.,nenergy*nbins),nenergy,nbins))

if dat.data_name eq 'C8 Energy-Angle-Mass' then begin

	str_element,/add,omni, 'theta',reform(dat.theta)
	str_element,/add,omni, 'dtheta',reform(dat.dtheta)
	str_element,/add,omni, 'phi',dat.phi
	str_element,/add,omni, 'dphi',dat.dphi
	str_element,/add,omni, 'domega',reform(dat.domega)
	str_element,/add,omni, 'denergy',reform(dat.denergy)
	str_element,/add,omni, 'energy' ,reform(dat.energy)
	str_element,/add,omni, 'bins',dat.bins
	str_element,/add,omni, 'bins_sc',dat.bins_sc
	str_element,/add,omni, 'gf'   ,reform(dat.gf)
	str_element,/add,omni, 'eff'   ,reform(dat.eff)
	str_element,/add,omni, 'bkg'    ,reform(dat.bkg)
	str_element,/add,omni, 'dead'    ,reform(dat.dead)
	str_element,/add,omni, 'cnts'    ,reform(dat.cnts)
	str_element,/add,omni, 'data'   ,reform(dat.data)

endif else if ndimen(dat.data) eq 2 and dat.nbins eq 1 then begin

	str_element,/add,omni, 'theta',reform(dat.theta[*,0])
	str_element,/add,omni, 'dtheta',reform(dat.dtheta[*,0])
	str_element,/add,omni, 'phi',reform(dat.phi[*,0])
	str_element,/add,omni, 'dphi',reform(dat.dphi[*,0])
	str_element,/add,omni, 'domega',reform(dat.domega[*,0])
	str_element,/add,omni, 'denergy',reform(dat.denergy[*,0])
	str_element,/add,omni, 'energy' ,reform(dat.energy[*,0])
	str_element,/add,omni, 'bins',dat.bins
	str_element,/add,omni, 'bins_sc',dat.bins_sc
	str_element,/add,omni, 'gf'   ,total(dat.gf[*,*],2)/dat.nmass
	str_element,/add,omni, 'eff'   ,total(dat.eff[*,*],2)/dat.nmass
	str_element,/add,omni, 'bkg'    ,total(dat.bkg[*,*],2)
	str_element,/add,omni, 'dead'   ,total(dat.dead[*,*],2)/dat.nmass
	str_element,/add,omni, 'cnts'   ,total(dat.cnts[*,*],2)
	str_element,/add,omni, 'data'   ,total(dat.data[*,*],2)

endif else if ndimen(dat.data) eq 3 then begin

	str_element,/add,omni, 'theta',reform(dat.theta[*,*,0],dat.nenergy,dat.nbins)
	str_element,/add,omni, 'dtheta',reform(dat.dtheta[*,*,0],dat.nenergy,dat.nbins)
	str_element,/add,omni, 'phi',reform(dat.phi[*,*,0],dat.nenergy,dat.nbins)
	str_element,/add,omni, 'dphi',reform(dat.dphi[*,*,0],dat.nenergy,dat.nbins)
	str_element,/add,omni, 'domega',reform(dat.domega[*,*,0],dat.nenergy,dat.nbins)

	str_element,/add,omni, 'denergy',reform(dat.denergy[*,*,0],dat.nenergy,dat.nbins)
	str_element,/add,omni, 'energy' ,reform(dat.energy[*,*,0],dat.nenergy,dat.nbins)
	str_element,/add,omni, 'bins',dat.bins
	str_element,/add,omni, 'bins_sc',dat.bins_sc
	str_element,/add,omni, 'gf'     ,reform(total(  dat.gf[*,*,*],3),dat.nenergy,dat.nbins)/dat.nmass
	str_element,/add,omni, 'eff'    ,reform(total( dat.eff[*,*,*],3),dat.nenergy,dat.nbins)/dat.nmass
	str_element,/add,omni, 'bkg'    ,reform(total( dat.bkg[*,*,*],3),dat.nenergy,dat.nbins)
	str_element,/add,omni, 'dead'    ,reform(total( dat.dead[*,*,*],3),dat.nenergy,dat.nbins)/dat.nmass
	str_element,/add,omni, 'cnts'    ,reform(total( dat.cnts[*,*,*],3),dat.nenergy,dat.nbins)
	str_element,/add,omni, 'data'   ,reform(total(dat.data[*,*,*],3),dat.nenergy,dat.nbins)

endif

return,omni
end






