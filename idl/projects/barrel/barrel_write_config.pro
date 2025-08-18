;+
;NAME: barrel_write_config
;
;DESCRIPTION: 
;  Writes the barrel_config file
;
;REQUIRED INPUTS:
; none (filename is hardcoded, 'barrel_config.txt', and is put in a folder
;   given by the routine 'barrel_config_filedir', that uses the IDL routine
;   app_user_dir to create/obtain it:
; e.g. (MacOS X)
;   /Users/username/.idl/themis/barrel_config-4_darwin
;
;KEYWORD ARGUMENTS (OPTIONAL):
; COPY:         If set, make a copy, creating a new file whose filename 
;       is timestamped with an appended !STIME.
;
;OUTPUT
; the file is written, and a copy of any old file is generated 
;
;STATUS:
;
;TO BE ADDED: n/a
;
;EXAMPLE:
;
;REVISION HISTORY:
;Version 0.90a KBY 04/19/2013 no changes
;Version 0.84 KBY 12/04/2012 added header 
;Version 0.83 KBY 12/04/2012 initial beta release 
;Version 0.80 KBY 10/29/2012 from 'goesmag/goes_write_config.pro' by JWL(?)
;-

PRO barrel_write_config, copy=copy, _extra=_extra
    otp = -1    ; doesn't do anything here..
    ; get the filename
    dir = barrel_config_filedir()
    ll = strmid(dir, strlen(dir)-1,1)
    if (ll EQ '/' or ll EQ '\') then filex = dir+'barrel_config.txt' $
      else filex = dir + PATH_SEP() + 'barrel_config.txt'
  
    ; if we are copying the file, get a filename, header, and old configuration
    if (keyword_set(copy)) then begin
        xt = time_string(systime(/sec))
        ttt = strmid(xt, 0, 4) + strmid(xt, 5, 2) + strmid(xt, 8, 2) + $
          '_' + strmid(xt, 11, 2) + strmid(xt, 14, 2) + strmid(xt, 17, 2)
        filex_out = filex + '_' + ttt
        cfg = barrel_read_config(header = hhh)
    endif else begin
        ; does the file exist?  if so, then copy it
        if (file_search(filex) NE '') then barrel_write_config, /copy
        filex_out = filex
        cfg = {local_data_dir:!barrel.local_data_dir, $
            remote_data_dir:!barrel.remote_data_dir, $
            no_download:!barrel.no_download, $
            no_update:!barrel.no_update, $
            downloadonly:!barrel.downloadonly, $
            user_agent:!barrel.user_agent, $
            verbose:!barrel.verbose}

        hhh = [';barrel_config.txt', '; BARREL configuration file', $
            ';Created'+time_string(systime(/sec))]
    endelse

    ; you need to be sure that the directory exists
    xdname = file_dirname(filex_out)
    if (xdname NE '') then file_mkdir, xdname

    ; write the file
    ;   write header
    openw, unit, filex_out, /get_lun
    for j=0, n_elements(hhh)-1 do printf, unit, hhh[j]
    ;   write configuration information
    ctags = tag_names(cfg)
    nctags = n_elements(ctags)
    for j=0, nctags-1 do begin
        x0 = strtrim(ctags[j])  ; field tag
        x1 = cfg.(j)            ; associated data
        if (is_string(x1)) then x1 = strtrim(x1,2) else begin
            ; odd things can happen with byte arrays-- convert to integer type
            if (size(x1, /type) EQ 1) then x1 = fix(x1)
            x1 = strcompress(/remove_all, string(x1))
        endelse
        printf, unit, x0 + '=' + x1
    endfor

    FREE_LUN, unit
    RETURN

END



