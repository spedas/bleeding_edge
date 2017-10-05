;+
; PROCEDURE: iug_load_gmag_stel_induction
;
; PURPOSE:
;   To load STEL induction magnetometer data from the STEL ERG-SC site 
;
; NOTE: 
;   This procedure is a simple alias to "erg_load_gmag_stel_induction"
;   and calls the original one by just providing the same
;   arguments/keywords given.
;   Some load procedures for the ground-based observational data
;   in the  ERG mission, named "erg_load_???", can be also called
;   by "iug_load_???", because these data are related to the both
;   ERG and IUGONET projects.
;   For more information, see http://www.iugonet.org/en/
;                         and http://gemsissc.stelab.nagoya-u.ac.jp/erg/
;   See the rules of the road.
;   For more information, see http://stdb2.stelab.nagoya-u.ac.jp/magne/
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_gmag_stel_induction, site='msr',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['msr', 'sta']
;           or a single string delimited by spaces, e.g., 'msr sta'.
;           Sites: ath mgd ptk msr sta
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   frequency_dependent = get frequecy-dependent sensitivity and phase difference
;            (frequency [Hz], sensitivity (H,D,Z) [V/nT], and phase_difference (H,D,Z) [deg])
;   /time_pulse, get time pulse
;
; EXAMPLE:
;   iug_load_gmag_stel_induction, site='msr sta', $
;         trange=['2008-02-28/00:00:00','2008-02-28/02:00:00']
;
; Written by: Y.-M Tanaka, Apr 12, 2013 (ytanaka at nipr.ac.jp)
;-

pro iug_load_gmag_stel_induction, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip, $
        frequency_dependent=frequency_dependent, time_pulse=time_pulse

erg_load_gmag_stel_induction, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip, $
        frequency_dependent=frequency_dependent, time_pulse=time_pulse

end
