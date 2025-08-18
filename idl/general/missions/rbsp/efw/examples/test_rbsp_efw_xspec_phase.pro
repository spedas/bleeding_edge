; test_rbsp_efw_xspec_phase.pro
;
; simple IDL routine for calculating XSPEC phase and coherence
;
; version 1.0, Kris Kersten, UMN, June 2012
;			email: kris.kersten@gmail.com

; CAVEAT: this assumes we have 64-bin specs

pro test_rbsp_efw_xspec_phase

	; nominally there are 4 xspec quantities, although some may be empty
	
	nxspec=4
	xspec_names = ['rbspa_efw_xspec_64_xspec' + string(lindgen(nxspec),format='(I0)'), $
				'rbspb_efw_xspec_64_xspec' + string(lindgen(nxspec),format='(I0)') ]
	rc_names = xspec_names + '_rc'
	ic_names = xspec_names + '_ic'
	src1_names = xspec_names + '_src1'
	src2_names = xspec_names + '_src2'
	
	for count=0,nxspec-1 do begin
		
		get_data,rc_names[count],data=rc_temp,limits=rclimits,dlimits=rcdlimits
		get_data,ic_names[count],data=ic_temp
		get_data,src1_names[count],data=src1_temp,limits=src1limits,dlimits=src1dlimits
		get_data,src2_names[count],data=src2_temp
		
		; make sure we have the data and calculate phase, coherence^2
		if is_struct(rc_temp) and is_struct(ic_temp) and $
			is_struct(src1_temp) and is_struct(src2_temp) then begin
		
			phase_temp=ATAN(ic_temp.y, rc_temp.y)/!DTOR
			coh_temp=sqrt((rc_temp.y^2 + ic_temp.y^2)/( src1_temp.y * src2_temp.y ))
				
			phase_struct={x:rc_temp.x,y:phase_temp,v:rc_temp.v}
			store_data,xspec_names[count]+'_phase',data=phase_struct,$
				limits=rclimits,dlimits=rcdlimits
			print,'Saved:  '+xspec_names[count]+'_phase'
	
			coh_struct={x:rc_temp.x,y:coh_temp,v:rc_temp.v}
			store_data,xspec_names[count]+'_coh',data=coh_struct,$
				limits=rclimits,dlimits=rcdlimits
			print,'Saved:  '+xspec_names[count]+'_coh'
		
		endif

	endfor

end


