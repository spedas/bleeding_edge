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

function das2dim::init, _extra=ex
	compile_opt idl2
	
	void = self.IDL_Object::init()
	self.kind = 'unknown'
	self.props = hash()
	self.vars = hash()
	return, !TRUE
end

pro das2dim::getproperty, PROPS=props, VARS=vars, KIND=kind
	compile_opt idl2
	if arg_present(kind) then kind = self.kind
	if arg_present(props) then props = self.props
	if arg_present(vars) then vars = self.vars
end

pro das2dim::setproperty, KIND=kind
	compile_opt idl2
	if isa(kind) then self.kind = kind
end

function das2dim::_overloadBracketsRightSide, $
	isrange, r, i, j, k, l, m, n, o
	
	if isrange[0] gt 0 then begin
		message, 'Range selection not supported for variable roles, i.e. no ''center'':''min'' slices'
	endif
	
	if n_elements(isrange) gt 1 then rng = isrange[1:-1]

	case n_elements(isrange) of
		1: return, self.vars[r]
		2: return, self.vars[r]._overloadBracketsRightSide(rng, i)
		3: return, self.vars[r]._overloadBracketsRightSide(rng, i, j)
		4: return, self.vars[r]._overloadBracketsRightSide(rng, i, j, k)
		5: return, self.vars[r]._overloadBracketsRightSide(rng, i, j, k, l)
		6: return, self.vars[r]._overloadBracketsRightSide(rng, i, j, k, l, m)
		7: return, self.vars[r]._overloadBracketsRightSide(rng, i, j, k, l, m, n)
		8: return, self.vars[r]._overloadBracketsRightSide(rng, i, j, k, l, m, n, o)
	else: message, 'Syntax error: empty array index'
	endcase
end

;+
; Das2 dimension object, provides arrays and properties for a single
; physical dimension, such as Time or Spectral Density
;-
pro das2dim__define
	compile_opt idl2, hidden
	void = { das2dim, inherits IDL_Object, kind:'', $
	         props:obj_new(), vars:obj_new()}
end
