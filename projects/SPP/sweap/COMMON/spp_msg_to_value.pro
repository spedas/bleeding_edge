
pro spp_msg_to_value

  spp_apid_data,'7C0'x,apdata=ap
  print_struct,ap
  dat = *ap.dataptr
  w = where( strmid(dat.msg,0,4) eq 'set ')

end

