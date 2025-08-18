;+
; FUNCTION:
;       kgy_ck_gaps
; PURPOSE:
;       Returns times of gaps in the ck kernel due to altitude manoeuvres
; CALLING SEQUENCE:
;       in_gaps = kgy_ck_gaps( times )
; INPUT:
;       time array
; OUTPUT:
;       in gaps (1) or out of gaps (0)
; CREATED BY:
;       Yuki Harada on 2018-05-15
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-05-15 23:37:33 -0700 (Tue, 15 May 2018) $
; $LastChangedRevision: 25226 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/general/spice/kgy_ck_gaps.pro $
;-

function kgy_ck_gaps, times


ck_gaps = time_double( [ $
;; see http://darts.jaxa.jp/pub/spice/SELENE/kernels/ck/aareadme.txt
;; Gap Start                Gap End                  Reason
;;   -----------------------------------------------------------------------------
  ['2007-11-10/12:00:30.072', '2007-11-10/12:06:04.072'], $ ;Unloading Function Check
  ['2007-12-11/02:59:34.658', '2007-12-11/06:02:40.662'], $ ;Altitude Keeping Maneuver
  ['2007-12-18/06:06:54.844', '2007-12-18/13:59:54.857'], $ ;Low Load Mode
  ['2007-12-19/07:05:58.883', '2007-12-19/07:47:00.884'], $ ;Unknown
  ['2007-12-30/00:55:11.266', '2007-12-30/09:00:03.280'], $ ;MDR* operation failure
  ['2008-02-04/23:40:18.542', '2008-02-06/23:40:40.584'], $ ;Altitude Keeping Maneuver
  ['2008-03-29/19:24:59.205', '2008-03-29/22:10:41.207'], $ ;Altitude Keeping Maneuver
  ['2008-04-02/20:58:29.275', '2008-04-02/22:32:41.276'], $ ;Yaw around operation
  ['2008-05-24/15:40:05.909', '2008-05-24/17:48:35.910'], $ ;Altitude Keeping Maneuver
  ['2008-07-16/11:30:05.865', '2008-07-16/13:38:41.869'], $ ;Altitude Keeping Maneuver
  ['2008-07-28/01:03:28.338', '2008-07-28/23:38:58.375'], $ ;Reaction Wheel 1 trouble
  ['2008-08-03/02:34:58.532', '2008-08-03/04:37:42.535'], $ ;Orbit plane change maneuver
  ['2008-09-02/00:42:51.150', '2008-09-02/03:02:41.151'], $ ;Orbit plane change maneuver
  ['2008-09-10/09:27:51.289', '2008-09-10/12:02:41.291'], $ ;Altitude Keeping Maneuver
  ['2008-10-01/01:14:57.670', '2008-10-01/03:48:41.672'], $ ;Altitude Keeping Maneuver
  ['2008-10-07/06:21:59.804', '2008-10-07/07:51:41.806'], $ ;Yaw around operation
  ['2008-11-03/03:43:22.306', '2008-11-03/06:17:42.308'], $ ;Altitude Keeping Maneuver
  ['2008-12-27/00:41:47.739', '2008-12-27/02:49:41.744'], $ ;Reaction Wheel 3 trouble
  ['2009-02-09/12:19:58.763', '2009-02-09/15:49:40.766'], $ ;Lunar eclipse operation
  ['2009-02-20/21:42:58.976', '2009-02-21/00:06:40.977'], $ ;Altitude Keeping Maneuver
  ['2009-03-19/18:29:59.285', '2009-03-19/21:19:41.286'], $ ;Altitude Keeping Maneuver
  ['2009-04-03/07:42:55.467', '2009-04-03/09:11:41.468'], $ ;Yaw around operation
  ['2009-04-16/17:54:57.669', '2009-04-16/20:43:41.670'], $ ;Altitude Keeping Maneuver
  ['2009-06-10/16:56:32.446', '2009-06-10/17:59:16.447'] $ ;Impact operation
                        ] )


if n_elements(times) eq 0 then return, ck_gaps

ngaps = n_elements(ck_gaps[0,*])

in_gaps = replicate(0b,n_elements(times))
for i=0,ngaps-1 do begin
   w = where( times ge ck_gaps[0,i] and times le ck_gaps[1,i] , nw )
   if nw gt 0 then in_gaps[w] = 1
endfor

;; Start: 2007.10.20 02:30:00.00 UT
;; End:   2009.06.10 19:30:00.00 UT

w = where( times lt time_double('2007-10-20/02:30') or times gt time_double('2009-06-10/19:30') , nw )
if nw gt 0 then in_gaps[w] = 1

return, in_gaps

end
