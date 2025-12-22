;+
;PROCEDURE:	plot_fa_k0_ies.pro
;INPUT:	none
;
;PURPOSE:
;	Plots FAST ion key parameter data.
;
;	Plot 1: Ion Differential Energy Flux vs Energy, 0-45    deg pitch angle 
;	Plot 2: Ion Differential Energy Flux vs Energy, 45-135  deg pitch angle 
;	Plot 3: Ion Differential Energy Flux vs Energy, 135-180 deg pitch angle 
;	Plot 4: Ion Differential Energy Flux vs Pitch Angle, < 1 keV  
;	Plot 5: Ion Differential Energy Flux vs Pitch Angle, > 1 keV  
;	Plot 6: Ion Energy Flux - mapped to 100 km, positive earthward  
;	Plot 7: Ion Flux - mapped to 100 km, positive earthward  
;
;KEYWORDS
;
;NOTES:	
;	Run load_fa_k0_ies.pro first to get the k0 data
;
;CREATED BY:	J.McFadden		96-9-24
;VERSION:	1
;LAST MODIFICATION:  97-03-25
;MOD HISTORY:	
;	97-03-04	color=4 used for positive (earthward) Ji,JEi; color=6 used for negative Ji,JEi
;				upgrade for Ji,JEi definition changes - mapped to 100 km now
;	97-3-25		Lists multiple orbit numbers in title	
;-
pro plot_fa_k0_ies

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

	tplot,['ion_0','ion_90','ion_180','ion_low','ion_high','JEi','Ji'] $
	,var_label=['MLT','ALT','ILAT'],title='FAST Ions  Orbit '+orbit_num

return
end

