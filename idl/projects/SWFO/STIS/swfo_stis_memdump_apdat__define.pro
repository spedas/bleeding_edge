; $LastChangedBy: ali $
; $LastChangedDate: 2023-11-26 19:30:16 -0800 (Sun, 26 Nov 2023) $
; $LastChangedRevision: 32255 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_memdump_apdat__define.pro $


function swfo_stis_memdump_apdat::decom,ccsds,source_dict=source_dict

  ;common swfo_stis_memdump_com2, byteimage, bytecount, last_str
  ;  if n_elements(last_str) eq 0 || (abs(last_str.time-ccsds.time) gt 300) then begin
  ;    byteimage = bytarr(2UL ^17+1024)
  ;    bytecount = intarr(2ul ^17+1024)
  ;  endif

  dd= 24 ;  was 20
  ccsds_data = swfo_ccsds_data(ccsds)
  str1=swfo_stis_ccsds_header_decom(ccsds)

  ; memdata = ccsds_data[20:1024+20-1]
  ; memdata = swap_endian( uint(ccsds_data,20,256) ,/swap_if_little_endian)

  addr = swfo_data_select(ccsds_data,dd*8,32)
  datalen = ccsds.pkt_size - dd - 4
  if str1.fpga_rev gt 209 then datalen-=2 ;checksum bytes at the end of each packet
  memdat = ccsds_data[dd+4: dd+4+datalen-1]

  str2 = {$
    addr:    addr,  $
    datalen:  datalen, $
    data:    memdat,  $
    gap:ccsds.gap }

  datastr=create_struct(str1,str2)

  if self.test && debug(2) then begin
    printdat,time_string(datastr.time,/local)
    printdat,/hex,addr
    dprint,datalen
    hexprint,memdat
  endif

  mapn = datastr.user_09
  if ~obj_valid(self.user_dict) then self.user_dict = dictionary()
  ud = self.user_dict
  if ~ud.haskey('maps') then ud.maps = orderedhash()
  if ~ud.maps.haskey(mapn) then ud.maps[mapn] = dictionary()

  d = ud.maps[mapn]
  if ~d.haskey('image_ptr') then d.image_ptr = ptr_new(bytarr(2UL ^17))
  d.last_data = datastr
  ud.last_mapid = mapn

  if addr gt '20000'x-datalen then begin
    dprint,'Memory Dump address caused crossing memory boundaries...',dlevel=2
    hexprint,addr
    return,datastr
  endif
  (*d.image_ptr)[addr:addr+datalen-1] = memdat

  if debug(2) then begin
    byteimage = *d.image_ptr
    sze = n_elements(byteimage)
    rn = 2
    nrows = 512
    ncols = sze /nrows
    wi,1,wsize = [nrows*rn,ncols*rn]
    image2 = reform(byteimage,nrows,ncols)
    image2 = congrid(image2,nrows * rn,ncols *rn)
    tv,image2
    dprint,'hello',dlevel=3

  endif

  ; last_str =datastr
  return,datastr

end


PRO swfo_stis_memdump_apdat__define

  void = {swfo_stis_memdump_apdat, $
    inherits swfo_gen_apdat, $    ; superclass
    ;   memdict: obj_new(),  $         ; dictionary (or hash) to hold memory maps
    flag: 0 $
  }
END

