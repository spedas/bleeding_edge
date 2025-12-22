; ENVIRONMENT VARIABLES USED:
; YEAR1 - Year for starting data
; YEAR2 - Year for ending data
; DOY1 - Starting day of year
; DOY2 - Ending day of year
; GIF_DIR - Directory for gif output

sys7_temps_gifs, GETENV('DOY1'), GETENV('YEAR1'), GETENV('DOY2'), GETENV('YEAR2'), GETENV('GIF_DIR')
exit
