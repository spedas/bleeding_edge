;+
;NAME:
; dsc_time_absolute__define
;
;PURPOSE:
; Defines an object to represent an absolute amount of time, not in reference
; to any date.  e.g., "10 minutes."  Used to enable time amount conversion and 
; string representations.
; 
; Designates all times as a combination of days(d), hours(h), minutes(m),
; seconds(s), and milliseconds(ms) and can be both positive and negative.  
; The time representation is always kept in a reduced form.  So, for example, 
; you can define a time of 1 hour and 65 minutes
;   IDL> t1 = dsc_time_absolute('1h65m')   
; In this case it will be stored as 2 hours and 5 minutes.
;   IDL> print,t1
;   02h 05m
; 
; 
;CALLING SEQUENCE:
; abstime = Obj_New("DSC_TIME_ABSOLUTE")
; abstime = Obj_New("DSC_TIME_ABSOLUTE",h=1,mn=30)
; abstime = Obj_New("DSC_TIME_ABSOLUTE",'1h30m')
; abstime = dsc_time_absolute()
; abstime = dsc_time_absolute(h=1,mn=30)
; abstime = dsc_time_absolute('1h30m')
;
; 
;INPUT:
; TIMESTRING (Optional) If this argument is supplied, all other keywords are ignored.
;             A string representing the desired time amount in the format: '#d#h#m#s#ms'
;             with d,h,m,s,ms signifying respectively days,hours,minutes,seconds, and milliseconds.
;               You may leave out unit id strings, but not repeat them:
;                  OK     '3h2m'
;                  NOT OK '3h45m13m'
;               Numbers must all be positive integers, with the execption of the leading negative.
;                  OK     '3d4h23m16s400ms'
;                  OK '-23h'
;                  NOT OK '15h-4m'
;                  NOT OK '15.4m'
;                  
;KEYWORDS (Optional):
; NEG:    Set this to negate the total time value set by the other keywords
; D=:     Days
; H=:     Hours
; MN=:    Minutes
; S=:     Seconds
; MS=:    Milliseconds
;
;OUTPUT:
; dsc_time_absolute object reference
;
;METHODS:
; Set     - pass a timestring argument or keywords to set the class values
; SetAll	- pass a structure to set class values.
; Negate  - switch the sign of the time value stored
; Copy    - create a copy of this object
; Add     - add an amount of time (as specified in a timestring) to this object
; Sub     - subtranct an amount of time (as specified in a timestring) from this object
; GetAll  - returns a structure of type {dsc_time_absolute} containing this object's values
; GetMilli   - returns this object's millisecond field (long)
; GetSeconds - returns this object's seconds field (long)
; GetMinutes - returns this object's minutes field (long)
; GetHours   - returns this object's hours field (long)
; GetDays    - returns this object's days field (long)
; IsNeg      - returns TRUE if time object is negative, FALSE otherwise (boolean)
; ToString   - returns string representation of this time. Only non-zeroed fields are displayed (string)
; ToSeconds  - returns the total time value of this object, in seconds (double)
; ToMinutes  - returns the total time value of this object, in minutes (double)
; ToHours    - returns the total time value of this object, in hours (double)
; ToDays     - returns the total time value of this object, in days (double)
; StringParse - (Static Method) parse a timestring and return a structure holding the extracted elements
; Convert     - (Static Method) convert between units of time.
;                 usage: dsc_time_absolute.convert(amount, input_unit, output_unit)
;                   where input/output units are one of the following strings:
;                   'd','h','m','s','ms'
;
;NOTES:
; +/- and print/implied print are overloaded for this class.
;   e.g.,
;     t1 = dsc_time_absolute('1h')
;     t2 = dsc_time_absolute('55s')
;     t3 = t1 + t2
;     print,t3
;       ==> 01h 55s
;     t1
;       ==> 01h
; 
;CREATED BY: Ayris Narock (ADNET/GSFC) 2018
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/mission_compare/dsc_time_absolute__define.pro $
;-----------------------------------------------------------------------------------

FUNCTION DSC_TIME_ABSOLUTE::INIT, timestring, $
		neg=neg, $ ; Negative Time Flag
		ms=ms, $ ; Milliseconds
		s=s,   $ ; Seconds
		mn=m,  $ ; Minutes
		h=h,   $ ; Hours
		d=d      ; Days
	
	compile_opt idl2
	
	warnexit = 0
	if isa(timestring,'UNDEFINED') then begin
		; Check for keywords if no string sent
		if isa(neg,'UNDEFINED') then neg = !FALSE
		if isa(ms,'UNDEFINED') then ms = 0
		if isa(s,'UNDEFINED') then s = 0
		if isa(m,'UNDEFINED') then m = 0
		if isa(h,'UNDEFINED') then h =0
		if isa(d,'UNDEFINED') then d = 0

		if ~isa(neg,/BOOLEAN) then begin
			if ~isa(neg,/NUMBER,/SCALAR)||~(neg eq 1 or neg eq 0) then warnexit = 1 $
			else neg = (neg eq 1) ? !TRUE : !FALSE
		endif
		if ~isa(ms,/NUMBER,/SCALAR) then warnexit = 1
		if ~isa(s,/NUMBER,/SCALAR) then warnexit = 1
		if ~isa(m,/NUMBER,/SCALAR) then warnexit = 1
		if ~isa(h,/NUMBER,/SCALAR) then warnexit = 1
		if ~isa(d,/NUMBER,/SCALAR) then warnexit = 1


	endif else begin
		r = dsc_time_absolute.stringParse(timestring)
		if isa(r,'STRUCT') then begin
			neg = !FALSE
			ms = (tag_exist(r,'ms')) ? r.ms : 0
			s  = (tag_exist(r,'s'))  ? r.s  : 0
			m  = (tag_exist(r,'m'))  ? r.m  : 0
			h  = (tag_exist(r,'h'))  ? r.h  : 0
			d  = (tag_exist(r,'d'))  ? r.d  : 0
		endif else warnexit = 1
	endelse
	
	if warnexit eq 1 then begin
		dprint,dlevel=1,'Usage:{"DSC_TIME_ABSOLUTE"} Initialize with properly formatted shortcut string OR time element keywords as scalar numbers'
		return,0
	endif else begin
		self.setAll,{neg:neg, ms:ms, s:s, m:m, h:h, d:d}
		return,1
	endelse
	
END


FUNCTION DSC_TIME_ABSOLUTE::_overloadPrint
	return, self.DSC_TIME_ABSOLUTE::toString()
END


FUNCTION DSC_TIME_ABSOLUTE::_overloadImpliedPrint,varname
	return, self.DSC_TIME_ABSOLUTE::_overloadPrint()
END


FUNCTION DSC_TIME_ABSOLUTE::_overloadPlus,left,right
	compile_opt idl2

	out = left.Copy()
	out.add,(right.toString(/compact))
	return,out
END


FUNCTION DSC_TIME_ABSOLUTE::_overloadMinus,left,right
	compile_opt idl2
	
	out = left.Copy()
	out.sub,(right.toString(/compact))
	return,out
END


;+
;DESCRIPTION:
;  Set the class values by passing a timestring argument or keywords 
;  
;  Timestring argument will supsercede other keywords.
;  
;  Called with no arguments sets the object to 0 time.
;
;SYNTAX:
;  DSC_TIME_ABSOLUTE::Set,timestring,neg=neg,ms=ms,s=s,mn=m,h=h,d=d
;  
;CALLING SEQUENCE:
;  mt = dsc_time_absolute()
;  mt.set,h=3,mn=32,ms=400    --> time is 3 hours 32 minutes and 0.400 seconds
;    
;  mt.set,d=3.5,/neg   --> time is negative 3 days,12 hours
;            
;  mt.set,'3h42s'    --> time is 3 hours and 42 seconds
;             
;  mt.set,'-3m'      --> time is negative 3 minutes
;  
;  mt.set    --> time is 0 seconds
;  
;  mt.set,'15h2m',d=2,h=4  --> sets time to 15 hours and 2 minutes NOT  2 days and 4 hours        
;-
PRO DSC_TIME_ABSOLUTE::Set, timestring, $
	neg=neg, $ ; Negative Time Flag 
	ms=ms, $ ; Milliseconds
	s=s,   $ ; Seconds
	mn=m,  $ ; Minutes
	h=h,   $ ; Hours
	d=d      ; Days

	compile_opt idl2
	
	warnexit = 0
	if isa(timestring,'UNDEFINED') then begin
		; Check for keywords if no string sent
		if isa(neg,'UNDEFINED') then neg = !FALSE
		if isa(ms,'UNDEFINED') then ms = 0
		if isa(s,'UNDEFINED') then s = 0
		if isa(m,'UNDEFINED') then m = 0
		if isa(h,'UNDEFINED') then h =0
		if isa(d,'UNDEFINED') then d = 0
	
		
		if ~isa(neg,/BOOLEAN) then begin
			if ~isa(neg,/NUMBER,/SCALAR)||~(neg eq 1 or neg eq 0) then warnexit = 1 $
			else neg = (neg eq 1) ? !TRUE : !FALSE
		endif
		if ~isa(ms,/NUMBER,/SCALAR) then warnexit = 1
		if ~isa(s,/NUMBER,/SCALAR) then warnexit = 1
		if ~isa(m,/NUMBER,/SCALAR) then warnexit = 1
		if ~isa(h,/NUMBER,/SCALAR) then warnexit = 1
		if ~isa(d,/NUMBER,/SCALAR) then warnexit = 1
		if warnexit eq 1 then dprint,dlevel=1,'Usage: obj_new("DSC_TIME_ABSOLUTE",s=45,h=5,/neg) where time element keywords are scalar numbers.' 

	endif else begin
		r = dsc_time_absolute.stringParse(timestring)
		if isa(r,'STRUCT') then begin
			neg = !FALSE
			ms = (tag_exist(r,'ms')) ? r.ms : 0
			s  = (tag_exist(r,'s'))  ? r.s  : 0
			m  = (tag_exist(r,'m'))  ? r.m  : 0
			h  = (tag_exist(r,'h'))  ? r.h  : 0
			d  = (tag_exist(r,'d'))  ? r.d  : 0
		endif else warnexit = 1
	endelse

	if warnexit eq 0 then	self.setAll,{neg:neg, ms:ms, s:s, m:m, h:h, d:d}
END


;+
;DESCRIPTION:
;  Set the class values by passing a structure.
;  The fields MS, S, M, H, D, and NEG 
;    will be assigned if they exist
;    or set to 0 if they are missing from the passed structure.
;    
;  NEG field must be a boolean.
;   
;CALLING SEQUENCE:
;  mt = dsc_time_absolute()
;  mstruct = {neg:!TRUE, d:4, s:32}
;  mt.SetAll,mstruct
;    --> time is negative 4 days and 32 seconds
;-
PRO DSC_TIME_ABSOLUTE::SetAll, str
	compile_opt idl2
	if isa(str,'STRUCT') then begin
		if tag_exist(str,'neg') && ~isa(str.neg,/BOOLEAN) then begin
			dprint,dlevel=1,'Usage: TIMEABSOLUTE.SETALL,STR where STR.NEG must be BOOLEAN'
			return
		endif
		self.neg = !FALSE
		
		;must maintain this order from smallest increment to largest to work with the
		;downwardly additive set___ private methods.

		if tag_exist(str,'ms') then self.setMilli,str.ms else self.setMilli,0
		if tag_exist(str,'s') then self.setSeconds,str.s else self.setSeconds,0
		if tag_exist(str,'m') then self.setMinutes,str.m else self.setMinutes,0
		if tag_exist(str,'h') then self.setHours,str.h else self.setHours,0
		if tag_exist(str,'d') then self.setDays,str.d else self.setDays,0

		self.reduce	;this may set the neg flag if fields total to negative time
		if tag_exist(str,'neg') && str.neg then self.Negate
	endif else begin
		dprint,dlevel=1,'Usage: DSC_TIME_ABSOLUTE.SETALL,STR where STR is a structure'
		return
	endelse
END


;+
;DESCRIPTION:
;  Switch the sign of the time value stored
;
;CALLING SEQUENCE:
;  mt = dsc_time_absolute('4h15m') --> time is 04h 15m
;  mt.negate                   --> time is -04h 15m
;  mt.negate                   --> time is 04h 15m
;-
PRO	DSC_TIME_ABSOLUTE::Negate
	compile_opt idl2
	
	self.neg = (self.neg) ? !FALSE : !TRUE
END


;+
;DESCRIPTION:
;  Create a copy of this object
;
;CALLING SEQUENCE:
;  mt = dsc_time_absolute(s=40,mn=12,/neg)
;  mtcopy = mt.copy()
;-
FUNCTION DSC_TIME_ABSOLUTE::COPY
	compile_opt idl2

	str = self.getall()
	out = Obj_New("DSC_TIME_ABSOLUTE", $
		neg=str.neg, $
		ms=str.ms, $
		s =str.s,  $
		mn =str.m,  $
		h =str.h,  $
		d =str.d)
	return,out
END


;+
;DESCRIPTION:
;  Add an amount of time to this object by passing a 
;  time string.
;  The overloaded '+' operator uses this method internally.
;  
;  Timestring rules:
;    - A string composed of the concatenation of one or more substrings 
;      of the form substring = '{number}{unit_string}' where:
;	      * {number} is a positive integer
;	      * {unit_string} is one of  'd','h','m',s', or 'ms'  
;	        [Representing days, hours, minutes, seconds, and milliseconds, respectively.]
;	  - The substrings can be combined in any order, with a limit of one 
;	    substring per {unit_string} type.
;	  - A leading '-' is accepted to indicate a negative time amount.
;	  - A leading '+' is accepted (but not required) to indicate a positive time amount.
;
;	  Time is always stored in reduced form in the dsc_time_absolute object.
;	  I.e., 300 seconds will show as 5 minutes; 1 hour 90 minutes as 2 hours 30 minutes, etc.
;	  
;CALLING SEQUENCE:
;  mt = dsc_time_absolute('3h20m')
;  mt.add,'40m'
;  --> time is now 4 hours
;  
;  Alternately, use the '+' operator:
;  mt1 = dsc_time_absolute('3h20m')
;  mt2 = dsc_time_absolute('40m')
;  mt = mt1 + mt2
;
;-
PRO DSC_TIME_ABSOLUTE::Add,addstring
	compile_opt idl2
	
	r = dsc_time_absolute.stringParse(addstring)
	if isa(r,'STRUCT') then begin
		if self.neg then begin
			if tag_exist(r,'ms') then self.setMilli,r.ms-self.ms
			if tag_exist(r,'s') then self.setSeconds,r.s-self.s
			if tag_exist(r,'m') then self.setMinutes,r.m-self.m
			if tag_exist(r,'h') then self.setHours,r.h-self.h
			if tag_exist(r,'d') then self.setDays,r.d-self.d
		endif else begin
			if tag_exist(r,'ms') then self.setMilli,r.ms+self.ms
			if tag_exist(r,'s') then self.setSeconds,r.s+self.s
			if tag_exist(r,'m') then self.setMinutes,r.m+self.m
			if tag_exist(r,'h') then self.setHours,r.h+self.h
			if tag_exist(r,'d') then self.setDays,r.d+self.d
		endelse
		self.neg = !FALSE
		self.reduce	;this will set the neg flag if fields total a negative time
	endif
END


;+
;DESCRIPTION:
;  Subtract an amount of time from this object by passing a 
;  time string.
;  The overloaded '-' operator uses this method internally.
;  
;  Timestring rules:
;    - A string composed of the concatenation of one or more substrings 
;      of the form substring = '{number}{unit_string}' where:
;	      * {number} is a positive integer
;	      * {unit_string} is one of  'd','h','m',s', or 'ms'  
;	        [Representing days, hours, minutes, seconds, and milliseconds, respectively.]
;	  - The substrings can be combined in any order, with a limit of one 
;	    substring per {unit_string} type.
;	  - A leading '-' is accepted to indicate a negative time amount.
;	  - A leading '+' is accepted (but not required) to indicate a positive time amount.
;
;	  Time is always stored in reduced form in the dsc_time_absolute object.
;	  I.e., 300 seconds will show as 5 minutes; 1 hour 90 minutes as 2 hours 30 minutes, etc.
;	  
;CALLING SEQUENCE:
;  mt = dsc_time_absolute('3h20m')
;  mt.sub,'40m'
;  --> time is now 2 hours 40 minutes
;  
;  Alternately, use the '-' operator:
;  mt1 = dsc_time_absolute('3h20m')
;  mt2 = dsc_time_absolute('40m')
;  mt = mt1 - mt2
;-
PRO DSC_TIME_ABSOLUTE::Sub,substring
	compile_opt idl2

	r = dsc_time_absolute.stringParse(substring)
	if isa(r,'STRUCT') then begin
		if self.neg then begin
			if tag_exist(r,'ms') then self.setMilli,-self.ms-r.ms
			if tag_exist(r,'s') then self.setSeconds,-self.s-r.s
			if tag_exist(r,'m') then self.setMinutes,-self.m-r.m
			if tag_exist(r,'h') then self.setHours,-self.h-r.h
			if tag_exist(r,'d') then self.setDays,-self.d-r.d
		endif else begin
			if tag_exist(r,'ms') then self.setMilli,self.ms-r.ms
			if tag_exist(r,'s') then self.setSeconds,self.s-r.s
			if tag_exist(r,'m') then self.setMinutes,self.m-r.m
			if tag_exist(r,'h') then self.setHours,self.h-r.h
			if tag_exist(r,'d') then self.setDays,self.d-r.d
		endelse
		self.neg = !FALSE
		self.reduce	;this will set the neg flag if fields total a negative time
	endif
END


;+
;DESCRIPTION:
;  (Static Method) 
;  Parse a timestring and return a structure holding the extracted elements
;
;CALLING SEQUENCE:
;  IDL> elements = dsc_time_absolute.StringParse('-1d12h15m')
;  IDL> print,elements,/implied
;  {
;      "D": -1,
;      "H": -12,
;      "M": -15,
;      "S": 0,
;      "MS": 0
;  }
;-
FUNCTION DSC_TIME_ABSOLUTE::StringParse,input
	compile_opt idl2, static
	
	out = {d:0,h:0,m:0,s:0,ms:0}
	warnexit = 0
	if isa(input,/STRING,/SCALAR) then begin
		if input.Matches('^\-') then begin
			mysign = -1
			input = input.Substring(1,-1)
		endif else begin
			mysign = 1
			if input.Matches('^\+') then input = input.Substring(1,-1)
		endelse
		if input.Matches('([^dhms0-9]|^[dhms]|[0-9]$)') then warnexit = 1 $
		else begin
			dsplit = (input.Split('d',/fold_case)).length
			hsplit = (input.Split('h',/fold_case)).length
			msplit = (input.Split('m([^s]|$)',/fold_case)).length
			ssplit = (input.Split('[^m]s',/fold_case)).length
			mssplit = (input.Split('ms',/fold_case)).length
			if dsplit gt 2 || hsplit gt 2 || msplit gt 2 || ssplit gt 2 || mssplit gt 2 then warnexit = 1
		endelse
		
		if warnexit ne 1 then begin
			out.d = mysign*((input.Extract('[0-9]+d',/fold_case)).Substring(0,-2)).toInteger()
			out.h = mysign*((input.Extract('[0-9]+h',/fold_case)).Substring(0,-2)).toInteger()
			mstring = input.Extract('[0-9]+m([0-9]|$)',/fold_case)
			out.m = ((mstring.Substring(-1)).Matches('[0-9]')) ? mysign*(mstring.Substring(0,-3)).toInteger() : mysign*(mstring.Substring(0,-2)).toInteger()
			out.s = mysign*((input.Extract('[0-9]+s',/fold_case)).Substring(0,-2)).toInteger()
			out.ms = mysign*((input.Extract('[0-9]+ms',/fold_case)).Substring(0,-2)).toInteger()
		endif
	endif else warnexit = 1
	
	if warnexit eq 1 then begin
		dprint,dlevel=1,'Usage: DSC_TIME_ABSOLUTE shortcut string error.
		dprint,dlevel=1,'   Format: ''#d#h#m#s#ms'''
		dprint,dlevel=1,'You may leave out unit id strings, but not repeat them:'
		dprint,dlevel=1,'   OK     ''3h2m'' '
		dprint,dlevel=1,'   NOT OK ''3h45m13m'' '
		dprint,dlevel=1,'Numbers must all be positive integers, with the execption of the leading negative.'
		dprint,dlevel=1,'   OK     ''3d4h23m16s400ms'' '
		dprint,dlevel=1,'   OK ''-23h'' '
		dprint,dlevel=1,'   NOT OK ''15h-4m'' '
		dprint,dlevel=1,'   NOT OK ''15.4m'' '
		out = -1
	endif
	return,out
END


;+
;DESCRIPTION:
;  (Private Method)
;-
PRO DSC_TIME_ABSOLUTE::SetMilli,ms
	compile_opt idl2,hidden

	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		catch, /cancel
		dprint,dlevel=1,'Call failed; Attempt to call private method; Use .Set or .SetAll'
		return
	endif
	
	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_TIME_ABSOLUTE') then begin
		if isa(ms,/number,/scalar) then self.ms = round(ms) $
		else begin
			dprint,dlevel=1,'MILLISECONDS must be scalar number'
			return
		endelse
	endif else dprint,dlevel=1,'Call failed; Attempt to call private method; Use .Set or .SetAll'
END


;+
;DESCRIPTION:
;  (Private Method)
;-
PRO DSC_TIME_ABSOLUTE::SetSeconds,s
	compile_opt idl2,hidden

	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		catch, /cancel
		dprint,dlevel=1,'Call failed; Attempt to call private method; Use .Set or .SetAll'
		return
	endif

	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_TIME_ABSOLUTE') then begin
		if isa(s,/number,/scalar) then begin
			self.s = floor(s)
			if (s-self.s gt 0) then self.SetMilli,self.ms+((s-self.s)*1000.)
		endif	else begin
			dprint,dlevel=1,'SECONDS must be scalar number'
			return
		endelse
	endif
END


;+
;DESCRIPTION:
;  (Private Method)
;-
PRO DSC_TIME_ABSOLUTE::SetMinutes,m
	compile_opt idl2,hidden

	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		catch, /cancel
		dprint,dlevel=1,'Call failed; Attempt to call private method; Use .Set or .SetAll'
		return
	endif

	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_TIME_ABSOLUTE') then begin
		if isa(m,/number,/scalar) then begin
			self.m = floor(m)
			if (m-self.m gt 0) then self.setSeconds,self.s+((m-self.m)*60.)
		endif	else begin
			dprint,dlevel=1,'MINUTES must be scalar number'
			return
		endelse
	endif
END


;+
;DESCRIPTION:
;  (Private Method)
;-
PRO DSC_TIME_ABSOLUTE::SetHours,h
	compile_opt idl2,hidden

	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		catch, /cancel
		dprint,dlevel=1,'Call failed; Attempt to call private method; Use .Set or .SetAll'
		return
	endif

	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_TIME_ABSOLUTE') then begin
		if isa(h,/number,/scalar) then begin
			self.h = floor(h)
			if (h-self.h gt 0) then self.setMinutes,self.m+((h-self.h)*60.)
		endif	else begin
			dprint,dlevel=1,'HOURS must be scalar number'
			return
		endelse
	endif
END


;+
;DESCRIPTION:
;  (Private Method)
;-
PRO DSC_TIME_ABSOLUTE::SetDays,d
	compile_opt idl2,hidden

	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		catch, /cancel
		dprint,dlevel=1,'Call failed; Attempt to call private method; Use .Set or .SetAll'
		return
	endif

	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_TIME_ABSOLUTE') then begin
		if isa(d,/number,/scalar) then begin
			self.d = floor(d)
			if (d-self.d gt 0) then self.setHours,self.h+((d-self.d)*24.)
		endif	else begin
			dprint,dlevel=1,'DAYS must be scalar number'
			return
		endelse
	endif
END


;+
;DESCRIPTION:
;  Return a structure of type {DSC_TIME_ABSOLUTE} that containins
;  this object's values
;
;CALLING SEQUENCE:
;  IDL> mt = dsc_time_absolute('-15m36s300ms')
;  IDL> mtall = mt.GetAll()
;  IDL> print,mtall,/implied
;  {
;			"IDL_OBJECT_TOP": 0,
;			"__OBJ__": <NullObject>,
;			"IDL_OBJECT_BOTTOM": 0,
;			"NEG": true,
;			"MS": 300,
;			"S": 36,
;			"M": 15,
;			"H": 0,
;			"D": 0
;		}
;
;-
FUNCTION DSC_TIME_ABSOLUTE::GetAll
	compile_opt idl2
	
	str = create_struct(name=obj_class(self))
	struct_assign,self,str
	RETURN,str
END


;+
;DESCRIPTION:
;  Return this object's Milliseconds field (long)
;  Note: Time is always stored in reduced form
;	   I.e., 5000 milliseconds is stored as 5 seconds
;	  
;	 Unit fields are always positive.  The sign of the DSC_TIME_ABSOLUTE object
;	 is stored in the NEG field.
;
;CALLING SEQUENCE:
;  IDL> mt = dsc_time_absolute('12h2m35ms')
;  IDL> mt.getMilli()
;  				35
;  
;  IDL> mt.set,'3m2s5050ms'
;  IDL> mt.getMilli()
;					50
;-
FUNCTION DSC_TIME_ABSOLUTE::GetMilli
	compile_opt idl2
	return,self.ms
END


;+
;DESCRIPTION:
;  Return this object's Seconds field (long)
;  Note: Time is always stored in reduced form
;	   I.e., 75 seconds is stored at 1 minute, 15 seconds
;	   
;	 Unit fields are always positive.  The sign of the DSC_TIME_ABSOLUTE object
;	 is stored in the NEG field.
;
;CALLING SEQUENCE:
;  IDL> mt = dsc_time_absolute('12h2s35ms')
;  IDL> mt.getSeconds()
;  				2
;  
;  IDL> mt.set,'3m2s5050ms'
;  IDL> mt.getMilli()
;					7
;-
FUNCTION DSC_TIME_ABSOLUTE::GetSeconds
	compile_opt idl2
	return,self.s
END


;+
;DESCRIPTION:
;  Return this object's Minutes field (long)
;  Note: Time is always stored in reduced form
;	   I.e., 90 minutes is stored as 1 hour, 30 minutes
;	   
;	 Unit fields are always positive.  The sign of the DSC_TIME_ABSOLUTE object
;	 is stored in the NEG field.
;
;CALLING SEQUENCE:
;  IDL> mt = dsc_time_absolute('3h90m')
;  IDL> mt.getMinutes()
;  				30
;  
;  IDL> mt.set,'30m200s'
;  IDL> mt.getMinutes()
;					33
;-
FUNCTION DSC_TIME_ABSOLUTE::GetMinutes
	compile_opt idl2
	return,self.m
END


;+
;DESCRIPTION:
;  Return this object's Hours field (long)
;  Note: Time is always stored in reduced form
;	   I.e., 90 minutes is stored as 1 hour, 30 minutes
;	   
;	 Unit fields are always positive.  The sign of the DSC_TIME_ABSOLUTE object
;	 is stored in the NEG field.
;
;CALLING SEQUENCE:
;  IDL> mt = dsc_time_absolute('-3h90m')
;  IDL> mt.getHours()
;  				4
;  
;  IDL> mt.set,'66m'
;  IDL> mt.getHours()
;					1
;-
FUNCTION DSC_TIME_ABSOLUTE::GetHours
	compile_opt idl2
	return,self.h
END


;+
;DESCRIPTION:
;  Return this object's Days field (long)
;  Note: Time is always stored in reduced form
;	   I.e., 25 hours is stored as 1 day, 1 hour
;	   
;	 Unit fields are always positive.  The sign of the DSC_TIME_ABSOLUTE object
;	 is stored in the NEG field.
;
;CALLING SEQUENCE:
;  IDL> mt = dsc_time_absolute('2d15h')
;  IDL> mt.getDays()
;  				2
;  
;  IDL> mt.set,'-30h'
;  IDL> mt.getDays()
;					1
;-
FUNCTION DSC_TIME_ABSOLUTE::GetDays
	compile_opt idl2
	return,self.d
END


;+
;DESCRIPTION:
;  Returns TRUE if time object is negative, FALSE otherwise (boolean)
;
;CALLING SEQUENCE:
;  IDL> mt = dsc_time_absolute('-30h')
;  IDL> mt.IsNeg()
;  true
;  
;  IDL> mt.set,'15s2h'
;  IDL> mt.IsNeg()
;  false
;
;-
FUNCTION DSC_TIME_ABSOLUTE::IsNeg
	compile_opt idl2
	return,self.neg
END


;+
;DESCRIPTION:
;  Returns the string representation of this time. 
;  Only non-zeroed fields are displayed (string)
;
;  Use keyword /COMPACT to remove whitespace
;  
;CALLING SEQUENCE:
;  IDL> mt = dsc_time_absolute(d=3,h=42.5,s=10)
;  IDL> mtstring = mt.ToString()
;  IDL> print,mtstring
;  04d 18h 30m 10s
;
;-
FUNCTION DSC_TIME_ABSOLUTE::ToString,compact=compact
	compile_opt idl2
	;TODO - add option flags - like, /minutes, etc.
	out = ''
	compact = keyword_set(compact) ? 1 : 0
	prefix = (self.neg) ? '-' : ''
	if self.d gt 0 then out = out+String(self.d,format='(I02)')+'d '
	if self.h gt 0 then out = out+String(self.h,format='(I02)')+'h '
	if self.m gt 0 then out = out+String(self.m,format='(I02)')+'m '
	if self.ms gt 0 then out = out+String(self.s,format='(I02)')+'.'+String(self.ms,format='(I03)')+'s' $
	else if self.s gt 0 then begin
		out = out+String(self.s,format='(I02)')+'s'
	endif
	if compact then begin
		a = out.Split(' ')
		out = a.Join()
	endif
	if out eq '' then return,'0s'
	return,(prefix+out).Trim()
END


;+
;DESCRIPTION:
;  Returns the total time value of this object, in seconds (double)
;
;CALLING SEQUENCE:
;  IDL> mt.set,'1d1h1m1s1ms'
;  IDL> mt.toSeconds()
;        90061.001000000004
;  IDL> mt.negate()
;  IDL> mt.toSeconds()
;       -90061.001000000004
;-
FUNCTION DSC_TIME_ABSOLUTE::ToSeconds
	compile_opt idl2
	result = $
		self.convert(self.ms,'ms','s') + $
		self.s +  $
		self.convert(self.m,'m','s') + $
		self.convert(self.h,'h','s') + $
		self.convert(self.d,'d','s')
	
	if self.neg then result = -1*result
	return,result
END


;+
;DESCRIPTION:
;  Returns the total time value of this object, in minutes (double)
;
;CALLING SEQUENCE:
;  IDL> mt.set,'1d1h1m1s1ms'
;  IDL> mt.toMinutes()
;        1501.0166833333333
;  IDL> mt.negate()
;  IDL> mt.toMinutes()
;       -1501.0166833333333
;-
FUNCTION DSC_TIME_ABSOLUTE::ToMinutes
	compile_opt idl2
	result = $
		self.convert(self.ms,'ms','m') + $
		self.convert(self.s,'s','m') +  $
		self.m + $
		self.convert(self.h,'h','m') + $
		self.convert(self.d,'d','m')

	if self.neg then result = -1*result		
	return,result
END


;+
;DESCRIPTION:
;  Returns the total time value of this object, in hours (double)
;
;CALLING SEQUENCE:
;  IDL> mt.set,'1d1h1m1s1ms'
;  IDL> mt.toHours()
;        25.016944722222224
;  IDL> mt.negate()
;  IDL> mt.toHours()
;       -25.016944722222224
;-
FUNCTION DSC_TIME_ABSOLUTE::ToHours
	compile_opt idl2
	result = $
		self.convert(self.ms,'ms','h') + $
		self.convert(self.s,'s','h') +  $
		self.convert(self.m,'m','h') + $
		self.h + $
		self.convert(self.d,'d','h')

	if self.neg then result = -1*result
	return,result
END


;+
;DESCRIPTION:
;  Returns the total time value of this object, in days (double)
;
;CALLING SEQUENCE:
;  IDL> mt.set,'1d1h1m1s1ms'
;  IDL> mt.toDays()
;        1.0423726967592593
;  IDL> mt.negate()
;  IDL> mt.toDays()
;       -1.0423726967592593
;-
FUNCTION DSC_TIME_ABSOLUTE::ToDays
	compile_opt idl2
	result = $
		self.convert(self.ms,'ms','d') + $
		self.convert(self.s,'s','d') + $
		self.convert(self.m,'m','d') + $
		self.convert(self.h,'h','d') + $
		self.d

	if self.neg then result = -1*result
	return,result
END


;+
;DESCRIPTION:
;  (Private Method)
;-
PRO DSC_TIME_ABSOLUTE::Reduce
	compile_opt idl2,hidden

	; Work around to act as a private method
	catch, stranger
	if stranger ne 0 then begin
		catch, /cancel
		dprint,dlevel=1,'Call failed; Attempt to call private method.
		return
	endif
		
	if obj_isa((scope_varfetch('self', level=-1)), 'DSC_TIME_ABSOLUTE') then begin		
		DHMfactor = [86400.,3600.,60.]
		out = intarr(3)
		sec = self.toSeconds()
		self.neg = (sec lt 0) ? !TRUE : !FALSE
		sec = abs(sec)
		
		for i = 0,2 do begin
			out[i] = floor(sec/DHMFactor[i])
			sec = sec mod DHMfactor[i]
		endfor
	
		self.d = out[0]
		self.h = out[1]
		self.m = out[2]
		self.s = floor(sec)
		self.ms = round((sec mod 1)*1000.)
	endif
END


;+
;DESCRIPTION:
;  (Static Method)
;  Convert between units of time.
;	 Usage: 
;    dsc_time_absolute.convert(amount, input_unit, output_unit)
;      where input/output units are one of the following strings:
;      'd','h','m','s','ms'
;
;CALLING SEQUENCE:
;  IDL> dsc_time_absolute.convert(15, 'm', 's')
;       900.00000000000000
;  IDL> dsc_time_absolute.convert(368, 'm', 'h')
;				6.1333333333333329      
;-
FUNCTION DSC_TIME_ABSOLUTE::Convert,value,in_unit,out_unit
	compile_opt idl2, static
	
	out_value = -1
	if (~isa(value,/scalar,/number) || $
		 ~isa(in_unit,/scalar,/string) || $
		 ~isa(out_unit,/scalar,/string)) then begin 
		dprint,dlevel=1,'Usage Error: DSC_TIME_ABSOLUTE.convert,VALUE,IN_UNIT,OUT_UNIT'
		dprint,dlevel=1,"and   IN_UNIT,OUT_UNIT in the set {'ms','s','m','h','d'}"
		return,-1
	endif

	in_unit = in_unit.ToLower()
	out_unit = out_unit.ToLower()
	strerr = 0
	case (in_unit) of
		'ms': begin
						case (out_unit) of
							'ms': multiplier = 1d
							's' : multiplier = .001d
							'm' : multiplier = .001d/60.
							'h' : multiplier = .001d/3600.
							'd' : multiplier = .001d/(3600.*24.)
							else: strerr = 1
						endcase
			end
		's':  begin
						case (out_unit) of
							'ms': multiplier = 1000d
							's' : multiplier = 1d
							'm' : multiplier = 1d/60.
							'h' : multiplier = 1d/3600.
							'd' : multiplier = 1d/(3600.*24.)
							else: strerr = 1
						endcase
			end
		'm':  begin
						case (out_unit) of
							'ms': multiplier = 60000d
							's' : multiplier = 60d
							'm' : multiplier = 1d
							'h' : multiplier = 1d/60.
							'd' : multiplier = 1d/(60.*24.)
							else: strerr = 1
						endcase
			end
		'h':  begin
						case (out_unit) of
							'ms': multiplier = 3.6d6
							's' : multiplier = 3600d
							'm' : multiplier = 60d
							'h' : multiplier = 1d
							'd' : multiplier = 1d/24.
							else: strerr = 1
						endcase
			end
		'd':  begin
						case (out_unit) of
							'ms': multiplier = 24d*3.6e6
							's' : multiplier = 24d*3600.
							'm' : multiplier = 24d*60.
							'h' : multiplier = 24d
							'd' : multiplier = 1d
							else: strerr = 1
						endcase
			end
		else: strerr = 1
	endcase

	if strerr then begin
		dprint,dlevel=1,'Usage Error: DSC_TIME_ABSOLUTE.convert,VALUE,IN_UNIT,OUT_UNIT'
		dprint,dlevel=1,"and   IN_UNIT,OUT_UNIT in the set {'ms','s','m','h','d'}"
		return,-1
	endif

	return, value*multiplier
END


PRO DSC_TIME_ABSOLUTE__DEFINE
	compile_opt idl2
	
	STRUCT = { DSC_TIME_ABSOLUTE, INHERITS IDL_Object, $
		neg: !FALSE,  $ ; Negative Time Flag
		ms: 0,   $ ; Milliseconds
		s : 0,   $ ; Seconds
		m : 0,   $ ; Minutes
		h : 0,   $ ; Hours
		d : 0    $ ; Days
	}

END