;+
;PROCEDURE:	make_plot (batchfile)
;PURPOSE:	makes summary plots daily when called by make_sum_plots script
;INPUT:		none
;KEYWORDS:	none
;
;CREATED BY:	Jasper Halekas
;LAST MODIFICATION:	@(#)make_plot.pro	1.19 01/06/06
;-
!p.charsize = 1
dates = get_latest_dates()
s = dimen1(dates)
for i = 0, s-1 do begin $
load_3dp_data, dates(i) &$
get_emom		&$
get_spec,'eh'		&$
get_spec,'el'		&$
popen,'/home/wind/www/plots3/1997/daily/eesa/'+dates(i)+'_eesa' &$
loadct,39	&$
tplot, ['Ne','Ve','Te','ehspec','elspec']	                &$
pclose, printer = 'wp1' &$
get_pmom		&$
get_spec,'ph'		&$
get_spec,'pl'		&$
popen,'/home/wind/www/plots2/1997/daily/pesa/'+dates(i)+'_pesa' &$
loadct,39	&$
options,'plspec','spec',1	&$
options,'plspec','ytitle','plspec'	&$
tplot, ['Np','Vp','Tp','phspec','plspec']	                &$
pclose, printer = 'wp1' &$
endfor

exit
