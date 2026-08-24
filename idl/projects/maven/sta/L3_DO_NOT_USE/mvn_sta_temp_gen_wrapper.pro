
  trange = ['2018-04-01','2018-04-04']

; Send mail to myself that processing has started

  uinfo = get_login_info()
  mailto = 'gwen.hanley@berkeley.edu'

  ofile = 'tgen_email_msg.txt'
  openw, lun, ofile, /get_lun
  printf, lun, 'Time range: ' + trange[0] + ' to ' + trange[1]
  free_lun, lun
  file_chmod, ofile, '664'o

  subj = 'STATIC temperature generation started on ' + uinfo.machine_name
  cmd = 'mailx -s "' + subj + '" ' + mailto + ' < ' + ofile
  spawn, cmd

; Call the processing routine

    ndays = ceil((time_double(trange[1]) - time_double(trange[0]))/86400d)
    for nd=0,ndays-1 do $
      date=time_string( time_double(trange[0])+nd*86400d,prec=-3) & $
      mvn_sta_l3_top,date,den=1,temp=1,tmpdir='/disks/data/maven/data/sci/sta/l3/' & $
      if (nd lt (ndays-1)) then store_data,'*',/delete 
    
  ;mvn_sta_temp_gen, trange, /phobos

; Send mail to myself that processing has finished

  subj = 'STATIC temperature generation finished on ' + uinfo.machine_name
  cmd = 'mailx -s "' + subj + '" ' + mailto + ' < ' + ofile
  spawn, cmd
  file_delete, ofile

  exit

;end
