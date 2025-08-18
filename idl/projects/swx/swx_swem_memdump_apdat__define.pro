

 
 
function swx_swem_memdump_apdat::decom,ccsds,  source_dict=source_dict  ;,header

  ccsds_data = swx_ccsds_data(ccsds)

  strct = {  $
    time:ccsds.time, $
    met: ccsds.met,  $
    seqn:ccsds.seqn, $
    bsize: ccsds.pkt_size-14, $
    addr: 0ul, $
    memp: ptr_new(),  $
    gap: ccsds.gap  $
  }


  strct.bsize = ccsds.pkt_size -14

  mem = !null
  b = ccsds_data[10:*]
  addr = ((b[0]*256uL+b[1])*256Ul+b[2])*256Ul+b[3]
  strct.addr = addr
  if ccsds.pkt_size gt 14 then   mem = b[4:*] else dprint,dlevel=1,'Mem dump with 0 size. Address:',strct.addr
  memsize = n_elements(mem)
  strct.memp = ptr_new(mem)
  if debug(self.dlevel+3) then begin
    dprint,strct.addr, n_elements(mem),format='(Z08, i)'
    hexprint,mem
  endif
  
 ; if keyword_set( self.mram_p) eq 0 then self.mram_p = ptr_new(!null)
 ; if keyword_set(*self.mram_p) eq 0 then *self.mram_p = 
  
  if addr + memsize le self.mram_size then begin
    dprint,dlevel=self.dlevel+2, format='("Addr: ", Z06,"     size:",i)',addr,memsize
    self.mram[addr: addr+memsize-1]  = mem
    self.cntr[addr: addr+memsize-1] += 1b
  endif else begin
    dprint, 'Not enough memory in object.', addr,memsize
  endelse
  
  ;print,addr / '100000'x
  if debug(self.dlevel+1) then begin
    wi,2 ;map,wsize=[1024,1024]
    self.display, addr / '100000'x
  endif
 
  return,strct
end



; 6fffff

function swx_swem_memdump_apdat::init,apid,name,_extra=ex
  valid = self->swx_gen_apdat::Init(apid,name,_EXTRA=ex)
  self.mram_size = 8*2Ul^20 
  return,valid
end


PRO swx_swem_memdump_apdat::GetProperty,data=data, array=array, npkts=npkts, apid=apid, name=name,  typename=typename, $
  nsamples=nsamples,nbytes=nbytes,strct=strct,ccsds_last=ccsds_last,tname=tname,dlevel=dlevel,ttags=ttags,last_data=last_data,mram=mram,cntr=cntr
  COMPILE_OPT IDL2
  IF (ARG_PRESENT(nbytes)) THEN nbytes = self.nbytes
  IF (ARG_PRESENT(name)) THEN name = self.name
  IF (ARG_PRESENT(tname)) THEN tname = self.tname
  IF (ARG_PRESENT(ttags)) THEN ttags = self.ttags
  IF (ARG_PRESENT(apid)) THEN apid = self.apid
  IF (ARG_PRESENT(npkts)) THEN npkts = self.npkts
  IF (ARG_PRESENT(ccsds_last)) THEN ccsds_last = self.ccsds_last
  IF (ARG_PRESENT(data)) THEN data = self.data
  if (arg_present(last_data)) then last_data = *(self.last_data_p)
  IF (ARG_PRESENT(array)) THEN array = self.data.array
  IF (ARG_PRESENT(nsamples)) THEN nsamples = self.data.size
  IF (ARG_PRESENT(typename)) THEN typename = typename(*self.data)
  IF (ARG_PRESENT(dlevel)) THEN dlevel = self.dlevel
  if (arg_present(strct) ) then strct = self.struct()
  IF (ARG_PRESENT(mram)) THEN mram = self.mram
  IF (ARG_PRESENT(cntr)) THEN name = self.cntr
END

pro swx_swem_memdump_apdat::display,section,discntr=discntr,mram=mram,cntr=cntr,buffer=b

meg = 2UL ^20

mram=self.mram
cntr=self.cntr
if keyword_set(discntr) then b = self.cntr else b = self.mram
start = round(section * meg)
b = b[start: start+meg-1]
b = reform(b,1024,1024)
;printdat,b
tv,b 

end



 
PRO swx_swem_memdump_apdat__define

mram_size = 8 * 2ul^20  ; 8 megabytes
void = {swx_swem_memdump_apdat, $
  inherits swx_gen_apdat, $    ; superclass
  mram_size : mram_size, $
  mram: bytarr(mram_size),   $
  cntr: bytarr(mram_size) $
  }
END





