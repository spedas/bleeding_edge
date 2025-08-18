PRO eva_sitl_validate_handler, count, title=title, warning=warning,$
  desc=desc
  stype = keyword_set(warning) ? 'warning' : 'error'
  if n_elements(title) eq 0 then title = 'EVA'
  sfx = (count eq 1) ? '.' : 's.'
  msg = 'You have '+strtrim(string(count),2)+' '+stype+sfx
  if n_elements(desc) ne 0 then begin
    msg = [msg, desc]
  endif
  msg = [msg, "Please fix them before submission."]
  rst = dialog_message(msg,/error,/center,title=title); 'OK'
END
