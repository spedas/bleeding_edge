;+
;Procedure:	diag_t, temp, t=t, s=s
;INPUT:	
;	temp:	temperature array of n by 6 or a string (e.g., 'Tp')
;PURPOSE:
;	Returns the temperature: [Tpara,Tperp,Tperp], T_total and 
;		the unit symmetry axis s. Also returns 'T_diag' and 'S.axis'
;		for plotting purposes.  
;
;CREATED BY:
;	Tai Phan	98-07-02
;LAST MODIFICATION:
;	98-07-02	Tai Phan
;-

pro diag_t, temp, t=t, s=s

	test= data_type(temp)

	case test of
		4:	begin
			temperature= p
			end
		7:	begin
			get_data, temp, data= tmp
			time= tmp.x
			temperature= tmp.y
			end
	endcase

	result= size(temperature)
	npt= result(1)

	eig_val= fltarr(npt,3)
	eig_vec= fltarr(npt,3)
	for i= 0, npt-1 do begin
		mat_diag, temperature(i,*), EIG_VAL= val, EIG_VEC= vec
		eig_val(i,*)= val
		eig_vec(i,*)= vec(*,0)
	endfor

	t= eig_val
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


