;+
; PROCEDURE: iug_load_gmag_stel_fluxgate
;   To load the STEL fluxgate geomagnetic data from the STEL ERG-SC site 
;
; NOTE: This procedure is a simple alias to "erg_load_gmag_stel_fluxgate" 
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
;   and http://www1.osakac.ac.jp/crux/ (for mdm and tew).
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_gmag_stel_fluxgate, site='msr',
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
;   iug_load_gmag_stel_fluxgate, site='msr kag', datatype='1min', $
;       trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; Written by: Y.-M Tanaka, Feb. 5, 2014 (ytanaka at nipr.ac.jp)
;
;-

pro iug_load_gmag_stel_fluxgate, site=site, datatype=datatype, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

erg_load_gmag_stel_fluxgate, site=site, datatype=datatype, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

end
