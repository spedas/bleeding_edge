;Crib sheet for interpolating Scott's density calibration dates. 
;He lists the dates as the date(s) he tests the UH line for the density fit. 
;For example, he finds fit parameters for 2017-01-15, 2017-02-15, and 2017-03-15. 
;This crib interpolates these dates such that the valid range for the 2017-02-15 test would be:
;2017-02-01 to 2017-03-01. It then uses the 2017-03-15 parameters from 2017-03-01 to xxxx-xx-xx. 



;Dates the UH line tested on 
init = ['2018-05-19/00:00:00','2018-04-05/00:00:00','2018-03-11/00:00:00','2018-02-11/00:00:00','2018-01-11/00:00:00','2017-12-19/00:00:00','2017-11-18/00:00:00','2017-10-20/00:00:00','2017-09-21/00:00:00','2017-08-06/00:00:00','2017-07-29/00:00:00']

;number of days to subtract from each testing date
ndays1 = (time_double(init) - time_double(shift(init,-1)))/86400/2.    
;number of days to add to each testing date
ndays2 = (time_double(shift(init,1)) - time_double(init))/86400/2.    


;new arrays with interpolated times
newinit = strarr(n_elements(ndays))
newfin = newinit


;interpolated initial times
for i=0,n_elements(newinit)-1 do newinit[i] = time_string(time_double(init[i]) - ndays1[i]*86400.)    
;interpolated final times
for i=0,n_elements(newinit)-1 do newfin[i] =  time_string(time_double(init[i]) + ndays2[i]*86400.)    
;print out the dates in the format:  initial_time_inter  original_time  final_time_interp
for i=0,n_elements(newinit)-1 do print,newinit[i] + ' ' + init[i] + ' ' + newfin[i]










