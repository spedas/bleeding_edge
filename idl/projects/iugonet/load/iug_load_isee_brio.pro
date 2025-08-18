;+
; PROCEDURE: IUG_LOAD_ISEE_BRIO
;
; PURPOSE:
;   Loads the broadbeam riometer data obtained from ISEE riometer network.
;
; NOTE: This procedure is a simple alias to "erg_load_isee_brio"
;   and calls the original one by just providing the same
;   arguments/keywords given.
;   Some load procedures for the ground-based observational data
;   in the  ERG mission, named "erg_load_???", can be also called
;   by "iug_load_???", because these data are related to the both
;   ERG and IUGONET projects.
;   For more information, see http://www.iugonet.org/
;                         and https://ergsc.isee.nagoya-u.ac.jp/index.shtml.en
;   See the rules of the road.
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_brio_isee, site='',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['ath', 'hus']
;           or a single string delimited by spaces, e.g., 'ath hus'.
;           Available sites as of July, 2017 : ath, kap, gak, hus
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose: set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   iug_load_isee_brio, site='ath', $
;                 trange=['2017-03-20/00:00:00','2017-03-21/00:00:00']
;
; Written by: Y.-M Tanaka, Dec. 1, 2017 (ytanaka at nipr.ac.jp)
;
;-

pro iug_load_isee_brio, site=site, trange=trange, $
      verbose=verbose, downloadonly=downloadonly, $
            no_download=no_download

erg_load_isee_brio, site=site, trange=trange, $
      verbose=verbose, downloadonly=downloadonly, $
            no_download=no_download

end
