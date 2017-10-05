; Routine to get the leap seconds
;

pro load_leap_table2, leaps, juls


; New way - using TDAS routines to get leap seconds. Must run mms_init or cdf_leap_second_init to use properly

leap_data = read_asc(!cdf_leap_seconds.local_data_dir+'/CDFLeapSeconds.txt')
leap_dates= time_double(strtrim(leap_data.(0),2)+'-'+strtrim(leap_data.(1),2)+'-'+strtrim(leap_data.(2),2)+'/00:00:00')

juls = leap_dates/double(86400) + julday(1, 1, 1970, 0, 0)

leaps=leap_data.(3)
 
; Old way - leap table was hardcoded into the routine.

  ;--------------------------------------------
  ; Define leap second table
  ;--------------------------------------------
  
;  juls = 1d0* [julday(1, 1, 1972, 0, 0, 0), $  ;10  # 1 Jan 1972
;               julday(7, 1, 1972, 0, 0, 0), $  ;11  # 1 Jul 1972
;               julday(1, 1, 1973, 0, 0, 0), $  ;12  # 1 Jan 1973
;               julday(1, 1, 1974, 0, 0, 0), $  ;13  # 1 Jan 1974
;               julday(1, 1, 1975, 0, 0, 0), $  ;14  # 1 Jan 1975
;               julday(1, 1, 1976, 0, 0, 0), $  ;15  # 1 Jan 1976
;               julday(1, 1, 1977, 0, 0, 0), $  ;16  # 1 Jan 1977
;               julday(1, 1, 1978, 0, 0, 0), $  ;17  # 1 Jan 1978
;               julday(1, 1, 1979, 0, 0, 0), $  ;18  # 1 Jan 1979
;               julday(1, 1, 1980, 0, 0, 0), $  ;19  # 1 Jan 1980
;               julday(7, 1, 1981, 0, 0, 0), $  ;20  # 1 Jul 1981
;               julday(7, 1, 1982, 0, 0, 0), $  ;21  # 1 Jul 1982
;               julday(7, 1, 1983, 0, 0, 0), $  ;22  # 1 Jul 1983
;               julday(7, 1, 1985, 0, 0, 0), $  ;23  # 1 Jul 1985
;               julday(1, 1, 1988, 0, 0, 0), $  ;24  # 1 Jan 1988
;               julday(1, 1, 1990, 0, 0, 0), $  ;25  # 1 Jan 1990
;               julday(1, 1, 1991, 0, 0, 0), $  ;26  # 1 Jan 1991
;               julday(7, 1, 1992, 0, 0, 0), $  ;27  # 1 Jul 1992
;               julday(7, 1, 1993, 0, 0, 0), $  ;28  # 1 Jul 1993
;               julday(7, 1, 1994, 0, 0, 0), $  ;29  # 1 Jul 1994
;               julday(1, 1, 1996, 0, 0, 0), $  ;30  # 1 Jan 1996
;               julday(7, 1, 1997, 0, 0, 0), $  ;31  # 1 Jul 1997
;               julday(1, 1, 1999, 0, 0, 0), $  ;32  # 1 Jan 1999
;               julday(1, 1, 2006, 0, 0, 0), $  ;33  # 1 Jan 2006
;               julday(1, 1, 2009, 0, 0, 0), $  ;34  # 1 Jan 2009
;               julday(7, 1, 2012, 0, 0, 0), $  ;35  # 1 Jul 2012
;               julday(7, 1, 2015, 0, 0, 0)]    ;36  # 1 Jul 2015
;    
;  leaps = dindgen(26) + 10
  
  
end
