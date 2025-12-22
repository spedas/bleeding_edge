;+
; PROCEDURE: is_leap_year
;
; PURPOSE: determine if a given year (or array of years) is leap
;
; INPUTS:     
;     year:
;         year is an int or long or an array of ints or longs
;     
; OUTPUTS:
;     return value is a byte (or byte array of same size as year if year is array)
;     value is 1 for each year that is a leap year
;
; CREATED BY: Vince Saba, 9/96
;
; VERSION: @(#)is_leap_year.pro	1.1 10/02/96
;-


function is_leap_year, year

result = (year eq 0) or (year mod 4 eq 0) and (year mod 100 ne 0) or $
    (year mod 400 eq 0) and (year mod 4000 ne 0)

return, result
end

