;+
; Procedure:
;  sosmag_crib
;
; Purpose:
;  Demonstrate how to load and plot KOMPSAT data.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2026-06-22 09:10:52 -0700 (Mon, 22 Jun 2026) $
;$LastChangedRevision: 34595 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/examples/kompsat_crib.pro $
;-


pro kompsat_crib

  ; Load some KOMPSAT data and plot it.

  ; Delete any previous data.
  thm_init
  del_data, '*'

  ; Specify a date:
  trange = ['2024-05-11/00:00:00', '2024-05-12/00:00:00']

  ; Get SOSMAG data.
  kompsat_load_data, trange=trange, dataset='recalib'

  ; Print the names of loaded data.
  tplot_names

  ; Plot the loaded variables.
  tplot, tnames('kompsat*')
  stop

  ; Get particle data.
  kompsat_load_data, trange=trange, dataset='p'
  kompsat_load_data, trange=trange, dataset='e'

  ; Print the names of loaded data.
  tplot_names

  ; Plot b-field and particle data
  tplot, ['kompsat_b_gse', 'kompsat_p_all', 'kompsat_e_all']

end