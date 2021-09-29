; Unit testing for the das2pro package


pro das2pro_ut
	compile_opt IDL2

	sTest = 'Test 1, T1970 to TT2000:'
	t = das2_double_to_tt2000('t1970', 10)
	if t eq -946727949814622001LL then begin
		print, sTest + 'passed'
	endif else begin
		print, sTest + 'failed'
	endelse

	sTest = 'Test 2, String to TT2000:'
	t = das2_text_to_tt2000('2000-01-01T11:58:55.815999999')
	if t eq -1LL then begin
		print, sTest + 'passed'
	endif else begin
		print, sTest + 'failed'
	endelse
	
end
