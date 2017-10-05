;+
;;Function: isdaylightsavingtime
;purpose: returns 0 or 1 depending upon
;Limitations:   Current only works for US time zones (-5 though -11)  
;        It will return 0 outside of these regions
;        Arizona and Hawaii are unfortunately lumped together with the other 48 states.
;-
function  isdaylightsavingtime,gmtime,timezone,set_time_changes=set_time_changes
   ; this can give odd results during the 2 hour interval around the DST change.

common isdaylightsavingtime_com,time_changes_us
;dprint,dlevel=9,gmtime

if n_elements(set_time_changes) ne 0 then time_changes_us = long( time_double(set_time_changes) )

; The following dates are only valid for the U.S. (except arizona and hawaii)
if n_elements(time_changes_us) eq 0 then   time_changes_us =  $
  long(time_double([ ['2001-4-1/2' ,'2001-10-28/2'], $
                     ['2002-4-7/2' ,'2002-10-27/2'], $
                     ['2003-4-6/2' ,'2003-10-26/2'], $
                     ['2004-4-4/2' ,'2004-10-31/2'], $
                     ['2005-4-3/2' ,'2005-10-30/2'], $
                     ['2006-4-2/2' ,'2006-10-29/2'], $
                     ['2007-3-11/2','2007-11-04/2'], $
                     ['2008-3-09/2','2008-11-02/2'],$
                     ['2009-3-8/2' ,'2009-11-1/2'],$
                     ['2010-3-14/2','2010-11-7/2'],$
                     ['2011-3-13/2','2011-11-6/2'],$
                     ['2012-3-11/2','2012-11-4/2'], $
                     ['2013-3-10/2','2013-11-3/2'], $
                     ['2014-3-9/2','2014-11-2/2'], $
                     ['2015-3-8/2','2015-11-1/2'], $
                     ['2016-3-13/2','2016-11-6/2'], $
                     ['2017-3 12/2','2017-11-5/2'] , $
                     ['2018-3 11/2','2018-11-4/2'] , $
                     ['2019-3 10/2','2019-11-3/2']           ]))  ;, $

if n_elements(timezone) eq 0  then begin
     timezone = getenv('TIMEZONE')
     if not keyword_set(timezone) then begin  ;  This is a cluge... but the only way I know of to determine the timezone.
;dprint,dlevel=3,"Determining timezone..."   Do not uncomment... produces infinite recursion
        timezone = fix(round((time_double(strjoin(bin_date(systime(0)))) -systime(1)) / 3600))
        timezone -= isdaylightsavingtime(systime(1),timezone)   ; Warning recursive call!
        setenv,'TIMEZONE='+strtrim(timezone,2)
;dprint,dlevel=3,'timezone is:',timezone
     endif else timezone = fix(timezone)
endif
  
if timezone eq 0 then return,fix(gmtime * 0)
if timezone lt -11 or timezone gt -5 then return,fix(gmtime *0)  ; Only the U.S. is handled


ltime = timezone*3600d + gmtime
dst = fix(ltime *0)
for i = 0,n_elements(time_changes_us)/2-1 do dst = dst +(ltime gt time_changes_us[0,i])  and (ltime lt time_changes_us[1,i])
  
return,dst

end

