; The MIT License
;
; Copyright 2018-2019 David Pisa (IAP CAS Prague) dp@ufa.cas.cz
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


; docstrings formatted according to the guidlines at:
; https://www.harrisgeospatial.com/docs/IDLdoc_Comment_Tags.html 

;+
; Provide feedback that the stream is downloading
;
; :Private:
;-
function _das2_urlCallback, status, progress, data
   compile_opt idl2, hidden
   
   print, status    ; print the info msgs from the url object
   return, 1        ; return 1 to continue, return 0 to cancel
end


;+
; Request data from a specific das2 server using native HTTP GET parameters
; 
; :Params:
;    sUrl:  in, required, type=string
;       The full HTTP GET url to retrieve, it doesn't need to be URL encoded
;       this function will handle that step
;
; :Keywords:
;    params: in, optional, type=list
;    ascii: in, optional, type=boolean
;    extras: in, optional, type=list
;    verbose: in, optional, type=boolean
;
; :Returns:
;    A list of dataset objects.  Each dataset object corresponds to a single
;    packet type in the input.  If no datasets could be retrieved the function
;    return an empty list, so ret_val.length = 0.
;
; :Requires:
;    xml_parse: IDL 8.6.1
;    IDLnetURL: IDL 6.4
;
; :Example:
;    sServer = 'http://planet.physics.uiowa.edu/das/das2Server'
;    sDataset = 'Cassini/RPWS/HiRes_MidFreq_Waveform'
;    sBeg = '2008-08-10T09:06'
;    sEnd = '2008-08-10T09:13'
;    sParams = '10khz'
;    sFmt = '%s?server=dataset&dataset=%s&start_time=%s&end_time=%s&params=%s'
;    sUrl = string(sServer, sDataset, sMin, sMax, sParams, format=sFmt)
;   
;    lDs = das2_readhttp(sUrl, /messages=sMsg)
;
;    if lDs eq !null then begin
;       print, sMsg
;       stop
;    endif
;
;    print, n_elements(lDs), /format="%d datesets read"
;
;    print, lDs[0]
;
; :History:
;    Jul. 2018, D. Pisa : original
;    May  2019, C. Piker: refactored
;-
function das2_readhttp, sUrl, extras=extras, verbose=verbose, debug=debug, messages=messages
   
   compile_opt idl2

   ; catch exceptions
   ;CATCH, errorStatus
   errorStatus = 0
	
	lErr = list()  ; An empty list to return on an error

;  if float(!version.release) LT 8.6 then begin
;     print, 'Das2reader does not support earlier IDL version than 8.6!'
;     return, !null
;  endif

   if keyword_set(VERBOSE) then VERBOSE = !true else VERBOSE = !false
	
	;if keyword_set(params) then url_path += '&params=' + IDLnetURL.URLEncode(STRJOIN('--'+params+' ', /SINGLE))
   
   if (errorStatus NE 0) then begin
      CATCH, /CANCEL
      ; Display the error msg in a dialog and in the IDL output log
      r = DIALOG_MESSAGE(!ERROR_STATE.msg, TITLE='URL Error', /ERROR)
      if VERBOSE then print, !ERROR_STATE.msg
		
      ; Get the properties that will tell us more about the error.
      oUrl.GetProperty, RESPONSE_CODE=rspCode, $
      RESPONSE_HEADER=rspHdr, RESPONSE_FILENAME=rspFn
      if VERBOSE then begin
         print, 'rspCode = ', rspCode
         print, 'rspHdr= ', rspHdr
         print, 'rspFn= ', rspFn
      endif
      ; Destroy the url object
      OBJ_DESTROY, oUrl

      return, lErr
   endif

   oUrl = IDLnetURL()  ; object creation

   if VERBOSE then begin
     oUrl.SetProperty, CALLBACK_FUNCTION='_das2_urlCallback'
     oUrl.SetProperty, VERBOSE=1
   endif

   if keyword_set(extras) then begin
       oUrl.SetProperty, URL_USERNAME=extras.USERNAME
       oUrl.SetProperty, URL_PASSWORD=extras.PASSWORD
       oUrl.SetProperty, URL_PORT=extras.port
   endif

   printf, -2, "INFO: Requesting "+sUrl
   
   ; Should maybe change this so to callback processing so the whole stream is
   ; not buffered in memory twice but is put in data arrays as read. -cwp
   buffer = oUrl.get(URL=sUrl, /buffer)
   
   ;save, buffer, file='buffer_wbr.sav'
   ;restore, 'buffer_wbr.sav', /v
   obj_destroy, oUrl
	
   return, das2_parsestream(buffer, messages=messages)
	
end
