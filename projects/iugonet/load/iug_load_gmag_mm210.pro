;+
; PROCEDURE: iug_load_gmag_mm210
;   to load the 210 MM geomagnetic data from the STEL ERG-SC site 
;
; NOTE: This procedure is a simple alias to "erg_load_gmag_mm210" 
;   and calls the original one by just providing the same 
;   arguments/keywords given.
;   Some load procedures for the ground-based observational data 
;   in the  ERG mission, named "erg_load_???", can be also called  
;   by "iug_load_???", because these data are related to the both 
;   ERG and IUGONET projects.
;   For more information, see http://www.iugonet.org/en/ 
;                         and http://gemsissc.stelab.nagoya-u.ac.jp/erg/
;   See the rules of the road.
;   For more information, see http://stdb2.stelab.nagoya-u.ac.jp/mm210/
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_gmag_mm210, site='rik',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['rik', 'onw']
;           or a single string delimited by spaces, e.g., 'rik onw'.
;           Sites:  tik zgn yak irt ppi bji lnp mut ptn wtk
;                   lmt kat ktn chd zyk mgd ptk msr rik onw
;                   kag ymk cbi gua yap kor ktb bik wew daw
;                   wep bsv dal can adl kot cst ewa asa mcq
;   datatype = Time resolution. '1min' for 1 min, and '1h' for 1 h.
;              The default is '1min'.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   trange = (Optional) Time range of interest  (2 element array).
;
; EXAMPLE:
;   iug_load_gmag_mm210, site='rik onw', datatype='1min', $
;                        trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; Written by: Y.-M Tanaka, Apr 22, 2010 (ytanaka at nipr.ac.jp)
;
;   $LastChangedBy: jwl $
;   $LastChangedDate: 2014-01-22 15:54:40 -0800 (Wed, 22 Jan 2014) $
;   $LastChangedRevision: 13976 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/iugonet/load/iug_load_gmag_mm210.pro $
;-

pro iug_load_gmag_mm210, site=site, datatype=datatype, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

erg_load_gmag_mm210, site=site, datatype=datatype, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

end
