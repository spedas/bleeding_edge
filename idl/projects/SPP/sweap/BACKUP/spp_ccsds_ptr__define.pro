;  not ready for primetime!  ignore this file


function spp_ccsds_ptr::struct
  str = {spp_ccsds_ptr}
  pstr = self->spp_ccsds_header::struct()
  struct_assign,pstr,str,/nozero
  str.datasize = self.datasize
  str.datastart= self.datastart
  str.dataptr  = self.dataptr
  return,str
end


function spp_ccsds_ptr::init,buffer,datastart=start
  success =  self->spp_ccsds_header::init(buffer)
  if n_elements(start) eq 0 then start = 12
  if n_elements(buffer) gt start then begin
    self.datastart = start
    self.datasize = n_elements(buffer) - start
    self.dataptr = ptr_new(buffer[start:*])
  endif
  return,1
end



pro spp_ccsds_ptr__define
cc = {spp_ccsds_ptr, inherits spp_ccsds_header, datasize:0u, datastart:0u, dataptr: ptr_new()}
end