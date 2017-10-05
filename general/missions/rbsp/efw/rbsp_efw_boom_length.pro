;+
; NAME:
;   rbsp_efw_boom_length (function)
;
; PURPOSE:
;   Return the boom length for a give time.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   result = rbsp_efw_boom_length(sc, time)
;
; ARGUMENTS:
;   sc: (In, required) Spacecraft name. Should be 'a' or 'b'.
;   time: (In, required) A value of time.
;
; KEYWORDS:
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-10-08: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;   2012-11-05: Initial release to TDAS. JBT, SSL/UCB.
;   2013-06-20: JBT. Accounted for AXB trimming.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2013-06-20 14:01:20 -0700 (Thu, 20 Jun 2013) $
; $LastChangedRevision: 12561 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_boom_length.pro $
;
;-

function rbsp_efw_boom_length, sc, time

; sc: either 'a' or 'b'
; time: epoch time, i.e., a double precision number of seconds since 1/1/1970

; Get the RBSP EFW boom lengths based on the deployment history from 
; John Bonnell.
; The returned value is of format [len_boom12, len_boom34, len_boom56].
; The boom lengths are in units of meters.

compile_opt idl2

; Full length time, i.e., deployment completion time, in UT.
t_full_length_spb_a = time_double('2012-09-22/19:47:50')
t_full_length_axb_a = time_double('2012-09-24/18:28:30')
t_full_length_spb_b = time_double('2012-09-22/22:31:31')
t_full_length_axb_b = time_double('2012-09-24/20:56:00')



; As of 10/8/12, the boom length before the deployment completion is set as
; NaNs. (JBT, SSL)
t_full = time_double('2012-09-25')
; Not supposed to use for data before 2012-09-25
if time lt t_full then return, [0, 0, 0] * !values.d_nan

len12_a = 49.1d * 2d + 1.82d
len34_a = 49.1d * 2d + 1.82d
len56_a = 4.02d + 4.02d + 1.2d + 0.76d

len12_b = 49.1d * 2d + 1.82d
len34_b = 49.1d * 2d + 1.82d
len56_b = 4.02d + 4.02d + 1.2d + 0.76d

t_trim_1_a = time_double('2012-10-13/04:50') 
t_trim_2_a = time_double('2012-10-23/22:52') 
t_trim_3_a = time_double('2012-11-09/18:37') 
t_trim_4_a = time_double('2012-12-07/04:41') 

t_trim_1_b = time_double('2012-10-12/16:47') 
t_trim_2_b = time_double('2012-10-23/20:32') 
t_trim_3_b = time_double('2012-11-09/22:08') 
t_trim_4_b = time_double('2012-12-07/17:25') 

; AXB trim # 1
if time gt t_trim_1_a and time lt t_trim_2_a then $
  len56_a = 11.6d
if time gt t_trim_1_b and time lt t_trim_2_b then $
  len56_b = 11.6d

; AXB trim # 2
if time gt t_trim_2_a and time lt t_trim_3_a then $
  len56_a = 12.5d
if time gt t_trim_2_b and time lt t_trim_3_b then $
  len56_b = 12.4d

; AXB trim # 3
if time gt t_trim_3_a and time lt t_trim_4_a then $
  len56_a = 13.4d
if time gt t_trim_3_b and time lt t_trim_4_b then $
  len56_b = 13.3d

; AXB trim # 4
if time gt t_trim_4_a then $
  len56_a = 13.65d
if time gt t_trim_4_b then $
  len56_b = 13.55d


if strcmp(sc, 'a', /fold) then return, [len12_a, len34_a, len56_a]
if strcmp(sc, 'b', /fold) then return, [len12_b, len34_b, len56_b]

return, [0, 0, 0] * !values.d_nan ; something bad has happened if the code reach
                                  ; this point.

end

