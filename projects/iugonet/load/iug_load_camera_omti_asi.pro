;+
; PROCEDURE: iug_load_camera_omti_asi
;
; PURPOSE:
;   To load the OMTI ASI data from the STEL ERG-SC site 
;
; NOTE: This procedure is a simple alias to "iug_load_camera_omti_asi"
;   and calls the original one by just providing the same
;   arguments/keywords given.
;   Some load procedures for the ground-based observational data
;   in the  ERG mission, named "erg_load_???", can be also called
;   by "iug_load_???", because these data are related to the both
;   ERG and IUGONET projects.
;   For more information, see http://www.iugonet.org/en/
;                         and http://gemsissc.stelab.nagoya-u.ac.jp/erg/
;   See the rules of the road.
;   For more information, see http://stdb2.stelab.nagoya-u.ac.jp/omti/
;
; KEYWORDS:
;   site  = Observatory name, example, iug_load_camera_omti_asi, site='sgk'.
;           The default is 'all', i.e., load all available stations.
;           This can be an array of strings, e.g., ['sgk', 'sta']
;           or a single string delimited by spaces, e.g., 'sgk sta'.
;           Sites: ith rsb trs ath mgd ptk rik sgk sta yng drw ktb syo
;   wavelength = Wavelength in Angstrom, i.e., 5577, 6300, 7200, 7774, 5893, etc.
;                The default is 5577. This can be an array of integers, e.g., [5577, 6300]
;                or strings, e.g., '5577', '5577 6300', and ['5577', '6300'].
;   /downloadonly, if set, then only download the data, do not load it into variables.
;   /no_server, use only files which are online locally.
;   /no_download, use only files which are online locally. (Identical to no_server keyword.)
;   trange = (Optional) Time range of interest  (2 element array).
;   /timeclip, if set, then data are clipped to the time range set by timespan
;
; EXAMPLE:
;   iug_load_camera_omti_asi, site='sgk', wavelength=5577, trange=['2012-01-01/00:00:00','2012-01-02/00:00:00']
;
; Author: Y. Miyashita, Mar 28, 2013
;         ERG-Science Center, STEL, Nagoya Univ.
;         erg-sc-core at st4a.stelab.nagoya-u.ac.jp
;
; Written by: Y.-M Tanaka, Feb. 5, 2014 (ytanaka at nipr.ac.jp)
;
;-

pro iug_load_camera_omti_asi, $
        site=site, wavelength=wavelength, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

erg_load_camera_omti_asi, $
        site=site, wavelength=wavelength, $
        downloadonly=downloadonly, no_server=no_server, no_download=no_download, $
        trange=trange, timeclip=timeclip

end
