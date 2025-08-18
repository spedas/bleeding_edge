; NAME: tracers_config_read_template
;
; PURPOSE: Read template structure from configuration file.
;
; IDL> tracers_config_write, pref
;
;
; $LastChangedBy: elfin_shared $
; $LastChangedDate: 2025-07-14 22:58:01 -0700 (Mon, 14 Jul 2025) $
; $LastChangedRevision: 33465 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/tracers/common/tracers_config_read.pro $
;
; read_ascii template for tracers_config_read
FUNCTION tracers_config_read_template
  anan = fltarr(1) & anan[0] = 'NaN'
  ppp = {$
    VERSION:1.00, $
    DATASTART:0L, $
    DELIMITER:61b, $; <----------- Delimited by =
    ;DELIMITER:58b, $; <----------- Delimited by colon
    MISSINGVALUE:anan[0], $
    COMMENTSYMBOL:';', $
    FIELDCOUNT: 2L, $
    FIELDTYPES:[7L,7L], $
    FIELDNAMES:['PARAMETER','VALUE'], $
    FIELDLOCATIONS:[0,15], $
    FIELDGROUPS:[0,1]}
  return, ppp
End

FUNCTION tracers_config_read
  cfg = -1
  dir = tracers_config_filedir(/app_query); look for the config directory
  if(dir[0] ne '') then begin
    ;Is there a trailing slash? Not for linux or windows, not sure about Mac
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Eq '/' Or ll Eq '\') Then filex = dir+'tracers_config.txt' $
    Else filex = dir+'\'+'tracers_config.txt'
    if file_test(filex) then begin;........ if dir found, look for the config file
      ttt = tracers_config_read_template()
      rst = read_ascii(filex,template=ttt,header=hhh)
      nmax = n_elements(rst.VALUE)
      for n=0,nmax-1 do begin
        if is_numeric(rst.VALUE[n]) then begin; convert to float or long
          rst_value = (strpos(rst.VALUE[n],'.') ge 0) ? float(rst.VALUE[n]) : long(rst.VALUE[n])
        endif else rst_value = strtrim(rst.VALUE[n],2); stays 'string'
        str_element,/add,cfg,rst.PARAMETER[n],rst_value
      endfor; for each line
    endif; if file_test; if config file not found, do nothing (cfg=-1)
  endif; dir[0] ne ''; if config dir not found, do nothing (cfg=-1)
  return, cfg; a structure will be created if config file read
END
