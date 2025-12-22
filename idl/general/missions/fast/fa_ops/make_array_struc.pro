;+
;PROCEDURE:	make_array_struct
;PURPOSE:	
;	Makes an array of structures from input function, output used by get_array_struc.pro
;INPUT:		
;	data_str, 	a string (either 'eh','pl','fa_eesa_surv','fa_ess', ...)
;			where get_'string' returns a 2D or 3D 
;			data structure
;KEYWORDS:		
;
;CREATED BY:	J.McFadden
;VERSION:	1
;LAST MODIFICATION:  96-11-7	McFadden
;MOD HISTORY:
;
;NOTES:	  
;	Used to make an array of structures that is called by get_array_struc.pro
;	Current version only works for FAST
;	Written to speed up summary plot production for ees and ies
;-

pro make_array_struc,data_str, calib=calib

common array_struc_com, array_struc, nstruc, max_index, cur_index

routine = 'get_'+data_str

t = 1000             ; get first sample
dat = call_function(routine, t, /start, calib=calib)

if dat.valid eq 0 then begin no_data = 1 & return & end $
else no_data = 0

;t1=dat.time
;dtime=dat.end_time-dat.time
;dat2 = call_function(routine, t, /en)
;t2=dat2.time
;nstruc = fix((t2-t1)/dtime * 1.05)
;if nstruc gt 1000 then nstruc=1000

nstruc=1000
array_struc=replicate(dat,nstruc)

n=0
while (dat.valid ne 0) and (n lt nstruc) do begin
	array_struc(n).data_name=dat.data_name
	array_struc(n).valid=dat.valid
	array_struc(n).project_name=dat.project_name
	array_struc(n).units_name=dat.units_name
	array_struc(n).units_procedure=dat.units_procedure
	array_struc(n).time=dat.time
	array_struc(n).end_time=dat.end_time
	array_struc(n).integ_t=dat.integ_t
	array_struc(n).nbins=dat.nbins
	array_struc(n).nenergy=dat.nenergy
	array_struc(n).data=dat.data
	array_struc(n).energy=dat.energy
	array_struc(n).theta=dat.theta
	array_struc(n).geom=dat.geom
	array_struc(n).denergy=dat.denergy
	array_struc(n).dtheta=dat.dtheta
	array_struc(n).eff=dat.eff
	array_struc(n).mass=dat.mass
	array_struc(n).geomfactor=dat.geomfactor
	array_struc(n).header_bytes=dat.header_bytes
	dat = call_function(routine,t,/ad, calib=calib)
	n=n+1
endwhile

max_index=n-1
cur_index=0

return

end
