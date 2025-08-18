;Add fce, fce/2, flh and fci lines to spectral plots

;Requirements:
;	Can load some EFW spectral data with 
;	rbsp_load_efw_spec.pro  or  rbsp_load_efw_xspec.pro


;speclist -> list of tplot names of spectral data
;sc -> Van Allen probe 'a' or 'b' 
;period -> Downsample the EMFISIS data to this time period. 
;			Defaults to 11 seconds (~ Van Allen Probe spin period)


;Written by:
;Aaron W Breneman, Dec 2012

;Modified to use EMFISIS L3 data  2013-01-25  AWB



pro rbsp_add_fce2spec,speclist,sc,period=period



if ~keyword_set(period) then period = 11.  ;sc rotation period



;First find out if EMFISIS data is loaded
;If not, then load it
;get_data,'rbsp'+sc+'_emfisis_quicklook_Magnitude',data=mag
get_data,'rbsp'+sc+'_emfisis_l3_4sec_gse_Magnitude',data=mag


if ~is_struct(mag) then begin
;	rbsp_load_emfisis,probe=sc,/quicklook
;	get_data,'rbsp'+sc+'_emfisis_quicklook_Magnitude',data=mag

	rbsp_load_emfisis,probe=sc,coord='gse',cadence='4sec',level='l3'  	
	get_data,'rbsp'+sc+'_emfisis_l3_4sec_gse_Magnitude',data=mag
endif



if keyword_set(period) then begin
;	rbsp_downsample,['rbsp'+sc+'_emfisis_quicklook_Magnitude'],1/period,suffix='_DS_tmp'
;	get_data,'rbsp'+sc+'_emfisis_quicklook_Magnitude_DS_tmp',data=mag	
	rbsp_downsample,'rbsp'+sc+'_emfisis_l3_4sec_gse_Magnitude',1/period,suffix='_DS_tmp'
	get_data,'rbsp'+sc+'_emfisis_l3_4sec_gse_Magnitude_DS_tmp',data=mag	
endif






;Loop through each spec variable
for i=0,n_elements(speclist)-1 do begin	
	
	get_data,speclist[i],data=dat,dlimits=dlim,limits=lim


	;Check to see if tplot variable is spectral data
	if is_struct(dat) then begin

		if dlim.spec eq 1 then begin
		
		
			print,'Adding fce lines to ' + speclist[i]
		
		
			fce = 28.*mag.y
			fce = interpol(fce,mag.x,dat.x)
		
			store_data,'fce',data={x:dat.x,y:fce}
			store_data,'fce_2',data={x:dat.x,y:fce/2.}
			store_data,'fci',data={x:dat.x,y:fce/1836.}
			store_data,'flh',data={x:dat.x,y:sqrt(fce*fce/1836.)}
		
		
			store_data,speclist[i]+'_fce',data=[speclist[i],'fce','fce_2','fci','flh']
			ylim,speclist[i]+'_fce',3,10000,1
		
		;		if keyword_set(nochange) then begin
		;			
		;			get_data,speclist[i]+'_fce',data=dat
		;			store_data,speclist[i],data=dat
		;			ylim,speclist[i],3,10000,1
		;
		;
		;			tplot,[speclist[i]+'_fce',speclist[i]]
		;			get_data,speclist[i],data=dd1
		;			get_data,speclist[i]+'_fce',data=dd2
		;
		;		endif
		
		
		endif	
	
	endif
	



endfor

end


