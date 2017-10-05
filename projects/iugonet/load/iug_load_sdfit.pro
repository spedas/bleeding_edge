;+
; PROCEDURE: iug_load_sdfit
;
; PURPOSE:
;    Load fitacf CDF files of SuperDARN as tplot variables.
;
; NOTE: This procedure is a simple alias to "erg_load_sdfit" 
;   and calls the original one by just providing the same 
;   arguments/keywords given.
;   Some load procedures for the ground-based observational data 
;   in the  ERG mission, named "erg_load_???", can be also called  
;   by "iug_load_???", because these data are related to the both 
;   ERG and IUGONET projects.
;   For more information, see http://www.iugonet.org/en/ 
;                         and http://gemsissc.stelab.nagoya-u.ac.jp/erg/
;
; :KEYWORDS:
;    sites: 3-letter code of SD radar name. 
;           Currently only the following station codes work: 
;                 'ade', 'adw', 'bks', 'cly', 'cve', 'cvw', 'dce', 'fhe', 
;                  'fhw', 'gbr', 'hal', 'han', 'hok', 'inv', 'kap', 'kod', 
;                  'ksr', 'pgr', 'pyk', 'rkn', 'san', 'sas', 'sto', 'sye', 
;                  'sys', 'tig', 'unw', 'wal', 'zho' 
;    cdffn: File path of a CDF file if given explicitly. 
;    get_support_data: Turn this on to load the supporting data 
;    trange: time range for which data are loaded. 
;            e.g., ['2008-10-01/00:00:00','2008-10-02/00:00:00'] 
;
; :AUTHOR: 
;     Tomo Hori (E-mail: horit at stelab.nagoya-u.ac.jp)
; :HISTORY:
;   2010/03/09: Created as a draft version
;   2010/07/01: now work for hok and ksr
;   2010/09/10: added some keywords
;
;---------------------------------------------------------------------------
;!!!!! NOTICE !!!!!
;The common time fitacf data of SuperDARN in CDF are distributed
;by Energization and Radiation in Geospace Science Center (ERG-SC) at
;Solar-Terrestrial Environment Laboratory, Nagoya University, in
;collaboration with the SuperDARN PI groups.
;
;It is required for users to read carefully and follow 
;the rules of the road attached to the CDF files upon using the data for 
;his/her scientific researches. 
;
;As for questions and request for the data, please feel free to contact
;the ERG-SC office (E-mail:  erg-sc-core at st4a.stelab.nagoya-u.ac.jp,
;please replace "at" by "@").
;------------------------------------------------------------------------------
;
; Written by: Y.-M Tanaka, Feb. 5, 2014 (ytanaka at nipr.ac.jp)
;
;-

pro iug_load_sdfit, sites=sites, cdffn=cdffn, $
  get_support_data=get_support_data, $
  noacknowledgment=noacknowledgment, trange=trange, $
  downloadonly=downloadonly, no_download=no_download, $
  compact=compact

erg_load_sdfit, sites=sites, cdffn=cdffn, $
  get_support_data=get_support_data, $
  noacknowledgment=noacknowledgment, trange=trange, $
  downloadonly=downloadonly, no_download=no_download, $
  compact=compact

end
