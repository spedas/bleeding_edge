;+
; Name: dsc_ut_timeabsolute.pro
;
; Purpose: command line test script for DSC_TIME_ABSOLUTE class
;
; Notes:	Called by dsc_cltestsuite.pro
;
; Test 1: Create object with no arguments
; Test 2: Create object with good keyword arguments - all set, no reducing, +/-
; Test 3: Create object with good keyword arguments - some set, no reducing, +/-
; Test 4: Create object with good keyword arguments - needs reducing, all positive
; Test 5: Create object with good keyword arguments - needs reducing, all negative
; Test 6: Create object with good keyword arguments - needs reducing, mixed signs
; Test 7: Create object with bad keyword arguments
; Test 8: Create object with good timestring argument - positive
; Test 9: Create object with good timestring argument - negative
; Test 10: Create object with bad timestring argument
; Test 11: Create object when passed both string and keywords
; Test 12: Call Set with no arguments
; Test 13: Set object with good keyword arguments
; Test 14: Set object with bad keyword arguments
; Test 15: Set object with good timestring argument
; Test 16: Set object with bad timestring argument
; Test 17: Set object when passed both string and keywords
; Test 18: Set object with good structure argument
; Test 19: Set object with bad structure argument
; Test 20: Negate object
; Test 21: Get structure containing object values
; Test 22: Copy object
; Test 23: Add to object with good argument
; Test 24: Add to object with bad argument
; Test 25: Subtract from object with good argument
; Test 26: Subtract from object with bad argument
; Test 27: Representing object as a string
; Test 28: Return Object value in various units
; Test 29: Parse a timestring 
; Test 30: Convert between units of time - positive and negative
; Test 31: Add two objects using the + operator 
; Test 32: Subtract two objects using the - operator
; -


PRO DSC_UT_TIMEABSOLUTE,t_num=t_num

compile_opt IDL2

if ~keyword_set(t_num) then t_num = 0
l_num = 1
utname = 'DSC_TIME_ABSOLUTE Class '

tstrc_0 = { $
	ms: 0,   $ 
	s : 0,   $ 
	m : 0,   $ 
	h : 0,   $ 
	d : 0,    $
	string1: '0d0h0m0s0ms', $
	string2: '0d' $
}

tstrc_all_pos_noreduce = { $
		ms: 450,   $ 
		s : 32,   $
		m : 12,   $
		h : 3,   $ 
		d : 1,    $
		string1: '1d3h12m32s450ms', $
		string2: '+3h450ms32s12m1d', $
		r_neg: !FALSE, $
		r_ms: 450,   $
		r_s : 32,   $
		r_m : 12,   $
		r_h : 3,   $
		r_d : 1    $
}

tstrc_all_neg_noreduce = { $
		ms: -30,   $
		s : -52,   $
		m : -47,   $
		h : -1,   $
		d : -2,    $
		string1: '-30ms52s47m1h2d', $
		string2: '-2d1h47m52s30ms', $
		r_neg: !TRUE, $
		r_ms: 30,   $
		r_s : 52,   $
		r_m : 47,   $
		r_h : 1,   $
		r_d : 2    $
}

tstrc_some_pos = { $
	ms: 450,   $
	m : 12,   $
	h : 3,   $
	string1: '3h12m450ms', $
	string2: '+3h450ms12m', $
	r_neg: !FALSE, $
	r_ms: 450,   $
	r_s : 0,   $
	r_m : 12,   $
	r_h : 3,   $
	r_d : 0    $
}

tstrc_some_neg = { $
	s : -52,   $
	h : -1,   $
	d : -2,    $
	string1: '-52s1h2d', $
	string2: '-2d1h52s', $
	r_neg: !TRUE, $
	r_ms: 0,   $
	r_s : 52,   $
	r_m : 0,   $
	r_h : 1,   $
	r_d : 2    $
}

tstrc_pos_reduce = { $
	ms: 4000,   $
	s : 102,   $
	m : 12,   $
	h : 3.5,   $
	d : 1,    $
	string1: '1d3h43m46s', $
	string2: '1d3h42m102s4000ms', $
	r_neg: !FALSE, $
	r_ms: 0,   $
	r_s : 46,   $
	r_m : 43,   $
	r_h : 3,   $
	r_d : 1    $	
}

tstrc_neg_reduce = { $
	ms: -30,   $
	s : -152,   $
	m : -47,   $
	h : -1.8,   $
	d : -2,    $
	string1: '-2d2h37m32s30ms', $
	string2: '-2d1h95m152s30ms', $
	r_neg: !TRUE, $
	r_ms: 30,   $
	r_s : 32,   $
	r_m : 37,   $
	r_h : 2,   $
	r_d : 2    $
}

tstrc_mix_reduce = { $
	ms: -30,   $
	s : 152,   $
	m : 63,   $
	h : -1.8,   $
	d : 0,    $
	r_neg: !TRUE, $
	r_ms: 30,   $
	r_s : 28,   $
	r_m : 42,   $
	r_h : 0,   $
	r_d : 0    $
}


; Test 1: Create object with no arguments
; 
t_name=utname+l_num.toString()+': Create object with no arguments'
catch,err
if err eq 0 then begin
	t_1 = dsc_time_absolute()
	if (t_1.getMilli() ne tstrc_0.ms) || $
		(t_1.getSeconds() ne tstrc_0.s) || $
		(t_1.getMinutes() ne tstrc_0.m) || $
		(t_1.getHours() ne tstrc_0.h) || $
		(t_1.getDays() ne tstrc_0.d) $
	then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 2: Create object with good keyword arguments - all set, no reducing, +/-
; 
t_name=utname+l_num.toString()+': Create object with good keyword arguments - all set, no reducing, +/-'
catch,err
if err eq 0 then begin
	t_2A = dsc_time_absolute(d=tstrc_all_pos_noreduce.d, $
		h=tstrc_all_pos_noreduce.h, $
		mn=tstrc_all_pos_noreduce.m, $
		s=tstrc_all_pos_noreduce.s, $
		ms=tstrc_all_pos_noreduce.ms)
	t_2B = dsc_time_absolute(d=tstrc_all_neg_noreduce.d, $
			h=tstrc_all_neg_noreduce.h, $
			mn=tstrc_all_neg_noreduce.m, $
			s=tstrc_all_neg_noreduce.s, $
			ms=tstrc_all_neg_noreduce.ms)
			
	if (t_2A.isNeg() ne  tstrc_all_pos_noreduce.r_neg) || $
		(t_2A.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_2A.getSeconds() ne tstrc_all_pos_noreduce.r_s) || $
		(t_2A.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_2A.getHours() ne tstrc_all_pos_noreduce.r_h) || $
		(t_2A.getDays() ne tstrc_all_pos_noreduce.r_d) $
		then message,'data error A '+t_name
	if (t_2B.isNeg() ne  tstrc_all_neg_noreduce.r_neg) || $
		(t_2B.getMilli() ne tstrc_all_neg_noreduce.r_ms) || $
		(t_2B.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_2B.getMinutes() ne tstrc_all_neg_noreduce.r_m) || $
		(t_2B.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_2B.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error B '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 3: Create object with good keyword arguments - some set, no reducing, +/-
; 
t_name=utname+l_num.toString()+': Create object with good keyword arguments - some set, no reducing, +/-'
catch,err
if err eq 0 then begin
	t_3A = dsc_time_absolute(d=tstrc_all_pos_noreduce.d, $
		mn=tstrc_all_pos_noreduce.m, $
		ms=tstrc_all_pos_noreduce.ms)
	t_3B = dsc_time_absolute(d=tstrc_all_neg_noreduce.d, $
			h=tstrc_all_neg_noreduce.h, $
			s=tstrc_all_neg_noreduce.s)
			
	if (t_3A.isNeg() ne  tstrc_all_pos_noreduce.r_neg) || $
		(t_3A.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_3A.getSeconds() ne 0) || $
		(t_3A.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_3A.getHours() ne 0) || $
		(t_3A.getDays() ne tstrc_all_pos_noreduce.r_d) $
		then message,'data error A '+t_name
	if (t_3B.isNeg() ne  tstrc_all_neg_noreduce.r_neg) || $
		(t_3B.getMilli() ne 0) || $
		(t_3B.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_3B.getMinutes() ne 0) || $
		(t_3B.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_3B.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error B '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 4: Create object with good keyword arguments - needs reducing, all positive
; 
t_name=utname+l_num.toString()+': Create object with good keyword arguments - needs reducing, all positive'
catch,err
if err eq 0 then begin
	t_4 = dsc_time_absolute(d=tstrc_pos_reduce.d, $
		h=tstrc_pos_reduce.h, $
		mn=tstrc_pos_reduce.m, $
		s=tstrc_pos_reduce.s, $
		ms=tstrc_pos_reduce.ms)
	
	if t_4.isNeg() || $
		(t_4.getMilli() ne tstrc_pos_reduce.r_ms) || $
		(t_4.getSeconds() ne tstrc_pos_reduce.r_s) || $
		(t_4.getMinutes() ne tstrc_pos_reduce.r_m) || $
		(t_4.getHours() ne tstrc_pos_reduce.r_h) || $
		(t_4.getDays() ne tstrc_pos_reduce.r_d) $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 5: Create object with good keyword arguments - needs reducing, all negative
; 
t_name=utname+l_num.toString()+': Create object with good keyword arguments - needs reducing, all negative'
catch,err
if err eq 0 then begin
	t_5 = dsc_time_absolute(d=tstrc_neg_reduce.d, $
		h=tstrc_neg_reduce.h, $
		mn=tstrc_neg_reduce.m, $
		s=tstrc_neg_reduce.s, $
		ms=tstrc_neg_reduce.ms)
	
	if ~t_5.isNeg() || $
		(t_5.getMilli() ne tstrc_neg_reduce.r_ms) || $
		(t_5.getSeconds() ne tstrc_neg_reduce.r_s) || $
		(t_5.getMinutes() ne tstrc_neg_reduce.r_m) || $
		(t_5.getHours() ne tstrc_neg_reduce.r_h) || $
		(t_5.getDays() ne tstrc_neg_reduce.r_d) $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 6: Create object with good keyword arguments - needs reducing, mixed signs
; 
t_name=utname+l_num.toString()+': Create object with good keyword arguments - needs reducing, mixed signs'
catch,err
if err eq 0 then begin
	t_6 = dsc_time_absolute(d=tstrc_mix_reduce.d, $
		h=tstrc_mix_reduce.h, $
		mn=tstrc_mix_reduce.m, $
		s=tstrc_mix_reduce.s, $
		ms=tstrc_mix_reduce.ms)
	
	if (t_6.isNeg() ne tstrc_mix_reduce.r_neg ) || $
		(t_6.getMilli() ne tstrc_mix_reduce.r_ms) || $
		(t_6.getSeconds() ne tstrc_mix_reduce.r_s) || $
		(t_6.getMinutes() ne tstrc_mix_reduce.r_m) || $
		(t_6.getHours() ne tstrc_mix_reduce.r_h) || $
		(t_6.getDays() ne tstrc_mix_reduce.r_d) $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 7: Create object with bad keyword arguments
; 
t_name=utname+l_num.toString()+': Create object with bad keyword arguments'
catch,err
if err eq 0 then begin
	t_7 = dsc_time_absolute(d='string',h=!TRUE,mn=!NULL,s=12b,ms={a:1,b:2})
	if (t_7 ne !NULL) then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 8: Create object with good timestring argument - positive
; 
t_name=utname+l_num.toString()+': Create object with good timestring argument - positive'
catch,err
if err eq 0 then begin
	t_8A = dsc_time_absolute(tstrc_0.string1)
	t_8B = dsc_time_absolute(tstrc_0.string2)
	t_8C = dsc_time_absolute(tstrc_all_pos_noreduce.string1)
	t_8D = dsc_time_absolute(tstrc_all_pos_noreduce.string2)
	t_8E = dsc_time_absolute(tstrc_pos_reduce.string1)
	t_8F = dsc_time_absolute(tstrc_pos_reduce.string2)
	
	if (t_8A.getMilli() ne tstrc_0.ms) || $
		(t_8A.getSeconds() ne tstrc_0.s) || $
		(t_8A.getMinutes() ne tstrc_0.m) || $
		(t_8A.getHours() ne tstrc_0.h) || $
		(t_8A.getDays() ne tstrc_0.d) $
		then message,'data error A '+t_name
	if (t_8B.getMilli() ne tstrc_0.ms) || $
		(t_8B.getSeconds() ne tstrc_0.s) || $
		(t_8B.getMinutes() ne tstrc_0.m) || $
		(t_8B.getHours() ne tstrc_0.h) || $
		(t_8B.getDays() ne tstrc_0.d) $
		then message,'data error B '+t_name
	if t_8C.isNeg() || $
		(t_8C.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_8C.getSeconds() ne tstrc_all_pos_noreduce.r_s) || $
		(t_8C.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_8C.getHours() ne tstrc_all_pos_noreduce.r_h) || $
		(t_8C.getDays() ne tstrc_all_pos_noreduce.r_d) $	
		then message,'data error C '+t_name
	if t_8D.isNeg() || $
		(t_8D.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_8D.getSeconds() ne tstrc_all_pos_noreduce.r_s) || $
		(t_8D.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_8D.getHours() ne tstrc_all_pos_noreduce.r_h) || $
		(t_8D.getDays() ne tstrc_all_pos_noreduce.r_d) $
		then message,'data error D '+t_name
	if t_8E.isNeg() || $
		(t_8E.getMilli() ne tstrc_pos_reduce.r_ms) || $
		(t_8E.getSeconds() ne tstrc_pos_reduce.r_s) || $
		(t_8E.getMinutes() ne tstrc_pos_reduce.r_m) || $
		(t_8E.getHours() ne tstrc_pos_reduce.r_h) || $
		(t_8E.getDays() ne tstrc_pos_reduce.r_d) $
		then message,'data error E '+t_name
	if t_8F.isNeg() || $
		(t_8F.getMilli() ne tstrc_pos_reduce.r_ms) || $
		(t_8F.getSeconds() ne tstrc_pos_reduce.r_s) || $
		(t_8F.getMinutes() ne tstrc_pos_reduce.r_m) || $
		(t_8F.getHours() ne tstrc_pos_reduce.r_h) || $
		(t_8F.getDays() ne tstrc_pos_reduce.r_d) $
		then message,'data error F '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 9: Create object with good timestring argument - negative
; 
t_name=utname+l_num.toString()+': Create object with good timestring argument - negative'
catch,err
if err eq 0 then begin
	t_9A = dsc_time_absolute(tstrc_all_neg_noreduce.string1)
	t_9B = dsc_time_absolute(tstrc_all_neg_noreduce.string2)
	t_9C = dsc_time_absolute(tstrc_neg_reduce.string1)
	t_9D = dsc_time_absolute(tstrc_neg_reduce.string2)

	if ~t_9A.isNeg() || $
		(t_9A.getMilli() ne tstrc_all_neg_noreduce.r_ms) || $
		(t_9A.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_9A.getMinutes() ne tstrc_all_neg_noreduce.r_m) || $
		(t_9A.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_9A.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error A '+t_name
	if ~t_9B.isNeg() || $
		(t_9B.getMilli() ne tstrc_all_neg_noreduce.r_ms) || $
		(t_9B.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_9B.getMinutes() ne tstrc_all_neg_noreduce.r_m) || $
		(t_9B.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_9B.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error B '+t_name
	if ~t_9C.isNeg() || $
		(t_9C.getMilli() ne tstrc_neg_reduce.r_ms) || $
		(t_9C.getSeconds() ne tstrc_neg_reduce.r_s) || $
		(t_9C.getMinutes() ne tstrc_neg_reduce.r_m) || $
		(t_9C.getHours() ne tstrc_neg_reduce.r_h) || $
		(t_9C.getDays() ne tstrc_neg_reduce.r_d) $
		then message,'data error C '+t_name
	if ~t_9D.isNeg() || $
		(t_9D.getMilli() ne tstrc_neg_reduce.r_ms) || $
		(t_9D.getSeconds() ne tstrc_neg_reduce.r_s) || $
		(t_9D.getMinutes() ne tstrc_neg_reduce.r_m) || $
		(t_9D.getHours() ne tstrc_neg_reduce.r_h) || $
		(t_9D.getDays() ne tstrc_neg_reduce.r_d) $
		then message,'data error D '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 10: Create object with bad timestring argument
; 
t_name=utname+l_num.toString()+': Create object with bad timestring argument'
catch,err
if err eq 0 then begin
	t_10A = dsc_time_absolute('IamABadString')
	t_10B = dsc_time_absolute('10d2.3h')
	t_10C = DSC_TIME_ABSOLUTE('3h-2m15s')
	
	if t_10A ne !NULL then message,'data error A '+t_name
	if t_10B ne !NULL then message,'data error B '+t_name
	if t_10C ne !NULL then message,'data error C '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 11: Create object when passed both string and keywords
; 
t_name=utname+l_num.toString()+': Create object when passed both string and keywords'
catch,err
if err eq 0 then begin
	t_11A = DSC_TIME_ABSOLUTE('2d16h',d=5,mn=30)
	t_11B = DSC_TIME_ABSOLUTE('-2d16h',d=5,mn='BadValue')

	if t_11A.isNeg() || $
		(t_11A.getMilli() ne 0) || $
		(t_11A.getSeconds() ne 0) || $
		(t_11A.getMinutes() ne 0) || $
		(t_11A.getHours() ne 16) || $
		(t_11A.getDays() ne 2) $
		then message,'data error A '+t_name

	if ~t_11B.isNeg() || $
		(t_11B.getMilli() ne 0) || $
		(t_11B.getSeconds() ne 0) || $
		(t_11B.getMinutes() ne 0) || $
		(t_11B.getHours() ne 16) || $
		(t_11B.getDays() ne 2) $
		then message,'data error B '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 12: Call Set with no arguments
; 
t_name=utname+l_num.toString()+': Call Set with no arguments'
catch,err
if err eq 0 then begin
	t_12 = DSC_TIME_ABSOLUTE('54s')
	t_12.Set

	if (t_12.getMilli() ne tstrc_0.ms) || $
		(t_12.getSeconds() ne tstrc_0.s) || $
		(t_12.getMinutes() ne tstrc_0.m) || $
		(t_12.getHours() ne tstrc_0.h) || $
		(t_12.getDays() ne tstrc_0.d) $
		then message,'data error '+t_name


endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 13: Set object with good keyword arguments
; 
t_name=utname+l_num.toString()+': Set object with good keyword arguments'
catch,err
if err eq 0 then begin
	t_13 = DSC_TIME_ABSOLUTE(h=7,mn=29,s=120)

	t_13.Set,d=tstrc_all_pos_noreduce.d, $
		h=tstrc_all_pos_noreduce.h, $
		mn=tstrc_all_pos_noreduce.m, $
		s=tstrc_all_pos_noreduce.s, $
		ms=tstrc_all_pos_noreduce.ms
	if t_13.isNeg() || $
		(t_13.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_13.getSeconds() ne tstrc_all_pos_noreduce.r_s) || $
		(t_13.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_13.getHours() ne tstrc_all_pos_noreduce.r_h) || $
		(t_13.getDays() ne tstrc_all_pos_noreduce.r_d) $
		then message,'data error A '+t_name

	t_13.Set,d=tstrc_all_neg_noreduce.d, $
		h=tstrc_all_neg_noreduce.h, $
		mn=tstrc_all_neg_noreduce.m, $
		s=tstrc_all_neg_noreduce.s, $
		ms=tstrc_all_neg_noreduce.ms
	if (t_13.isNeg() ne  tstrc_all_neg_noreduce.r_neg) || $
		(t_13.getMilli() ne tstrc_all_neg_noreduce.r_ms) || $
		(t_13.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_13.getMinutes() ne tstrc_all_neg_noreduce.r_m) || $
		(t_13.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_13.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error B '+t_name
		
	t_13.Set,d=tstrc_all_pos_noreduce.d, $
		mn=tstrc_all_pos_noreduce.m, $
		ms=tstrc_all_pos_noreduce.ms
	if (t_13.isNeg() ne  tstrc_all_pos_noreduce.r_neg) || $
		(t_13.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_13.getSeconds() ne 0) || $
		(t_13.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_13.getHours() ne 0) || $
		(t_13.getDays() ne tstrc_all_pos_noreduce.r_d) $
		then message,'data error C '+t_name

	t_13.Set,d=tstrc_all_neg_noreduce.d, $
		h=tstrc_all_neg_noreduce.h, $
		s=tstrc_all_neg_noreduce.s
	if (t_13.isNeg() ne  tstrc_all_neg_noreduce.r_neg) || $
		(t_13.getMilli() ne 0) || $
		(t_13.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_13.getMinutes() ne 0) || $
		(t_13.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_13.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error D '+t_name

	t_13.Set,d=tstrc_pos_reduce.d, $
		h=tstrc_pos_reduce.h, $
		mn=tstrc_pos_reduce.m, $
		s=tstrc_pos_reduce.s, $
		ms=tstrc_pos_reduce.ms
	if t_13.isNeg() || $
		(t_13.getMilli() ne tstrc_pos_reduce.r_ms) || $
		(t_13.getSeconds() ne tstrc_pos_reduce.r_s) || $
		(t_13.getMinutes() ne tstrc_pos_reduce.r_m) || $
		(t_13.getHours() ne tstrc_pos_reduce.r_h) || $
		(t_13.getDays() ne tstrc_pos_reduce.r_d) $
		then message,'data error E '+t_name
			
	t_13.Set,d=tstrc_neg_reduce.d, $
		h=tstrc_neg_reduce.h, $
		mn=tstrc_neg_reduce.m, $
		s=tstrc_neg_reduce.s, $
		ms=tstrc_neg_reduce.ms
	if ~t_13.isNeg() || $
		(t_13.getMilli() ne tstrc_neg_reduce.r_ms) || $
		(t_13.getSeconds() ne tstrc_neg_reduce.r_s) || $
		(t_13.getMinutes() ne tstrc_neg_reduce.r_m) || $
		(t_13.getHours() ne tstrc_neg_reduce.r_h) || $
		(t_13.getDays() ne tstrc_neg_reduce.r_d) $
		then message,'data error F '+t_name
			
	t_13.Set,d=tstrc_mix_reduce.d, $
		h=tstrc_mix_reduce.h, $
		mn=tstrc_mix_reduce.m, $
		s=tstrc_mix_reduce.s, $
		ms=tstrc_mix_reduce.ms
	if (t_13.isNeg() ne tstrc_mix_reduce.r_neg ) || $
		(t_13.getMilli() ne tstrc_mix_reduce.r_ms) || $
		(t_13.getSeconds() ne tstrc_mix_reduce.r_s) || $
		(t_13.getMinutes() ne tstrc_mix_reduce.r_m) || $
		(t_13.getHours() ne tstrc_mix_reduce.r_h) || $
		(t_13.getDays() ne tstrc_mix_reduce.r_d) $
		then message,'data error G '+t_name
		
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 14: Set object with bad keyword arguments
; 
t_name=utname+l_num.toString()+': Set object with bad keyword arguments'
catch,err
if err eq 0 then begin
	t_14 = DSC_TIME_ABSOLUTE('15h3s53ms')
	t_14.Set,d='string',h=!TRUE,mn=!NULL,s=12b,ms={a:1,b:2}

	if (t_14.getMilli() ne 53) || $
		(t_14.getSeconds() ne 3) || $
		(t_14.getMinutes() ne 0) || $
		(t_14.getHours() ne 15) || $
		(t_14.getDays() ne 0) $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 15: Set object with good timestring argument
; 
t_name=utname+l_num.toString()+': Set object with good timestring argument'
catch,err
if err eq 0 then begin
	t_15 = DSC_TIME_ABSOLUTE('1h340m')
	t_15.Set,tstrc_0.string1
	if (t_15.getMilli() ne tstrc_0.ms) || $
		(t_15.getSeconds() ne tstrc_0.s) || $
		(t_15.getMinutes() ne tstrc_0.m) || $
		(t_15.getHours() ne tstrc_0.h) || $
		(t_15.getDays() ne tstrc_0.d) $
		then message,'data error A '+t_name

	t_15.Set,tstrc_0.string2
	if (t_15.getMilli() ne tstrc_0.ms) || $
		(t_15.getSeconds() ne tstrc_0.s) || $
		(t_15.getMinutes() ne tstrc_0.m) || $
		(t_15.getHours() ne tstrc_0.h) || $
		(t_15.getDays() ne tstrc_0.d) $
		then message,'data error B '+t_name

	t_15.Set,tstrc_all_pos_noreduce.string1
	if t_15.isNeg() || $
		(t_15.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_15.getSeconds() ne tstrc_all_pos_noreduce.r_s) || $
		(t_15.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_15.getHours() ne tstrc_all_pos_noreduce.r_h) || $
		(t_15.getDays() ne tstrc_all_pos_noreduce.r_d) $
		then message,'data error C '+t_name

	t_15.Set,tstrc_all_pos_noreduce.string2
	if t_15.isNeg() || $
		(t_15.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_15.getSeconds() ne tstrc_all_pos_noreduce.r_s) || $
		(t_15.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_15.getHours() ne tstrc_all_pos_noreduce.r_h) || $
		(t_15.getDays() ne tstrc_all_pos_noreduce.r_d) $
		then message,'data error D '+t_name

	t_15.Set,tstrc_pos_reduce.string1
	if t_15.isNeg() || $
		(t_15.getMilli() ne tstrc_pos_reduce.r_ms) || $
		(t_15.getSeconds() ne tstrc_pos_reduce.r_s) || $
		(t_15.getMinutes() ne tstrc_pos_reduce.r_m) || $
		(t_15.getHours() ne tstrc_pos_reduce.r_h) || $
		(t_15.getDays() ne tstrc_pos_reduce.r_d) $
		then message,'data error E '+t_name

	t_15.Set,tstrc_pos_reduce.string2
	if t_15.isNeg() || $
		(t_15.getMilli() ne tstrc_pos_reduce.r_ms) || $
		(t_15.getSeconds() ne tstrc_pos_reduce.r_s) || $
		(t_15.getMinutes() ne tstrc_pos_reduce.r_m) || $
		(t_15.getHours() ne tstrc_pos_reduce.r_h) || $
		(t_15.getDays() ne tstrc_pos_reduce.r_d) $
		then message,'data error F '+t_name

	t_15.Set,tstrc_all_neg_noreduce.string1
	if ~t_15.isNeg() || $
		(t_15.getMilli() ne tstrc_all_neg_noreduce.r_ms) || $
		(t_15.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_15.getMinutes() ne tstrc_all_neg_noreduce.r_m) || $
		(t_15.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_15.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error G '+t_name
	
	t_15.Set,tstrc_all_neg_noreduce.string2
	if ~t_15.isNeg() || $
		(t_15.getMilli() ne tstrc_all_neg_noreduce.r_ms) || $
		(t_15.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_15.getMinutes() ne tstrc_all_neg_noreduce.r_m) || $
		(t_15.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_15.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error H '+t_name
	
	t_15.Set,tstrc_neg_reduce.string1
	if ~t_15.isNeg() || $
		(t_15.getMilli() ne tstrc_neg_reduce.r_ms) || $
		(t_15.getSeconds() ne tstrc_neg_reduce.r_s) || $
		(t_15.getMinutes() ne tstrc_neg_reduce.r_m) || $
		(t_15.getHours() ne tstrc_neg_reduce.r_h) || $
		(t_15.getDays() ne tstrc_neg_reduce.r_d) $
		then message,'data error I '+t_name
	
	t_15.Set,tstrc_neg_reduce.string2
	if ~t_15.isNeg() || $
		(t_15.getMilli() ne tstrc_neg_reduce.r_ms) || $
		(t_15.getSeconds() ne tstrc_neg_reduce.r_s) || $
		(t_15.getMinutes() ne tstrc_neg_reduce.r_m) || $
		(t_15.getHours() ne tstrc_neg_reduce.r_h) || $
		(t_15.getDays() ne tstrc_neg_reduce.r_d) $
		then message,'data error J '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 16: Set object with bad timestring argument
; 
t_name=utname+l_num.toString()+': Set object with bad timestring argument'
catch,err
if err eq 0 then begin
	t_16 = DSC_TIME_ABSOLUTE('3d33s15h')
	
	t_16.Set,'IamABadString'
	if (t_16.getMilli() ne 0) || $
		(t_16.getSeconds() ne 33) || $
		(t_16.getMinutes() ne 0) || $
		(t_16.getHours() ne 15) || $
		(t_16.getDays() ne 3) $
		then message,'data error A '+t_name
	
	t_16.Set,'10d2.3h'
	if (t_16.getMilli() ne 0) || $
		(t_16.getSeconds() ne 33) || $
		(t_16.getMinutes() ne 0) || $
		(t_16.getHours() ne 15) || $
		(t_16.getDays() ne 3) $
		then message,'data error B '+t_name
	
	t_16.Set,'3h-2m15s'
	if (t_16.getMilli() ne 0) || $
		(t_16.getSeconds() ne 33) || $
		(t_16.getMinutes() ne 0) || $
		(t_16.getHours() ne 15) || $
		(t_16.getDays() ne 3) $
		then message,'data error C '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 17: Set object when passed both string and keywords
; 
t_name=utname+l_num.toString()+': Set object when passed both string and keywords'
catch,err
if err eq 0 then begin
	t_17 = DSC_TIME_ABSOLUTE(mn=31)
	
	t_17.Set,'2d16h',d=5,mn=30
	if t_17.isNeg() || $
		(t_17.getMilli() ne 0) || $
		(t_17.getSeconds() ne 0) || $
		(t_17.getMinutes() ne 0) || $
		(t_17.getHours() ne 16) || $
		(t_17.getDays() ne 2) $
		then message,'data error A '+t_name

	t_17.Set,'-2d16h',d=5,mn='BadValue'
	if ~t_17.isNeg() || $
		(t_17.getMilli() ne 0) || $
		(t_17.getSeconds() ne 0) || $
		(t_17.getMinutes() ne 0) || $
		(t_17.getHours() ne 16) || $
		(t_17.getDays() ne 2) $
		then message,'data error B '+t_name


endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 18: Set object with good structure argument
; 
t_name=utname+l_num.toString()+': Set object with good structure argument'
catch,err
if err eq 0 then begin
	t_18 = DSC_TIME_ABSOLUTE('15m')
	
	t_18.SetAll,tstrc_all_pos_noreduce
	if t_18.isNeg() || $
		(t_18.getMilli() ne tstrc_all_pos_noreduce.r_ms) || $
		(t_18.getSeconds() ne tstrc_all_pos_noreduce.r_s) || $
		(t_18.getMinutes() ne tstrc_all_pos_noreduce.r_m) || $
		(t_18.getHours() ne tstrc_all_pos_noreduce.r_h) || $
		(t_18.getDays() ne tstrc_all_pos_noreduce.r_d) $
		then message,'data error A '+t_name

	t_18.SetAll,tstrc_all_neg_noreduce
	if (t_18.isNeg() ne  tstrc_all_neg_noreduce.r_neg) || $
		(t_18.getMilli() ne tstrc_all_neg_noreduce.r_ms) || $
		(t_18.getSeconds() ne tstrc_all_neg_noreduce.r_s) || $
		(t_18.getMinutes() ne tstrc_all_neg_noreduce.r_m) || $
		(t_18.getHours() ne tstrc_all_neg_noreduce.r_h) || $
		(t_18.getDays() ne tstrc_all_neg_noreduce.r_d) $
		then message,'data error B '+t_name

	t_18.SetAll,tstrc_some_pos
	if (t_18.getMilli() ne tstrc_some_pos.r_ms) || $
		(t_18.getSeconds() ne tstrc_some_pos.r_s) || $
		(t_18.getMinutes() ne tstrc_some_pos.r_m) || $
		(t_18.getHours() ne tstrc_some_pos.r_h) || $
		(t_18.getDays() ne tstrc_some_pos.r_d) $
		then message,'data error C '+t_name

	t_18.SetAll,tstrc_some_neg
	if ~t_18.isNeg() || $
		(t_18.getMilli() ne tstrc_some_neg.r_ms) || $
		(t_18.getSeconds() ne tstrc_some_neg.r_s) || $
		(t_18.getMinutes() ne tstrc_some_neg.r_m) || $
		(t_18.getHours() ne tstrc_some_neg.r_h) || $
		(t_18.getDays() ne tstrc_some_neg.r_d) $
		then message,'data error D '+t_name

	t_18.SetAll,tstrc_pos_reduce
	if t_18.isNeg() || $
		(t_18.getMilli() ne tstrc_pos_reduce.r_ms) || $
		(t_18.getSeconds() ne tstrc_pos_reduce.r_s) || $
		(t_18.getMinutes() ne tstrc_pos_reduce.r_m) || $
		(t_18.getHours() ne tstrc_pos_reduce.r_h) || $
		(t_18.getDays() ne tstrc_pos_reduce.r_d) $
		then message,'data error E '+t_name

	t_18.SetAll,tstrc_neg_reduce
	if ~t_18.isNeg() || $
		(t_18.getMilli() ne tstrc_neg_reduce.r_ms) || $
		(t_18.getSeconds() ne tstrc_neg_reduce.r_s) || $
		(t_18.getMinutes() ne tstrc_neg_reduce.r_m) || $
		(t_18.getHours() ne tstrc_neg_reduce.r_h) || $
		(t_18.getDays() ne tstrc_neg_reduce.r_d) $
		then message,'data error F '+t_name

	t_18.SetAll,tstrc_mix_reduce
	if (t_18.isNeg() ne tstrc_mix_reduce.r_neg ) || $
		(t_18.getMilli() ne tstrc_mix_reduce.r_ms) || $
		(t_18.getSeconds() ne tstrc_mix_reduce.r_s) || $
		(t_18.getMinutes() ne tstrc_mix_reduce.r_m) || $
		(t_18.getHours() ne tstrc_mix_reduce.r_h) || $
		(t_18.getDays() ne tstrc_mix_reduce.r_d) $
		then message,'data error G '+t_name	

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 19: Set object with bad structure argument
; 
t_name=utname+l_num.toString()+': Set object with bad structure argument'
catch,err
if err eq 0 then begin
	t_19 = DSC_TIME_ABSOLUTE('17s42m500ms2d4h')
	
	t_19.SetAll,7
	if t_19.isNeg() || $
		(t_19.getMilli() ne 500) || $
		(t_19.getSeconds() ne 17) || $
		(t_19.getMinutes() ne 42) || $
		(t_19.getHours() ne 4) || $
		(t_19.getDays() ne 2) $
		then message,'data error A '+t_name

		t_19.SetAll,!TRUE
	if t_19.isNeg() || $
		(t_19.getMilli() ne 500) || $
		(t_19.getSeconds() ne 17) || $
		(t_19.getMinutes() ne 42) || $
		(t_19.getHours() ne 4) || $
		(t_19.getDays() ne 2) $
			then message,'data error B '+t_name

		t_19.SetAll,'874m'
	if t_19.isNeg() || $
		(t_19.getMilli() ne 500) || $
		(t_19.getSeconds() ne 17) || $
		(t_19.getMinutes() ne 42) || $
		(t_19.getHours() ne 4) || $
		(t_19.getDays() ne 2) $
			then message,'data error C '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 20: Negate object
; 
t_name=utname+l_num.toString()+': Negate object'
catch,err
if err eq 0 then begin
	t_20A = DSC_TIME_ABSOLUTE(tstrc_pos_reduce.string1)
	t_20B = DSC_TIME_ABSOLUTE(tstrc_neg_reduce.string1)
	initA = t_20A.isNeg()
	initB = t_20B.isNeg()
	t_20A.Negate
	t_20B.Negate
	
	if (t_20A.isNeg() eq initA) || $
		(t_20A.getMilli() ne tstrc_pos_reduce.r_ms) || $
		(t_20A.getSeconds() ne tstrc_pos_reduce.r_s) || $
		(t_20A.getMinutes() ne tstrc_pos_reduce.r_m) || $
		(t_20A.getHours() ne tstrc_pos_reduce.r_h) || $
		(t_20A.getDays() ne tstrc_pos_reduce.r_d) $
		then message,'data error A '+t_name
		
	if (t_20B.isNeg() eq initB) || $
		(t_20B.getMilli() ne tstrc_neg_reduce.r_ms) || $
		(t_20B.getSeconds() ne tstrc_neg_reduce.r_s) || $
		(t_20B.getMinutes() ne tstrc_neg_reduce.r_m) || $
		(t_20B.getHours() ne tstrc_neg_reduce.r_h) || $
		(t_20B.getDays() ne tstrc_neg_reduce.r_d) $
		then message,'data error D '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 21: Get structure containing object values
;
t_name=utname+l_num.toString()+': Get structure containing object values'
catch,err
if err eq 0 then begin
	t_21 = DSC_TIME_ABSOLUTE(tstrc_pos_reduce.string2)
	g = t_21.getall()
	if (g.neg ne tstrc_pos_reduce.r_neg) || $
		(g.d ne tstrc_pos_reduce.r_d) || $
		(g.h ne tstrc_pos_reduce.r_h) || $
		(g.m ne tstrc_pos_reduce.r_m) || $
		(g.s ne tstrc_pos_reduce.r_s) || $
		(g.ms ne tstrc_pos_reduce.r_ms) $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 22: Copy object
;
t_name=utname+l_num.toString()+': Copy object'
catch,err
if err eq 0 then begin
	t_22A = DSC_TIME_ABSOLUTE('-34h12m')
	t_22B = t_22A.Copy()
	gA = t_22A.getall()
	gB = t_22B.getall()
	
	if (gA.neg ne gB.neg) || $
		(gA.d ne gB.d) || $
		(gA.h ne gB.h) || $
		(gA.m ne gB.m) || $
		(gA.s ne gB.s) || $
		(gA.ms ne gB.ms) $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 23: Add to object with good argument
; 
t_name=utname+l_num.toString()+': Add to object with good argument'
catch,err
if err eq 0 then begin
	t_23 = DSC_TIME_ABSOLUTE('23m50s')
	
	t_23.Add,'1h16m'
	g = t_23.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 0) || $
		(g.h ne 1) || $
		(g.m ne 39) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error A '+t_name

	t_23.Add,'0m'
	g = t_23.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 0) || $
		(g.h ne 1) || $
		(g.m ne 39) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error B '+t_name

	t_23.Add,'-1h16m'
	g = t_23.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 0) || $
		(g.h ne 0) || $
		(g.m ne 23) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error C '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 24: Add to object with bad argument
; 
t_name=utname+l_num.toString()+': Add to object with bad argument'
catch,err
if err eq 0 then begin
	t_24 = DSC_TIME_ABSOLUTE('1d23m50s')
	
	t_24.Add,!NULL
	g = t_24.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 1) || $
		(g.h ne 0) || $
		(g.m ne 23) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error A '+t_name

	t_24.Add,'taco'
	g = t_24.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 1) || $
		(g.h ne 0) || $
		(g.m ne 23) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error B '+t_name

	t_24.Add,576
	g = t_24.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 1) || $
		(g.h ne 0) || $
		(g.m ne 23) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error C '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 25: Subtract from object with good argument
; 
t_name=utname+l_num.toString()+': Subtract from object with good argument'
catch,err
if err eq 0 then begin
	t_25 = DSC_TIME_ABSOLUTE('23m50s')
	
	t_25.Sub,'1h16m'
	g = t_25.getall()
	if (g.neg ne !TRUE) || $
		(g.d ne 0) || $
		(g.h ne 0) || $
		(g.m ne 52) || $
		(g.s ne 10) || $
		(g.ms ne 0) $
		then message,'data error A '+t_name

	t_25.Sub,'0m'
	g = t_25.getall()
	if (g.neg ne !TRUE) || $
		(g.d ne 0) || $
		(g.h ne 0) || $
		(g.m ne 52) || $
		(g.s ne 10) || $
		(g.ms ne 0) $
		then message,'data error B '+t_name

	t_25.Sub,'-1h16m'
	g = t_25.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 0) || $
		(g.h ne 0) || $
		(g.m ne 23) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error C '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 26: Subtract from object with bad argument
; 
t_name=utname+l_num.toString()+': Subtract from object with bad argument'
catch,err
if err eq 0 then begin
	t_26 = DSC_TIME_ABSOLUTE('1d23m50s')
	
	t_26.Sub,!NULL
	g = t_26.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 1) || $
		(g.h ne 0) || $
		(g.m ne 23) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error A '+t_name

	t_26.Sub,'taco'
	g = t_26.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 1) || $
		(g.h ne 0) || $
		(g.m ne 23) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error B '+t_name

	t_26.Sub,576
	g = t_26.getall()
	if (g.neg ne !FALSE) || $
		(g.d ne 1) || $
		(g.h ne 0) || $
		(g.m ne 23) || $
		(g.s ne 50) || $
		(g.ms ne 0) $
		then message,'data error C '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 27: Representing object as a string
; 
t_name=utname+l_num.toString()+': Representing object as a string'
catch,err
if err eq 0 then begin
	t_27A = DSC_TIME_ABSOLUTE('4d32h12m54s300ms')
	t_27B = DSC_TIME_ABSOLUTE('16m3h')
	t_27C = DSC_TIME_ABSOLUTE('-2d2h3m4s1ms')
	t_27D = DSC_TIME_ABSOLUTE('-200m64s')
	if (t_27A.toString() ne '05d 08h 12m 54.300s') || $
		(t_27B.toString() ne '03h 16m') || $
		(t_27C.toString() ne '-02d 02h 03m 04.001s') || $
		(t_27D.toString() ne '-03h 21m 04s') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 28: Return Object value in various units
; 
t_name=utname+l_num.toString()+': Return Object value in various units'
catch,err
if err eq 0 then begin
	t_28 = DSC_TIME_ABSOLUTE('3h200m')
	if abs(t_28.toSeconds()- 22800.) gt 1e-6 then message,'data error A '+t_name
	if abs(t_28.toMinutes()- 380.) gt 1e-6 then message,'data error B '+t_name
	if abs(t_28.toHours()- (6+(1./3))) gt 1e-6 then message,'data error C '+t_name
	if abs(t_28.toDays()- (380./(60.*24.))) gt 1e-6 then message,'data error D '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 29: Parse a timestring
; 
t_name=utname+l_num.toString()+': Parse a timestring'
catch,err
if err eq 0 then begin
	; 			- good, positive
	; 			- good, negative
	; 			- bad
	g = dsc_time_absolute.StringParse('21h3m432ms')
	if (g.d ne 0) || $
		(g.h ne 21) || $
		(g.m ne 3) || $
		(g.s ne 0) || $
		(g.ms ne 432) $
		then message,'data error A '+t_name
		
	g = dsc_time_absolute.StringParse('-28h15s3m')
	if (g.d ne 0) || $
		(g.h ne -28) || $
		(g.m ne -3) || $
		(g.s ne -15) || $
		(g.ms ne 0) $
		then message,'data error B '+t_name
		
	g = dsc_time_absolute.StringParse('abadstring')
	if g ne -1 then message,'data error C '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 30: Convert between units of time - positive and negative
; 
t_name=utname+l_num.toString()+': Convert between units of time - positive and negative'
catch,err
if err eq 0 then begin
	;Just a spot check
	if abs(dsc_time_absolute.Convert(200,'m','d')-(10./72)) gt 1e-6 then message,'data error A '+t_name
	if abs(dsc_time_absolute.Convert(3,'h','s')- 10800.) gt 1e-6 then message,'data error B '+t_name
	if abs(dsc_time_absolute.Convert(200000,'ms','d')- 0.0023148) gt 1e-6 then message,'data error C '+t_name
	if abs(dsc_time_absolute.Convert(-32,'d','h')- (-768)) gt 1e-6 then message,'data error D '+t_name
	if abs(dsc_time_absolute.Convert(-15,'s','m')- (-.25)) gt 1e-6 then message,'data error E '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 31: Add two objects using the + operator
; 
t_name=utname+l_num.toString()+': Add two objects using the + operator'
catch,err
if err eq 0 then begin
	t_31A = dsc_time_absolute('18h32m12s')
	t_31B = dsc_time_absolute('-3h12m10s')
	
	t_31AA = t_31A + t_31A
	t_31BB = t_31B + t_31B
	t_31AB = t_31A + t_31B
	
	if t_31AA.toString() ne '01d 13h 04m 24s' then message,'data error A '+t_name
	if t_31BB.toString() ne '-06h 24m 20s' then message,'data error B '+t_name
	if t_31AB.toString() ne '15h 20m 02s' then message,'data error C '+t_name 
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 32: Subtract two objects using the - operator
; 
t_name=utname+l_num.toString()+': Subtract two objects using the - operator'
catch,err
if err eq 0 then begin
	t_32A = dsc_time_absolute('18h32m12s')
	t_32B = dsc_time_absolute('-3h12m10s')
	t_32C = dsc_time_absolute('4h13m')
	t_32D = dsc_time_absolute('-45m')
	
	t_32AA = t_32A - t_32A
	t_32BB = t_32B - t_32B
	t_32AB = t_32A - t_32B
	t_32BA = t_32B - t_32A
	t_32AC = t_32A - t_32C
	t_32BD = t_32B - t_32D
	
	if t_32AA.toString() ne '0s' then message,'data error A '+ t_name
	if t_32BB.toString() ne '0s' then message,'data error B '+ t_name
	if t_32AB.toString() ne '21h 44m 22s' then message,'data error C '+ t_name 
	if t_32BA.toString() ne '-21h 44m 22s' then message,'data error D '+ t_name
	if t_32AC.toString() ne '14h 19m 12s' then message,'data error E '+ t_name
	if t_32BD.toString() ne '-02h 27m 10s' then message,'data error F '+ t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num

END