;+
;PROCEDURE: 
;	MVN_SWIA_PACKET_DECODE
;PURPOSE: 
;	General purpose routine to decode a series of words according to a provided definition
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_PACKET_DECODE, Message, Decoder, Data
;INPUTS: 
;	Message: An array of words from a packet
;	Decoder: A struct with the decommutator type for each field in Data
;OUTPUTS:
;	Data: A structure returning the decommutated version of Message
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_packet_decode.pro $
;
;-

pro mvn_swia_packet_decode, message, decoder, data

compile_opt idl2

nt = n_tags(decoder) 

for i = 2,nt-1 do begin
	if tag_names(decoder.(i),/struct) eq 'SUBWORD' then begin
		word = decoder.(i).word
		bit1 = decoder.(i).bit1
		bit2 = decoder.(i).bit2
		
		data.(i-2) = mvn_swia_subword(message[word],bit1 = bit1,bit2 = bit2)	
	endif
	
	if tag_names(decoder.(i),/struct) eq 'WORDS' then begin
		word0 = decoder.(i).word0
		word1 = word0 + decoder.(i).nwords - 1
		data.(i-2) = message[word0:word1]
	endif
	
	
	if tag_names(decoder.(i),/struct) eq 'BYTES' then begin
		nbytes = decoder.(i).nbytes
		word0 = decoder.(i).word0
		word1 = word0 + nbytes/2-1
		
		words = message[word0:word1]
		
		msbytes = words/256
		lsbytes = words mod 256
	
		counts = intarr(nbytes)
		ind = indgen(nbytes/2)
		counts[ind*2] = msbytes
		counts[ind*2+1] = lsbytes
		
		data.(i-2) = counts
		
	endif
endfor

end