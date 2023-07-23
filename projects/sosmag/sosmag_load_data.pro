;+
; Procedure:
;  sosmag_load_data
;
; Purpose:
;  Load SOSMAG data.
;
; Keywords:
;     server:     Server to use. Default is HAPI.
;     trange:     Time range of interest (array with 2 elements, start and end time)
;     dataset:    Two datasets are available: recalibrated (default) and 1-min:
;                      'spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_recalib'
;                      'spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_1m'
;     recalib:    If 1 then select recalibrated dataset, if 0 select 1-min dataset
;     prefix:     String to append to the beginning of the loaded tplot variables
;     tplotnames: Array of strings with the tplot variables that were loaded.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2021-12-13 16:22:55 -0800 (Mon, 13 Dec 2021) $
;$LastChangedRevision: 30466 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/sosmag/sosmag_load_data.pro $
;-


pro sosmag_load_data, server=server, trange=trange, dataset=dataset, recalib=recalib, tplotnames=tplotvars, prefix=prefix
  ; Load SOSMAG data.
  ; Currently only HAPI server access is availble but in the future thismay change.

  compile_opt idl2

  if ~keyword_set(server) then server='hapi'

  if server eq 'hapi' then begin
    sosmag_hapi_load_data, trange=trange, dataset=dataset, recalib=recalib, tplotnames=tplotvars, prefix=prefix
  endif

end