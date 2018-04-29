;+
;  SPP_GEN_APDAT
;  This basic object is the entry point for defining and obtaining all data for all apids
;-


FUNCTION spp_gen_apdat::Init,apid,name,_EXTRA=ex
COMPILE_OPT IDL2
; Call our superclass Initialization method.
void = self->IDL_Object::Init()
;printdat,a
self.apid  =apid
self.dlevel = 2
if keyword_set(name) then self.name  =name
self.ccsds_last = ptr_new(/allocate_heap)
;self.ccsds_array = obj_new('dynamicarray')
self.data = obj_new('dynamicarray')
if debug(3) and keyword_set(ex) then dprint,ex,phelp=2,dlevel=2
IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
RETURN, 1
END
 
 
 
PRO spp_gen_apdat::Clear, tplot_names=tplot_names
  COMPILE_OPT IDL2
  dprint,'clear arrays: ',self.apid,self.name,dlevel=3
  self.nbytes=0
  self.npkts = 0
  self.lost_pkts = 0
  self.data.array = !null
  ptr_free,  ptr_extract(*self.ccsds_last)
  *self.ccsds_last = !null
  if keyword_set(tplot_names) && keyword_set(self.tname) then store_data,self.tname+'*',/clear
END



PRO spp_gen_apdat::Cleanup
  COMPILE_OPT IDL2
  ; Call our superclass Cleanup method
  ptr_free,self.ccsds_last
  self->IDL_Object::Cleanup
END



PRO spp_gen_apdat::help
  help,/obj,self
END


function spp_gen_apdat::info,header=header
;rs =string(format="(Z03,'x ',a-14, i8,i8 ,i12,i3,i3,i8,' ',a-14,a-36,' ',a-36, ' ',a-20,a)",self.apid,self.name,self.npkts,self.lost_pkts, $
;    self.nbytes,self.save_flag,self.rt_flag,self.data.size,self.data.typename,string(/print,self),self.routine,self.tname,self.save_tags)
  fmt ="(Z03,'x ',a-14, i8,i8 ,i12,i3,i3,i3,i8,' ',a-14,a-26,' ',a-36, ' ',a-20,'<',a,'>')"
  hfmt="( a4,' ',a-14, a8,a8 ,a12,a3,a3,a3,a8,' ',a-14,a-26,' ',a-36, ' ',a-20,'<',a,'>')"
;  if keyword_set(header) then rs=string(format=hfmt,'APID','Name','npkts','lost','nbytes','save','rtf','size','type','objname','routine','tname','tags')
  rs =string(format=fmt,self.apid,self.name,self.npkts,self.lost_pkts, $
    self.nbytes,self.save_flag,self.rt_flag,self.dlevel,self.data.size,self.data.typename,typename(self),self.routine,self.tname,self.ttags)

  if keyword_set(header) then rs=string(format=hfmt,'APID','Name','Npkts','lost','nbytes','sv','rt','dl','size','type','objname','routine','tname','tags') +string(13b)+ rs

return,rs
end


PRO spp_gen_apdat::print,dlevel=dlevel,verbose=verbose,strng,header=header
  print,self.info(header=header)
END



;pro spp_gen_apdat::store_data,  strct,pname,verbose=verbose
;  if self.rt_flag && self.rt_tags then begin
;    store_data,self.tname+pname,data=strct, tagnames=self.rt_tags, /append, verbose=0, gap_tag='GAP'
;  endif
;end




function spp_gen_apdat::decom,ccsds,header
;if typename(ccsds) eq 'BYTE' then return,  self.spp_gen_apdat( spp_swp_ccsds_decom(ccsds) )  ;; Byte array as input

strct = ccsds
strct.pdata = ptr_new()
ap = self.struct()
if self.routine then  strct = call_function(self.routine,ccsds, ptp_header=header ,apdat = ap) $
else  strct = ccsds
dprint,dlevel=self.dlevel+2,phelp=2,strct

return,strct
end


pro spp_gen_apdat::increment_counters,ccsds
  self.npkts += 1
  self.nbytes += ccsds.pkt_size
  if ccsds.seqn_delta gt 1 then self.lost_pkts += (ccsds.seqn_delta -1)
;  if ccsds.time_delta eq 0 then self.print
  self.drate = ccsds.pkt_size / ( ccsds.time_delta > .001)
  *self.ccsds_last = ccsds
end




pro spp_gen_apdat::handler,ccsds,header
  
  strct = self.decom(ccsds,header)

;if ccsds.seq_group ne 3 then self.help   ;dprint,dlevel=2,ccsds.seq_group,ccsds.apid

  if self.save_flag && keyword_set(strct) then begin
    dprint,self.name,dlevel=self.dlevel+2,self.apid
    self.data.append,  strct
  endif

  if self.rt_flag && keyword_set(strct) then begin
    if ccsds.gap eq 1 then strct = [fill_nan(strct[0]),strct]
    store_data,self.tname,data=strct, tagnames=self.ttags , append = 1, gap_tag='GAP'
  endif
  
  
  
  
end
 
 
 
 
pro spp_gen_apdat::finish
  if self.npkts ne 0 then self.print ,dlevel=3,'finish'
  store_data,self.tname,data=self.data.array, tagnames=self.ttags,  gap_tag='GAP',verbose=0
end
 



function spp_gen_apdat::struct
  strct = create_struct(name=typename(self))
  struct_assign , self, strct
  return,strct
END

 
 
 
PRO spp_gen_apdat::GetProperty,data=data, array=array, npkts=npkts, apid=apid, name=name,  typename=typename, $
   nsamples=nsamples,nbytes=nbytes,strct=strct,ccsds_last=ccsds_last,tname=tname,dlevel=dlevel,ttags=ttags
COMPILE_OPT IDL2
IF (ARG_PRESENT(nbytes)) THEN nbytes = self.nbytes
IF (ARG_PRESENT(name)) THEN name = self.name
IF (ARG_PRESENT(tname)) THEN tname = self.tname
IF (ARG_PRESENT(ttags)) THEN ttags = self.ttags
IF (ARG_PRESENT(apid)) THEN apid = self.apid
IF (ARG_PRESENT(npkts)) THEN npkts = self.npkts
IF (ARG_PRESENT(ccsds_last)) THEN ccsds_last = self.ccsds_last
IF (ARG_PRESENT(data)) THEN data = self.data
IF (ARG_PRESENT(array)) THEN array = self.data.array
IF (ARG_PRESENT(nsamples)) THEN nsamples = self.data.size
IF (ARG_PRESENT(typename)) THEN typename = typename(*self.data)
IF (ARG_PRESENT(dlevel)) THEN dlevel = self.dlevel
if (arg_present(strct) ) then strct = self.struct()
END
 
  
 
PRO spp_gen_apdat::SetProperty,apid=apid, _extra=ex
COMPILE_OPT IDL2
; If user passed in a property, then set it.
;if isa(name,/string) then  self.name = name
;if isa(routine,/string) then self.routine=routine
if keyword_set(apid) then dprint,'apid can not be changed!'
if keyword_set(ex) then begin
  struct_assign,ex,self,/nozero
endif

END
 
 
 
PRO spp_gen_apdat__define
void = {spp_gen_apdat, $
  inherits IDL_Object, $    ; superclass
  apid: 0u,  $
  name: '', $
  nbytes: 0UL,  $
  npkts: 0UL,  $
  lost_pkts: 0UL,  $
  drate: 0. , $
  rt_flag: 0b, $
  save_flag: 0b, $
  routine:  '', $
  tname: '',  $
  ttags: '',  $
  ccsds_last: ptr_new(), $
  ccsds_array: obj_new(), $  
  data: obj_new(), $
  dlevel: 0  $
  }
END



