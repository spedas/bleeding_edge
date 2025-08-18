;+
; PROCEDURE: erg_load_gmag_stel_fluxgate
;
; PURPOSE:
;   To load the STEL fluxgate geomagnetic data from the STEL ERG-SC site
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_gmag_stel_fluxgate, site='msr',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['msr', 'kag']
;           or a single string delimited by spaces, e.g., 'msr kag'.
;           Sites for 1 sec data:
;              msr rik kag ktb
;           Sites for 1 min/h data:
;              msr rik kag ktb mdm tew
;   datatype = Time resolution. '1sec' for 1 sec', '1min' for 1 min, and '1h' for 1 h.
;              The default is 'all'.  If you need two of them, set to 'all'.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /timeclip, if set, then data are clipped to the time range set by timespan
;
; EXAMPLE:
;   erg_load_gmag_stel_fluxgate, site='msr kag', datatype='1min', $
;       trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; NOTE: See the rules of the road.
;       For more information, see http://stdb2.isee.nagoya-u.ac.jp/magne/
;       and http://www1.osakac.ac.jp/crux/ (for mdm and tew).
;
; Written by: Y. Miyashita, Jun 19, 2013
;             ERG-Science Center, ISEE, Nagoya Univ.
;             erg-sc-core at isee.nagoya-u.ac.jp
;
; Changed from original load procedure to the alias, by S. Kurita,
;        Nov. 20, 2017.
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;-

pro erg_load_gmag_stel_fluxgate, site=site, datatype=datatype, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

erg_load_gmag_isee_fluxgate, site=site, datatype=datatype, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

return
end
