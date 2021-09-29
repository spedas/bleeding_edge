;+
;Returns a random value for probe, and sets timespan to a random
;date. For testing. Can input start_data and end_date as keywords to
;search smaller time ranges; the default is the full mission after
;2007-03-23
; $LastChangedBy: jimm $
; $LastChangedDate: 2018-04-16 10:47:48 -0700 (Mon, 16 Apr 2018) $
; $LastChangedRevision: 25050 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_random_dp.pro $
;-
Function thm_random_dp, start_date = start_date, end_date = end_date, _extra = _extra
  probes = ['a', 'b', 'c', 'd', 'e']
  index = fix(5*randomu(seed))
  probe = probes[index]

  If(keyword_set(start_date)) Then t0 = time_double(start_date) $
  Else t0 = time_double('2007-03-23')
  If(keyword_set(end_date)) Then t1 = time_double(end_date) $
  Else t1 = time_double(time_string(systime(/sec), /date))
  dt = t1-t0
  date = time_string(t0+dt*randomu(seed), /date)
  timespan, date
  Return, probe
End
