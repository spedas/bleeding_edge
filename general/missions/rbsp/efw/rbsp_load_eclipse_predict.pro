;downloads eclipse predict files from http://themis.ssl.berkeley.edu/data/rbsp/MOC_data_products
;
;Creates these tplot variables.
;rbsp(a,b)_umbra
;rbsp(a,b)_penumbra
;
;
;The x-value is the start time of the umbra(penumbra) and y-value is the duration 
;
;
;probe = 'a' or 'b'
;date = '2012-10-13' format
;
;
;notes: There are some dates in which the eclipse predict file that is loaded doesn't
;		have the correct data, or that the suffix has been changed. These exceptions
;		are addressed individually below
;
;Written by Aaron W Breneman - University of Minnesota
;2013-01-30



pro rbsp_load_eclipse_predict,probe,date,remote_data_dir=remote_data_dir,local_data_dir=local_data_dir


	rbsp_spice_init

;URL stuff...

	if ~keyword_set(remote_data_dir) then $
		remote_data_dir = !rbsp_spice.remote_data_dir
	if ~keyword_set(local_data_dir) then $
		local_data_dir = !rbsp_spice.local_data_dir

	dirpath='MOC_data_products/RBSP'+strupcase(probe)+'/eclipse_predict/'
	
;Find out what files are online
	FILE_HTTP_COPY,dirpath,url_info=ui,links=links,localdir=local_data_dir,$
		serverdir=remote_data_dir


;Modify date/time strings

	date2 = time_string(time_double(date),tformat='YYYYMMDD')
	year = time_string(time_double(date),tformat='YYYY')
	doy = time_string(time_double(date),tformat='DOY')


	months = replicate(0.,n_elements(links))
	days = replicate(0.,n_elements(links))
	test = replicate(0B,n_elements(links))

	doys = strmid(links,11,3)
	years = strmid(links,6,4)



	doy_to_month_date,years,doys,months,days


	months = strtrim(floor(months),2)
	days = strtrim(floor(days),2)

	uts = years + '-' + months + '-' + days

	;fix string format
	uts = time_string(time_double(uts))


;uts holds the unix times of all the files available online to download
;Since each file holds the times for multiple eclipse dates we need to figure out
;which one to load

	test = (time_double(date) - time_double(uts))/86400.   
	goo = where(test ge 0)


	if goo[0] ne -1 then begin

		val = min(test[goo],loc)
		file = links[loc]


		;*******
		;Fix filenames for exceptions. The APL file in the below cases is messed up, maybe
		;b/c it doesn't have the data it's supposed to have, or b/c the suffix has changed.
		
		;Exceptions:
		;A: 10-23 (should work)
		;B: 10-23 (should work)
		
		;A: 10-11, 10-12
		if file eq 'rbspa_2012_285_01.pecl' then file = 'rbspa_2012_285_01.pecl.orig'

		;B: 10-05, 10-06, 10-07, 10-08, 10-09		
		if file eq 'rbspb_2012_279_01.pecl' then file = 'rbspb_2012_272_01.pecl'

		;*******

		relpathnames = dirpath + file



		;download the file
		file_loaded = file_retrieve(relpathnames,remote_data_dir=remote_data_dir,$
			local_data_dir=local_data_dir,/last_version)


	;Hopefully the file is now downloaded locally. 
	;Let's read it

		ft = [3,3,7,3,7,3,7,3,7,4,7,7,4]
		fn = ['orbit_number','daystart','monthstart','yearstart','timestart','daystop',$
				'monthstop','yearstop','timestop','duration','obstruction',$
				'current_condition','total_duration']
		fl = [0,16,19,23,28,44,47,51,56,81,90,105,138]
		fg = [indgen(13)]

		template = {version:1.,$
					datastart:6L,$
					delimiter:32B,$
					missingvalue:!values.f_nan,$
					commentsymbol:'',$
					fieldcount:13L,$
					fieldtypes:ft,$
					fieldnames:fn,$
					fieldlocations:fl,$
					fieldgroups:fg}


		vals = read_ascii(file_loaded,template=template)


		if is_struct(vals) then begin

		;Fix up date to yyyy-mm-dd/hh:mm:ss.msec format
			months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']


			;start date
			months2 = fltarr(n_elements(vals.monthstart))
			for i=0L,n_elements(vals.monthstart) - 1 do begin	$
				goo = where(vals.monthstart[i] eq months)	& $
				months2[i] = goo + 1	& $
			endfor

			ec_start = strtrim(vals.yearstart,2)+'-'+strtrim(months2,2)+'-'+strtrim(vals.daystart,2) + '/' + vals.timestart
			ec_start = time_string(time_double(ec_start))

			goo_start = where(strmid(ec_start,0,10) eq date)

			if goo_start[0] ne -1 then ec_start = ec_start[goo_start] else begin
				print,'NO ECLIPSE TIMES FOR THIS DATE(S)'
				return
			endelse

			ec_startd = time_double(ec_start)

			;stop date
			months2 = fltarr(n_elements(vals.monthstop))
			for i=0L,n_elements(vals.monthstop) - 1 do begin	$
				goo = where(vals.monthstop[i] eq months)	& $
				months2[i] = goo + 1	& $
			endfor

			ec_stop = strtrim(vals.yearstop,2)+'-'+strtrim(months2,2)+'-'+strtrim(vals.daystop,2) + '/' + vals.timestop
			ec_stop = time_string(time_double(ec_stop))

			goo_stop = where(strmid(ec_stop,0,10) eq date)

			if goo_stop[0] ne -1 then ec_stop = ec_stop[goo_stop] else begin
				print,'NO ECLIPSE TIMES FOR THIS DATE(S)'
				return
			endelse


			ec_stopd = time_double(ec_stop)


			type = vals.current_condition[goo_start]
			duration = vals.duration[goo_start]
			umb = where(type eq 'Umbra',cntu)
			pen = where(type eq 'Penumbra',cntp)




			if umb[0] ne -1 then begin
				store_data,'rbsp'+probe+'_umbra',data={x:time_double(ec_start[umb]),y:duration[umb]}
			endif else print,'NO UMBRA DATA FOUND FOR THIS TIMESPAN'
			if pen[0] ne -1 then begin
				store_data,'rbsp'+probe+'_penumbra',data={x:time_double(ec_start[pen]),y:duration[pen]}
			endif else print,'NO PENUMBRA DATA FOUND FOR THIS TIMESPAN'


		endif else print,'NO ECLIPSE DATA FOR THIS TIME'

	endif else print,'NO ECLIPSE FILE FOR THIS DAY'


end






