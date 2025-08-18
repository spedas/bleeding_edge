;+
;PROCEDURE:	get_latest_dates
;PURPOSE:	look at wi_lz_3dp_files.new and see what dates the 
;       files in it have
;		This is useful because you can call this from a procedure
;		like "make_plot" to do something
;		with the latest data.
;INPUTS:	none
;KEYWORDS:	none
;
;CREATED BY:	Jasper Halekas
;LAST MODIFICATION:	@(#)get_latest_dates.pro	1.4 95/10/06
;-

function get_latest_dates
@wind_com.pro
init_wind_lib

fname = data_directory+'/wi_lz_3dp_files.new'
openr,lun,fname,/get_lun
while not eof(lun) do begin
	s = ''
	readf,lun,s
	s = strcompress(strtrim(s,2))
	s = strmid(s,0,10)
	if not keyword_set(dates) then dates = s else dates = [dates,s]
end

return, dates
end
