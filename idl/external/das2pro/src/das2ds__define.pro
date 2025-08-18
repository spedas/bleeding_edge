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
function das2ds::init, _extra=ex
	compile_opt idl2
	
	void = self.IDL_Object::init()
	self.props = hash()
	self.dims = hash()
	self.rank = 0
	return, !true
end

; --------------------------------------------------------------------------- ;
pro das2ds::getproperty, PROPS=props, DIMS=dims, RANK=rank, GROUP=group, $
  NAME=name
  
	compile_opt idl2
	if arg_present(props) then props = self.props
	if arg_present(dims) then dims = self.dims
	if arg_present(rank) then rank = self.rank
	if arg_present(name) then name = self.name
	if arg_present(group) then group = self.group
end

pro das2ds::setproperty, RANK=rank, GROUP=group, NAME=name
	compile_opt idl2
	
	if isa(units) then self.units = units
	if isa(rank) then self.rank = rank
	if isa(name) then self.name = name
	if isa(group) then self.group = group
end

; --------------------------------------------------------------------------- ;
;+
; Answers the question, how big are data packets for this dataset.
;
; Datasets can be parsed from das2 streams.  A stream consists of 
; header and data packets.  Each data packet must have a sufficent 
; number of data values to increment the highest index of the internal
; data arrays by 1.
;
; :Returns:
;    The number of total bytes in each data packet for this dataset.
;     
;-
function das2ds::recsize
	compile_opt idl2
	
	nRecBytes = 0
	
	aDims = self.dims.keys()
	
	;printf, -2, "DEBUG: Dims in dataset: ", n_elements(nDims)
	
	for d = 0, n_elements(aDims) - 1 do begin
		dim = self.dims[ aDims[d] ]
		
		aVar = dim.vars.keys()
		for v = 0, n_elements(aVar) - 1 do begin
			var = dim.vars[ aVar[v] ]
			
			if var.parser ne obj_new() then begin
				
				; Using IDL convention of end including the last index instead of
				; of being an upper bound.
				nEnd = var.parser.offset() + var.parser.chunksize()
				
				if nEnd gt nRecBytes then nRecBytes = nEnd
			endif 
		endfor 
	endfor
	return, nRecBytes
end

; --------------------------------------------------------------------------- ;
function das2ds::_overloadBracketsRightSide, isrange, d, r, i, j, k, l, m, n 
	compile_opt idl2
	
	if isrange[0] gt 0 then begin
		message, 'Range selection not supported for physical dimensions, i.e. no ''time'':''frequency'' slices'
	endif
	
	if (n_elements(isrange)) gt 1 && (isrange[1] gt 0) then begin
		message, 'Range selection not supported for variable roles, i.e. no ''center'':''min'' slices'
	endif
	
	if n_elements(isrange) gt 2 then rng = isrange[2:-1]
	
	case n_elements(isrange) of
		1: return, self.dims[d]
		2: return, self.dims[d].vars[r]
		3: return, self.dims[d].vars[r]._overloadBracketsRightSide(rng, i)
		4: return, self.dims[d].vars[r]._overloadBracketsRightSide(rng, i, j)
		5: return, self.dims[d].vars[r]._overloadBracketsRightSide(rng, i, j, k)
		6: return, self.dims[d].vars[r]._overloadBracketsRightSide(rng, i, j, k, l)
		7: return, self.dims[d].vars[r]._overloadBracketsRightSide(rng, i, j, k, l, m)
		8: return, self.dims[d].vars[r]._overloadBracketsRightSide(rng, i, j, k, l, m, n)
	else: message, 'Syntax error: empty array index'
	endcase
	
end

; --------------------------------------------------------------------------- ;
;+
; Inspect all owned variables and get the index range of the
; overall dataset.  Map sizes to array dimensions using the 
; index maps.
;
; :Private:
;-
function das2ds::_idxRangeStr
	compile_opt idl2, hidden
		
	if self.rank lt 1 then return, ''
	
	aIdxVar  = ['i','j','k','l','m','n','o','p']
	aOut     = strarr(self.rank)
	aDsShape = intarr(self.rank)
	
	foreach dim, self.dims, sDim do begin
		
		foreach var, self.dims[sDim].vars, sRole do begin
			
			;printf, -2, '_idxRangeStr: Calling dshape for ',sDim,':',sRole
			aMap = var.dshape()
			;printf, -2, '_idxRangeStr: shape is', aMap
			;printf, -2, '_idxRangeStr: size is', size(aMap, /DIMENSIONS)
			
			; IDL likes to switch output types...a lot
			aSize = size(aMap, /DIMENSIONS)
			if n_elements(aSize) eq 1 then nMapDims = 1 $
			else nMapDims = aSize[1]

			; If the map doesn't have the same dimensions as the dataset rank, 
			; the dataset is inconsistant.			
			if nMapDims ne self.rank then begin
				sMsg = string( $
					sDim, sRole, n_elements(var.idxmap), self.nRank, $
					format='Inconsistant dataset, rank of variable %s[''%s''] is %d, expected %d' $
				)
				message, sMsg
			endif
			
			for iDsAxis = 0, self.rank - 1 do begin
				iVarAxis = aMap[0,iDsAxis] ; the var axis that maps to this DS axis
				nVarSize = aMap[1,iDsAxis] ; the var extent in this axis
				
				; Var has no axis that maps to this dataset axis, just continue...
				if iVarAxis lt 0 then continue 
				
				if aDsShape[ iDsAxis ] lt nVarSize then aDsShape[ iDsAxis ] = nVarSize
			endfor		
		endforeach
	endforeach
	
	; have the max extents in each axis, now make the string
	for i = 0, self.rank - 1 do begin
		aOut[i] = string(aIdxVar[i], aDsShape[i], format='(%"%s=0:%d")')
	endfor
	
	return, aOut.join(', ')
end

; --------------------------------------------------------------------------- ;
function das2ds::_overloadPrint
	compile_opt idl2, hidden

	nl = string([10B])
	aIdxVar  = ['i','j','k','l','m','n','o','p']

	s = self._idxRangeStr()
	;n = self.recsize()
	;s = string(n, format='Record Size: %d bytes')

	sOut = string(self.name, self.group, s, format='(%"Dataset: `%s` from group `%s` | %s")')
	aKeys = self.props.keys()
	for i = 0, n_elements(aKeys) - 1 do begin
		prop = self.props[aKeys[i]]
		sOut += nl + string(aKeys[i], prop.strval, format='(%"   Property: %s | %s")')
	endfor
	
	; TODO: Refactor this.  Dims and Variables should be responsible for
	;       printing themselves instead of doing it all here
	
	
	; Sort all data dimensions before all coordinate dimensions
	aKeys = self.dims.keys()
	lCoordKeys = list()
	lDataKeys = list()
	for i = 0, n_elements(aKeys) - 1 do begin
		dim = self.dims[aKeys[i]]
		if dim.kind eq 'Data' then lDataKeys.add, aKeys[i] $
			else lCoordKeys.add, aKeys[i]
	endfor
	aKeys = [ lDataKeys.ToArray(), lCoordKeys.ToArray() ]
		
	for i = 0, n_elements(aKeys) - 1 do begin
		sDim = aKeys[i]
		dim = self.dims[sDim]
		
		sDimName = aKeys[i]
		
		sOut += nl + nl + string(dim.kind, sDimName, format='(%"   %s Dimension: %s")')
		
		aSubKeys = dim.props.keys()
		for j = 0, n_elements(aSubKeys) - 1 do begin
			prop = dim.props[aSubKeys[j]]
			sOut += nl + string(aSubKeys[j], prop.strval, $
			                    format='(%"      Property: %s | %s")')
		endfor
		
		aSubKeys = dim.vars.keys()
		for j = 0, n_elements(aSubKeys) - 1 do begin
			sRole = aSubKeys[j]
			var = dim.vars[sRole]
			
			if var.values eq ptr_new() then sType = 'NO_DATA_YET'
			
			aSz = strarr(n_elements(var.idxmap))
			for iDsAx=0,n_elements(var.idxmap) - 1 do begin
				if (var.idxmap)[iDsAx] lt 0 then aSz[iDsAx] = '-' else aSz[iDsAx] = aIdxVar[iDsAx]
			endfor
			sSz = aSz.join(',')
			sType = typename(*(var.values))
			sOut += nl + string(sDimName, sRole, sSz, sType, var.units, $
			                    format='(%"      Variable: %s[''%s''][%s] (%s) %s")')
		endfor
		
	endfor
	
	return, sOut + nl
end

; --------------------------------------------------------------------------- ;
;+
; Provide the key names for all physical dimensions in the dataset
;
; :Keywords:
;     D : in, type=boolean, optional
;        Return just the string ids for the data dimensions
;
;     C : in, type=boolean, optional
;        Return just the string ids for the coordinate dimensions
;
; :Returns:
;    list - A list of strings containing the hask keys for the requested
;        physical dimensions.
;
; :Author:
;    Chris Piker
;-

function das2ds::keys, D=d, C=c
	compile_opt idl2, hidden

	lOut = list()
	if keyword_set(d) then begin
		foreach key, self.dims.keys() do begin
			dim = self.dims[key]
			if dim.kind eq 'Data' then lOut.add, key
		endforeach
	endif else if keyword_set(c) then begin
		foreach key, self.dims.keys() do begin
			dim = self.dims[key]
			if dim.kind ne 'Data' then lOut.add, key
		endforeach
	endif else lOut = self.dims.keys()

	aOut = lOut.toarray()
	aOut = aOut[ sort(aOut) ]
	return, aOut
end	

; --------------------------------------------------------------------------- ;
;+
; Dataset objects (das2ds) explicitly denote, and separate, array index
; dimensions and physical dimensions.
;
; For each physical space, such as Time or Spectral Density, there is a das2dim
; (das2 dimension) member object of a dataset.  Each dimension may have more
; than one set of applicable values.  For example in the Time dimension there
; may be a set of values that represent when a measurement was taken in UTC 
; and, the time uncertianty in seconds.  Each set of measurements and thier
; units are contained within a das2var (das2 variable) object.
;
; To make plots and analyze data we have to know which values "go together".
; Considering an energy spectra dataset for a moment, we would need to know
; what array index numbers should be used to match a time, with an energy level
; with a count rate, with a look direction.  This is a bookkeeping problem.
; We could solve this problem in a manner similar to the ISTP standard by
; insisting that each dimension of an array correspond with a single physical
; dimension.  Doing so quickly results in display tools confusing index space
; for physical space, a problem that we want to avoid.  Instead, to provide this
; information, an overall dataset index space is defined.  Each variable within
; the dataset provides a mapping between it's array indices and the overall 
; dataset index space.  This mapping can be used to correlate values from
; various arrays without constraining the nature of the physical measurements
; contained within the dataset.
;
; :Author:
;    Chris Piker
;-
pro das2ds__define
	compile_opt idl2, hidden
	
	; Have to use obj_new() to declare storage space for any compound types
	; (i.e. classes) that are part of a structure.  See:
	;
	;  https://www.harrisgeospatial.com/Support/Maintenance-Detail/ArtMID/13350/ArticleID/15715/Problems-Assigning-LIST-HASH-etc-to-Class-or-Structure-Tags
	;
	; for details
	void = { $
		das2Ds, inherits IDL_Object, name:'', group:'', rank:'', $
		props:obj_new(), dims:obj_new() $
	}
end
