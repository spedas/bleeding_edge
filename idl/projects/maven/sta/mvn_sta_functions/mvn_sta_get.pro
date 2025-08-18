;+
;PROCEDURE:	mvn_sta_get
;PURPOSE:	
;	Returns static data structure for keyword selected APID averaged over a time range
;INPUT:		
;	apid:		string		apid of data to be returned 'c0','c2','c4','c6'...
;
;KEYWORDS:
;
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  14/03/17
;MOD HISTORY:
;
;NOTES:
;	Program assumes tplot has been called	  
;	Returned data structures can be used as inputs to functions such as n_4d.pro, v_4d.pro, omni4d.pro, sum4m.pro, sum4d.pro
;	Or as input to plotting programs like spec3d, plot3d, contour4d
;	Or used in conjunction with iterative programs such as get_2dt.pro, get_en_spec.pro
;-
FUNCTION mvn_sta_get, apid, tt=tt

if size(/type,apid) ne 7 then begin
   print,' ERROR - mvn_sta_get requires a string input of the apid, i.e. c0,c2,...'
   return, {project_name:'MAVEN', valid:0}
endif else routine = 'mvn_sta_get_'+apid

choose_tt: 
if not keyword_set(tt) then ctime,tt,npoints=2

if n_elements(tt) ne 2 then begin
   print,' ERROR - need two times chosen'
   tt=0
   goto, choose_tt
endif

if tt[0] gt tt[1] then tt=reverse(tt)

dat = call_function(routine,tt[0])
str_element, dat, 'mode', mode, success=gotmode
if (~gotmode) then return, dat
if dat.time gt tt[1] or dat.end_time lt tt[0] then return, dat

nnn=0l
nnn_max = round((tt[1]-tt[0])/4.+4) < 300000
while dat.end_time lt tt[1] and dat.end_time gt tt[0] and nnn lt nnn_max do begin
    dat1 = call_function(routine,/ad)
    str_element, dat1, 'mode', mode1, success=gotmode
    if (gotmode) then if (mode eq mode1) then dat = sum4d(dat, dat1)
	nnn=nnn+1l
endwhile

return, dat

end

