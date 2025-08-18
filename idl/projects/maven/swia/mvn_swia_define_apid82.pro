;+
;PROCEDURE: 
;	MVN_SWIA_DEFINE_APID82
;PURPOSE: 
;	Routine to define decoder and data structures for APID82 (Fine Survey)
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_DEFINE_APID82, Decoder = Decoder, Data = Data, /LONG
;KEYWORDS:
;	LONG: Set to one if defining the large version of the product, else zero
;OPTIONAL OUTPUTS:
;	Decoder: A structure containing the decommutator type for each field in the packet
;	Data: A structure returning name/type of each field in the packet
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_define_apid82.pro $
;
;-

pro mvn_swia_define_apid82, decoder = decoder, data = data, long= long

compile_opt idl2

subw = {subword, word: 0, bit1: 0, bit2: 0}
wrds = {words, word0: 0, nwords: 0}
byts = {bytes, word0: 0, nbytes: 0}

decoder = {length:0, ccsdsver:subw,apid:subw,seqcount:subw,packetlen:subw,clock1:subw,clock2:subw,subsec:subw, $
compressed:subw,modeid:subw,comptype:subw,atten:subw,format:subw,accumper:subw,estepfirst:subw,dstepfirst:subw, $
anode:subw,energies:byts}

if keyword_set(long) then begin
	decoder.length = 968
	ncounts = 16*12*10
endif else begin
	decoder.length = 776
	ncounts = 32*8*6
endelse

decoder.ccsdsver = {subword,0,15,13}
decoder.apid = {subword,0,10,0}
decoder.seqcount = {subword,1,13,0}
decoder.packetlen = {subword,2,15,0}
decoder.clock1 = {subword,3,15,0}
decoder.clock2 = {subword,4,15,0}
decoder.subsec = {subword,5,15,0}
decoder.compressed = {subword,6,15,15}
decoder.modeid = {subword,6,14,8}
decoder.comptype = {subword,6,7,6}
decoder.atten = {subword,6,5,4}
decoder.format = {subword,6,3,3}
decoder.accumper = {subword,6,2,0}
decoder.estepfirst = {subword,7,15,9}
decoder.dstepfirst = {subword,7,8,4}
decoder.anode = {subword,7,3,0}
decoder.energies = {bytes,8,ncounts}

data = {apid:0s,seqcount:0s,packetlen:0L,clock1:0L,clock2:0L,subsec:0L,compressed:0s,modeid:0s,comptype:0s, $
atten:0s,format:0s,accumper:0s,estepfirst:0s,dstepfirst:0s,anode:0s,counts:intarr(ncounts)}

end