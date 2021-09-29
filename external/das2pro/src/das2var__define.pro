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

; --------------------------------------------------------------------------- ;
function das2var::init, _EXTRA=ex
	compile_opt idl2
	void = self.IDL_Object::init()
	
	; default values
	self.units = ''
	self.values = ptr_new()
	self.parser = obj_new()
	self.idxmap = ptr_new()
	
	if(isa(ex)) then self.setproperty, _EXTRA=ex
	return, !TRUE
end

; --------------------------------------------------------------------------- ;
pro das2var::getproperty, $
	UNITS=units, VALUES=values, IDXMAP=idxmap, PARSER=parser, ARRAY=array
	compile_opt idl2
	if arg_present(units) then units = self.units
	if arg_present(values) then values = self.values
	if arg_present(idxmap) then idxmap = *(self.idxmap)
	if arg_present(parser) then parser = self.parser
	
	if arg_present(array) then begin 
		if self.values eq ptr_new() then array = !null else array = *(self.values)
	endif
end

; --------------------------------------------------------------------------- ;
pro das2var::setproperty, $
	UNITS=units, VALUES=values, IDXMAP=idxmap, PARSER=parser
	compile_opt idl2
	
	if isa(units) then self.units = units 
	if isa(values) then self.values = ptr_new(values, /no_copy) 
	if isa(parser) then self.parser = parser 
	
	; Maybe add checking code here to make sure that the index map 
	; has no more non-zero entries than the values array?  I don't
	; want this function to be annoying to code that sets the index
	; before the array is set, so let it go for now.
	if isa(idxmap) then begin
		self.idxmap = ptr_new(idxmap) ; copies internally by default
	endif
end

; --------------------------------------------------------------------------- ;
;+
; Provide index ranges for this variable in terms of the top level dataset
; index space.
;
; Cordinate variables often have lower dimensional arrays than the data
; variables.  For example, think of an insturment that collects energetic
; partical hit-counts in 45 energy bands once per minute.  The coordinates of 
; this dataset would be energy and time, with the data being the count rate.
; An hour's worth of these measurements could be stored in the following
; arrays:
; 
; ```
;    aTime    = long64arr(60)
;    aEnergy  = fltarr(45)
;    aCounts  = intarr(45, 60)
; ```
;
; Looking at the index ranges for this simple dataeset it's apparent that the
; first index of array aTime must correspond to the second index of array 
; aCounts.  To help visualize this mapping, especially when datasets become
; more complex, we could "line-up" all the index ranges to make the mapping
; more explicit:
;
; ```
; Values   Extents
; ------   -------
; Time     [ - , 60]
; Energy   [ 45, - ]
; Counts   [ 45, 60]
; ```
;
; This is what the idxmap function outputs, the mapping of index space of a
; single array to the overall dataset index space.  Assume now that these
; arrays are actually the `.values` member of three different das2var objects.
; Calling `.dshape()` would yield the following (without comments of course):
;
; ```
; print, vTime.dshape() 
;   -1      0      ; var is degenerate in first dataset index (0 values)
;    0     60      ; second dataset index maps to first var index (60 values)
;
; print, vEnergy.dshape()
;    0     45      ; first dataset index maps to first var index (45 values)
;   -1      0      ; var is degenerate in the second dataset index (0 values)
;
; print, vCounts.dshape()
;    0     45      ; first dataset index maps to first var index (45 values)
;    1     60      ; second dataset index maps to second var index (60 values)
; ```
;
; :Returns:
;   A 2 by N array, where N is the number of independent indexes required to
;   correlate all values in a dataset.
;
; :Author: Chris Piker
;-
function das2var::dshape
	
	idxmap = *(self.idxmap)
	
	nIdxDims = n_elements(idxmap)
	aShape = intarr(2, nIdxDims)
	for i =0, nIdxDims - 1 do begin
		aShape[0, i] = idxmap[i]
		arydims = size(*(self.values), /DIMENSIONS)
		
		if idxmap[i] gt -1 then begin	
			;printf, -2, 'das2var::dshape, idxmap:  ', idxmap, 'array dims:  ', arydims
			aShape[1, i] =  arydims[ idxmap[i] ]
		endif else aShape[1,i] = 0.0
	endfor
	
	return, aShape
end

; --------------------------------------------------------------------------- ;
;+
; Provide access to the underlying value using standard array indexing.
;
; Due to limitations of the IDL language (i.e. array._overloadBracketsRightSide
; doesn't exist) ranges are only supported up to 3 index dimensions.  To
; get a block range for arrays larger than rank 3 use the .array() method to
; get the array variable directly.
;
; To avoid suprise return values when gathing a slice of data, the indexmap
; is ignore.  If you are getting single values (not recommended in IDL) and
; wish to work in dataset index space use the .at() method.
;-

function das2var::_overloadBracketsRightSide, $
	rng, i, j, k, l, m, n, o, p 
	
	
	; IDL, really?  The is-range/is-not-range info needs to stay with the slice
	; objects.  If not, you end up with insane combinatoric problems like this
	; one.  There is probably some sort of introspection will prevent the code
	; below, but I don't know what it would be.
	;
	; POSIX defines vsprintf for *exactly* the same reason as this.  There is
	; no way to capture the information [1,2,1] + bIsRange and send it to a 
	; sub array without *explicity syntax*.  Even the IDL example at:
	;
	;    https://www.harrisgeospatial.com/docs/Example__Overloading_the1.html
	;
	; totally glosses over the fact that range specifications can't be deligated
	; to sub objects in a simple manner.
	;
	; Maybe there's an iterative way to get this done using reform but I'm not
	; sure what it is.
	
	vals = *(self.values)
	
	; Yay, simple for 1-D case
	if n_elements(rng) eq 1 then begin
		if rng[0] then begin
			return, vals[i[0]:i[1]:i[2]]
		endif else begin
			return, vals[i             ]
		endelse
	endif
	
	; Wow wait, this is getting big fast (2**x)....
	if n_elements(rng) eq 2 then begin

		if            (~ rng[0]) && (~ rng[1]) then begin
			return, vals[i,              j             ]
			
		endif else if (~ rng[0]) && (  rng[1]) then begin
			return, vals[i,              j[0]:j[1]:j[2]]
			
		endif else if (  rng[0]) && (~ rng[1]) then begin
			return, vals[i[0]:i[1]:i[2], j             ]
			
		endif else begin
			return, vals[i[0]:i[1]:i[2], j[0]:j[1]:j[2]]
			
		endelse
	endif
	
	; Okay, this is insane, but one more, 'cause we're crazy too.
	if n_elements(rng) eq 3 then begin
		 
		if            (~ rng[0]) && (~ rng[1]) && (~ rng[2]) then begin
			return, vals[i,              j,              k            ]
		
		endif else if (~ rng[0]) && (~ rng[1]) && (  rng[2]) then begin
			return, vals[i,              j,              k[0]:k[1]:k[2]]
		
		endif else if (~ rng[0]) && (  rng[1]) && (~ rng[2]) then begin
			return, vals[i,              j[0]:j[1]:j[2], k            ]
		
		endif else if (~ rng[0]) && (  rng[1]) && (  rng[2]) then begin
			return, vals[i,              j[0]:j[1]:j[2], k[0]:k[1]:k[2]]
		
		endif else if (  rng[0]) && (~ rng[1]) && (~ rng[2]) then begin
			return, vals[i[0]:i[1]:i[2], j,              k            ]	
		
		endif else if (  rng[0]) && (~ rng[1]) && (  rng[2]) then begin
			return, vals[i[0]:i[1]:i[2], j,              k[0]:k[1]:k[2]]
		
		endif else if (  rng[0]) && (  rng[1]) && (~ rng[2]) then begin
			return, vals[i[0]:i[1]:i[2], j[0]:j[1]:j[2], k            ]
		
		endif else begin
			return, vals[i[0]:i[1]:i[2], j[0]:j[1]:j[2], k[0]:k[1]:k[2]]
		
		endelse
		
	endif
	
	; Stopping here, as dimension 8 would be a 256 part if statement...
	if n_elements(rng) gt 3 then begin
		if max(rng) gt 0 then begin
			message, 'Range selections not currently supported for rank 3 arrays and above'
		endif
	endif			
	
	case n_elements(rng) of
		4: return, (*(self.values))[i, j, k, l]
		5: return, (*(self.values))[i, j, k, l, m]
		6: return, (*(self.values))[i, j, k, l, m, n]
		7: return, (*(self.values))[i, j, k, l, m, n, o]
		8: return, (*(self.values))[i, j, k, l, m, n, o, p]
	else: message, 'Syntax error: empty array index'
	endcase
		
end

; --------------------------------------------------------------------------- ;
;+
; Das2 Variable, an array, it's units and it's index map.
;-
pro das2var__define
	compile_opt idl2, hidden
	void = { $
		das2var, inherits IDL_Object, units:'', values:ptr_new(), $
		parser:obj_new(), idxmap: ptr_new() $
	}
end
