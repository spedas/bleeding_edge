; The MIT License
;
; Copyright 2019 Chris Piker
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
; copies of the Software, and to permit persons to whom the Software is 
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in 
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.


function das2prop::init, _extra=ex
	compile_opt idl2
	void = self.IDL_Object::init()
		
	if(isa(ex)) then self.setproperty, _EXTRA=ex
	return, !TRUE
end

pro das2prop::getproperty, TYPE=type, VALUE=value, STRVAL=strval
	compile_opt idl2
	if arg_present(type) then type = self.type
	
	if arg_present(strval) then strval = self.value
	
	if arg_present(value) then begin 
		; return an appropriate IDL type for the value even though it's stored
		; as a string
		case self.type of
			'int': value = fix(self.value)
			'double': value = double(self.value)
			'Datum':  begin
				l = self.value.split(' ')
				sUnits = !null
				if n_elements(l) gt 1 then sUnits = l[1:*]
				sVal = l[0]
				value = create_struct('value', double(sVal), 'units', sUnits)
				end
			'DatumRange': begin
				l = self.value.split(' ')
				sUnits = !null
				sMin = l[0]
				if n_elements(l) lt 3 then sMax = sMin else sMax = l[2]
				if n_elements(l) gt 3 then sUnits = l[3:*]
				value = create_struct('min', double(sMin), 'max', double(sMax), 'units', sUnits)
				end
			'boolean': value = self.value ? !true : !false
			'String':  value = self.value
			'Time':  value = das2_text_to_tt2000(self.value)
			'TimeRange': begin
				l = self.value.split(' ')
				sBeg = l[0]
				if n_elements(l) lt 3 then sEnd = sBeg else sEnd = l[2]
				nBeg = das2_text_to_tt2000(sBeg)
				nEnd = das2_text_to_tt2000(sEnd)
				value = create_struct('min', nBeg, 'max', nEnd, units, 'UTC')
				end
			else: value = self.value
		endcase
		
	endif
end

pro das2prop::setproperty, TYPE=type, VALUE=value
	compile_opt idl2, hidden
	
	if isa(type) then self.type = type
	if isa(value) then self.value = value
end

function das2prop::_overloadPrint
	compile_opt idl2, hidden
	return, self.tostr()
end

function das2prop::tostr
	compile_opt idl2, hidden
	return, string(self.type, self.value, format= '%s | %s')
end

;+
; Das2 property has a type and value
;-
pro das2prop__define
	compile_opt idl2, hidden
	void = { $
		das2prop, inherits IDL_Object, type: '', value: '' $
	}
end
