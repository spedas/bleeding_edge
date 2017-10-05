;+
;PROCEDURE: 
;	MVN_SWIA_DEFINE_APID84
;PURPOSE: 
;	Routine to define decoder and data structures for APID84 (Raw Survey)
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_DEFINE_APID84, Decoder = Decoder, Data = Data
;OPTIONAL OUTPUTS:
;	Decoder: A structure containing the decommutator type for each field in the packet
;	Data: A structure returning name/type of each field in the packet
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_define_apid84.pro $
;
;-

pro mvn_swia_define_apid84, decoder = decoder, data = data

compile_opt idl2

subw = {subword, word: 0, bit1: 0, bit2: 0}
wrds = {words, word0: 0, nwords: 0}
byts = {bytes, word0: 0, nbytes: 0}

decoder = {length:0, ccsdsver:subw,apid:subw,seqcount:subw,packetlen:subw,clock1:subw,clock2:subw,subsec:subw, $
compressed:subw,modeid:subw,attenpos:subw,cyclestep:subw,p0counts:byts}

decoder.length = 584
decoder.ccsdsver = {subword,0,15,13}
decoder.apid = {subword,0,10,0}
decoder.seqcount = {subword,1,13,0}
decoder.packetlen = {subword,2,15,0}
decoder.clock1 = {subword,3,15,0}
decoder.clock2 = {subword,4,15,0}
decoder.subsec = {subword,5,15,0}
decoder.compressed = {subword,6,15,15}
decoder.modeid = {subword,6,14,8}
decoder.attenpos = {subword,6,2,1}
decoder.cyclestep = {subword,7,11,0}
decoder.p0counts = {bytes,8,1152}

data = {apid:0s,seqcount:0s,packetlen:0L,clock1:0L,clock2:0L,subsec:0L,compressed:0s,modeid:0s,attenpos:0s,cyclestep:0s, $
counts:intarr(1152)}

end