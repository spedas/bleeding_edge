;+
;Procedure:	diag_p, p, n, t=t, s=s
;INPUT:	
;	p:	pressure array of n by 6 or a string (e.g., 'p_3d_el')
;	n:	density array of n or a string (e.g., 'n_3d_el')
;PURPOSE:
;	Returns the temperature: [Tpara,Tperp,Tperp], T_total and 
;		the unit symmetry axis s. Also returns 'T_diag' and 'S.axis'
;		for plotting purposes.  
;
;CREATED BY:
;	Tai Phan	95-09-28
;LAST MODIFICATION:
;	2015-09-09		Tai Phan
;-

pro diag_p, p , n, t=t, s=s

catch, Error_status
if Error_status ne 0 then begin
	print,'********************* problem '
;	error_code=1
;	error_time=time_dist
	return

endif
	get_data, p, data = d1
	get_data, n, data = d2

	if n_elements(reform(d1.y(*, 0))) ne n_elements(d2.y) then begin
		print, 'Arguments to diag_p do not have the same dimensions'
		stop
	endif

	test= data_type(p)

	case test of
		4:	begin
			pressure= p
			dens= n
			end
		7:	begin
			get_data, p, data= tmp
			time= tmp.x
			pressure= tmp.y
			get_data, n, data= tmp
			dens= tmp.y
			end
	endcase

	result= size(pressure)
	npt= result(1)

	eig_val= fltarr(npt,3) - 999.0
	eig_vec= fltarr(npt,3) - 999.0
	for i= 0, npt-1 do begin
		mat_diag, pressure(i,*), EIG_VAL= val, EIG_VEC= vec
		if n_elements(val) ne 1 then begin
			eig_val(i,*)= val
			eig_vec(i,*)= vec(*,0)
		endif
	endfor

;	t= eig_val/(2.*dens # [1.,1.,1.])
	t= eig_val/(dens # [1.,1.,1.])
	t_ani= .5*(t(*,1)+t(*,2))/t(*,0)
	t_tot= (t(*,1)+t(*,2)+t(*,0))/3.
	s= eig_vec

	if test eq 7 then begin
		t= {xtitle:'Time',x:time,y:t}
		store_data,'T_diag', data=t
		t_ani= {xtitle:'Time',x:time,y:t_ani}
		store_data,'T_ani', data=t_ani
		t_tot= {xtitle:'Time',x:time,y:t_tot}
		store_data,'T_tot', data=t_tot
		s= {xtitle:'Time',x:time,y:s}
		store_data,'Saxis', data=s
	endif





return
end

