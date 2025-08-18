function ccsds_header::struct
  ccsds= {ccsds_header}
  ccsds.apid = self.apid
  ccsds.seq_cntr = self.seq_cntr
  ccsds.seq_group = self.seq_group
  ccsds.valid  = self.valid
  ccsds.type_flag = self.type_flag
  ccsds.version = self.version
  ccsds.size_1 = self.size_1
return,ccsds
end

pro ccsds_header::help
  printdat,self
  ccsds = self->struct()
  printdat,ccsds
end



function ccsds_header::init,buffer
;  dprint,'hello'
  if n_elements(buffer) ge 6 then begin
    header = uint(buffer,0,3)  &  byteorder,header,/swap_if_little_endian
    self.version = ishft(buffer[0],-5)
    self.type_flag    = ishft(buffer[0],-3) and 3
    self.apid    = header[0] and '7ff'x
    self.seq_cntr = header[1] and '3ff'x
    self.seq_group = ishft(header[1],-14)
    self.size_1 = header[2]
    self.valid = 1
    dprint,dlevel=3,'Created ccsds'    
  endif
  return,1
end





pro ccsds_header__define,ccsds
  ccsds = {ccsds_header, $
    inherits IDL_Object, $    ; superclass
    apid:0u, $
    seq_cntr:0u, $
    size_1:0u, $
    version: 0b, $
    type_flag:0b, $
    seq_group: 0b, $
    valid:0b  }
end

