;+
; Name: dsc_ut_shiftline.pro
;
; Purpose: command line test script for DSC_SHIFTLINE procedure
;
; Notes:	Called by dsc_cltestsuite.pro
; 				This simply runs it through its paces and makes sure no 
; 				errors are thrown.  For the most part, it is not checking 
; 				that the plots are displaying the expected shifts.
;
; Test 1: One panel, one line
; Test 2: One panel, multiple lines
; Test 3: One panel, bad input
; Test 4: One panel, with dsc_dyplot
; Test 5: Multi-panel, shifts in all panels
; Test 6: Multi-panel, shifts in select panels
; Test 7: Multi-panel, with dsc_dyplot 
;-

PRO DSC_UT_SHIFTLINE,t_num=t_num

	compile_opt IDL2
	@tplot_com.pro

	if ~keyword_set(t_num) then t_num = 0
	l_num = 1
	utname = 'DSC_SHIFTLINE '

	
	timespan,'2017-01-01'
	dsc_load_mag
	dsc_load_fc
	wi_mfi_load
	wi_swe_load
	
	split_vec,'wi_swe_V_GSE'
	split_vec,'wi_h0_mfi_B3GSE'
	
	store_data,'Combo_Np',data=['wi_swe_Np','dsc_h1_fc_Np']
	store_data,'Combo_Vx',data=['wi_swe_V_GSE_x','dsc_h1_fc_V_GSE_x']
	store_data,'Combo_Bz',data=['wi_h0_mfi_B3GSE_z','dsc_h0_mag_B1GSE_z']
	options,'Combo_Np',ytitle='Np'
	options,'Combo_Vx',ytitle='Vx'
	options,'Combo_Bz',ytitle='Bz'

	; Test 1: One panel, one line
	; 
	t_name=utname+l_num.toString()+': One panel, one line'
	catch,err
	if err eq 0 then begin
		tplot,'dsc_h1_fc_V_GSE_x'
		dsc_shiftline,shift='45m30s'
		dsc_shiftline,/reset
		dsc_shiftline,shift='-2h',newvars=nv
		if n_elements(nv) ne 1 || $
			nv[0] ne 'dsc_h1_fc_V_GSE_xSHIFT-02h' $
			then message,'data error '+t_name
		
		dsc_shiftline,var='d',shift='30m'
		dsc_shiftline,var='dsc',shift='200m'
	endif
	catch,/cancel
	spd_handle_error,err,t_name,++t_num
	++l_num


	; Test 2: One panel, multiple lines
	; 
	t_name=utname+l_num.toString()+': One panel, multiple lines'
	catch,err
	if err eq 0 then begin
		tplot,'Combo_Np'
		dsc_shiftline,shift='45m30s',newvars=nv
		if n_elements(nv) ne 2 then message,'data error '+t_name
		
		dsc_shiftline,var='wi',shift='-45m30s',newvars=nv
		if n_elements(nv) ne 1 || nv[0] ne 'wi_swe_Np' $
			then message,'data error '+t_name
			
		dsc_shiftline,var='dsc',shift='1h'
	endif
	catch,/cancel
	spd_handle_error,err,t_name,++t_num
	++l_num
	
	
	; Test 3: One panel, bad input
	; 
	t_name=utname+l_num.toString()+': One panel, bad input'
	catch,err
	if err eq 0 then begin
		tplot,'Combo_Bz',new_tvars=tvar_orig
		
		dsc_shiftline,var='notavar',shift='20m'
		if ~compare_struct(tvar_orig,tplot_vars) then message,'plot error: '+t_name
		
		dsc_shiftline,shift='32w'
		if ~compare_struct(tvar_orig,tplot_vars) then message,'plot error: '+t_name
		
		dsc_shiftline,var='dsc',shift=['15m','-3h']
		if ~compare_struct(tvar_orig,tplot_vars) then message,'plot error: '+t_name
		
		dsc_shiftline,var=['d','w'],shift=['13s'],newvars=nv
		if ~compare_struct(tvar_orig,tplot_vars) then message,'plot error: '+t_name
		if nv ne !NULL then message,'data error '+t_name
	endif
	catch,/cancel
	spd_handle_error,err,t_name,++t_num
	++l_num


	; Test 4: One panel, with dsc_dyplot
	; 
	t_name=utname+l_num.toString()+': One panel, with dsc_dyplot'
	catch,err
	if err eq 0 then begin
		tplot,'Combo_Vx'
		dsc_dyplot
		dsc_shiftline,var='dsc',shift='4h30m',/dscdy
		
		tplot,'Combo_Vx'
		dsc_dyplot,/force,new_dyinfo=dyinfo
		dsc_shiftline,var='dsc',shift='-3h',dyinfo=dyinfo
		
		tplot,'wi_swe_V_GSE_x'
		dsc_dyplot,/force,new_dyinfo=dyinfo
		dsc_shiftline,shift='49m',dyinfo=dyinfo
		dsc_shiftline,/reset,/dscdy
	endif
	catch,/cancel
	spd_handle_error,err,t_name,++t_num
	++l_num
	

	; Test 5: Multi-panel, shifts in all panels
	; 
	t_name=utname+l_num.toString()+': Multi-panel, shifts in all panels'
	catch,err
	if err eq 0 then begin
		tplot,['Combo_Np','Combo_Bz','Combo_Vx']
		dsc_shiftline,shift='+42m'
		dsc_shiftline,var='dsc',shift='100s'
		dsc_shiftline,var='dsc',shift='-10d'
		dsc_shiftline,var='wi',shift='1h54m'
		dsc_shiftline,var='wi',shift='-6h'
		
		dsc_shiftline,/reset
		dsc_shiftline,shift=['15m','-2h','5h500s']
		
		dsc_shiftline,/reset
		tvar_orig = tplot_vars
		dsc_shiftline,var='pqr',shift='30m'
		if ~compare_struct(tvar_orig,tplot_vars) then message,'plot error: '+t_name
	endif
	catch,/cancel
	spd_handle_error,err,t_name,++t_num
	++l_num
	

	; Test 6: Multi-panel, shifts in select panels
	; 
	t_name=utname+l_num.toString()+': Multi-panel, shifts in select panels'
	catch,err
	if err eq 0 then begin
		tplot,['Combo_Np','Combo_Bz','Combo_Vx']
		dsc_shiftline,panel=[1,3],shift='+42m'
		dsc_shiftline,panel=3,var='dsc',shift='100s'
		dsc_shiftline,panel=[1,2],var='dsc',shift=['-10d','20m']
		dsc_shiftline,panel=[1,3],var=['wi','dsc'],shift='1h54m'
		dsc_shiftline,panel=[1,3],var=['wi','dsc'],shift=['1h54m','-14h']
		dsc_shiftline,panel=2,var='wi',shift='-6h'

		dsc_shiftline,/reset
		tvar_orig = tplot_vars
		dsc_shiftline
		if ~compare_struct(tvar_orig,tplot_vars) then message,'plot error: '+t_name
		
		dsc_shiftline,/dscdy
		if ~compare_struct(tvar_orig,tplot_vars) then message,'plot error: '+t_name
	endif
	catch,/cancel
	spd_handle_error,err,t_name,++t_num
	++l_num
	

	; Test 7: Multi-panel, with dsc_dyplot
	; 			
	t_name=utname+l_num.toString()+': Multi-panel, with dsc_dyplot'
	catch,err
	if err eq 0 then begin
		tplot,['Combo_Np','Combo_Bz','Combo_Vx']
		dsc_dyplot
		dsc_shiftline,panel=2,var='dsc',shift='4h30m',/dscdy

		tplot,['Combo_Np','Combo_Bz','Combo_Vx']
		dsc_dyplot,panel=[2,3],/force,new_dyinfo=dyinfo
		dsc_shiftline,panel=1,var='wi',shift='-3h',dyinfo=dyinfo
	endif
	catch,/cancel
	spd_handle_error,err,t_name,++t_num
	++l_num

	store_data,'*',/del
END