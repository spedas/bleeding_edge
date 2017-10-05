; Parses the strings so that we can easily convert to jul
; 

pro mms_parse_start_string, starts, months, days, years, hours, minutes, seconds, num_chars

months = intarr(n_elements(starts))
days = months
years = months
hours = months
minutes = months
seconds = months
num_chars = intarr(n_elements(starts))

for i = 0, n_elements(starts)-1 do begin
  length = strlen(starts(i))
  num_chars(i) = length
  case length of
    8:  begin
          years(i) = fix(strmid(starts(i), 0, 4))
          months(i) = fix(strmid(starts(i), 4, 2))
          days(i) = fix(strmid(starts(i), 6, 2))
        end
    10: begin
          years(i) = fix(strmid(starts(i), 0, 4))
          months(i) = fix(strmid(starts(i), 4, 2))
          days(i) = fix(strmid(starts(i), 6, 2))
          hours(i) = fix(strmid(starts(i), 8, 2))
        end
    12: begin
          years(i) = fix(strmid(starts(i), 0, 4))
          months(i) = fix(strmid(starts(i), 4, 2))
          days(i) = fix(strmid(starts(i), 6, 2))
          hours(i) = fix(strmid(starts(i), 8, 2))
          minutes(i) = fix(strmid(starts(i), 10, 2))
        end
    14: begin
          years(i) = fix(strmid(starts(i), 0, 4))
          months(i) = fix(strmid(starts(i), 4, 2))
          days(i) = fix(strmid(starts(i), 6, 2))
          hours(i) = fix(strmid(starts(i), 8, 2))
          minutes(i) = fix(strmid(starts(i), 10, 2))
          seconds(i) = fix(strmid(starts(i), 12, 2))
        end
  endcase
endfor

end