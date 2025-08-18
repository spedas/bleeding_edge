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


;+
; Convert a byte array to an array of given type
;
; :Private:
;
; :Params:
;    aPktData : in, required, type=byte array
;       The binary data for an entire das2 packet
; :Keywords:
;    debug : in, optional, hidden, type=bool
;       If !true print debugging info to standard error
;
; :Returns:
;    an array of given type, time values are converted to TT2000
; 
; :History:
;    Jul. 2018, D. Pisa : original
;    May  2019, C. Piker : updates to auto-convert times to TT2000
;-
function das2decoder::decode, aPktData, debug=debug
   compile_opt idl2

   if not keyword_set(dim) then dim = 1
   nDataSz = n_elements(aPktData)
	
	if nDataSz lt self.iOffset + self.nItems*self.nSize then $
		message, 'Unexpected end of packet data'
	
	iEnd = self.iOffset + self.nItems*self.nSize - 1
	;printf, -2, 'das2decoder::decode, transating bytes',self.iOffset,$
	;    'to',iEnd, 'packet data has size',n_elements(aPktData)
		 
   aMine = aPktData[self.iOffset : iEnd]
	   
   ; Get array of properly sized byte strings
   aVals = reform(aMine, self.nSize, self.nItems)

   if stregex(self.sType, 'real4$', /boolean) then begin
      if self.bBigE then return, swap_endian(reform(float(aVals, 0, 1, self.nItems))) $
      else return, reform(float(aVals, 0, 1, self.nItems))
   endif

   if stregex(self.sType, 'real8$', /boolean) then begin
	
      if self.bBigE then aTmp = swap_endian(reform(double(aVals, 0, 1, self.nItems))) $
      else aTmp = reform(double(aVals, 0, 1, self.nItems))
		
		; Convert to TT2000 if these are time values
		if self.sEpoch ne '' then begin
			aTmp2 = make_array(n_elements(aTmp), /L64)
			for i=0, n_elements(aTmp)-1 do $
				aTmp2[i] = das2_double_to_tt2000(self.sEpoch, aTmp[i])
			
			return, aTmp2
		endif else begin
			return, aTmp
		endelse
		
   endif

   if strcmp(self.sType, 'ascii', 5) then begin
     aTmp = float(string(aVals))
     if n_elements(aTmp) ne self.nItems then message, 'Item number mismatch in decoding'
     return, aTmp
   endif

   if strcmp(self.sType, 'time', 4) then begin ; no case fold on purpose
     aTmp = strtrim( string(aVals), 2)    ; remove spaces to clean times
	  aTmp2 = make_array(n_elements(aTmp), /L64)
	  
	  ; need to vectorize this...
	  for i=0,n_elements(aTmp)-1 do aTmp2[i] = das2_text_to_tt2000(aTmp[i])
	  
     return, aTmp2
   endif
   
   ; never should reach this
   message, 'can not decode values of type ' + sType
   return, []
end


;+
; Initialize a das2 stream data value decoder.  Handles coversion of 
; time values to TT2000.
;
; :Private:
;
; TODO: This should be in das2_parsestream.pro since it uses packet 
;       headers.
;
; :Param:
;    hPlane : in, required, type=hash
;        A hash as return by xml_parse for the <x>, <y>, <z> or <yscan> plane
;        of interest.
;    
;-
function das2decoder::init, iOffset, hPlane
	compile_opt idl2, hidden

	self.iOffset = iOffset
	self.sType = hPlane['%type']
	b = stregex(self.sType, '[0-9]{1,2}$', /extract)
	self.nSize = uint(b)
	
	self.nItems = 1
	if hPlane.haskey('%nitems') then self.nItems = uint(hPlane['%nitems'])
	
	; big endian
   if stregex(self.sType, '^big_', /boolean) or stregex(self.sType, '^sun_', /boolean) then $
	   self.bBigE = !true
		
	; Get time base (if this is a time value)
	if hPlane.haskey('%units') then begin
	
		sUnits = hPlane['%units']
		if (sUnits eq 'us2000') or (sUnits eq 'mj1958') or (sUnits eq 't2000') $
		   or (sUnits eq 't1970')then self.sEpoch = sUnits

	endif
	  	
	return, !true
end

;+
; Return the total number of bytes converted to data values in each
; invocation of das2decoder::decode.
;
; :Private:
;-
function das2decoder::chunkSize
	compile_opt idl2, hidden
	return, self.nItems * self.nSize
end

function das2decoder::offset
	compile_opt idl2, hidden
	return, self.iOffset
end

;+
; Data plane decoder object, plain object, does not derive from
; IDL_Object, can't have auto properties
;
; :Private:
;-
pro das2decoder__define
	compile_opt idl2, hidden
	struct = { $
	   das2decoder, iOffset:0, nSize:0, nItems:0, $
		sType:'', bBigE:!false, sEpoch:'' $
	}
end
