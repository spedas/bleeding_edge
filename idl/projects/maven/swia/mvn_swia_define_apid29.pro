;+
;PROCEDURE: 
;	MVN_SWIA_DEFINE_APID29
;PURPOSE: 
;	Routine to define decoder and data structures for APID29 (Housekeeping)
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_DEFINE_APID29, Decoder = Decoder, Data = Data
;OPTIONAL OUTPUTS:
;	Decoder: A structure containing the decommutator type for each field in the packet
;	Data: A structure returning name/type of each field in the packet
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_define_apid29.pro $
;
;-

pro mvn_swia_define_apid29, decoder = decoder, data = data

compile_opt idl2

subw = {subword, word: 0, bit1: 0, bit2: 0}
wrds = {words, word0: 0, nwords: 0}

decoder = {length:0, ccsdsver:subw,apid:subw,seqcount:subw,packetlen:subw,clock1:subw,clock2:subw, $
lvpst:subw,mcphvi:subw,mcphv:subw,defrawi:subw,defrawv:subw,swprawv:subw,hsk6:subw,hsk7:subw, $
analhv:subw,analerrhv:subw,def1hv:subw,def1errhv:subw,def2hv:subw,def2errhv:subw,hsk14:subw, $
hsk15:subw,digt:subw,p2p5dv:subw,p5dv:subw,p3p3dv:subw,p5av:subw,n5av:subw,p28v:subw,p12v:subw, $
modeid:subw,options:subw,coarsesvy:subw,coarsearc:subw,finesvy:subw,finearc:subw,momsvy:subw, $
specsvy:subw,modeper:subw,attper:subw,luta0:subw,luta1:subw,csmlmt:subw,csmctr:subw,rstlmt:subw, $
rstsec:subw,mux0:subw,mux1:subw,mux2:subw,mux3:subw,attt1:subw,attt2:subw,modex:subw,modey:subw, $
ssctl:subw,sifctl:subw,mcpdac:subw,rawdac:subw,offsets:subw,lut1:subw,lut0:subw, $
cmdcnt:subw,regdata:subw,regrdbk:subw,diagdata:subw,dighsk:subw}

decoder.length = 54
decoder.ccsdsver = {subword,0,15,13}
decoder.apid = {subword,0,10,0}
decoder.seqcount = {subword,1,13,0}
decoder.packetlen = {subword,2,15,0}
decoder.clock1 = {subword,3,15,0}
decoder.clock2 = {subword,4,15,0}
decoder.lvpst = {subword,5,15,0}
decoder.mcphvi = {subword,6,15,0}
decoder.mcphv = {subword,7,15,0}
decoder.defrawi = {subword,8,15,0}
decoder.defrawv = {subword,9,15,0}
decoder.swprawv = {subword,10,15,0}
decoder.hsk6 = {subword,11,15,0}
decoder.hsk7 = {subword,12,15,0}
decoder.analhv = {subword,13,15,0}
decoder.analerrhv = {subword,14,15,0}
decoder.def1hv = {subword,15,15,0}
decoder.def1errhv = {subword,16,15,0}
decoder.def2hv = {subword,17,15,0}
decoder.def2errhv = {subword,18,15,0}
decoder.hsk14 = {subword,19,15,0}
decoder.hsk15 = {subword,20,15,0}
decoder.digt = {subword,21,15,0}
decoder.p2p5dv = {subword,22,15,0}
decoder.p5dv = {subword,23,15,0}
decoder.p3p3dv = {subword,24,15,0}
decoder.p5av = {subword,25,15,0}
decoder.n5av = {subword,26,15,0}
decoder.p28v = {subword,27,15,0}
decoder.p12v = {subword,28,15,0}
decoder.modeid = {subword,29,15,8}
decoder.options = {subword,29,7,0}
decoder.coarsesvy = {subword,30,15,8}
decoder.coarsearc = {subword,30,7,0}
decoder.finesvy = {subword,31,15,8}
decoder.finearc = {subword,31,7,0}
decoder.momsvy = {subword,32,15,8}
decoder.specsvy = {subword,32,7,0}
decoder.modeper = {subword,33,15,8}
decoder.attper = {subword,33,7,0}
decoder.luta0 = {subword,34,15,8}
decoder.luta1 = {subword,34,7,0}
decoder.csmlmt = {subword,35,15,8}
decoder.csmctr = {subword,35,7,0}
decoder.rstlmt = {subword,36,15,8}
decoder.rstsec = {subword,36,7,0}
decoder.mux0 = {subword,37,15,8}
decoder.mux1 = {subword,37,7,0}
decoder.mux2 = {subword,38,15,8}
decoder.mux3 = {subword,38,7,0}
decoder.attt1 = {subword,39,15,0}
decoder.attt2 = {subword,40,15,0}
decoder.modex = {subword,41,15,0}
decoder.modey = {subword,42,15,0}
decoder.ssctl = {subword,43,15,0}
decoder.sifctl = {subword,44,15,0}
decoder.mcpdac = {subword,45,15,0}
decoder.rawdac = {subword,46,15,0}
decoder.offsets = {subword,47,15,0}
decoder.lut1 = {subword,48,15,8}
decoder.lut0 = {subword,48,7,0}
decoder.cmdcnt = {subword,49,15,0}
decoder.regdata = {subword,50,15,0}
decoder.regrdbk = {subword,51,15,0}
decoder.diagdata = {subword,52,15,0}
decoder.dighsk = {subword,53,15,0}


data = {apid:0s,seqcount:0s,packetlen:0L,clock1:0L,clock2:0L,lpvst:0s,mcphvi:0s,mcphv:0s,defrawi:0s, $
defrawv:0s,swprawv:0s,hsk7:0s,hsk8:0s,analhv:0s,analerrhv:0s,def1hv:0s,def1errhv:0s,def2hv:0s,def2errhv:0s, $
hsk14:0s,hsk15:0s,digt:0s,p2p5dv:0s,p5dv:0s,p3p3dv:0s,p5av:0s,n5av:0s,p28v:0s,p12v:0s,modeid:0s,options:0s, $
csvy:0s,carc:0s,fsvy:0s,farc:0s,msvy:0s,ssvy:0s,modeper:0s,attper:0s,luta0:0s,luta1:0s,csmlmt:0s,csmctr:0s, $
rstlmt:0s,rstsec:0s,mux0:0s,mux1:0s,mux2:0s,mux3:0s,attt1:0L,attt2:0L,modex:0L,modey:0L,ssctl:0L, $
sifctl:0L,mcpdac:0L,rawdac:0L,offsets:0L,lut1:0s,lut0:0s,cmdcnt:0L,regdata:0L,regrdbk:0L,diagdata:0L,dighsk:0L}

end