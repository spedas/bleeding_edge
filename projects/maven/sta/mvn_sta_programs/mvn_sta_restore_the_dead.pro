;+
;PROCEDURE:	mvn_sta_restore_the_dead
;PURPOSE:	
;	Loads dat_dead array into the "mvn_sta_dead" common block from maven_dir+'data\maven\data\sci\sta\iv1\dead'
;INPUT:		
;
;KEYWORDS:
;	maven_dead_dir	string	default is "C:\data\maven\data\sci\sta\iv1\dead\'
;	trange		dbl(2)	if not set, uses the current default time range - for testing purposes
;	expand		flt	if set, current default time range expanded by "expand" seconds
;
;CREATED BY:	J. McFadden 20/11/17
;VERSION:	1
;LAST MODIFICATION:  20/11/17		
;MOD HISTORY:
;
;NOTES:	  
;	dat_dead is used by mvn_sta_bkg_stragglers.pro
;-

pro mvn_sta_restore_the_dead,maven_dead_dir=maven_dead_dir,trange=trange,expand=expand

common mvn_sta_dead,dat_dead	
starttime = systime(1)

if not keyword_set(maven_dead_dir) then maven_dead_dir='C:\data\maven\data\sci\sta\iv1\dead\'
if not keyword_set(trange) then trange=timerange()
if size(trange,/type) ne 5 then begin
	print,'Error - trange keyword must be dbl(2)'
	return
endif
if keyword_set(expand) then trange = [trange[0]-expand,trange[1]+expand]


	datetime1 = time_string(trange[0])
	datetime2 = time_string(trange[1])
	yrmoda1 = strmid(datetime1,0,4)+strmid(datetime1,5,2)+strmid(datetime1,8,2)
	yrmoda2 = strmid(datetime2,0,4)+strmid(datetime2,5,2)+strmid(datetime2,8,2)
	first_day = time_double(strmid(datetime1,0,10))
	last_day = time_double(strmid(time_string(trange[1]-1.),0,10))

ndays = round((last_day-first_day)/(24.*3600.))+1

for i=0,ndays-1 do begin
	datetime = time_string(time_double(strmid(datetime1,0,10)) + 24.*3600.*i)
	yrmoda = strmid(datetime,0,4)+strmid(datetime,5,2)+strmid(datetime,8,2)
	dead_sav = maven_dead_dir+strmid(yrmoda,0,4)+path_sep()+$
                   strmid(yrmoda,4,2)+path_sep()+'mvn_sta_dead_'+yrmoda+'.sav' 
	restore,filename=dead_sav
	minval = min(abs(dat_dead.time-trange[0]),ind1)
	minval = min(abs(dat_dead.time-trange[1]),ind2)

	print,i,ind1,ind2

	if i eq 0 then begin
		tmp_dead = {	time :dat_dead.time[ind1:ind2],$
				dead :dat_dead.dead[ind1:ind2,*,*],$
				droop:dat_dead.droop[ind1:ind2,*,*],$
				rate :dat_dead.rate[ind1:ind2,*,*],$
				valid:dat_dead.valid[ind1:ind2,*,*],$
				anode:dat_dead.anode[ind1:ind2,*,*]}

	endif else begin

		tmp_dead = {	time :[tmp_dead.time ,dat_dead.time[ind1:ind2]],$
				dead :[tmp_dead.dead ,dat_dead.dead[ind1:ind2,*,*]],$
				droop:[tmp_dead.droop,dat_dead.droop[ind1:ind2,*,*]],$
				rate :[tmp_dead.rate ,dat_dead.rate[ind1:ind2,*,*]],$
				valid:[tmp_dead.valid,dat_dead.valid[ind1:ind2,*,*]],$
				anode:[tmp_dead.anode,dat_dead.anode[ind1:ind2,*,*]]}

	endelse


endfor

	dat_dead = tmp_dead

; print out the run time

	help,dat_dead
	print,time_string(minmax(dat_dead.time))
	print,'mvn_sta_restore_the_dead run time = ',systime(1)-starttime

end
