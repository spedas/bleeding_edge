;+
; NAME: rbsp_efw_emfisis_19dB_gain_list
; SYNTAX:
; PURPOSE: Returns a list of times when EMFISIS turned on/off the 19dB
;          attenuator on the SCM burst waveform signal.
;
; KEYWORDS:
; NOTES: Notes to Aaron Breneman: See D. Malaspina email on Feb 2, 2018.
;        Initial list of on/off times from Hospodarsky 2018-02-28 email
;
; HISTORY: Written by Aaron W Breneman
; VERSION:
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2018-12-21 11:35:33 -0800 (Fri, 21 Dec 2018) $
;   $LastChangedRevision: 26395 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/calibration_files/rbsp_efw_emfisis_19dB_gain_list.pro $
;-


function rbsp_efw_emfisis_19dB_gain_list

  rbspa_off = time_string(['2012-09-01T00:00:00.000Z',$
    '2012-10-06T15:59:51.333Z',$
    '2015-06-08T23:34:47.292Z',$
    '2015-09-15T21:29:50.336Z',$
    '2015-09-22T20:51:39.428Z',$
    '2015-10-19T20:54:45.267Z',$
    '2015-11-07T00:49:01.337Z'])

  rbspa_on = time_string(['2012-10-05T15:59:57.333Z',$
    '2015-02-16T11:59:54.262Z',$
    '2015-06-08T23:34:53.292Z',$
    '2015-09-15T21:48:20.337Z',$
    '2015-09-22T20:51:45.428Z',$
    '2015-10-19T21:12:33.270Z',$
    '2015-11-07T16:17:49.242Z'])

  rbspb_off = time_string(['2012-09-01T00:00:00.000Z',$
    '2012-09-01T03:59:09.846Z',$
    '2012-10-07T22:11:39.267Z',$
    '2015-02-16T12:11:43.533Z'])

  rbspb_on = time_string(['2012-09-01T03:58:45.846Z',$
    '2012-10-06T22:11:39.332Z',$
    '2014-10-04T01:11:45.926Z'])

  list = {rbspa_on:rbspa_on,$
          rbspa_off:rbspa_off,$
          rbspb_on:rbspb_on,$
          rbspb_off:rbspb_off}

  return,list

end
