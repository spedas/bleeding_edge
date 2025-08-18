;+
;Function:	get_thm_esa_calib
;PURPOSE:	
;	Returns esa calibration data in a structure
;INPUT:		
;
;KEYWORDS:
;	sc:		string		themis spacecraft - "a", "b", "c", "d", "e"
;					if not set defaults to all		
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  07/07/08
;MOD HISTORY:
;
;NOTES:	  
;	
;-

function get_thm_esa_calib,sc=sc,time=time

rel_ion_gf=[1.000,1.000,1.000,1.000,1.000,1.00]			; default		
rel_ele_gf=[1.000,1.000,1.000,1.000,1.000,1.00]			; default		


calib={deadtime:1.7e-7,rel_ion_gf:rel_ion_gf,rel_ele_gf:rel_ele_gf}

return,calib

end
