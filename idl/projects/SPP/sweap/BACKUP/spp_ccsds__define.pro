


function spp_ccsds::struct
  str = {spp_ccsds}
  pstr = self->spp_ccsds_header::struct()
  struct_assign,pstr,str,/nozero
  str.datasize = self.datasize
  str.datap  = self.datap
  return,str
end


function spp_ccsds::init,buffer,datastart=start
  success =  self->spp_ccsds_header::init(buffer)
  if n_elements(start) eq 0 then start = 12
  if n_elements(buffer) gt start then begin
    self.datastart = start
    self.datasize = n_elements(buffer) - start
    self.datap = ptr_new(buffer[start:*])
  endif
  return,1
end



pro spp_ccsds__define
cc = {spp_ccsds, inherits spp_ccsds_header, datasize:0u, datastart:0u, datap: ptr_new()}
end