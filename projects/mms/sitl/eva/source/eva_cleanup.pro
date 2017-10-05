PRO eva_cleanup
  cfg = -1
  dir = mms_config_filedir(/app_query); look for the config directory
  if(dir[0] ne '') then begin
    ;Is there a trailing slash? Not for linux or windows, not sure about Mac
    ll = strmid(dir, strlen(dir)-1, 1)
    If(ll Eq '/' Or ll Eq '\') Then filex = dir+'mms_config.txt' $
    Else filex = dir+'/'+'mms_config.txt'
    if file_test(filex) then begin;........ if dir found, look for the config file
      file_delete, filex
    endif; if file_test; if config file not found, do nothing (cfg=-1)
  endif; dir[0] ne ''; if config dir not found, do nothing (cfg=-1)
END
