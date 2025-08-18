;+
; PROCEDURE: IUG_LOAD_ISEE_VLF
;
; PURPOSE:
;   To load VLF spectrum data obtained by ISEE ELF/VLF network from the ISEE ERG-SC site
;
; NOTE: This procedure is a simple alias to "erg_load_isee_vlf"
;   and calls the original one by just providing the same
;   arguments/keywords given.
;   Some load procedures for the ground-based observational data
;   in the  ERG mission, named "erg_load_???", can be also called
;   by "iug_load_???", because these data are related to the both
;   ERG and IUGONET projects.
;   For more information, see http://www.iugonet.org/
;                         and https://ergsc.isee.nagoya-u.ac.jp/index.shtml.en
;   See the rules of the road.
;   For more information, see http://stdb2.isee.nagoya-u.ac.jp/vlf/
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_isee_vlf, site='ath',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['ath', 'kap']
;           or a single string delimited by spaces, e.g., 'ath kap'.
;           Available sites as of July, 2017 : ath, kap
;   downloadonly : if set, then only download the data, do not load it into variables.
;   no_server : use only files which are online locally.
;   no_download : use only files which are online locally. (Identical to no_server keyword.)
;   trange : Time range of interest  (2 element array).
;   timeclip :  if set, then data are time clipped.
;
;   cal_gain : if set, frequency-dependent gain of the antenna system is calibrated.
;              The unit of gain G(f) is V/T, and calibrated spectral power P(f)
;              at frequecy f is computed as
;
;               P(f) = S(f)/ (G(f)^2) [nT^2/Hz],
;
;              where S(f) is uncaibrated spectral power in unit of V^2/Hz.
;
; EXAMPLE:
;   iug_load_isee_vlf, site='ath', $
;         trange=['2015-03-17/00:00:00','2015-03-17/02:00:00']
;
; Written by: Y.-M Tanaka, Dec. 1, 2017 (ytanaka at nipr.ac.jp)
;
;-

pro iug_load_isee_vlf, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip,cal_gain=cal_gain

erg_load_isee_vlf, site=site, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip,cal_gain=cal_gain

end
