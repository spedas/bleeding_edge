;+
; Procedure:
;  sosmag_crib
;
; Purpose:
;  Demonstrate how to load and plot KOMPSAT data.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2024-11-09 15:31:36 -0800 (Sat, 09 Nov 2024) $
;$LastChangedRevision: 32939 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kompsat/examples/kompsat_crib.pro $
;-


pro kompsat_crib

  ; Each user has to register at https://swe.ssa.esa.int/hapi/
  ; Then the user must save the username and password in the file kompsat_password.txt

  ; Check if the ESA server password can be read.
  kompsat_read_password, username=username, password=password
  if ~keyword_set(username) || ~keyword_set(password) || username eq '' || password eq '' then begin
    print, 'Cannot read username or password. Please check file kompsat_password.txt.
    return
  endif else begin
    print, 'Username and password were successfully loaded from kompsat_password.txt.
  endelse


  ; Now load some KOMPSAT data and plot it.

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