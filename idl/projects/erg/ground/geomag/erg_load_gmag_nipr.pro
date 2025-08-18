;+
; PROCEDURE: ERG_LOAD_GMAG_NIPR
;   erg_load_gmag_nipr, site = site, $
;                     datatype=datatype, $
;                     trange=trange, $
;                     verbose=verbose, $
;                     downloadonly=downloadonly
;                     no_download=no_download
;
; PURPOSE:
;   Loads the fluxgate magnetometer data obtained by NIPR.
;
; NOTE: This procedure is a simple alias to "iug_load_gmag_nipr" 
;   and calls the original one by just providing the same 
;   arguments/keywords given.
;   Some load procedures for the ground-based observational data in 
;   the IUGONET projetct, named "iug_load_???", can be also called  
;   by "erg_load_???", because these data are related to the both 
;   ERG and IUGONET projects.
;   For more information, see http://www.iugonet.org/en/ 
;                         and http://gemsissc.stelab.nagoya-u.ac.jp/erg/
;
; KEYWORDS:
;   site  = Observatory name, example, erg_load_gmag_nipr, site='syo',
;           the default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['syo', 'hus']
;           or a single string delimited by spaces, e.g., 'syo hus'.
;           Available sites: syo hus tjo aed isa
;   datatype = Time resolution. Please notice that '1sec' means nearly
;           1-sec time resolution. Even if datatype was set to '1sec', 
;           the time resolution corresponds to
;           2sec : syo(1981-1997), hus & tjo(1984-2001/08), isa(1984-1989), 
;                  aed(1989-1999/10)
;           1sec : syo(1997-present)
;           0.5sec  : hus & tjo(2001/09-present), aed(2001/09-2008/08)
;           Available datatype: 1sec(default) or 20hz
;   trange = (Optional) Time range of interest  (2 element array).
;   /verbose : set to output some useful info
;   /downloadonly: if set, then only download the data, do not load it 
;           into variables.
;   /no_download: use only files which are online locally.
;
; EXAMPLE:
;   erg_load_gmag_nipr, site='syo', $
;                 trange=['2003-11-20/00:00:00','2003-11-21/00:00:00']
;
; Written by Y.-M. Tanaka, December 24, 2010 (ytanaka at nipr.ac.jp)
; Changed from original load procedure to the alias, by Y.-M Tanaka, 
;        July 24, 2012.
;-

;*****************************************************
;*** Load procedure for fluxgate magnetometer data ***
;***                obtained by NIPR               ***
;*****************************************************
pro erg_load_gmag_nipr, site=site, datatype=datatype, fproton=fproton, $
  trange=trange, verbose=verbose, downloadonly=downloadonly, $
  no_download=no_download

iug_load_gmag_nipr, site=site, datatype=datatype, fproton=fproton, $
  trange=trange, verbose=verbose, downloadonly=downloadonly, $
  no_download=no_download

end

