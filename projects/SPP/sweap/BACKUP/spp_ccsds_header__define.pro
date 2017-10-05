; Not ready for prime time - ignore this file.

function spp_ccsds_header::struct
  str = {spp_ccsds_header}
  pstr = self->ccsds_header::struct()
  struct_assign,pstr,str,/nozero
  str.time = self.time
  str.met  = self.met
  return,str
end


function spp_ccsds_header::init,buffer
  success =  self->ccsds_header::init(buffer)
  if n_elements(buffer) ge 12 then begin
    met = swap_endian( ulong(buffer[6:9],0), /swap_if_little_endian )
    subsec =  swap_endian( uint(buffer[10:11],0), /swap_if_little_endian )
    fracsec = (subsec and 'fffc'x) / 2.^16
    self.met = met
;    self.time = !values.d_nan
    epoch =  946771200d - 12L*3600   ; long(time_double('2000-1-1/12:00'))  ; Normal use
    self.time =  met +  epoch   ; this will need to change eventually to account for spacecraft time drift
  endif
  return,1
end


pro spp_ccsds_header__define
ccsds = {spp_ccsds_header, time:0d, met:0d, inherits ccsds_header,  nyt:0u }
end