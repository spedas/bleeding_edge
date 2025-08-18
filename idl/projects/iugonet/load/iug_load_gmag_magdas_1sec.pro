;+
; PROCEDURE: iug_load_gmag_magdas_1sec
;
; PURPOSE:
;   To load the MAGDAS geomagnetic data from the STEL ERG-SC site 
;
; NOTE: This procedure is a simple alias to "erg_load_gmag_magdas_1sec" 
;   and calls the original one by just providing the same 
;   arguments/keywords given.
;   Some load procedures for the ground-based observational data 
;   in the  ERG mission, named "erg_load_???", can be also called  
;   by "iug_load_???", because these data are related to the both 
;   ERG and IUGONET projects.
;   For more information, see http://www.iugonet.org/en/ 
;                         and http://gemsissc.stelab.nagoya-u.ac.jp/erg/
;   See the rules of the road.
;   For more information, see http://magdas.serc.kyushu-u.ac.jp/
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_magdas_1sec, site='asb',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['asb', 'onw']
;           or a single string delimited by spaces, e.g., 'asb onw'.
;           Sites for 1 sec data:  
;              asb ...
;           Sites for 1 min/h data:
;              ...
;   datatype = Time resolution. '1sec' for 1 sec', '1min' for 1 min, and '1h' for 1 h.
;              The default is 'all'.  If you need two of them, set to 'all'.
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;
; EXAMPLE:
;   iug_load_gmag_magdas_1sec, site='asb onw', datatype='1sec', $
;                        trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; Written by: Y.-M Tanaka, Feb. 5, 2014 (ytanaka at nipr.ac.jp)
;
;-

pro iug_load_gmag_magdas_1sec, site=site, datatype=datatype, $
	downloadonly=downloadonly, no_server=no_server, $
	verbose=verbose, $
	no_download=no_download, range=trange

erg_load_gmag_magdas_1sec, site=site, datatype=datatype, $
	downloadonly=downloadonly, no_server=no_server, $
	verbose=verbose, $
	no_download=no_download, range=trange

end
