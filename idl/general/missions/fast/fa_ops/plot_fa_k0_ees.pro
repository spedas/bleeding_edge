;+
;PROCEDURE:	plot_fa_k0_ees.pro
;INPUT:	none
;
;PURPOSE:
;	Plots FAST electron key parameter data.
;
;	Plot 1: Electron Differential Energy Flux vs Energy, 0-45    deg pitch angle 
;	Plot 2: Electron Differential Energy Flux vs Energy, 45-135  deg pitch angle 
;	Plot 3: Electron Differential Energy Flux vs Energy, 135-180 deg pitch angle 
;	Plot 4: Electron Differential Energy Flux vs Pitch Angle, < 1 keV  
;	Plot 5: Electron Differential Energy Flux vs Pitch Angle, > 1 keV  
;	Plot 6: Electron Energy Flux - mapped to 100 km, positive earthward  
;	Plot 7: Electron Flux - mapped to 100 km, positive earthward  
;
;KEYWORDS
;
;NOTES:	
;	Run load_fa_k0_ees.pro first to get the k0 data
;
;CREATED BY:	J.McFadden		96-9-24
;VERSION:	1
;LAST MODIFICATION:  97-03-25
;MOD HISTORY:	
;	97-03-04	color=4 used for positive (earthward) Ji,JEi; color=6 used for negative Ji,JEi
;				upgrade for Ji,JEi definition changes - mapped to 100 km now
;	97-3-25		Lists multiple orbit numbers in title	
;-
pro plot_fa_k0_ees

	get_data,'ORBIT',data=tmp
	ntmp=n_elements(tmp.y)
	if ntmp gt 5 then begin
		orb=tmp.y(5)
		orbit_num=strcompress(string(orb),/remove_all)
		if ntmp gt 11 and orb ne tmp.y(ntmp-5) then begin
			orbit_num=orbit_num+'-'+strcompress(string(tmp.y(ntmp-5)),/remove_all)
		endif
	endif else begin
		orb=tmp.y(ntmp-1)
		orbit_num=strcompress(string(orb),/remove_all)
	endelse
	
	tplot,['el_0','el_90','el_180','el_low','el_high','JEe','Je'] $
	,var_label=['MLT','ALT','ILAT'],title='FAST Electrons  Orbit '+orbit_num

return
end
