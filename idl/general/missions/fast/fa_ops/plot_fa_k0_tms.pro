;+
;PROCEDURE:	plot_fa_k0_tms.pro
;INPUT:	none
;
;PURPOSE:
;	Plots FAST TEAMS key parameter data.
;
;	Plot 1: Hydrogen Differential Energy Flux vs Energy, 0-360    deg pitch angle 
;	Plot 2: Oxygen   Differential Energy Flux vs Energy, 0-360  deg pitch angle 
;	Plot 3: Hydrogen Differential Energy Flux vs Pitch Angle, < 1 keV  
;	Plot 4: Hydrogen Differential Energy Flux vs Pitch Angle, > 1 keV  
;	Plot 5: Oxygen   Differential Energy Flux vs Pitch Angle, < 1 keV  
;	Plot 6: Oxygen   Differential Energy Flux vs Pitch Angle, > 1 keV  
;	Plot 7: MassSpectrum Counts Rate vs Mass, 1eV - 12keV, 4*Pi angles
;
;KEYWORDS
;
;NOTES:	
;	Run load_fa_k0_tms.pro first to get the k0 data
;
;CREATED BY:	J.McFadden		96-10-7
;VERSION:	1
;LAST MODIFICATION:  97-3-25
;MOD HISTORY:
;	97-3-25		Checks for "hm" data and includes it in plot if it exists
;	97-3-25		Lists multiple orbit numbers in title	
;-
pro plot_fa_k0_tms

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
	
        datanames=['H+','He+','O+','H+_low','H+_high','He+_low','He+_high',$
                 'O+_low','O+_high']
        for i=0, n_elements(datanames) -1 do  begin
            get_data,datanames(i),index=index
            if index gt 0 then begin
                if n_elements (indices) eq 0 then indices = index   $
                else indices = [indices, index]
            endif 
        endfor
        
        tplot, indices, var_label=['MLT','ALT','ILAT'], $
          title='FAST Mass Spec  Orbit '+orbit_num
	
return
end
