; Write PREF into a configuration file
PRO eva_config_write, pref

  ; Configuration
  cfg = eva_config_read()                 ; read current config
  cfg = eva_config_push(pref,cfg,/force)  ; update 'cfg' with 'pref'

  ; Filename
  dir = eva_config_filedir(/app_query)
  ll = strmid(dir, strlen(dir)-1, 1)
  If(ll Eq '/' Or ll Eq '\') Then filex = dir+'eva_config.txt' $
  Else filex = dir+'/'+'eva_config.txt'
  
  ; Header
  hhh = [';eva_config.txt', ';EVA configuration file', ';Created:'+time_string(systime(/sec))]
  
  ; Write
  openw, nf, filex, /get_lun
  for j = 0, n_elements(hhh)-1 Do printf, nf, hhh[j]
  ctags = tag_names(cfg)
  nctags = n_elements(ctags)
  for j = 0, nctags-1 do begin
    x0 = strtrim(ctags[j])
    x1 = cfg.(j)
    if(is_string(x1)) then begin 
      x1 = strtrim(x1, 2)
    endif else begin; Odd thing can happen with byte arrays
      if(size(x1, /type) eq 1) Then x1 = fix(x1)
      x1 = strcompress(/remove_all, string(x1))
    endelse
    printf, nf, x0+':'+x1
  endfor
  free_lun, nf
END
