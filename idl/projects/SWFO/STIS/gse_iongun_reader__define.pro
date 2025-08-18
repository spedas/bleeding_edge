;+
;  gse_iongun_reader
;  This object works with the common block files to decommutate data from Keysight power supplies
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-11-13 07:46:41 -0800 (Mon, 13 Nov 2023) $
; $LastChangedRevision: 32242 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/gse_iongun_reader__define.pro $
;-

COMPILE_OPT IDL2



pro gse_iongun_reader::read,source,source_dict=source_dict

  if ~isa(source_dict,'dictionary') then begin
    
    
  endif
  
  nb = n_elements(source)
  nbytes = 0ul
  npkts = 0ul
  
  ;firstsample = self.dyndata.size eq 0
  
  while isa( (buf = self.read_line(source,pos=nbytes) )   ) do begin
    dprint,verbose=self.verbose,dlevel=3,nbytes,string(buf)
    if debug(3,self.verbose,msg='Hex: '+strtrim(n_elements(buf))) then begin
      hexprint,buf      
    endif
    strct = json_parse(buf,/tostruct)
    str_element,/add_replace,strct,'time',time_double(strct.time)
    if isa(self.dyndata,'dynamicarray') then self.dyndata.append, strct
    nbytes += n_elements(buf)
    npkts += 1
  endwhile
  ;printdat,strct
  self.npkts += npkts
  self.nbytes += nbytes
  if self.isasocket then begin
    self.msg = time_string(systime(1),tformat='hh:mm:ss ')+strtrim(nbytes,2)+' bytes'
  endif
  ;if keyword_set(firstsample) && self.dyndata.size gt 0 then store_data, self.name,data=self.dyndata,tagnames='*',time_tag='time'

end






PRO gse_iongun_reader__define
  void = {gse_iongun_reader, $
    inherits socket_reader, $    ; superclass
    ;ddata: obj_new(),  $
    ;powersupply_num:0    $           ; not actually used
    dummy: 0  $
  }
END


