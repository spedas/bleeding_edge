;+
;  json_reader
;  This object works with the common block files to decommutate data from Keysight power supplies
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-11-13 07:46:41 -0800 (Mon, 13 Nov 2023) $
; $LastChangedRevision: 32242 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/json_reader__define.pro $
;-

COMPILE_OPT IDL2


function json_reader::translate,buf,source_dict=source_dict

  if (~KEYWORD_SET(dbg)) then begin
    ;ON_ERROR, 2
    ; Catch errors from our method and fake the call stack.
    CATCH, iErr
    if (iErr ne 0) then begin
      CATCH, /CANCEL
      ;MESSAGE, !ERROR_STATE.msg, /cont
      ;dprint,verbose=self.verbose,dlevel=3,"'"+string(buf)+"'"
      dprint,verbose=self.verbose,dlevel=3,"'"+result+"'"     
      dprint,verbose=self.verbose,dlevel=3,!error_state.msg
      return,!null
    endif
  endif
  ;hexprint,buf

  if isa(buf,'byte') then result = string(buf) else result=buf

  ;result = str_sub(result,',',',"')   ;  CLUGE  - Inserting missing quotes. - Delete line after Tony fixes ion gun code
  result = str_sub(result,':+',': ')    ; cluge - remove when the + sign gets removed.
  ;pos = strpos(result,'}{')
  ;if pos gt 0 then result = strmid(result,0,pos+1)
  ;  result = str_sub(result,'}{','},{')
  if debug(3,self.verbose,msg='test') then begin
    print,string(buf)
    print,result
  endif
  result = json_parse(string(result),/fold_case,/debug)
  if self.convert_to_float then begin
    keys = result.keys()
    foreach val,result,k do begin
      if strupcase(k) eq 'TIME' then continue
      if isa(val,'double') then result[k] = float(val)
    endforeach
  endif
  if result.haskey('TIME') && isa(result['TIME'],/string) then result['TIME'] = time_double(result['TIME'])
  ;printdat,source_dict
  add_DTIME = 1
  if keyword_set(add_DTIME) && isa(source_dict,'dictionary') && source_dict.haskey('CMBHDR')  then begin
    result['DTIME'] = 0.d  ; float(source_dict.cmbhdr.time - result['TIME'])

  endif

  if self.convert_to_struct then result = result.tostruct()
  return,result
end



pro json_reader::read,source,source_dict=source_dict

  nb = n_elements(source)
  nbytes = 0ul
  npkts = 0ul
    
  while isa( (buf = self.read_line(source,pos=nbytes) )   ) do begin
    dprint,verbose=self.verbose,dlevel=4,nbytes,string(buf)
    if debug(4,self.verbose,msg='Hex: '+strtrim(n_elements(buf))) then begin
      hexprint,buf      
    endif
    if self.run_proc then begin
      result = self.translate(buf,source_dict=source_dict)
      if debug(4,self.verbose,MSG='test: ') then printdat,result
      if isa(self.dyndata,'dynamicarray') then self.dyndata.append, result      
    endif
    nbytes += n_elements(buf)
    npkts += 1
  endwhile
  self.npkts += npkts
  self.nbytes += nbytes
  if self.isasocket then begin
    self.msg = time_string(systime(1),tformat='hh:mm:ss ')+strtrim(nbytes,2)+' bytes'
  endif

end


function json_reader::init,_extra=ex  
  ;dprint,'hello'
  void = self.socket_reader::init(_extra=ex)
  if ~isa(tplot_tagnames,'string') then tplot_tagnames='*'
  self.convert_to_struct = 1
  self.convert_to_float = 1
  if self.eol lt 0 then self.eol=byte(10)
  return,1

end




PRO json_reader__define
  void = {json_reader, $
    inherits socket_reader, $    ; superclass
    ;ddata: obj_new(),  $
    ;powersupply_num:0    $           ; not actually used
    tplot_tagnames: '', $
    convert_to_struct:0,  $
    convert_to_float:0  $
  }
END


