;+
; Procedure:
;  sosmag_crib
;
; Purpose:
;  Demonstrate how to load and plot SOSMAG data.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2023-09-05 16:26:53 -0700 (Tue, 05 Sep 2023) $
;$LastChangedRevision: 32080 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/sosmag/hapi/sosmag_crib.pro $
;-


pro sosmag_crib

  ; Each user has to register at https://swe.ssa.esa.int/hapi/
  ; Then the user must save the username and password in the file sosmag_password.txt

  ; Check if the sosmag password can be read.
  sosmag_read_password, username=username, password=password
  if ~keyword_set(username) || ~keyword_set(password) || username eq '' || password eq '' then begin
    print, 'Cannot read username or password. Please check file sosmag_password.txt.
    return
  endif else begin
    print, 'Username and password were successfully loaded from sosmag_password.txt.
  endelse

  ; SOSMAG data resides in a HAPI server. Check if the server is alive.
  hquery = 'capabilities'
  sosmag_hapi_query, hquery=hquery, query_response=query_response
  if query_response eq '' or query_response eq '-1' then begin
    print, 'There was an error communicating with the HAPI server.
    return
  endif else begin
    print, 'Communication with the ESA HAPI server was successfully established.
  endelse

  ; Now load some SOSMAG data and plot it.

  ; Delete any previous data (if needed).
  ;del_data, '*'

  ; Define a date:
  trange = ['2021-01-23/00:00:00', '2021-01-24/00:00:00']

  ; Get data.
  sosmag_load_data, trange=trange

  ; Print the names of loaded data.
  print, 'Tplot variables loaded:', tnames('sosmag*')

  ; Plot the loaded SOSMAG variables.
  tplot, tnames('sosmag*')

end