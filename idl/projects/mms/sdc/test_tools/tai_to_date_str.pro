;converts a Julian day to a calendar date string
;strings are in the format YYYY-MM-DD
function tai_to_date_str, julian_day 
  caldat, julian_day, month, day, year
  month = strtrim(month,2)
  day = strtrim(day,2)
  year = strtrim(year,2)
  if strlen(month) eq 1 then month='0'+month
  if strlen(day) eq 1 then day='0'+day
  date_str =  year+ '-' + month + '-' + day
  
  return, date_str
end