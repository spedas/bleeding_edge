;Returns epochvals and timevals for the L2 flag values


;date -> Day to return time values for (example: '2010-10-13')
;dt -> delta-time in seconds for cadence of time values

;epochvals -> returned times in epoch format
;timevals -> returned times in 'yyyy-mm-dd/hh:mm:ss.msec' format



;no_epoch16 -> use cdf_epoch instead of cdf_epoch16
;			Epoch16 is the default for RBSP

;Written by Aaron W Breneman  03/20/2013


pro epoch_flag_times,date,dt,epochvals,timevals,no_epoc16=no_epoch16


	timevals = dt*dindgen(86400/dt) + time_double(date + '/00:00:00')


	tstring = time_string(timevals,prec=3)

	year = long(strmid(tstring,0,4))
	month = long(strmid(tstring,5,2))
	day = long(strmid(tstring,8,2))
	hour = long(strmid(tstring,11,2))
	minute = long(strmid(tstring,14,2))
	second = long(strmid(tstring,17,2))
	msec = long(strmid(tstring,20,3))

	if keyword_set(no_epoch16) then $
		cdf_epoch,epochvals,year,month,day,hour,minute,second,msec,/compute_epoch else $	
		cdf_epoch16,epochvals,year,month,day,hour,minute,second,msec,000,000,/compute_epoch




end