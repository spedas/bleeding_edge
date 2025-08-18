;+
;FUNCTION:  timerange
;PURPOSE:	To get timespan from tplot_com or by using timespan, if
;		tplot time range not set.
;INPUT:
;	tr (optional)
;KEYWORDS:
; CURSOR   set to 1 to use the cursor to set the timerange
;	CURRENT  Set to 1 to get the current time range as set by tlimit.
;RETURNS:
;    two element time range vector.  (double)
;
;SEE ALSO:	"timespan"
;REPLACES:  "get_timespan"
;
;CREATED BY:	Davin Larson
; $LastChangedBy: jwl $
; $LastChangedDate: 2016-02-03 17:03:41 -0800 (Wed, 03 Feb 2016) $
; $LastChangedRevision: 19898 $
; $URL: svn+ssh:$
;
;-



function timerange,trange,current=current,cursor=cursor
@tplot_com.pro
if keyword_set(cursor) then begin
;   t=trange
   ctime,npoints=2,trange
   return,trange
;   return,t
endif
if keyword_set(trange) then return,minmax(time_double(trange))
str_element,tplot_vars,'options.trange_full',trange_full
if n_elements(trange_full) ne 2 then timespan
if tplot_vars.options.trange_full[0] ge tplot_vars.options.trange_full[1] then $
	timespan
t = tplot_vars.options.trange_full
if keyword_set(current) then t = tplot_vars.options.trange
return,t
end

