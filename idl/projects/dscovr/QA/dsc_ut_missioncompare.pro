;+
; Name: dsc_ut_missioncompare.pro
;
; Purpose: command line test script for DSC_MISSION_COMPARE class
;
; Notes:	Called by dsc_cltestsuite.pro
;
; Test 1: Initialize
; Test 2: SetAll      
; Test 3: SetTitle    
; Test 4: SetMissions 
; Test 5: SetVars     
; Test 6: SetVar      
; Test 7: ClearVar
; Test 8: SetColor 
; Test 9: Reorder
; Test 10: Plot        
; Test 11: FindMTag    
; -


PRO DSC_UT_MISSIONCOMPARE,t_num=t_num

	compile_opt IDL2

	if ~keyword_set(t_num) then t_num = 0
	l_num = 1
	utname = 'DSC_MISSION_COMPARE Class '


; Test 1: Initialize
; 
t_name=utname+l_num.toString()+': Initialize'
catch,err
if err eq 0 then begin
	mco = Obj_New("DSC_MISSION_COMPARE",m1='wi',m2='d',vars=['np','bx','by'],title="My New Title")
	g = mco.getall()
	if g.mission1 ne 'WIND' || g.mission2 ne 'DSC' || $
		g.np ne 1 || g.bx ne 1 || g.by ne 1 || $
		(g.b+g.bz+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.vth) ne 0 || $
		g.title ne 'My New Title' || mco.gettitle() ne 'My New Title' $
		then message,'data error A '+t_name
	if ~array_equal(*g._order,['np','bx','by']) then message,'data error A2 '+t_name 
	color = mco.getColor()
	if ~array_equal(color.m1,[2,2,2]) || ~array_equal(color.m2,[0,0,0]) || ~array_equal(g._unifcolor,[!TRUE,!TRUE]) then message,'error '+t_name

	mc_str = {DSC_MISSION_COMPARE}
	mc_str.mission1 = 'wi'
	mc_str.mission2 = 'a'
	mc_str.bx = 1
	mco = DSC_MISSION_COMPARE(set=mc_str)
	g = mco.getall()
	if g.mission1 ne 'WIND' || g.mission2 ne 'ACE' || $
		g.bx ne 1 || $
		(g.b+g.by+g.bz+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.np+g.vth) ne 0 || $
		mco.getvars() ne 'bx' || $
		g.title ne '' $
		then message,'data error B '+t_name
	if ~isa(*g._order,/NULL) then message,'data error B2 '+t_name
	color = mco.getColor()
	if ~array_equal(color.m1,[2]) || ~array_equal(color.m2,[0]) || ~array_equal(g._unifcolor,[!TRUE,!TRUE]) then message,'error '+t_name
	
	mc_str.title = 'Now I Have a Title'
	mco = Obj_New("DSC_MISSION_COMPARE",set=mc_str,m1='WIND',m2='dscv',vars=['np','bx','by'],title="Another Title")
	g = mco.getall()
	if g.mission1 ne 'WIND' || g.mission2 ne 'ACE' || $
		g.bx ne 1 || $
		(g.b+g.by+g.bz+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.np+g.vth) ne 0 || $
		mco.getvars() ne 'bx' || $ 
		mco.gettitle() ne 'Now I Have a Title' $
		then message,'data error C '+t_name
	if ~isa(*g._order,/NULL) then message,'data error C2 '+t_name
			
	mco = dsc_mission_compare(m1='ace',m2='D',vars=['np','bx','by'])
	g = mco.getall()
	if g.mission1 ne 'ACE' || g.mission2 ne 'DSC' || $
		g.np ne 1 || g.bx ne 1 || g.by ne 1 || $
		(g.b+g.bz+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.vth) ne 0 || $
		g.title ne 'ACE in blue with DSC overplotted in black' || mco.gettitle() ne 'ACE in blue with DSC overplotted in black' $
		then message,'data error D '+t_name
	if ~array_equal(*g._order,['np','bx','by']) then message,'data error D2 '+t_name		
	
	mco = dsc_mission_compare(m1='ace',m2='D',vars='vx')
	g = mco.getall()
	if ~array_equal(*g._order,['vx']) then message, 'data error E '+t_name
	
	mco = dsc_mission_compare(m1='w',m2='d',vars=['v','bx','b'],c1=['b','r','k'],c2=[200,200,200])
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,[2,6,0]) || ~array_equal(color.m2,[200,200,200]) || $
		 ~array_equal(g._unifcolor,[!FALSE,!TRUE]) || $
		 g.title ne 'WIND with DSC overplotted' then message,'error '+t_name
	
	mco = dsc_mission_compare(m1='w',m2='d',vars=['v','bx','b'],c1=20,c2='m')
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,[20,20,20]) || ~array_equal(color.m2,[1,1,1]) || $
		 ~array_equal(g._unifcolor,[!TRUE,!TRUE]) || $
		 g.title ne 'WIND with DSC overplotted in magenta' then message,'error '+t_name

	; With bad color arguments - print warning and then use default colors
	mco = dsc_mission_compare(m1='w',m2='d',vars=['v','bx','b'],c1=['h','r','k'],c2=[200,-30,200])
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,[2,6,0]) || ~array_equal(color.m2,[200,0,200]) || $
		~array_equal(g._unifcolor,[!FALSE,!FALSE]) || $
		g.title ne 'WIND with DSC overplotted' then message,'error '+t_name
	
	mco = dsc_mission_compare(m1='w',m2='d',vars=['v','bx','b'],c1=['g','r','k','m'],c2=55)
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,[2,2,2]) || ~array_equal(color.m2,[55,55,55]) || $
		~array_equal(g._unifcolor,[!TRUE,!TRUE]) || $
		g.title ne 'WIND in blue with DSC overplotted' then message,'error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 2: SetAll
; 
t_name=utname+l_num.toString()+': SetAll'
catch,err
if err eq 0 then begin
	mc_str = {DSC_MISSION_COMPARE}
	mc_str.mission1 = 'DSCV'
	mc_str.mission2 = 'a'
	mc_str.bx = 1
	mc_str.vphi = 6
	mc_str.title = "A Generic Title"
	
	mco.setAll,mc_str
	g = mco.getall()
	if g.mission1 ne 'DSC' || g.mission2 ne 'ACE' || $
		g.bx ne 1 || g.vphi ne 1 || $
		(g.b+g.by+g.bz+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.np+g.vth) ne 0 || $
		(mco.getvars()).Join(' ') ne 'bx vphi' || $ 
		mco.gettitle() ne 'A Generic Title' $
		then message,'data error A '+t_name
	if ~isa(*g._order,/NULL) then message,'data error A2 '+t_name
	color = mco.getColor()
	if ~array_equal(color.m1,[2,2]) || ~array_equal(color.m2,[0,0]) || ~array_equal(g._unifcolor,[!TRUE,!TRUE]) then message,'error '+t_name
	
	mc_str._order = ptr_new(['vphi','bx'])
	mco.setAll,mc_str
	g = mco.getall()
	if (mco.getvars()).Join(' ') ne 'vphi bx' || $
			~array_equal(*g._order,['vphi','bx']) $
			then message,'data error A3 '+t_name
	color = mco.getColor()
	if ~array_equal(color.m1,[2,2]) || ~array_equal(color.m2,[0,0]) || ~array_equal(g._unifcolor,[!TRUE,!TRUE]) then message,'error '+t_name			

	*mc_str._order = ['b','np','vphi','bx']
	mco.setAll,mc_str
	g = mco.getall()
	if (mco.getvars()).Join(' ') ne 'bx vphi' || $
		~isa(*g._order,/NULL) $
		then message,'data error A4 '+t_name
		
	mc_str._unifColor = [!FALSE,!TRUE]	;Should ignore this and set appropriately	
	mco.setAll,mc_str
	g = mco.getall()
	if ~array_equal(color.m1,[2,2]) || ~array_equal(color.m2,[0,0]) || ~array_equal(g._unifcolor,[!TRUE,!TRUE]) then message,'error '+t_name

	mc_str._color = [ptr_new(['r']),ptr_new(['b','g'])]
	mco.setAll,mc_str
	g = mco.getall()
	color = mco.getColor()
	if ~array_equal(color.m1,[6,6]) || ~array_equal(color.m2,[2,4]) || ~array_equal(g._unifcolor,[!TRUE,!FALSE]) then message,'error '+t_name
		
	*mc_str._color[0] = [5,2,7,1,99,21]
	*mc_str._color[1] = ['o']
	mco.setAll,mc_str
	g = mco.getall()
	color = mco.getColor()
	if ~array_equal(color.m1,[2,2]) || ~array_equal(color.m2,[0,0]) || ~array_equal(g._unifcolor,[!TRUE,!TRUE]) then message,'error '+t_name

	*mc_str._color[0] = [285,45]
	*mc_str._color[1] = [199,199]
	mco.setAll,mc_str
	g = mco.getall()
	color = mco.getColor()
	if ~array_equal(color.m1,[2,45]) || ~array_equal(color.m2,[199,199]) || ~array_equal(g._unifcolor,[!FALSE,!TRUE]) then message,'error '+t_name
	
	;Bad arguments, should remain unchanged	
	exc1 = [2,45]
	exc2 = [199,199]
	exunif = [!FALSE,!TRUE]
	mco.setAll,{this:1,is:54,abad:"structure"}
	gtest = mco.getall()
	if ~compare_struct(g,gtest) then message,'data error B '+t_name  
	if ~array_equal(color.m1,exc1) || ~array_equal(color.m2,exc2) || ~array_equal(g._unifcolor,exunif) then message,'error '+t_name
	
	mco.setAll,54
	gtest = mco.getall()
	if ~compare_struct(g,gtest) then message,'data error C '+t_name
	if ~array_equal(color.m1,exc1) || ~array_equal(color.m2,exc2) || ~array_equal(g._unifcolor,exunif) then message,'error '+t_name
	
	mco.setAll,!FALSE
	gtest = mco.getall()
	if ~compare_struct(g,gtest) then message,'data error D '+t_name
	if ~array_equal(color.m1,exc1) || ~array_equal(color.m2,exc2) || ~array_equal(g._unifcolor,exunif) then message,'error '+t_name
		
	mco.setAll
	gtest = mco.getall()
	if ~compare_struct(g,gtest) then message,'data error E '+t_name
	if ~array_equal(color.m1,exc1) || ~array_equal(color.m2,exc2) || ~array_equal(g._unifcolor,exunif) then message,'error '+t_name
	
	mco.setAll,'I am a string'
	gtest = mco.getall()
	if ~compare_struct(g,gtest) then message,'data error F '+t_name
	if ~array_equal(color.m1,exc1) || ~array_equal(color.m2,exc2) || ~array_equal(g._unifcolor,exunif) then message,'error '+t_name	
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 3: SetTitle
; 
t_name=utname+l_num.toString()+': SetTitle'
catch,err
if err eq 0 then begin
	mco.setTitle,'The New Title'
	g = mco.getall()
	if g.title ne 'The New Title' || $
		mco.getTitle() ne 'The New Title' $
		then message,'data error A '+t_name
		
	expTitle = mco.getDefTitle()	
	mco.setTitle
	g = mco.getall()
	if g.title ne expTitle || $
		mco.getTitle() ne expTitle $
		then message,'data error B '+t_name

	mco.setTitle,'The Newest Title'
	mco.setTitle,['This is','Not a good','Title']
	g = mco.getall()
	if g.title ne 'The Newest Title' || $
		mco.getTitle() ne 'The Newest Title' $
		then message,'data error C '+t_name
	
	mco.setTitle,4682
	g = mco.getall()
	if g.title ne 'The Newest Title' || $
		mco.getTitle() ne 'The Newest Title' $
		then message,'data error D '+t_name
		
	mco.setTitle,!TRUE
	g = mco.getall()
	if g.title ne 'The Newest Title' || $
		mco.getTitle() ne 'The Newest Title' $
		then message,'data error E '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 4: SetMissions
; 
t_name=utname+l_num.toString()+': SetMissions'
catch,err
if err eq 0 then begin
	;limited tests, as it handles bad data with interactive prompts
	mco = DSC_MISSION_COMPARE(m1='ace',m2='wind',vars=['v','b','bz'])
	mco.setMissions,'d','wind'
	g = mco.getall()
	if g.mission1 ne 'DSC' || g.mission2 ne 'WIND' || $
		g.title ne 'DSC in blue with WIND overplotted in black' $
		then message,'data error A '+t_name

	mco.setMissions,'WIND','ACE'
	g = mco.getall()
	if g.mission1 ne 'WIND' || g.mission2 ne 'ACE' || $
		g.title ne 'WIND in blue with ACE overplotted in black' $
		then message,'data error B '+t_name

	mco.setMissions,'wd','ds'
	g = mco.getall()
	if g.mission1 ne 'WIND' || g.mission2 ne 'DSC' || $
		g.title ne 'WIND in blue with DSC overplotted in black' $
		then message,'data error C '+t_name

	mco.setMissions,'ace'
	g = mco.getall()
	if g.mission1 ne 'ACE' || g.mission2 ne 'DSC' || $
		g.title ne 'ACE in blue with DSC overplotted in black' $
		then message,'data error D '+t_name

	mco.setMissions,'WIND'
	g = mco.getall()
	if g.mission1 ne 'WIND' || g.mission2 ne 'DSC' || $
		g.title ne 'WIND in blue with DSC overplotted in black' $
		then message,'data error E '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 5: SetVars
; 
t_name=utname+l_num.toString()+': SetVars'
catch,err
if err eq 0 then begin
	mco.setVars,'vz'
	if mco.getVars() ne 'vz' then message,'data error A '+t_name
	
	invars = ['bx','vx','v','bphi']
	mco.setVars,invars
	vars = mco.getVars()
	if ~array_equal(invars,vars) then message,'data error B '+t_name
	
	mc_str = {DSC_MISSION_COMPARE}
	mc_str.mission1 = 'DSCV'
	mc_str.mission2 = 'a'
	mc_str.bx = 1
	mc_str.vphi = 6
	mc_str.title = "A Generic Title"
	mco.setVars,mc_str		; Has default order
	vars = mco.GetVars()
	if ~array_equal(vars,['bx','vphi']) then mesage,'data error C '+t_name
	
	mc_str.np = 1
	mc_str._order = ptr_new(['vphi','np','bx'])
	mco.setVars,mc_str		; Has a valid order
	vars = mco.GetVars()
	if ~array_equal(vars,['vphi','np','bx']) then mesage,'data error D '+t_name

	mc_str.bz = 1
	mco.setVars,mc_str		;Has an invalid order -> use default
	vars = mco.GetVars()
	if ~array_equal(vars,['bx','bz','vphi','np']) then mesage,'data error E '+t_name
	
	; Don't test this - it rightly triggers an interactive session
;	mco.setVars,321
;	mco.setVars,['g','hssa']
;	mco.setVars,!TRUE	
;	vars = mco.GetVars()
;	if ~array_equal(vars,['bx','bz','vphi','np']) then mesage,'data error F '+t_name
	
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 6: SetVar
; 
t_name=utname+l_num.toString()+': SetVar'
catch,err
if err eq 0 then begin
	mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
	mco.setVar,'bz'
	g = mco.getall()
	if (g.np+g.bx+g.by+g.bz) ne 4 || $
		(g.b+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.vth) ne 0 $
		then message,'data error A '+t_name
	if ~array_equal(mco.getVars(),['np','bx','by','bz']) then message,'data error A2 '+t_name
			
	mco.setVar,/all
	g = mco.getall()
	if (g.np+g.bx+g.by+g.bz+g.b+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.vth) ne 14 $
		then message,'data error B '+t_name
	if ~array_equal(mco.getVars(),['b','bx','by','bz','btheta','bphi','v','vx','vy','vz','vtheta','vphi','np','vth']) $
		then message,'data error B2 '+t_name

	mco.setVars,['bx','v']		
	mco.SetVar,'badvariable'
	g = mco.getall()
	if (g.np+g.bx+g.by+g.bz+g.b+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.vth) ne 2 || $
		(g.bx+g.v) ne 2 $
		then message,'data error C '+t_name
	if ~array_equal(mco.getVars(),['bx','v']) then MESSAGE,'data error C2 '+t_name
		
	mco.setVar
	if ~array_equal(mco.getVars(),['bx','v']) then message,'data error D '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 7: ClearVar
; 
t_name=utname+l_num.toString()+': ClearVar'
catch,err
if err eq 0 then begin
	mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
	mco.clearVar,'bx'
	g = mco.getall()
	if (g.np+g.by) ne 2 || $
		(g.b+g.bx+g.bz+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.vth) ne 0 $
		then message,'data error A '+t_name
	if ~array_equal(mco.getVars(),['np','by']) then message,'data error A2 '+t_name
			
	mco.clearVar,/all
	g = mco.getall()
	if (g.np+g.bx+g.by+g.bz+g.b+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.vth) ne 0 $
		then message,'data error B '+t_name
	if ~isa(mco.getVars(),/NULL) then message,'data error B2 '+t_name

	mco.setVars,['bx','v']		
	mco.clearVar,'badvariable'
	g = mco.getall()
	if (g.np+g.bx+g.by+g.bz+g.b+g.btheta+g.bphi+g.v+g.vx+g.vy+g.vz+g.vtheta+g.vphi+g.vth) ne 2 || $
		(g.bx+g.v) ne 2 $
		then message,'data error C '+t_name
	if ~array_equal(mco.getVars(),['bx','v']) then message,'data error C2 '+t_name
		
	mco.clearVar
	if ~array_equal(mco.getVars(),['bx','v']) then message,'data error D '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 8: SetColor
;
t_name=utname+l_num.toString()+': SetColor'
catch,err
if err eq 0 then begin
	mco = DSC_MISSION_COMPARE(m1='dsc',m2='wind',vars=['v','bz','np','bphi'],c1=['b','g','k','r'],c2=['g','b','r','k'])
	mco.setColor,1	; Set mission 1 colors to default
	ex1 = [2,2,2,2]
	ex2 = [4,2,6,0]
	exUnif = [!TRUE,!FALSE]
	exTitle = 'DSC in blue with WIND overplotted'
	color = mco.getColor()
	g = mco.getall()	;Messy way to get to _unifcolor, but not generally expecting user to access this field 
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco = DSC_MISSION_COMPARE(m1='dsc',m2='wind',vars=['v','bz','np','bphi'],c1=['b','g','k','r'],c2=['g','b','r','k'])
	mco.setColor,2	; Set mission 2 colors to default
	ex1 = [2,4,0,6]
	ex2 = [0,0,0,0]
	exUnif = [!FALSE,!TRUE]
	exTitle = 'DSC with WIND overplotted in black'
	color = mco.getColor()
	g = mco.getall()	
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name	
	
	mco = DSC_MISSION_COMPARE(m1='dsc',m2='wind',vars=['v','bz','np','bphi'],c1=['b','g','k','r'],c2=['g','b','r','k'])
	mco.setColor	;Set all to defaults
	ex1 = [2,2,2,2]
	ex2 = [0,0,0,0]
	exUnif = [!TRUE,!TRUE]
	exTitle = 'DSC in blue with WIND overplotted in black'
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name

	mco = DSC_MISSION_COMPARE(m1='dsc',m2='wind',vars=['v','bz','np','bphi'],c1=['b','g','k','r'],c2=['g','b','r','k'])
	mco.setColor,1,'m'	; Set all mission 1 colors to magenta
	ex1 = [1,1,1,1]
	ex2 = [4,2,6,0]
	exUnif = [!TRUE,!FALSE]
	exTitle = 'DSC in magenta with WIND overplotted'
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,2,185	; Set all mission 2 colors to colortable value 185
	ex1 = [1,1,1,1]
	ex2 = [185,185,185,185]
	exUnif = [!TRUE,!TRUE]
	exTitle = 'DSC in magenta with WIND overplotted'
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,1,'c','np'	; Set mission 1 NP to cyan
	ex1 = [1,1,3,1]
	ex2 = [185,185,185,185]
	exUnif = [!FALSE,!TRUE]
	exTitle = 'DSC with WIND overplotted'
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,2,233,1		; Set mission 2, top panel color to colortable value 233
	ex1 = [1,1,3,1]
	ex2 = [233,185,185,185]
	exUnif = [!FALSE,!FALSE]
	exTitle = 'DSC with WIND overplotted'
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.clearVar,'np'
	ex1 = [1,1,1]
	ex2 = [233,185,185]
	exUnif = [!TRUE,!FALSE]
	exTitle = 'DSC in magenta with WIND overplotted'
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name

	mco.setVar,'np'
	ex1 = [1,1,1,2]
	ex2 = [233,185,185,0]
	exUnif = [!FALSE,!FALSE]
	exTitle = 'DSC with WIND overplotted'
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,/help	; Invoke the help text
	
	;Bad cases. Colors should remain unchanged.
	mco.setColor,3,'b'	; Bad mission number
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,'ace',5	; Bad mission arg
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,1,'gr'	; Bad color string
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,2,308	; Bad color index
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,1,200,0	; Bad panel number - low
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,2,100,10	; Bad panel number - high
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
	mco.setColor,1,'b','vphi'	; Bad panel variable id
	color = mco.getColor()
	g = mco.getall()
	if ~array_equal(color.m1,ex1) || ~array_equal(color.m2,ex2) || ~array_equal(g._unifcolor,exUnif) $
		|| g.title ne exTitle then MESSAGE,'error'+t_name
	
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 9: Reorder
;
t_name=utname+l_num.toString()+': Reorder'
catch,err
if err eq 0 then begin
	mco = DSC_MISSION_COMPARE(m1='dsc',m2='wind',vars=['v','bz','np','bphi'],c1=['b','g','k','r'],c2=['g','b','r','k'])

	mco.reorder,4		; Move 4th item to top
	expected = ['bphi','v','bz','np']
	c1expected = [6,2,4,0]
	c2expected = [0,4,2,6]
	colors = mco.getColor()
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error A '+t_name
	
	mco.reorder,2,3		; Move 2nd item to 3rd
	expected = ['bphi','bz','v','np']
	c1expected = [6,4,2,0]
	c2expected = [0,2,4,6]
	colors = mco.getColor()
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error B '+t_name

	mco.reorder,'bz'		; Move BZ to top
	expected = ['bz','bphi','v','np']
	c1expected = [4,6,2,0]
	c2expected = [2,0,4,6]
	colors = mco.getColor()
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error C '+t_name

	mco.reorder,'np',2		; Move NP item to 2nd
	expected = ['bz','np','bphi','v']
	c1expected = [4,0,6,2]
	c2expected = [2,6,0,4]
	colors = mco.getColor()
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error D '+t_name

	mco.reorder,['np','bz','v','bphi']		; Arrange panels to match string array
	expected = ['np','bz','v','bphi']
	c1expected = [0,4,2,6]
	c2expected = [6,2,4,0]
	colors = mco.getColor()
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error E '+t_name

	mco.reorder,[4,3,2,1]		; Arrange panels to match index array
	expected = ['bphi','v','bz','np']
	c1expected = [6,2,4,0]
	c2expected = [0,4,2,6]
	colors = mco.getColor()
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error F '+t_name

	mco.reorder,'bx'		; Bad input string, good position
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error G '+t_name

	mco.reorder,'bx',7 	; Bad input string, bad position
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error H '+t_name

	mco.reorder,'np',9		; Good input string, bad position
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error I '+t_name

	mco.reorder,['bx','v','btheta','bz']		; Bad content, good length input- string array
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error J '+t_name

	mco.reorder,['bx','btheta','bz']		; Bad content, bad length input- string array
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error K '+t_name

	mco.reorder,['v','bz']		; Good content, bad length (low) input- string array
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error L '+t_name

	mco.reorder,['np','bz','vth','v','bphi']		; Bad length (high) input- string array
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error M '+t_name
	
	mco.reorder,[5,4,0,2]		; Bad content, good length input- index array
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error N '+t_name

	mco.reorder,[5,0,2]		; Bad content, bad length input- index array
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error O '+t_name

	mco.reorder,[4,2]		; Good content, bad length (low) input- index array
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error P '+t_name

	mco.reorder,[5,3,1,2,4]		; Bad length (high) input- index array
	if ~array_equal(mco.getVars(), expected) || $ 
		~array_equal(colors.m1, c1expected) || ~array_equal(colors.m2, c2expected) $
		then message,'data error Q '+t_name
	
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 10: Plot
; 
t_name=utname+l_num.toString()+': Plot'
catch,err
if err eq 0 then begin
	timespan,'2017-01-01'
	
	; Default panel order
	st = {DSC_MISSION_COMPARE}
	st.np = 1
	st.v = 1
	st.bphi = 1
	st.mission1 = 'ace'
	st.mission2 = 'dsc'
	st._color[0] = ptr_new([2,1,4])	;Not the best way to set this 
	st._color[1] = ptr_new([0,4,5])
	mco = DSC_MISSION_COMPARE(set=st)
	mco.setTitle
	mco.plot
	
	g = mco.getall()
	vars = mco.getvars()
	tplot_options,get_options=gopt

	if n_elements(vars) ne n_elements(gopt.varnames) then message,'data error A '+t_name
	foreach name,gopt.varnames do begin
		error = !FALSE
		if ~name.Matches('^'+g.mission1+'&'+g.mission2+'_') then error=!TRUE
		vstring = (name.split('_'))[-1]

		r = where(vstring eq vars,rcount,comp=rcomp,ncomp=ncomp)
		if rcount eq !NULL then error=!TRUE $
		else vars = (ncomp gt 0) ? vars[rcomp] : []

		if error then message,'data error B '+t_name
	endforeach
	
	; Specified panel order
	exp_order = ['np','v','bphi']
	exp_colors1 = [4,1,2]	;
	exp_colors2 = [5,4,0]
	mco.reorder,exp_order[*]
	mco.plot

	g = mco.getall()
	tplot_options,get_options=gopt
	
	if n_elements(exp_order) ne n_elements(gopt.varnames) then message,'data error C '+t_name
	foreach name,gopt.varnames,i do begin
		vstring = (name.split('_'))[-1]
		if vstring ne exp_order[i] then message,'data error D '+t_name
		
		alim = {}
		get_data,name,alim=alim
		if ~array_equal(alim.colors ,[exp_colors1[i],exp_colors2[i]]) then message,'data error E '+t_name
	endforeach
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


; Test 11: FindMTag
;
t_name=utname+l_num.toString()+': FindMTag'
catch,err
if err eq 0 then begin
	r = DSC_MISSION_COMPARE.FindMTag()
	r2 = mco.FindMTag()
	if ~isa(r,/null) || ~isa(r2,/null) then message,'data error A '+t_name
	
	r = DSC_MISSION_COMPARE.FindMTag('a')
	r2 = mco.FindMTag('wnd')
	if r ne 'ACE' || r2 ne 'WIND' then message,'data error B '+t_name
	
	r = DSC_MISSION_COMPARE.FindMTag('WIND')
	r2 = mco.FindMTag('DSC')
	if r ne 'WIND' || r2 ne 'DSC' then message,'data error C '+t_name

	r = DSC_MISSION_COMPARE.FindMTag(['d','w'])
	r2 = mco.FindMTag(['ACE','wd'])
	if ~isa(r,/null) || ~isa(r2,/null) then message,'data error D '+t_name
	
	r = DSC_MISSION_COMPARE.FindMTag(/all)
	r2 = mco.FindMTag(/all)
	if ~isa(r,/string,/array) || ~isa(r2,/string,/array) then message,'data error E '+t_name
	if r.length ne 3 || r2.length ne 3 then message,'data error F '+t_name

	r = !NULL
	r2 = !NULL
	r = DSC_MISSION_COMPARE.FindMTag('wind',/all)
	r2 = mco.FindMTag('wind',/all)
	if ~isa(r,/string,/array) || ~isa(r2,/string,/array) then message,'data error E '+t_name
	if r.length ne 3 || r2.length ne 3 then message,'data error F '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num

store_data,'*',/del
END