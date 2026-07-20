pro abs_get_start_end,filename=filename,unix_starts=unix_starts, unix_ends=unix_ends
  restore, filename
  if is_struct(fomstr) then begin
    if tag_exist(fomstr, 'timestamps') then begin
      unix_starts=mms_tai2unix(fomstr.timestamps[0])
      unix_ends=mms_tai2unix(fomstr.timestamps[n_elements(fomstr.timestamps)-1])
    endif
  endif
end