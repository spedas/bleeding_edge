pro thm_file_download2,trange=trange,probes=probes,verbose=verbose,level=level,dates=dates


if keyword_set(dates) then begin
  for i=0,n_elements(dates)-1 do thm_file_download2,trange=dates[i],probes=probes,level=level
  return
endif


thm_init & !themis.use_wget=1   ; uncomment to use experimental wget routine instead of file_http_copy (not recommended)
;!themis.nowait = 1

level='l1'


thm_load_fit,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level
thm_load_sst,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level
thm_load_esa_pkt,probe=probes,trange=trange,/downloadonly,verbose=verbose;,level=level
;thm_load_esa,probe=probes,trange=trange,/downloadonly,verbose=verbose;,level=level
thm_load_hsk,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level
thm_load_state2,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level
thm_load_mom,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level
thm_load_fgm,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level
;thm_load_efi,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level
;thm_load_scm,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level
;thm_load_bau,probe=probes,trange=trange,/downloadonly,verbose=verbose,level=level

level='l2'
;thm_load_fgm,probe=probes,trange=trange,/downloadonly,verbose=verbose,level='l2'


end
