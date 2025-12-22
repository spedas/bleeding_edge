pro sys7_temps_gifs, DOY1, YEAR1, DOY2, YEAR2, GIF_DIR
; Output gifs for sys7 and temp trending to /disks/juneau/scratch/LZPfiles/trend/sys7/gifs
; and disks/juneau/scratch/LZPfiles/trend/temps/gifs

; ARGUEMENTS USED:
; YEAR1 - Year for starting data
; YEAR2 - Year for ending data
; DOY1 - Starting day of year
; DOY2 - Ending day of year
; GIF_DIR - Directory for gif output
; 

; Setup time variables
doy_to_month_date, YEAR1, DOY1, month1, day1
doy_to_month_date, YEAR2, DOY2, month2, day2

DATE1=STRTRIM(YEAR1, 2) + "-" + STRTRIM(month1, 2) + "-" + STRTRIM(day1, 2)
DATE2=STRTRIM(YEAR2, 2) + "-" + STRTRIM(month2, 2) + "-" + STRTRIM(day2, 2)

time1=str_to_time(DATE1)
time2=str_to_time(DATE2)

; load data
gts_dirarray='/disks/juneau/scratch/LZPfiles/trend/sys7/dat/' + STRTRIM(indgen(FIX(YEAR2) - FIX(YEAR1) +1) + FIX(YEAR1), 2)
temp_dirarray='/disks/juneau/scratch/LZPfiles/trend/temps/dat/' + STRTRIM(indgen(FIX(YEAR2) - FIX(YEAR1) + 1) + FIX(YEAR1), 2)

gts_concatenate, DATA_DIRECTORY=gts_dirarray, QUANTITIES=['P12S7V']
store_temp_trend, DATA=temp_dirarray

; Find min and max ylims
plot_array=['pctemp1', 'pctemp2', 'cputemp', 'bebtempa', 'P12S7V']

;FOR I = 0, 4 DO BEGIN
;  get_data, plot_array[I], data=datastr
;  subset = where(datastr.x GT time1 AND datastr.x LT time2)
;  ymin = min(datastr.y(subset), max=ymax)
;  ylim, plot_array[I], ymin, ymax
;ENDFOR

ylim, 'pctemp1', -10, 50
ylim, 'pctemp2', -10, 50
ylim, 'cputemp', -10, 50
ylim, 'bebtempa', -10, 50
IF YEAR1 EQ 1998 THEN ylim, 'P12S7V', 2, 14 ELSE ylim, 'P12S7V', 2, 6

;create gif
set_plot, 'Z'
loadct2, 39

tplot, plot_array
tlimit, DATE1, DATE2

array=tvrd()
tvlct, r, g, b, /get

gif_file = GIF_DIR + '/sys7_temps_' + YEAR1 + '_' + DOY1 + '_' + YEAR2 + '_' + DOY2 + '.gif'
write_gif, gif_file, array, r, g, b

end
