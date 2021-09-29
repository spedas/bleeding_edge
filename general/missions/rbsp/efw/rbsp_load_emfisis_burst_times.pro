;+
; NAME: RBSP_LOAD_EMFISIS_BURST_TIMES
;
; SYNTAX:
;	rbsp_load_emfisis_burst_times,probe='a b'
;
; PURPOSE: Loads EMFISIS Burst data availability. Creates a tplot
;	variable indicating available times.
;
;	date = 'yyyy-mm-dd'
;	probe = 'a' or 'b'
;
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2018-12-06 09:25:24 -0800 (Thu, 06 Dec 2018) $
;   $LastChangedRevision: 26261 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_load_emfisis_burst_times.pro $
;
;-

pro rbsp_load_emfisis_burst_times,date,probe

	rbsp_efw_init
	timespan,date

	remote_data_dir = 'https://emfisis.physics.uiowa.edu/events/'
	subdir = 'rbsp-'+probe+'/burst/'
	local_path = '/Users/aaronbreneman/data/rbsp/emfisis/burst_availability/rbsp-'+probe+'/burst/'


	ttmp = timerange()
	day = strmid(date,0,4)+strmid(date,5,2)+strmid(date,8,2)


	;grab the online EMFISIS list of burst times and read in
	fn = 'rbsp-'+probe+'_burst_times_'+day+'.txt'
	files = spd_download(remote_path=remote_data_dir+subdir,remote_file=fn,$
  local_path=local_path,$
  /last_version)

	resulttst = FILE_TEST(files)
if resulttst then begin

	openr,lun,local_path+fn,/get_lun
	jnk = ''
	readf,lun,jnk

	lines = strarr(50000.)
	q=0.
	while not eof(lun) do begin
		readf,lun,jnk
		lines[q] = jnk
		q++
	endwhile
	close,lun
	free_lun,lun



	;remove blank strings
	goo = where(lines eq '')
	lines = lines[0:goo[0]-1]

	t0 = dblarr(n_elements(lines))
	t1 = dblarr(n_elements(lines))
	type = strarr(n_elements(lines))

	;Extract the times
	for q=0,n_elements(lines)-1 do begin
		tmp = strsplit(lines[q],',',/extract)
		t0[q] = time_double(tmp[0])
		t1[q] = time_double(tmp[1])
		type[q] = tmp[3]
	endfor


	;create artificial array of times.
	timestmp = time_double(date) + dindgen(100.*86400.)/99.
	valstmp = fltarr(n_elements(timestmp))


	for i=0,n_elements(t0)-1 do begin
			goo = where((timestmp ge t0[i]) and (timestmp le t1[i]))
			if goo[0] ne -1 then valstmp[goo] = 1.
	endfor

	store_data,'rbsp'+probe+'_emfisis_burst',timestmp,valstmp
	ylim,'rbsp'+probe+'_emfisis_burst',0,2
	;tplot,'rbsp'+probe+'_emfisis_burst'
endif

end
