;+
;NAME:
;   srscan_write_config
;
;PURPOSE:
;   Writes the srscan_config.txt configuration file from the current
;   !srs_canada values. A timestamped copy of any existing file is kept.
;
;CALLING SEQUENCE:
;   srscan_write_config
;
;KEYWORD:
;   copy = if set, the existing file is read in and a copy with the time
;          appended is written out
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-10-14 09:44:38 -0700 (Wed, 14 Oct 2026) $
;$LastChangedRevision: 34972 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/srs_canada/srscan_write_config.pro $
;-
pro srscan_write_config, copy=copy, _extra=_extra

  dir = srscan_config_filedir()
  ll = strmid(dir, strlen(dir)-1, 1)
  if (ll eq '/' or ll eq '\') then filex = dir + 'srscan_config.txt' $
  else filex = dir + '/' + 'srscan_config.txt'

  if keyword_set(copy) then begin
    xt = time_string(systime(/sec))
    ttt = strmid(xt, 0, 4) + strmid(xt, 5, 2) + strmid(xt, 8, 2) + $
          '_' + strmid(xt, 11, 2) + strmid(xt, 14, 2) + strmid(xt, 17, 2)
    filex_out = filex + '_' + ttt
    cfg = srscan_read_config(header=hhh)
  endif else begin
    ; if the file already exists, keep a timestamped copy first
    if file_search(filex) ne '' then srscan_write_config, /copy
    filex_out = filex
    cfg = {local_data_dir: !srs_canada.local_data_dir, $
           remote_data_dir: !srs_canada.remote_data_dir, $
           no_download: !srs_canada.no_download, $
           no_update: !srs_canada.no_update, $
           downloadonly: !srs_canada.downloadonly, $
           verbose: !srs_canada.verbose}

    hhh = [';srscan_config.txt', ';srs_canada configuration file', $
           ';Created:' + time_string(systime(/sec))]
  endelse

  xdname = file_dirname(filex_out)
  if xdname ne '' then file_mkdir, xdname

  openw, unit, filex_out, /get_lun
  for j = 0, n_elements(hhh)-1 do printf, unit, hhh[j]
  ctags = tag_names(cfg)
  for j = 0, n_elements(ctags)-1 do begin
    x0 = strtrim(ctags[j])
    x1 = cfg.(j)
    if is_string(x1) then x1 = strtrim(x1, 2) $
    else begin
      if size(x1, /type) eq 1 then x1 = fix(x1)
      x1 = strcompress(/remove_all, string(x1))
    endelse
    printf, unit, x0 + '=' + x1
  endfor
  free_lun, unit

end
