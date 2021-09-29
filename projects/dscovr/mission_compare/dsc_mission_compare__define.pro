;+
;NAME:
; DSC_MISSION_COMPARE__DEFINE
;
;PURPOSE:
; Defines an object that represents a comparison between data of two missions
; and enables simplified plotting of matching parameters between the two.
; Currently supports the DSCOVR, WIND, and ACE default loaded datatypes.
;
;
;CALLING SEQUENCE:
; mco = Obj_New("DSC_MISSION_COMPARE")
; mco = Obj_New("DSC_MISSION_COMPARE",m1='wi',m2='d',vars=['np','bx','by'])
; mco = dsc_mission_compare()
; mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;
; REQUIRED INPUT:
; none - it will query for required information if none is passed.
;
;KEYWORDS (Optional):
; C1=:     Mission 1 color (array/scalar) (int/string)
; C2=:     Mission 2 color (array/scalar) (int/string)
;          Color arrays must match size to number of variables selected
;          IDL single char color strings supported. [k,m,b,c,g,y,r,w] 
; M1=:     Mission 1 shortcut string (string)
; M2=:     Mission 2 shortcut string (string)
; SET=:    A DSC_MISSION_COMPARE structure to use to initialize this object.  
;            This keyword supercedes the other keywords.
; TITLE=:  Title to use for comparison plot.  If not set, will create a 
;            default based on the missions set (string)
; VARS=:   Shortcut string(s) describing which variable(s) to compare between
;            the two missions.  If scalar, will describe a plot with one panel.
;            If array, the comparison plot will have one panel for each array 
;            element. (string)
;
;OUTPUT:
; dsc_mission_compare object reference
;
;METHODS:
; SetAll      - modify this object by passing a DSC_MISSION_COMPARE structure
; SetTitle    - modify the comparison plot title
; SetMissions - modify which missions to compare. Pass arguments or set interactively.  
; SetVars     - sets all comparison variables based on passed string array OR interactive prompt 
; SetVar      - set one variable to be compared, leaving other variable settings intact. OR set all with keyword \all.
; SetColor    - set the plotted line colors for the selected variables
; Plot        - create a plot based on this comparison object
; ClearVar    - de-selects one variable from the comparison, leaving other variable settings intact. OR unset all with keyword \all
; Reorder     - reorders the comparison variables
; GetAll      - returns a structure of type {dsc_mission_compare} containing this object's values
; GetTitle    - returns the object title (string)
; GetColor    - returns the object color settings
; GetVars     - returns a string array of shortcut names for all variables to be compared.
; FindMTag    - (Static Method) find a mission tag based on a passed string 
;                  OR return all supported mission tags with the \all keyword
;
;NOTES:
; print/implied print are overloaded for this class.
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2018
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/mission_compare/dsc_mission_compare__define.pro $
;-----------------------------------------------------------------------------------

FUNCTION DSC_MISSION_COMPARE::INIT,set=setting_str,m1=m1,m2=m2,vars=vars,title=title,c1=c1,c2=c2
	compile_opt idl2
	
	if isa(setting_str,'DSC_MISSION_COMPARE') then begin
		if isa(setting_str._color[0]) then c1 = *setting_str._color[0]
		if isa(setting_str._color[1]) then c2 = *setting_str._color[1]
		struct_assign,setting_str,self
		self.CheckSettings
		if isa(c1) then begin
			self.setColor,1
			self.setColor,1,c1
		endif
		if isa(c2) then begin
			self.setColor,2
			self.setColor,2,c2
		endif
		defTitle = self.getDefTitle()
		self._defTitle =  (self.title eq defTitle) ? !TRUE : !FALSE
	endif else begin
		self._order = ptr_new(/allocate_heap)
		self._color = [ptr_new(/allocate_heap),ptr_new(/allocate_heap)]
		self.setMissions,m1,m2
		if isa(vars) then self.setVars,vars else self.setVars
		if isa(c1) then self.setColor,1,c1
		if isa(c2) then self.setColor,2,c2
		if isa(title) then self.setTitle,title else self.setTitle 
	endelse
	
	return,1
END	


;+
;DESCRIPTION: 
;  Set new values of this object by passing a DSC_MISSION_COMPARE structure
;  
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  c = mco.getall()
;  c.btheta=1
;  c.vx = 1
;  c.np = 0
;  c.m1='ace'
;  mco.setall,c
;-
PRO DSC_MISSION_COMPARE::SetAll,setting_str
	compile_opt idl2

	if isa(setting_str,'DSC_MISSION_COMPARE') then begin
		if isa(setting_str._color[0]) then c1 = *setting_str._color[0]
		if isa(setting_str._color[1]) then c2 = *setting_str._color[1]
		struct_assign,setting_str,self
		self.CheckSettings
		if isa(c1) then begin
			self.setColor,1
			self.setColor,1,c1
		endif
		if isa(c2) then begin
			self.setColor,2
			self.setColor,2,c2
		endif
		defTitle = self.getDefTitle()
		self._defTitle =  (self.title eq defTitle) ? !TRUE : !FALSE
	endif else dprint,dlevel=2,'Invalid input. DSC_MISSION_COMPARE expected.'
END


FUNCTION DSC_MISSION_COMPARE::_overloadPrint
	compile_opt idl2
	
	vars = self.getvars()
	colors = self.getcolor()
	if isa(vars,/NULL) then vars = ''
	if isa(colors,/NULL) then colors = {m1:'',m2:''}
	out = { $
		mission1: self.mission1, $
		mission2: self.mission2, $
		title: self.title, $
		variables: vars, $
		M1_color: colors.m1, $
		M2_color: colors.m2 $
		}
		
	return, out
END


FUNCTION DSC_MISSION_COMPARE::_overloadImpliedPrint,varname
	compile_opt idl2
	return, self.DSC_MISSION_COMPARE::_overloadPrint()
END


PRO DSC_MISSION_COMPARE::CheckSettings
	compile_opt idl2
	
	std_names = DSC_MISSION_COMPARE.FindMTag(/all)
	m1_r = where(self.mission1 eq std_names,m1count)
	m2_r = where(self.mission2 eq std_names,m2count)
	if (m1count ne 1) || (m2count ne 1) || $  
		self.mission1 eq self.mission2 then self.SetMissions,self.mission1,self.mission2
	
	tags = tag_names(self)
	settags = []
	ix = (where(tags eq 'TITLE'))[0] + 1
	jx = (where(tags eq '_ORDER'))[0] - 1
	for i = ix,jx do begin
		if self.(i) ne 0 then begin
			self.(i) = 1
			settags = [settags,tags[i]]
		endif
	endfor

	if ~isa(self._order) then self._order = ptr_new(/allocate_heap)
	for i=0,1 do begin
		if ~isa(self._color[i]) then begin
			self._color[i] = ptr_new(/allocate_heap)
			self.SetColor,i+1
		endif
	endfor


	varnames = self.getVars()
	if ~isa(varnames) then self.setVars $
	else if ~isa(*self._order,/NULL) then begin
		self.CleanOrder		;remove any duplicate entries
		if ~dsc_is_permutation(settags.toLower(),*self._order) then begin
			(*self._order) = []
			dprint,dlevel=2,'Invalid Order: using default'
		endif			
	endif
END


;+
;DESCRIPTION:
;  Modify the comparison plot title.
;  Called with no argument will set the default title based on selected missions
;
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  mco.setTitle,'Comparing WIND and DSCOVR'
;-
PRO DSC_MISSION_COMPARE::SetTitle,title
	compile_opt idl2
	
	if isa(title,'UNDEFINED') then begin
		self.title = self.getDefTitle()
		self._defTitle = !TRUE 
	;self.title = self.mission1+' with '+self.mission2+' overplotted in black' $
	endif else if isa(title,/STRING,/SCALAR) then begin
		self.title = title
		self._defTitle = !FALSE
	endif else dprint,dlevel=2,'Invalid Title'

END


;+
;DESCRIPTION:
;  Set which missions to compare. 
;  Pass as string arguments or set interactively if no arguments passed.
;  If only one argument is passed, it updates Mission 1
;  
;  If missions are changed and it is already using a default title,
;  it will update the default title.  Otherwise, it will prompt the
;  user whether or not to update the current title to a new default
;  title.  
;  
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  mco.setMissions,'ace','dsc'
;-
PRO DSC_MISSION_COMPARE::SetMissions,m1,m2
  compile_opt idl2
  
  m1_init = self.mission1
  m2_init = self.mission2
  
  opts = DSC_MISSION_COMPARE.findMtag(/all)
  addtxt = ((1+indgen(opts.length)).toString())+':'

	if (n_params() eq 0) || (isa(m1,'UNDEFINED') && isa(m2,'UNDEFINED')) then begin
		id=-1.
		catch,ioerr
		repeat begin
			read,id,prompt='(Mission 1) '+((addtxt+opts).Join(' '))+'? (#)>'
			found = where(id eq 1+indgen(opts.length),count)
		endrep until (count ne 0) 
		catch,/cancel
		
		self.mission1 = opts[id-1]
		case (id) of
			1: begin
				opts2 = opts[1:*]
				addtxt2 = addtxt[1:*]
			end
			n_elements(opts): begin
				opts2 = opts[0:-2]
				addtxt2 = addtxt[0:-2]
			end
			else: begin
				opts2 = [opts[0:id-2],opts[id:*]]
				addtxt2 = [addtxt[0:id-2],addtxt[id:*]]
			end
		endcase
		
		count = 0
		catch,ioerr		
		repeat begin
			read,id,prompt='(Mission 2) '+((addtxt2+opts2).Join(' '))+'? '
			found = where(id eq addtxt2.Extract('[0-9]'),count)
		endrep until (count ne 0)
		catch,/cancel
		self.mission2 =opts[id-1]

	endif else if n_params() eq 1 then begin
		self.SetMissions,m1,self.mission2

	endif else begin
		m1_good = 0
		m2_good = 0
		if isa(m1,/STRING,/SCALAR) then begin
			stdName = DSC_MISSION_COMPARE.FindMTag(m1)
			if stdName ne !NULL then begin
				self.mission1 = stdName
				m1_good = 1
			endif
		endif
		if isa(m2,/STRING,/SCALAR) then begin
			stdName = DSC_MISSION_COMPARE.FindMTag(m2)
			if stdName ne !NULL then begin
				self.mission2 = stdName
				m2_good = 1
			endif
		endif
		if m1_good && m2_good then begin
			if self.mission1 eq self.mission2 then begin
				m2_good = 0
				dprint,dlevel=2,'Notice: Duplicate mission settings not allowed.'
			endif
		endif
		
		if (m1_good + m2_good eq 0) then begin
			print,'Bad Arguments.  Please select missions -- '
			self.SetMissions
		endif	else if ~(m1_good && m2_good) then begin
			good_id = (m1_good) ? 1 + where(self.mission1 eq opts) : 1 + where(self.mission2 eq opts)
			id = good_id[0]
			case (id) of
				0: message,'Something went wrong.'
				1: begin
					opts2 = opts[1:*]
					addtxt2 = addtxt[1:*]
				end
				n_elements(opts): begin
					opts2 = opts[0:-2]
					addtxt2 = addtxt[0:-2]
				end
				else: begin
					opts2 = [opts[0:id-2],opts[id:*]]
					addtxt2 = [addtxt[0:id-2],addtxt[id:*]]
				end
			endcase
			
			if m1_good then begin
				if isa(m2,'UNDEFINED') then m2='UNDEFINED'
				print,'Mission1 = ',self.mission1
				print,'Mission2 = ',m2
				print,'Mission 2 invalid.  Plese select:'

				count=0
				catch,ioerr
				repeat begin
					read,id,prompt='(Mission 2) '+((addtxt2+opts2).Join(' '))+'? '
					found = where(id eq addtxt2.Extract('[0-9]'),count)
				endrep until (count ne 0)
				catch,/cancel
				self.mission2 =opts[id-1]
			endif else begin
				if isa(m1,'UNDEFINED') then m1='UNDEFINED'
				print,'Mission1 = ',m1
				print,'Mission2 = ',self.mission2
				print,'Mission 1 invalid.  Plese select:'

				count=0
				catch,ioerr
				repeat begin
					read,id,prompt='(Mission 1) '+((addtxt2+opts2).Join(' '))+'? '
					found = where(id eq addtxt2.Extract('[0-9]'),count)
				endrep until (count ne 0)
				catch,/cancel
				self.mission1 =opts[id-1]
			endelse
		endif
	endelse
	
	; Don't prompt for title update if called privately
	changed = ((m1_init ne self.mission1) || (m2_init ne self.mission2)) ? !TRUE : !FALSE
	catch, stranger
	if stranger ne 0 then begin
		catch, /cancel
		if changed then	begin
			if self._defTitle then self.setTitle else self.QueryTitleUpdate
		endif
		print,'New settings:'
		print,'Mission1 = ',self.mission1,format='(T4,2A)'
		print,'Mission2 = ',self.mission2,format='(T4,2A)'
		print,"Title = '",self.title,"'",format='(T4,3A/)'
		return
	endif
	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_MISSION_COMPARE') then return
END


;+
;DESCRIPTION:
;  Returns the title generated by default.
;
;-
FUNCTION DSC_MISSION_COMPARE::getDefTitle
	compile_opt idl2

	colortext = strarr(2)
	for i=0,1 do begin
		if self._unifcolor[i] then begin
			colortext[i] = ' in '
			case ((*self._color[i])[0]) of
				0: cl = 'black'
				1: cl = 'magenta'
				2: cl = 'blue'
				3: cl = 'cyan'
				4: cl = 'green'
				5: cl = 'yellow'
				6: cl = 'red'
				255: cl = 'white'
				else: begin
					cl = ''
					colortext[i] = ''
				end
			endcase
			colortext[i] = colortext[i]+cl
		endif
	endfor

	defTitle = self.mission1+colortext[0]+' with '+self.mission2+' overplotted'+colortext[1]
	return,defTitle
end


PRO	DSC_MISSION_COMPARE::QueryTitleUpdate
	compile_opt idl2,hidden
	
	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		dprint,dlevel=1,'Call failed; Attempt to call private method;
		return
	endif

	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_MISSION_COMPARE') then begin
		dotitle = ''
		print,"Current Title:'"+self.title+"'. "
		repeat read,dotitle,prompt="Update to '"+self.getDefTitle()+"' (y/n)?" $ 
		until (dotitle.toLower() eq 'y' || dotitle.toLower() eq 'n')
		if dotitle.toLower() eq 'y' then self.setTitle
	endif
	catch, /cancel
END


;+
;DESCRIPTION:
;  Sets all comparison variables.
;  
;  If passed a string (scalar or array) will set these variables 
;  as those to be compared and will de-select all others.  
;  
;  If no strings, or bad strings, are passed the routine will provide
;  an interactive prompt.
;  
;  Array order implies the panel order in the plotted comparison.
;  If supplying variables interactively, the panel order is the
;  order in which the variables are entered at the prompt.
;  
;  If passed a {DSC_MISSION_COMPARE} structure it will set the variables
;  based on the fields set in the structure, preserving any valid
;  ordering and colors if they are set in the structure.  Title and 
;  mission fields in the structure are ignored.  May update the default title.
;    
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  mco.setVars
;  mco.setVars,'bx'              ;; Now only BX is set
;  mco.setVars,['v','np','bz']   ;; Now only V,NP,BZ are set. BX is cleared
;  
;  g = mco.getAll()
;  g.by = 1
;  g.v = 0
;  mco.setVars,g                 ;; Now NP,BZ, and BY are set.
;-
PRO DSC_MISSION_COMPARE::SetVars,vars
	compile_opt idl2
	
	self.ClearVar,/all
	if isa(vars,/STRING) then begin
		foreach var,vars do begin
			self.setVar,var
		endforeach
	endif else begin
		selfstrct = self.getall()
		tags = tag_names(selfstrct)
		sidx = (where(tags eq 'TITLE'))[0]; + 1
		eidx = (where(tags eq '_ORDER'))[0]

		if isa(vars,'DSC_MISSION_COMPARE') then begin
			print,'Setting variables from Structure'
			for i=sidx+1,eidx-1 do begin
				self.(i) = vars.(i)
			endfor
			self._order = vars._order
			self.CheckSettings
			self.setColor
			for i=0,1 do if isa(vars._color[i]) then self.setColor,i+1,*vars._color[i]
			
		endif else begin
			for i=sidx+1,eidx-1 do begin
				print,(i-sidx).toString()+': '+tags[i]
			endfor
			
			prompt = 'Select AT LEAST ONE variable:'
			vset = -1
			catch, ioerr
			if ioerr ne 0 then begin
				print,'Invalid entry. Try again'
			endif
			repeat begin
				read,vset,prompt=prompt
				if (vset lt 0) || (vset ge n_elements(tags)-sidx-1) then message,'Out of Range' $
				else if (vset ne 0) then begin
					self.setVar,tags[vset+sidx]
					prompt = '['+(self.getVars()).Join(',')+'] Another? [0 to quit]:'
				endif
			endrep until (vset eq 0)
			catch,/cancel
		endelse
	endelse
	self.CheckSettings
	print,'['+(self.getVars()).Join(',')+']'
END


;+
;DESCRIPTION:
;  Set one variable to be compared, leaving other variable 
;  settings intact. The newly added variable will be placed
;  at the end of the ordering.
;  
;KEYWORDS:
;  All:  Set all variables as selected with keyword \all.
;  
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  mco.setVar,'bz'       ;; Now NP,BX,BY and BZ are all set
;  mco.setVar,/all
;-
PRO DSC_MISSION_COMPARE::SetVar,var,all=all
	compile_opt idl2
	
	tags = tag_names(self)
	sidx = (where(tags eq 'TITLE'))[0]
	eidx = (where(tags eq '_ORDER'))[0]
	if keyword_set(all) then begin
		*self._order = []
		for i=1+sidx, eidx-1 do begin
			self.(i) = 1
			*self._order = [*self._order,tags[i]]
		endfor
		*self._order = *self._order.toLower()
		self.setColor
	endif else begin
		if ~keyword_set(var) || ~isa(var,/STRING) then var = ''
		var = var.toUpper()

		for i=1+sidx, eidx-1 do begin
			if tags[i] eq var then begin
				self.(i) = 1
				*self._order = [*self._order,var.toLower()]
				*self._color[0] = [*self._color[0],2]
				*self._color[1] = [*self._color[1],0]
				self.CleanOrder 
				break
			endif
		endfor
	endelse
	if self._defTitle then self.SetTitle
END


;+
;Description:
;  Set the color of lines to be plotted by DSC_MISSION_COMPARE::Plot 
;
;KEYWORDS:
;  HELP:	Print usage instructions
;
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'],c1=120,c2='g')
;  mco.setColor				; Set all lines to default colors
;  mco.setColor,1  		; Set all mission1 lines to default color
;  mco.setColor,2,'r'	; Set all mission2 lines red
;  mco.setColor,1,250,'np'	; Set mission1 NP variable line to colortable valued 250
;  
;-
pro DSC_MISSION_COMPARE::SetColor,mission,color,panel,help=help
	compile_opt idl2
	
	if keyword_set(help) then begin
		instructions = [ $
			'Syntax: DSC_MISSION_COMPARE::SetColor,mission,color,panel',	$
			'(All arguments are optional.)',$
			'With:',$
			'NO ARGUMENTS','Sets all lines to default colors',$
			'MISSION only','Sets all lines for this MISSION to default color',$
			'MISSION,COLOR','Sets all lines for this MISSION to this/these COLOR(s)',$
			'MISSION,COLOR,PANEL','Sets PANEL lines for this MISSION to this/these COLORS(s)',$
			'COLOR and PANEL arguments may be arrays.',$
			'-COLOR and PANEL arguments must match in size OR COLOR must be scalar.',$
			'-Scalar COLOR will set all selected PANEL(s) to COLOR',$
			'-Unedefined PANEL argument will apply to all panels',$
			'Examples:',$
			'mco.setColor','All M1 lines are blue, M2 lines black',$
			'mco.setColor,1,','All M1 lines are blue. M2 lines remain as previously set',$
			'mco.setColor,2,''r''','All M2 lines are red. M1 lines remain as previously set',$
			'mco.setColor,1,128,[1,3]','Set M1 lines in  panels 1 and 3 to colortable value 128',$
			'mco.setColor,2,[1,4],[1,3]','Set M2 lines in panels 1&3 to color values 1&4, respectively',$
			'mco.setColor,1,''g'',''np''','Set M1 NP line to green'$
			]
		
		print,instructions,format='(/3(A/),4(T4,A,T30,A/)/A/3(T4,A/)/A/6(T4,A,T35,A/)/)'
		return
	endif

	vars = self.getVars()
	if isa(vars,/NULL) then return
	
	c = intarr(2,vars.length)
	c[0,*] = 2	;Mission 1 default color is blue, Mission 2 default color is black
	if isa(mission,'UNDEFINED') then begin
		for i=0,1 do *self._color[i] = c[i,*]
		self._unifcolor = [!TRUE,!TRUE]
	endif else begin
		if ~isa(mission,/INT) || ((mission ne 1)&&(mission ne 2)) then begin
			dprint,DLEVEL=2,'Unexpected argument. Mission must be 1 or 2.'
			return
		endif
		if isa(color,'UNDEFINED') then begin
			*self._color[mission-1] = c[mission-1,*]
			self._unifcolor[mission-1] = !TRUE
		endif else begin
			if ~(isa(color,/INT)||isa(color,/STRING)) then begin
				dprint,DLEVEL=2,'Unexpected argument. Color must be INT(0-255) or STRING(''k'',''b'',''g'',''y'',''r'',''c'',''m'',''w'')'
				return
			endif
			
			if isa(panel,'UNDEFINED') then begin
				panel = indgen(vars.length)
			endif else begin
				if isa(panel,/STRING) then begin
					panel_string = panel
					panel = intarr(panel_string.length)
					foreach p,panel_string.toLower(),i do begin
						ip = where(vars eq p, count)
						if (count eq 0) then begin
							dprint,DLEVEL=2,'Panel argument '+panel_string[i]+' is not a selected variable'
							return
						endif
						panel[i] = ip 
					endforeach
				endif else if isa(panel,/INT)&&~isa(panel,/BOOLEAN) then begin
					foreach p,panel do begin
						ip = where(p eq panel,count)
						if ~((p ge 1)&&(p le vars.length)) || (count gt 1) then begin
							dprint,DLEVEL=2,'Bad panel argumement. Must be INT(s) in ['+((1+indgen(vars.length)).toString()).Join(',')+'] with no duplicates'
							return
						endif
					endforeach
					panel -= 1
				endif else begin
					dprint,DLEVEL=2,'Unexpected argument. Panel must be INT(s) in ['+((1+indgen(vars.length)).toString()).Join(',')+'] or STRING(s) in ['+(self.getVars()).Join(',')+']'
					return
				endelse
			endelse ;end panel check

			cscalar = !FALSE
			if ~(color.length eq panel.length) then begin
				if (color.length eq 1 && panel.length gt 1) then begin
					color = make_array(panel.length,value=color[0])
					cscalar = !TRUE
				endif else begin
					dprint,DLEVEL=2,'Incompatible color/panel argument size'
					return
				endelse
			endif
			if (panel.length gt vars.length) then begin
				dprint,DLEVEL=2,'Too many color/panel arguments.  There are only '+(vars.length).toString()+' variables currently selected.'
				return
			endif

			droplist = []
			if isa(color,/INTEGER) then begin
				foreach clr,color,j do begin
					if (clr lt 0) || (clr gt 255) then begin
						dprint,DLEVEL=2,'[ '+clr.toString()+' ]Bad color value. Leaving unmodified.'
						droplist = [droplist,j]
					endif 
				endforeach
			endif else begin
				color_str = color.toLower()
				color = make_array(panel.length,value=0)
				foreach clr,color_str,j do begin
					case (clr) of
						'k': color[j] = 0
						'm': color[j] = 1
						'b': color[j] = 2
						'c': color[j] = 3
						'g': color[j] = 4
						'y': color[j] = 5
						'r': color[j] = 6
						'w': color[j] = 255
						else: begin
							dprint,DLEVEL=2,'[ '+clr+' ]Bad color value. Leaving unmodified'
							droplist = [droplist,j]
						end
					endcase
				endforeach
			endelse
			if ~isa(droplist,/NULL) then begin
				if (N_ELEMENTS(droplist) eq N_ELEMENTS(color)) then return $
				else begin
				  foreach d,droplist do begin
				  	dsc_remove,d,color
				  	dsc_remove,d,panel
				  endforeach
				endelse
			endif
			
			(*self._color[mission-1])[panel] = color
			if cscalar && (color.length eq vars.length) then $
				self._unifcolor[mission-1] = !TRUE $
			else self.CheckUniformColor
		endelse ; end check color defined
	endelse ;end check mission defined
	if self._defTitle then self.SetTitle
	
end


;+
; DESCRIPTION
;	  Determine whether all selected variables are set
;	  to the same color within each mission. 
;-
pro DSC_MISSION_COMPARE::CheckUniformColor
	compile_opt idl2,hidden

	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		dprint,dlevel=1,'Call failed; Attempt to call private method;
		return
	endif

	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_MISSION_COMPARE') then begin 
		self._unifcolor = [!TRUE,!TRUE]
		colors = self.GetColor()
		if ~isa(colors,/NULL) then begin
			for i=0,1 do begin
				last = colors.(i)[0]
				foreach c,colors.(i) do begin
					if c ne last then begin
						self._unifcolor[i] = !FALSE
						break
					endif
					last = c
				endforeach
			endfor
		endif
	endif
	catch,/cancel
end


;+
; DESCRIPTION
;	  Clean duplicates from Order array
;-
pro DSC_MISSION_COMPARE::CleanOrder
	compile_opt idl2,hidden

	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		dprint,dlevel=1,'Call failed; Attempt to call private method;
		return
	endif

	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_MISSION_COMPARE') then begin
		if ~isa(*self._order,/NULL) then begin
			uvar = (*self._order)[uniq(*self._order, sort(*self._order))]
			rindex = []
			foreach var,uvar do begin
				ii = where(*self._order eq var,count)
				if count gt 1 then rindex = [rindex,ii[1:*]]
			endforeach
			dsc_remove,rindex,*self._order
			for i=0,1 do dsc_remove,rindex,*self._color[i]
		endif
		self.CheckUniformColor
	endif
	catch,/cancel
end


;+
;DESCRIPTION:
;  De-selects one variable from the comparison, leaving other 
;  variable settings intact. OR unset all with keyword \all
;  
;KEYWORDS:
;  All:  Mark all variables as unselected with keyword \all.
;  
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  mco.clearVar,'by'       ;; Now only NP,BX
;  mco.clearVar,/all
;-
PRO DSC_MISSION_COMPARE::ClearVar,var,all=all
	compile_opt idl2
	
	tags = tag_names(self)
	sidx = (where(tags eq 'TITLE'))[0]
	eidx = (where(tags eq '_ORDER'))[0]
	if keyword_set(all) then begin
		*self._order = []
		for i=0,1 do *self._color[i] = []
		for i=1+sidx,eidx-1 do begin
			self.(i) = 0
		endfor
	endif else begin
		if ~keyword_set(var) || ~isa(var,/STRING) then var = ''
		var = var.toUpper()
		
		found = 0
		for i=1+sidx,eidx-1 do begin
			if tags[i] eq var then begin
				found = 1
				self.(i) = 0
				j = where(*self._order eq tags[i].toLower(),count,/NULL)
				break
			endif
		endfor

		if ~found then dprint,dlevel=2,'Invalid variable name: '+var.toString() $
		else if count eq n_elements(*self._order) then begin
			*self._order = []
			for i=0,1 do *self._color[i] = []
		endif else begin
			dsc_remove,j,*self._order
			for i=0,1 do dsc_remove,j,*self._color[i]
		endelse
		self.CheckUniformColor
		if self._defTitle then self.SetTitle
	endelse
END


;+
;DESCRIPTION:
;  Reorders the comparison variables.
;  If passed no arguments it will enter an interactive session.
;  
;  Order positions are described by 1-indexed positions. 
;  (I.e.- the top panel is in position 1, the next panel down in
;   position 2, etc.)  
;  
;INPUT:
;  TARGET: 
;     if SCALAR - An identifier of the item in the variable list 
;                 that you want moved.  STRING or INTEGER.
;                 A STRING must match one of the selected variables.  
;                 An INTEGER must index a valid position. (I.e.- if 
;                 there are 4 selected variables, then a 1,2,3,and 4 are 
;                 valid positions. 
;     if ARRAY -  A description of the desired ordering. STRING or INTEGER.	
;                 A STRING array must be a permutation of the existing 
;                 selected values.
;                 AN INTEGER array must be a permuation of the existing positions.
;                 (I.e.- if there are 4 selected elements, then the existing positions
;                 can be described as [1,2,3,4].  Passing [4,1,2,3] as TARGET requests
;                 that the last item be moved to the first position, the first item 
;                 moved to the second position, etc.)
;  DESTINATION:  The desired end position for target element. (INTEGER)
;                Default is 1.
;                This argument only has meaning if TARGET is SCALAR; it is
;                ignored otherwise.
;-
pro DSC_MISSION_COMPARE::Reorder,target,destination
	compile_opt idl2
	
	current = self.getVars()
	n = current.length
	curcolor = self.getColor()
	m1col = curcolor.m1
	m2col = curcolor.m2
	
	if isa(target,'UNDEFINED') then begin
		instructions = [ $
			'Reorder items by entering ITEM,POSITION pairs.', $
			'Enter q to quit', $
			'Example: >bx,2 (Move BX to the 2nd position)', $
			'Example: >5,3  (Move the item currently in 5th to the 3rd spot)', $
			'Example: >q    (Quit)']
		print,instructions,format='(A/A,3(/T4,A))'
				

		repeat begin
			move = ''
			print,'Current: ',format='(/A)'
			foreach var,current,i do begin
				print,(i+1),var,format='(T4,I2,": ",A)'
			endforeach
			read,move,prompt='Move? (item,pos) or (q to quit)> '
			if move.toLower() ne 'q' then begin
				done = !FALSE
				move = move.Split(',')
				if move.length ne 2 then begin
					print,'!!Bad entry.'
					continue
				endif 
				
				if ~valid_num(move[1]) || move[1] lt 1 || move[1] gt n $
				then begin
					print,'POSITION argument must be INTEGER between 1 and '+n.toString()
					continue
				endif

				dest = move[1] - 1
				if ~valid_num(move[0]) then begin
					targ = where(current eq move[0],/NULL)
					if isa(targ,/NULL) then begin
						print,'ITEM argument is invalid. Choose from: ['+current.Join(',')+']'
						continue
					endif
				endif	else begin
					if (move[0] le 0) || (move[0] gt current.length) then begin
						dprint,DLEVEL=2,'ITEM argument is invalid. Must be between 1 and '+n.toString()
						continue
					endif
					targ = move[0]-1
				endelse

				tval = current[targ]
				col1 = m1col[targ]
				col2 = m2col[targ] 
				dsc_remove,targ,current
				dsc_remove,targ,m1col
				dsc_remove,targ,m2col
				case (dest) of
					0: begin
						current = [tval,current]
						m1col = [col1,m1col]
						m2col = [col2,m2col]
					end
					n-1: begin
						current = [current,tval]
						m1col = [m1col,col1]
						m2col = [m2col,col2]
					end
					else: begin
						current = [current[0:dest-1],tval,current[dest:*]]
						m1col = [m1col[0:dest-1],col1,m1col[dest:*]]
						m2col = [m2col[0:dest-1],col2,m2col[dest:*]]
					end
				endcase
			endif else done = !TRUE
		endrep until done
		*self._order = current
		*self._color[0] = m1col
		*self._color[1] = m2col
	endif else begin
		if isa(target,/STRING) || isa(target,/INTEGER) then begin
			if isa(target,/SCALAR) then begin
				if isa(destination,'UNDEFINED') then destination = 1
				if ~isa(destination,/INTEGER) || (destination le 0) || (destination gt n) then begin
					dprint,dlevel=2,'Reorder: (no change) DESTINATION argument must be INTEGER between 1 and '+n.toString()
					return
				endif				
				destination -= 1
				
				if isa(target,/STRING) then begin
					target = where(current eq target,/null)
					if isa(target,/NULL) then begin
						dprint,DLEVEL=2,'Reorder: (no change) TARGET string argument is invalid. Choose from: '+current.Join(',')
						return
					endif
				endif else begin
					if (target le 0) || (target gt n) then begin
						dprint,DLEVEL=2,'Reorder: (no change) TARGET integer argument is invalid. Must be between 1 and '+n.toString()
						return
					endif
					target -= 1
				endelse
				
				tval = current[target]		
				col1 = m1col[target]
				col2 = m2col[target]
				dsc_remove,target,current
				dsc_remove,target,m1col
				dsc_remove,target,m2col
				case (destination) of
					0: begin
						current = [tval,current]
						m1col = [col1,m1col]
						m2col = [col2,m2col]
					end
					n-1: begin
						current = [current,tval]
						m1col = [m1col,col1]
						m2col = [m2col,col2]
					end
					else: begin
						current = [current[0:destination-1],tval,current[destination:*]]
						m1col = [m1col[0:destination-1],col1,m1col[destination:*]]
						m2col = [m2col[0:destination-1],col2,m2col[destination:*]]
					end
				endcase
				
			endif else if isa(target,/ARRAY) then begin
				if target.length eq n then begin
					if isa(target,/STRING) then begin
						tarstring = target
						target = []
						foreach var,tarstring do begin
							ii = where(current eq var,/NULL)
							if isa(ii,/NULL) then begin
								dprint,DLEVEL=2,'Reorder: (no change) TARGET string array is invalid. '
								dprint,DLEVEL=2,'   '+var+' Not found in: '+current.Join(',')
								return
							endif
							target = [target,ii]
						endforeach
					endif else begin
						if ~DSC_IS_PERMUTATION(target,1+indgen(n)) then begin
							dprint,DLEVEL=2,'Reorder: (no change) TARGET integer array argument is invalid. 
							dprint,DLEVEL=2,'Must be a permutation of: ['+((1+indgen(n)).toString()).Join(',')+']'
							return
						endif
						target -= 1
					endelse
					current = current[target]
					m1col = m1col[target]
					m2col = m2col[target]
				endif else begin
					dprint,dlevel=2,'Reorder: (no change) Array argument must be length '+n.toString()
					return
				endelse
			endif
			*self._order = current
			*self._color[0] = m1col
			*self._color[1] = m2col
			print,'['+(self.getVars()).Join(',')+']'
		endif else dprint,dlevel=2,'Reorder: (no change) TARGET argument must be STRING or INTEGER' 
	endelse
end

;+
;DESCRIPTION:
;  Returns a structure of type {DSC_MISSION_COMPARE} 
;  containing this object's values
;  
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  mc_str =  mco.getall()
;-
FUNCTION DSC_MISSION_COMPARE::GetAll
	compile_opt idl2
	
	str = create_struct(name=obj_class(self))
	struct_assign,self,str
	RETURN,str
END


;+
;DESCRIPTION:
;  Returns the object title (string)
;  
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  defaultTitle = mco.getTitle()
;-
FUNCTION DSC_MISSION_COMPARE::GetTitle
	compile_opt idl2
	
	return,self.title
END


;+
;DESCRIPTION:
;  Returns the object color settings as a structure 
;
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  panelcolors = mco.getColor()
;-
FUNCTION DSC_MISSION_COMPARE::GetColor
	compile_opt idl2

	foreach clist,self._color do begin
		if isa(*clist,/NULL) then return,!NULL
	endforeach
	return,{m1:*self._color[0], m2:*self._color[1]} 
END


;+
;DESCRIPTION:
;  Returns a string array of shortcut names for all variables 
;  to be compared in the order the panels will be shown in a
;  plot.
; 
;CALLING SEQUENCE:
;  mco = dsc_mission_compare(m1='wi',m2='d',vars=['np','bx','by'])
;  vars = mco.getVars()
;-
FUNCTION DSC_MISSION_COMPARE::GetVars
	compile_opt idl2
	
	out = []
	if isa(*self._order,/NULL) then begin
		tags = tag_names(self)
		ix = (where(tags eq 'TITLE'))[0] + 1
		jx = (where(tags eq '_ORDER'))[0] - 1
		for i = ix,jx do if self.(i) eq 1 then out = [out,tags[i].toLower()]
	endif else out = *self._order
	return,out
END


;+
;DESCRIPTION:
;  Find the standardized mission tag given a passed string.
;  Returns !NULL if string does not match a tag.
;  
;  Note, this is a static method and can be called on an instance
;  of the class or on the class itself.
;
;KEYWORDS:
;  All:  Return all supported mission tags with the \all keyword
;   
;CALLING SEQUENCE:
;  tagMatch = dsc_mission_compare.findMTags('d')
;  allTags = dsc_mission_compare.findMTags(/all)
;-
FUNCTION DSC_MISSION_COMPARE::FindMTag,id,all=all
	compile_opt idl2,static
;	out = []
	if keyword_set(all) then return,['WIND','DSC','ACE']
	if ~keyword_set(id) || ~isa(id,/scalar,/string) then return,[]
	case !TRUE of
		id.Matches('(^w|wind|wi)',/fold_case): out = 'WIND'
		id.Matches('(^d|dsc)',/fold_case): out = 'DSC'
		id.Matches('(^a|ace)',/fold_case): out = 'ACE'
		else: out = []
	endcase
	
	return,out
END


PRO DSC_MISSION_COMPARE__DEFINE
	compile_opt idl2
	
	STRUCT = { DSC_MISSION_COMPARE, INHERITS IDL_Object, $
		mission1: '', $
		mission2: '', $
		title: '', $
		b: 0, $
		bx: 0,  $
		by: 0,  $
		bz: 0,  $
		btheta: 0,  $
		bphi: 0,  $
		v: 0,  $
		vx: 0,  $
		vy: 0,  $
		vz: 0,  $
		vtheta: 0,  $
		vphi: 0,  $
		np: 0,  $
		vth: 0, $
		_order: ptr_new(), $
		_color: ptrarr(2), $
		_unifcolor: [!FALSE,!FALSE], $
		_defTitle: !FALSE $
		}
END
