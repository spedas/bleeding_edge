;+
;dsc_mission_compare method: Plot
;
;Creates a plot to visualize the comparison described in the associated
;DSC_MISSION_COMPARE object.  Loads data as needed.
;
;Calling Sequence: 
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])  
;  mco.plot
;  
;Inputs:
;  (none)
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2018
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/mission_compare/dsc_mission_compare__plot.pro $
;-----------------------------------------------------------------------------------;				

;ace_mfi_load  datatype = One of: ['k0, 'h0', 'h1', 'h2', 'h3'] -- k0 is default
;ace_swe_load [k0,k1,h0,h2] -- k0 default

PRO DSC_MISSION_COMPARE::Plot 
	rstr = {routines, magload:'',plasload:'',ezname:''}
	vstr = {varstruct, type:'', ytitle:'', ysubtitle:'', create:'', parent:''}
	minfo = dictionary({ $
		WIND:{routines,'wi_mfi_load','wi_swe_load','wi_ezname'}, $
		DSC: {routines,'dsc_load_mag','dsc_load_fc','dsc_ezname'}, $
		ACE: {routines,'ace_mfi_load','ace_swe_load','ace_ezname'} $
		})
	vardict = dictionary({ $
		b: {varstruct, 'mag', 'B', '[nT]','cart_to_sphere','bgse'}, $
		bx: {varstruct, 'mag', 'Bx (GSE)', '[nT]','split_vec','bgse'},  $
		by: {varstruct, 'mag', 'By (GSE)', '[nT]','split_vec','bgse'},  $
		bz: {varstruct, 'mag', 'Bz (GSE)', '[nT]','split_vec','bgse'},  $
		btheta: {varstruct, 'mag', 'Btheta (GSE)', '[deg]','cart_to_sphere','bgse'},  $
		bphi: {varstruct, 'mag', 'Bphi (GSE)', '[deg]','cart_to_sphere','bgse'},  $
		v: {varstruct, 'plas', 'V', '[km/s]','cart_to_sphere','vgse'},  $
		vx: {varstruct, 'plas', 'Vx (GSE)', '[km/s]','split_vec','vgse'},  $
		vy: {varstruct, 'plas', 'Vy (GSE)', '[km/s]','split_vec','vgse'},  $
		vz: {varstruct, 'plas', 'Vz (GSE)', '[km/s]','split_vec','vgse'},  $
		vtheta: {varstruct, 'plas', 'Vtheta (GSE)', '[deg]','cart_to_sphere','vgse'},  $
		vphi: {varstruct, 'plas', 'Vphi (GSE)', '[deg]','cart_to_sphere','vgse'},  $
		np: {varstruct, 'plas', 'Ion N', '[#/cc]','load',''},  $
		vth: {varstruct, 'plas', 'Vth', '[km/s]','load',''} $
		})
	
	self.CheckSettings
	spd_graphics_config
	
	; based on vars and missions -- determine variables to look for
	varlist = self.GetVars()
	m1vars = call_function(minfo[self.mission1].ezname,varlist)
	m2vars = call_function(minfo[self.mission2].ezname,varlist)
	
	; if variables missing - load /process as needed
	trg = timerange()
	missing = dictionary(  $
		self.mission1,dictionary('mag',[],'plas',[]), $
		self.mission2,dictionary('mag',[],'plas',[])  $
		)
	foreach m1var,m1vars,i do begin
		if m1var eq '' then begin
			print,self.mission1 +' does not support '+varlist[i]
		endif else if ~tdexists(m1var,trg[0],trg[1]) then begin
			(missing[self.mission1])[(vardict[varlist[i]]).type] = $
				[(missing[self.mission1])[(vardict[varlist[i]]).type],{abbr:varlist[i],name:m1var}]
		endif
	endforeach
	foreach m2var,m2vars,i do begin
		if m2var eq '' then begin
			print,self.mission2 + ' does not support '+varlist[i]
		endif else if ~tdexists(m2var,trg[0],trg[1]) then begin
			(missing[self.mission2])[(vardict[varlist[i]]).type] = $
				[(missing[self.mission2])[(vardict[varlist[i]]).type],{abbr:varlist[i],name:m2var}]
		endif
	endforeach

	
	;foreach mission in 'missing'
	; if any mag type missing then
	;  start at first one, lookup 'parent', check forparent exist.. - or if it's just loadable
	;		if not exist - load parent
	;   lookup create function  / call on parent
	; 	now -- check entire misson/mag list -- any still missing?
	; 	if yes, jump to next missing index and loop again
	;   else done
	; repeate with plas

	foreach mission,missing,mkey do begin
		foreach typelist,mission,tkey do begin
			done = (isa(typelist)) ? 0 : 1
			i = 0
			while not done do begin
				info = vardict[(typelist[i]).abbr]
				if info.create ne 'load' then pname = call_function(minfo[mkey].ezname,info.parent) $
					else pname  = typelist[i].name
				testpname = pname
;				if isa(pname) then testpname = pname ;because tdexists() modifies the input
				if (info.create eq 'load') || ( ~tdexists(testpname,trg[0],trg[1])) then begin
					if info.type eq 'mag' then call_procedure,minfo[mkey].magload $
					else if info.type eq 'plas' then call_procedure,minfo[mkey].plasload $
					else message,'ERROR'
				endif
				;check this one again here.. in case straight loading got it
				
				testpname = pname
				if tdexists(testpname,trg[0],trg[1]) then begin
					testname = (typelist[i]).name
					if ~tdexists(testname,trg[0],trg[1]) then begin
						if (info.create eq 'cart_to_sphere') then begin
							get_data,pname,data=d
							x = d.y[*,0]
							y = d.y[*,1]
							z = d.y[*,2]
							cart_to_sphere,x,y,z,r,theta,phi,ph_0_360=1
							store_data,pname+'_F2',data={x:d.x, y:r}
							store_data,pname+'_THETA',data={x:d.x, y:theta}
							store_data,pname+'_PHI',data={x:d.x, y:phi}
						endif else if (info.create eq 'split_vec') then begin
							split_vec,pname
						endif
					endif
				endif
				
				; test again for missings, if no , set done
				needmore = 0
				for j=i,n_elements(typelist)-1 do begin
					testname = (typelist[j]).name
					if (~tdexists(testname,trg[0],trg[1])) then begin
						if j ne i then begin
							needmore = 1
							print,'Still missing ',(typelist[j]).name
							break							
						endif
					endif
				endfor
				if needmore then begin
					i = j
				endif else done = 1
			endwhile
		endforeach
	endforeach
		
	tn = []
	color = self.getColor()
	foreach var,varlist,i do begin
		comboname = self.mission1+'&'+self.mission2+'_'+var
		options,m1vars[i],labels=self.mission1
		options,m2vars[i],labels=self.mission2
		store_data,comboname,data=[m1vars[i],m2vars[i]],dlimit={ytitle:vardict[var].ytitle,ysbutitle:vardict[var].ysubtitle,colors:[color.m1[i],color.m2[i]]}
		tn = [tn,comboname]
	endforeach
	tplot,tn,title=self.title,new_tvars=new_tvars
	
	; TODO how to change panel order..?
END