;+
; NAME: rbsp_efw_emfisis_scm_gain_list.pro
; SYNTAX:
; PURPOSE: Returns a list of times when EMFISIS turned on/off the 19dB attenuator
;          on the SCM burst waveform signal.
; NOTES: Note for Aaron Breneman: See Malaspina email on Feb 2, 2018.
;        Full list of on/off times from Hospdarsky/Bounds 2018-02-28 email
; KEYWORDS:
; HISTORY: Aaron Breneman, 2018
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2018-12-21 11:38:35 -0800 (Fri, 21 Dec 2018) $
;   $LastChangedRevision: 26396 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/calibration_files/rbsp_efw_emfisis_scm_gain_list.pro $
;-


function rbsp_efw_emfisis_scm_gain_list

  st = time_string(systime(/seconds))

  rbspa_on_start = time_string([$
    '2012-10-05T15:59:57.333Z',$
    '2015-02-16T11:59:54.262Z',$
    '2015-06-08T23:34:53.292Z',$
    '2015-09-15T21:48:20.337Z',$
    '2015-09-22T20:51:45.428Z',$
    '2015-10-19T21:12:33.270Z',$
    '2015-11-07T16:17:49.242Z'])

  rbspa_on_stop = time_string([$
    '2012-10-06T15:59:51.333Z',$
    '2015-06-08T23:34:47.292Z',$
    '2015-09-15T21:29:50.336Z',$
    '2015-09-22T20:51:39.428Z',$
    '2015-10-19T20:54:45.267Z',$
    '2015-11-07T00:49:01.337Z'])

  ;add one element to stop array if the attenuator is currently ON
  if n_elements(rbspa_on_start) gt n_elements(rbspa_on_stop) then $
  rbspa_on_stop = [rbspa_on_stop,st]


  rbspb_on_start = time_string([$
    '2012-09-01T03:58:45.846Z',$  ;none
    '2012-10-06T22:11:39.332Z',$  ;1-flip
    '2014-10-04T01:11:45.926Z'])  ;none

  rbspb_on_stop = time_string([$
    '2012-09-01T03:59:09.846Z',$ ;none
    '2012-10-07T22:11:39.267Z',$ ;1-flip
    '2015-02-16T12:11:43.533Z'])


  ;add one element to stop array if the attenuator is currently ON
  if n_elements(rbspb_on_start) gt n_elements(rbspb_on_stop) then $
  rbspb_on_stop = [rbspb_on_stop,st]


  list = {rbspa_on_start:rbspa_on_start,$
  rbspa_on_stop:rbspa_on_stop,$
  rbspb_on_start:rbspb_on_start,$
  rbspb_on_stop:rbspb_on_stop}


  return,list

end
