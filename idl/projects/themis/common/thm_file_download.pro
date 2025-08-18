;+
;PROCEDURE:  thm_file_download
;PURPOSE:  This is a general purpose routine will download all THEMIS data files within
; a given time range.
;  It looks for all procedures that match: "thm_load_*.pro" and executes them with the /DOWNLOADONLY keyword set.
;
; Warning -  This is a BETA  routine and may be deleted in a future release.
; 23-may-2008, cg, added optional keyword /either to the call to
;                  resolve_routine
;-
pro  thm_file_download
    libs,'thm_load_*',routine_names=rtns
    resolve_routine,rtns,/no_recompile, /either

    for i=0,n_elements(rtns)-1 do begin
        proc_info = routine_info(rtns[i],/parameters)
        if proc_info.num_kw_args eq 0 then continue
        if total(/pres,strmatch(proc_info.kw_args,'DOWNLOADONLY')) gt 0 then begin
           if total(/pres,strmatch(proc_info.kw_args,'SITE')) gt 0 then begin
              dprint,'Executing: "'+rtns[i]+'"'
              call_procedure, rtns[i],SITE='all', /downloadonly
           endif else if $
              total(/pres,strmatch(proc_info.kw_args, 'PROBE')) gt 0 then begin
              dprint,'Executing: "'+rtns[i]+'"'
              call_procedure, rtns[i],PROBE='all', /downloadonly
           endif
        endif

    endfor
end

