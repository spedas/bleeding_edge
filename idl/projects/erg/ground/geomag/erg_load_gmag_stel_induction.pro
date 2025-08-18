;+
; PROCEDURE: erg_load_gmag_stel_induction
;
; PURPOSE:
;   To load STEL induction magnetometer data from the STEL ERG-SC site
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_gmag_stel_induction, site='msr',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['msr', 'sta']
;           or a single string delimited by spaces, e.g., 'msr sta'.
;           Sites: ath mgd ptk msr sta
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /timeclip, if set, then data are clipped to the time range set by timespan
;   frequency_dependent = get frequecy-dependent sensitivity and phase difference
;            (frequency [Hz], sensitivity (H,D,Z) [V/nT], and phase_difference (H,D,Z) [deg])
;   /time_pulse, get time pulse
;
; EXAMPLE:
;   erg_load_gmag_stel_induction, site='msr sta', $
;         trange=['2008-02-28/00:00:00','2008-02-28/02:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/magne/
;
; Written by: Y. Miyashita, Jan 23, 2011
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
; Changed from original load procedure to the alias, by S. Kurita,
;        Nov. 20, 2017.
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

pro erg_load_gmag_stel_induction, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip, $
        frequency_dependent=frequency_dependent, time_pulse=time_pulse

erg_load_gmag_isee_induction, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip, $
        frequency_dependent=frequency_dependent, time_pulse=time_pulse

return
end
