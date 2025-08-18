pro mms_submit_back_structure, backstr, local_dir


;Get the time of sitl submission
temptime = systime(/utc)
mostr = strmid(temptime, 4, 3)
monew = ''
case mostr of
  'Jan': monew = '01'
  'Feb': monew = '02'
  'Mar': monew = '03'
  'Apr': monew = '04'
  'May': monew = '05'
  'Jun': monew = '06'
  'Jul': monew = '07'
  'Aug': monew = '08'
  'Sep': monew = '09'
  'Oct': monew = '10'
  'Nov': monew = '11'
  'Dec': monew = '12'
endcase
  
daystr = strmid(temptime, 8, 2)
hrstr = strmid(temptime, 11, 2)
minstr = strmid(temptime, 14, 2)
secstr = strmid(temptime, 17, 2)
yearstr = strmid(temptime, 20, 4)
  
day_val = fix(daystr)
  
if day_val lt 10 then begin
  daystr = '0'+string(day_val, format = '(I1)')
endif else begin
  daystr = string(day_val, format = '(I2)')
endelse
  
savefile = local_dir + 'bdm_sitl_changes' + yearstr + '-' + monew + $
  '-' + daystr + '-' + hrstr + '-' + minstr + '-' + secstr + '.sav'
  
save, file = savefile, backstr

submit_mms_sitl_selections, local_file


end