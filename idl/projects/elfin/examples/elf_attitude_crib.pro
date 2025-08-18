;+
; ELF attitude crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to clrussell@igpp.ucla.edu
;
;
; $LastChangedBy: clrussell $
; $LastChangedDate: 2016-05-25 14:40:54 -0700 (Wed, 25 May 2016) $
; $LastChangedRevision: 21203 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elf/examples/basic/mms_load_state_crib.pro $
;-
pro elf_attitude_crib
  ;;    =================================
  ;; 1) Select date and time interval
  ;;    =================================
  ; download data for 7/21/2019
  date = '2020-07-04/00:00:00'
  timespan,date,1,/day
  tr=timerange()

  ;;    =================================
  ;; 2) Select probe
  ;;    =================================
  probe = 'a'

  ;;    =================================
  ;; 3) Get attitude
  ;;    =================================
  elf_get_att, probe=probe, trange=tr
  tplot_names
  print, ''
  print, 'Note there are 6 attitude variables and 4 spin variables.
  print, ''
  stop

  ; quick look at some of the tplot vars returned
  get_data, 'ela_att_gei', data=att
  get_data, 'ela_att_solution_date', data=date_soln
  get_data, 'ela_spin_sun_ang', data=sun_ang
help, att, date_soln, sun_ang
stop
  print, ''
  print, 'ATTITUDE VECTOR'
  print, time_string(att.x)
  print, att.y
  print, ''
  print, 'DATE OF LAST ATTITUDE SOLUTION'
  print, time_string(date_soln.x)
  print, ''
  print, 'SPIN SUN ANGLE'
  print, time_string(sun_ang.x)
  print, sun_ang.y
  stop

  ;;    =================================
  ;; 4) Get attitude for ELFIN B
  ;;    =================================
  elf_get_att, probe='b'
  tplot_names
  stop

  ;;    ========================================
  ;; 5) Retrieve attitude using elf_load_state
  ;;    ========================================
  ;delete existing elfin tvars first
  del_data, 'el*'
  elf_load_state, probe='a', trange=tr
  tplot_names
  stop


end