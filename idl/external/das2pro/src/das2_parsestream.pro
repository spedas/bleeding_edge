; The MIT License
;
; Copyright 2018-2019 David Pisa (IAP CAS Prague) dp@ufa.cas.cz
;           2019      Chris Piker
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
;+
; Try to determine a decent name for a dimension given a units string,
; return !null if nothing works
;
; :Private:
;-
function _das2_nameFromUnits, sUnits
	compile_opt idl2, hidden
	
	if sUnits.substring(0,3) eq 'time' then return, 'time'
	if sUnits eq 'us2000' then return, 'time'
	if sUnits eq 'mj1958' then return, 'time'
	if sUnits eq 't2000' then return, 'time'
	if sUnits eq 't1970' then return, 'time'
	
	if ((sUnits.substring(-2, -1)).tolower() eq 'hz') && (sUnits.strlen() lt 5) $
		then return, 'frequency'
	
	if ((sUnits.substring(-2, -1)).tolower() eq 'ev') && (sUnits.strlen() lt 5) $
	   then return, 'energy'
	
	return, !null
end

; --------------------------------------------------------------------------- ;s
;+
; Inspect the properties sub item of a stream header object hash and
; pull out the requested property value, if present.
;
; :Private:
;
; :Params:
;    hObj : in, required, type=hash
;        A hash, as returned by xml_parse() of the <stream>, <x>, <y>, <z>,
;        <yscan> element in question.
;    sProp: in, required, type=string
;        The property to find
;
; :Returns:
;    !null if the property is not present or a type object
;    (int, String, datum, datum range, etc.)
;-
function _das2_getProp, hObj, sProp
	compile_opt idl2, hidden
	
	if ~ hObj.haskey('properties') then return, !null
	
	hProp = hObj['properties']
	
	sType = !null
	sVal = !null
	
	; Listed in order of likely occurence frequency
	aTypes = [ $
		'String','Datum','double','DatumRange','int','Time','boolean', $
		'Time', 'TimeRange' $
	]
	
	if hProp.haskey('%'+sProp) then begin 
		sVal = hProp['%'+sProp]
		sType = 'String'
	endif else begin 
		for i = 0, n_elements(aTypes) - 1 do begin
			sKey = '%' + aTypes[i] + ':' + sProp
			if hProp.haskey(sKey) then begin
				sVal = hProp[sKey]
				sType = aTypes[i]
				break
			endif
		endfor
	endelse
	
	if (sType eq !null) || (sVal eq !null) then return, !null $
	else return, das2prop(type=sType, value=sVal)
end


;+
; Make a new variable given a plane header
;
; :Private:
;-
function _das2_varFromHdr, hPlane, idxmap, decoder
	compile_opt idl2, hidden
	
	sUnits = ''
	if hPlane.haskey('%units') then begin
		sUnits = hPlane['%units'] 
	endif else begin
		if hPlane.haskey('%zUnits') then sUnits = hPlane['%zUnits']
	endelse
	
	;var = das2var(units=sUnits, idxmap=idxmap, parser=decoder)
	;printf, -2, 'Making var with units='+sUnits+', idxmap=', idxmap, $
	;            ' and parser=', decoder

	var = obj_new('das2var', UNITS=sUnits, IDXMAP=idxmap, PARSER=decoder)
	return, var
end

; --------------------------------------------------------------------------- ;
;+
; Given a stream header, a plane header and a plane type, 
; make a new physical dimension structure
;
; :Private:
;
; :Returns:
;    The new dimension
;-
function _das2_dimFromHdr, hStream, sPlaneType, hPlane, sKind
	compile_opt idl2, hidden
	
	dim = obj_new('das2dim')
	dim.kind = sKind
	
	; First add all stream properites
	if hStream.haskey('properties') then begin
	
		;printf, -2, 'making dim using:  ', hStream['properties']
	
		; there's probably a better hash key iteration idiom than this in IDL
		d = hStream['properties']
		k = d.keys()
		for i= 0,n_elements(k) - 1 do begin
			sType = 'String'
	   	sKey = k[i]
			sVal = d[k[i]]
			
			; this is dumb, das2 streams need to follow proper XML rules -cwp
			lTmp = sKey.split(':')
			if n_elements(lTmp) gt 1 then begin
				sType = (lTmp[0]).substring(1,-1)
				sKey = lTmp[1]
			endif else sKey = sKey.substring(1,-1)
			
			sAx = sKey.charat(0) 
			if sAx eq sPlaneType then begin
				sKey = (sKey.charat(1)).tolower() + sKey.substring(2,-1)
				dim.props[sKey] = das2prop(type=sType, value=sVal)
			endif
		endfor
	endif
		
	; if no plane header, nothing to add at this point
	if hPlane eq !null then return, dim
	
	; Pick up out-of-spec properties, just to be nice, but have regular 
	; properties override them
	if hPlane.haskey('%label') then $
		dim.props['label'] = das2prop(type='String', value=hPlane['%label'])
	
	; now override with local properties
	if hPlane.haskey('properties') then begin
		; there's probably a better hash key iteration idiom than this in IDL
		d = hPlane['properties']
		k = d.keys()
		for i= 0,n_elements(k) - 1 do begin
			sType = 'String'
	   	sKey = k[i]
			sVal = d[k[i]]
			
			; this is dumb, das2 streams need to follow proper XML rules -cwp
			lTmp = sKey.split(':')
			if n_elements(lTmp) gt 1 then begin
				sType = (lTmp[0]).substring(1,-1)
				sKey = lTmp[1]
			endif else sKey = sKey.substring(1,-1)
			
			sAx = sKey.charat(0) 
			if sAx eq sPlaneType then begin
				sKey = (sKey.charat(1)).tolower() + sKey.substring(2,-1)				
				dim.props[sKey] = das2prop(type=sType, value=sVal)
			endif
			
			; TODO: Should we keep local properties that don't start with
			;       our axis tag?  
		endfor
	endif
		
	return, dim
end

; --------------------------------------------------------------------------- ;
;+
; When multiple planes of the same type are present in the stream it's possible
; that they are related
;
;-
function _das2_op2role, prop
	compile_opt idl2, hidden
	
	if prop.value eq 'BIN_MAX' then return, 'max'
	if prop.value eq 'BIN_MIN' then return, 'min'
	; Add others here
		
	return, 'center'
end


; --------------------------------------------------------------------------- ;
;+
; Add dimenions and variables from a single type of plane to a dataset
;
; :Private:
;
; :Params:
;    hStream : in, required, type=hash
;
;    hPkt  : in, required, type=hash
;
;    sPlaneType : in, required, type=string
;       The plane tag, one of x,y,z,yscan depending on which type of
;       planes to find
;
;    sDatAxis : in, required, type=string
;       The axis for data from this plane, which is not necessarily
;       the plane tag.  For examply yscan data can be either y values
;       (waveform) or z values (spectra)
;
;    idxmap : in, required, type=intarr
;       How values from this dat array map to overall dataset indices
;       since IDL is backwards from everyone else these are easy to 
;       mix up. 
;
;    iOffest : in, required, type=int
;       The offset into the packet header for data that has 
;       already been claimed by other dimensions.  Depends on all
;       <x><x>... coming before all <y><y>... before all <z><z>... 
;       before all <yscan><yscan>... in the packet definition.
;       
;       No way to check this currently since we are using xml_parse()
;       from IDL that does not preserve this information.
;
;   dataset : in, required, type=das2ds
;       The dataset object to receive these new dimensions
;
; :Keywords:
;    FIRST : out, optional, type=das2dim
;       Used to save off the first dimension of a type.
;
; :Returns:
;    The new offset into the records for the start of data from other
;    dimension sets.

function _das2_addDimsFromHdr, $
	hStream, hPkt, sPlaneType, sDatAxis, idxmap, iOffset, sKind, $
	dataset, FIRST=dimFirst

	compile_opt idl2, hidden
		
	sUnitAttr = '%units'
	if sPlaneType eq 'yscan' then begin 
		sUnitAttr = '%zUnits'
	endif
	
	bXOffset = !false
	if hStream.haskey('properties') then begin
		h = hStream['properties']
		if h.haskey('%renderer') then bXOffset = (h['%renderer'] eq 'waveform')
		if h.haskey('%String:renderer') then bXOffset = (h['%String:renderer'] eq 'waveform')
	endif
	
	if ~(hPkt.haskey(sPlaneType)) then return, iOffset
	
	; make sure planes are always a list
	lPlanes = hPkt[sPlaneType]
	if typename(lPlanes) ne 'LIST' then lPlanes = list( hPkt[sPlaneType] )
				
	; make decoders, variables and dimensions for each plane
	for iPlane=0, n_elements(lPlanes) - 1 do begin
						
		hPlane = lPlanes[iPlane]
	
		decoder = obj_new('das2decoder', iOffset, hPlane)
		iOffset += decoder.chunkSize()
		var = _das2_varFromHdr( hPlane, idxmap, decoder)
			
		; Add to an existing dimension (if min/max) or start a new one.
		
		; When we restructure das2 streams, dimensions (or some other plane
		; grouping mechanism) need to be added
			
		propSrc = _das2_getProp(hPlane, 'source')
		propOp  = _das2_getProp(hPlane, 'operation')
		
		; get an existing dim...
		dim = !null
		if propSrc ne !null then begin
			if dataset.dims.haskey(propSrc.value) then $
				dim = dataset.dims[propSrc.value]
		endif
		
		; ...or create a new one
		if dim eq !null then begin
			
			;printf, -2, sDatAxis, sKind, hPlane
			
			dim = _das2_dimFromHdr(hStream, sDatAxis, hPlane, sKind)
			
			if (sPlaneType eq 'x') && bXOffset && (dimFirst eq !null) then $
				dim.vars['reference'] = var $
			else $
				dim.vars['center'] = var
			
			; determining good names for dimensions is not easy...
			sName = !null
			if sSrc ne !null then sName = sSrc
			
			if sName eq !null then begin
				if hPlane.haskey('%name') then sName = hPlane['%name']
			endif
			if sName eq !null then begin
				if hPlane.haskey(sUnitAttr) then sName = _das2_nameFromUnits(hPlane[sUnitAttr])
			endif
			if sName eq !null then sName = string(sPlaneType, iPlane, format='%s_%d')
			
			if dataset.dims.haskey(sName) then $
				message, 'Error in das2 stream, name '+sName+' repeats in the same packet"
			
			dataset.dims[sName] = dim
			
			;printf, -2, dataset
			
			; Set the name based on the first plane of each kind.
			; WARNING ASSUMES: _das2_addDimsFromHdr is called in order from
			;                  <x> ... to <yscan>  This is not the best 
			; idea in the world, but the das2.2 stream format has no concept of
			; a dataset name.
			if dimFirst eq !null then dataset.name = sName
									
		endif else begin
			message, 'Peaks-averages datasets such as Voyager SA are not yet supported'
			sRole = _das2_op2role(propOp)
			dim.vars[sRole] = var
		endelse
			
		; Save off the first <x><y><z><yscan> dim in case we need to add an offset
		; variable to it from the ytags
		if dimFirst eq !null then begin
			dimFirst = dim
		endif
		
	endfor
	
	return, iOffset
end

; --------------------------------------------------------------------------- ;
;+
; Make a new dataset object given stream and packet headers. 
;
; :Private:
;
; :Params:
;    hStrmHdr: in, required, type=hash
;       The parsed stream XML header as returned from xml_parse
;
;    hPktHdr: in, required, type=hash
;       The parsed packet XML header as returned from xml_parse
;
; :Keywords:
;    DEBUG: in, optional, private, type=bool
;       If true print debugging information
;
; :Author:
;    Chris Piker (hence the snark)
;-
function _das2_onNewPktId, hStrmHdr, hPktHdr, DEBUG=bDebug
	compile_opt idl2, hidden
	
	; IDL note, make sure you define a dataset before any calls to define a
	; dimension or a variable or else das2ds__define.pro will not be compiled
	dataset = das2ds()
	
	hStream = hStrmHdr['stream'] ; only element that matters
	
	; Save properties that don't depend on the axis (i.e. the plane)	
	if hStream.haskey('properties') then begin
	
		; there's probably a better hash key iteration idiom than this in IDL
		h = hStream['properties']
		k = h.keys()
		for i= 0,n_elements(k) - 1 do begin
			sType = 'String'
	   	sKey = k[i]
			sVal = h[k[i]]
			
			; this is dumb, das2 streams need to follow proper XML rules -cwp
			lTmp = sKey.split(':')			
			if n_elements(lTmp) gt 1 then begin
				sType = (lTmp[0]).substring(1,-1)
				sKey = lTmp[1]
			endif else begin
				sKey = (lTmp[0]).substring(1,-1)
			endelse
			
			; For stuff that's not tagged as part of an axis, just add it's
			; properties to the top level dataset.  This ONLY WORKS because
			; most regular non-property names don't start with x, y or z.
			sAx = sKey.charat(0) 
			if (sAx ne 'x') && (sAx ne 'y') && (sAx ne 'z') then $
				dataset.props[sKey] = das2prop(type=sType, value=sVal)
		endfor
	endif
	
	hPkt = hPktHdr['packet']   ; only element that matters
	
	; Legal packet types (as of das2.2):
	;
	; <x> <y><y><y>...
	; <x> <y> <z><z><z>...
	;
	
	; Setting up decoders, variables and dimensions
	;
	; <x>  -> X centers
	; <y><properties operation="" > -> max or min
	;
	; When: <stream><properties>renderer=waveform  (Just...wow)
	; <yscan> yTags, yInterval, yMin -> X offsets
	
	; Handling the Y axis...
	; <y> -> Y center
	; <y><properties operation="" > -> max or min
	; <yscan> yTags, yInterval, yMin -> Y offsets

	; Handling the Z axis...
	; <z> -> Z center
	; <yscan> -> Z center
	; <yscan
	
	; Find out if this is a 1-index or 2-index dataset
	dataset.rank = 1
	if hPkt.haskey('yscan') then dataset.rank = 2
	;printf, -2, 'rank:', dataset.rank
	idxmap = make_array(dataset.rank, /integer)
	
	; X
	bXOffset = !false
	if hStream.haskey('properties') then begin
		h = hStream['properties']
		if h.haskey('%renderer') then bXOffset = (h['%renderer'] eq 'waveform')
		if h.haskey('%String:renderer') then bXOffset = (h['%String:renderer'] eq 'waveform')
	endif
	
	; Go down through the planes defined in the header and create dimensions
	; for each one.
	iOffset = 0
	xDimFirst = !null
		
	; REMEMEBER! Index maps are backwards for IDL.
	
	; The last overall dataset index is the only index that changes
	; the values read for <x><y> and <z> planes
	
	idxmap[0] = 0
	if dataset.rank eq 2 then begin 
		idxmap[0] = -1
		idxmap[1] = 0
	endif
	
	sKind = 'Coordinate'
	iOffset = _das2_addDimsFromHdr( $
		hStream, hPkt, 'x', 'x', idxmap, iOffset, sKind, dataset, FIRST=xDimFirst $
	)
	
	if hPkt.haskey('z') || hPkt.haskey('yscan') then sKind = 'Coordinate' $
		else sKind = 'Data'
		
	iOffset = _das2_addDimsFromHdr( $
		hStream, hPkt, 'y', 'y', idxmap, iOffset, sKind, dataset, FIRST=yDimFirst $
	)
	
	iOffset = _das2_addDimsFromHdr( $
		hStream, hPkt, 'z', 'z', idxmap, iOffset, 'Data', dataset $
	)
	
	if dataset.rank eq 2 then begin
		idxmap[0] = 0
		idxmap[1] = 1
		
		iOffset = _das2_addDimsFromHdr( $
			hStream, hPkt, 'yscan', 'z', idxmap, iOffset, 'Data', dataset $
		)
		
		; Get the first yscan object
		hPlane = hPkt['yscan']
		if typename(hPlane) eq 'LIST' then hPlane = hPlane[0]
				
		idxmap[0] = 0  ; We use /TRANSPOSE in list::toarray() below to get
		idxmap[1] = -1 ; back to column major order so that printed das2 streams
		               ; match the (un)natural indexing of IDL
		
		; the actual data values can be enumerated or come form a generator
		nItems = fix(hPlane['%nitems'])
			
		if hPlane.haskey('%yTags') then begin
			aVals = float(strtrim(strsplit(hPlane['%yTags'], ',', /extract)))
		endif else if hPlane.haskey('%yTagInterval') then begin
			rInt = double(hPlane['%yTagInterval'])
			rMin = 0.0
			if hPlane.haskey('%yTagMin') then rMin = double(hPlane['%yTagMin'])
			aVals = dindgen(nItems, start=rMin, increment=rInt)
		endif else begin 
			aVals = dindgen(nItems, start=0.0, increment=1.0)
		endelse
		
		; Set the values directly, this one has no decoder
		;printf, -2, 'DEBUG: Making var with values=', aVals, ', idxmap=', idxmap
		var = obj_new('das2var', VALUES=aVals, IDXMAP=idxmap)
		;printf, -2, 'DEBUG: After var, obj_new'
		
		if hPlane.haskey('%yUnits') then var.units = hPlane['%yUnits']
		sName = _das2_nameFromUnits(var.units)
				
		; Since yTags are not given as xOffset or yOffset in the overall
		; packet, use a random property waaaaay up at the top of the stream 
		; to decide (really?).
				
		if bXOffset then begin
			; ytags offset or set x
		
			if xDimFirst ne !null then begin
				xDimFirst.vars['offset'] = var
			endif else begin
				; there is no x dimension, going to have to make one, and yes
				; we use the y values to define the x dimension properties
				xDim = _das2_dimFromHdr(hStream, 'y', !null, 'Coordinate')
				xDim.vars['center'] = var
				if sName eq !null then sName = 'X'
				dataset.dims[sName] = xDim
			endelse
					
		endif else begin
			; ytags offset or set y
		
			if yDimFirst ne !null then begin
				yDimFirst.vars['offset'] = var
			endif else begin
				; there is no y dimension, going to have to make one
				yDim = _das2_dimFromHdr(hStream, 'y', !null, 'Coordinate')
				yDim.vars['center'] = var
				if sName eq !null then sName = 'Y'
				dataset.dims[sName] = yDim
			endelse
		endelse
		
	endif ; indexes = 2 (i.e. we have yscan objects)
	
	return, dataset
end


; --------------------------------------------------------------------------- ;
;+
; Parse data for a single packet using the given dataset structure and append
; it to the variable arrays
;
; note: since das2 streams don't put a length on the data packets there's
;       no way to cross check that the stream definition matches the length
;       of the data.  All we can do is try to parse it without running of
;       the end
;
; :Private:
;-
function _das2_onData, aBuffer, iBuf, messages, dataset
	compile_opt idl2, hidden
	
	;printf, -2, 'Parsing ', size(aBuffer), ' byte packet'
	
	nRecSz = dataset.recsize()
	aDims = dataset.dims.keys()
	aRec = aBuffer[iBuf + 4 : (iBuf + 4 + nRecSz) - 1]
	
	for d = 0, n_elements(aDims) - 1 do begin
		dim = dataset.dims[ aDims[d] ]
		
		aVar = dim.vars.keys()
		for v = 0, n_elements(aVar) - 1 do begin
			var = dim.vars[ aVar[v] ]
			
			if var.parser ne !null then begin
				aVals = var.parser.decode(aRec)
				
				; if decode failure...
				if aVals eq !null then return, !false
				
				if var.values eq ptr_new() then var.values = list()
				(*(var.values)).add, aVals
				
				;sTmp = string(n_elements(aVals), format='%d')
				;printf, -2, sTmp, ' more value(s), new size of ', $
				;            aDims[d], '[''', aVar[v], '''] is', $
				;				size(*(var.values), /DIMENSIONS)
					
			endif
		endfor 
	endfor
	return, !true
end

; --------------------------------------------------------------------------- ;
;+
; Convert all the variable value lists to arrays
;-
pro _das2_onFinish, lDatasets
	compile_opt idl2, hidden
	;printf, -2, '_das2_onFinish'
	
	for i = 0, n_elements(lDatasets) - 1 do begin
		dataset = lDatasets[i]
		;printf, -2, 'dataset', i
		
		aDims = dataset.dims.keys()
	
		for d = 0, n_elements(aDims) - 1 do begin
			dim = dataset.dims[ aDims[d] ]
			
			aVar = dim.vars.keys()
			for v = 0, n_elements(aVar) - 1 do begin
				var = dim.vars[ aVar[v] ]
				;printf, -2, '_das2_onFinish, ',aDims[d],':',aVar[v],' type ', $
				;	typename(*(var.values))
				;printf, -2, '_das2_onFinish, ',aDims[d],':',aVar[v],' dims ', $
				;	size(*(var.values), /DIMENSIONS)
				
				if typename(*(var.values)) eq 'LIST' then begin
					lVals = *(var.values)
					
					; we have a problem here.  IDL will collapse the dimensions if
					; only a single packet is read.					
					if n_elements(lvals) eq 1 then begin
						
						nSz = n_elements(lVals[0])
						
						aVals = (lVals).ToArray()
						
						var.values = reform(aVals, nSz, 1, /OVERWRITE)
						
					endif else begin
					
						if ~ lVals.isEmpty() then begin
							
							; transpose arrays greater than rank 1 so that column
							; numbers are still first in keeping with IDL style
							
							if n_elements(lVals[0]) eq 1 then begin
								var.values = lVals.ToArray() 
								;printf, -2, 'Not transposing array, type & size is', $
								;	size(*(var.values), /DIMENSIONS), $
								;	typename(*(var.values))
									
							endif else begin
								var.values = lVals.ToArray(/TRANSPOSE)
							endelse
						endif
					endelse
					
					
				; set to the proper units for any time types
				if _das2_nameFromUnits(var.units) eq 'time' then var.units = 'TT2000'
				
				endif
			endfor 
		endfor
	endfor
end


; --------------------------------------------------------------------------- ;
;+
; Look to see if a message was an exception, if it was, format it as
; a string and return it.
;-
function _das2_onComment, hPktHdr
	compile_opt idl2, hidden

	if ~ hPktHdr.haskey('exception') then return, !null
	
	hExcept = hPktHdr['exception1']
	sType = 'UnknownError'
	if hExcept.haskey('%type') then sType = hExcept['%type']
	sMsg = 'NoMessage'
	if hExcept.haskey('%message') then sType = hExcept['%message']

	return, sType + ':  ' + sMsg
end

; --------------------------------------------------------------------------- ;
;+
; Create a dataset structure from a list of packets.
;
; :Private:
;
; :Params:
;    pkts : in, required, type=byte array
;       A byte vector containing all the packets in a das2 stream, the
;       header packet (id [00]) should not be included.
;
; :Returns:
;    list of dataset structures
;
; :History:
;     Jul. 2018, D. Pisa : original 
;     Nov. 2018, D. Pisa : fixed object.struct conversion for ypackets
;     May  2018, C. Piker : refactored
;-

function _das2_parsePackets, hStrmHdr, buffer, DEBUG=bDebug, MESSAGES=sMsg                     
   compile_opt idl2
   
	; A hash map of packet IDs to dataset objects.  Holds the current dataset
	; map.  If a packet ID is redefined a new dataset is placed here.
	hDatasets = hash()
	
	; All the datasets read from the stream, not just the curent definitions.
	lAllDs = list()  
	
	sMsg = !null
	
   iBuf = 0l       ; byte offset in the stream
   nBufSz = n_elements(buffer) ; number of bytes in the stream
   
   while iBuf lt nBufSz do begin ; loop across the stream
      
		sTag = string(buffer[iBuf:iBuf+3])
		
		; Handle packet headers...
		if sTag.charat(0) eq '[' then begin
		
			nPktHdrSz = long(string(buffer[iBuf+4:iBuf+9]))
			hPktHdr = xml_parse(string(buffer[iBuf+10:iBuf+10+nPktHdrSz-1]))
			
			if (sTag.substring(1,2)).tolower() eq 'xx' then begin
			
				; It's a comment packet, save the message if it's an exception
				; ignore otherwise
				sTmp = _das2_onComment(hPktHdr)
				if sTmp ne !null then sMsg = sTmp
				
			endif else begin
			
				; it's a dataset definition
				nPktId = fix(sTag.substring(1,2))
				
				dataset = _das2_onNewPktId(hStrmHdr, hPktHdr, DEBUG=bDebug)
				if dataset eq !null then return, !null
				
				; Use the name as the group name and change the name to the 
				; name plus the packet ID
				dataset.group = dataset.name
				dataset.name = string(dataset.name, nPktId, format='(%"%s_%02d")')

				; Set this as the dataset object for this packet ID, and add it to
				; the list of all datasets incase this packet ID is redefined
				hDatasets[nPktId] = dataset
				lAllDs.add, dataset
		
			endelse
			
			iBuf += nPktHdrSz + 10
			
		; ...or handle packet data
		endif else begin
		
			if sTag.charat(0) eq ':' then begin
				
				; A data packet	
				nPktId = fix(sTag.substring(1,2))
				
				dataset = hDatasets[nPktId]
				;printf, -2, dataset
				
				if not _das2_onData(buffer, iBuf, messages, dataset) then return, !null
				
				iBuf += dataset.recsize() + 4
				
			endif else begin
				; Illegal packet start character
				messages = "Illegal character "+sTag.charat(0)+"in stream at position"+string(iBuf)
				return, !null
			endelse
		endelse
	endwhile
	
	_das2_onFinish, lAllDs
	
	return, lAllDs
end

; --------------------------------------------------------------------------- ;
;+
; Parse the contents of a byte buffer into a list of das2 dataset (das2ds) 
; objects.  This is an all-at-once parser that can't handle datasets larger
; than around 1/2 to 1/3 of the host machine's ram. 
;
; :Returns:
;    list - a list of das2 dataset (das2ds) objects.
;-
function das2_parsestream, buffer, MESSAGES=messages
	compile_opt idl2
	
	lErr = list()  ; An empty list to return on an error
	
	messages = ""
	
   nStreamSz = n_elements(buffer)
   if strcmp(string(buffer[0:3]), '[00]') NE 1 AND $
      strcmp(string(buffer[0:3]), '[xx]') NE 1 then begin
       printf, -2, 'ERROR: Invalid das2 stream! Does not start with [00]. Got: '+string(buffer[0:3])
       return, lErr
   endif
   nStreamHdrSz = long(string(buffer[4:9])) ; fixed length for stream header size
	 hStreamHdr = xml_parse(string(buffer[10:10+nStreamHdrSz-1]))
   
   if hStreamHdr.haskey('stream') then begin
      ptrStream = 10 + nStreamHdrSz
      
      ; No packets in the stream, just a header.  This is format error
      ; as there should at least be a [XX] packet (comment) that says 
      ; "NoDataInInterval" for a properly behaved stream.
      if ptrStream eq n_elements(buffer) then begin
			messages="Stream contains no packets, not even an exception message"
			return, lErr
		endif
            
      if keyword_set(debug) then begin
         lDataSet = _das2_parsePackets( $
				hStreamHdr, buffer[ptrStream:*], debug=debug, messages=messages $
			)
      endif else begin
         lDataSet = _das2_parsePackets( $
				hStreamHdr, buffer[ptrStream:*], messages=messages $
			)
      endelse
      
      return, lDataSet 
      
   endif else begin
		messages = string(buffer)
	   return, lErr
   endelse
	 
end

