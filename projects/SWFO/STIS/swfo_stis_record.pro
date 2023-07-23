;$LastChangedBy: $
;$LastChangedDate:  $
;$LastChangedRevision:  $
;$URL:  $

pro swfo_stis_record, debug=debug

  run_proc = 0
  station = 'S0'
  swfo_stis_load,station = 'S0',file_type ='gsemsg',run_proc=run_proc,trange=0,/no_exec,opts=opts_gsemsg
  swfo_stis_load,station = 'S0',file_type ='cmblk',run_proc=run_proc,trange=0,/no_exec, opts=opts_cmblk
  swfo_stis_load,station = 'S0',file_type ='ccsds',run_proc=run_proc,trange=0,/no_exec, opts=opts_ccsds
  ;swfo_stis_load,station = 'S0',file_type ='sccsds',run_proc=run_proc,trange=0,/no_exec, opts=opts_sccsds
  

  if keyword_set(debug) then stop



end