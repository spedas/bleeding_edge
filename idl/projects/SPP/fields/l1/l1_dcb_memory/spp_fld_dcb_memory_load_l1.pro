pro spp_fld_dcb_memory_load_l1, file, prefix = prefix, varformat = varformat
  compile_opt idl2

  if not keyword_set(prefix) then prefix = 'spp_fld_dcb_memory_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  get_data, 'spp_fld_dcb_memory_CCSDS_Sequence_Number', dat = d_seq

  if size(/type, d_seq) ne 8 then return

  get_data, 'spp_fld_dcb_memory_CCSDS_MET_Seconds', dat = d_sec
  get_data, 'spp_fld_dcb_memory_CCSDS_MET_SubSeconds', dat = d_ssec
  get_data, 'spp_fld_dcb_memory_DUMPADR', dat = d_adr
  get_data, 'spp_fld_dcb_memory_nbytes_dump', dat = d_nbytes
  get_data, 'spp_fld_dcb_memory_DUMP', dat = d_dump

  ;
  ; At startup, the DCB produces a small memory dump which contains
  ; the current ATS and RTS checksums. The following commands store the
  ; checksums as a TPLOT string variable.
  ;

  start_ind = where(d_seq.y eq 1 and $
    d_adr.y eq 133174 and $
    d_nbytes.y eq 64, start_count)

  if start_count gt 0 then begin
    rts_str = strarr(start_count)
    ats_str = strarr(start_count)

    for i = 0, start_count - 1 do begin
      rts_str[i] = (string(TO_HEX(d_dump.y[start_ind[i], 07 : 08]), $
        format = '(A2)')).join()
      ats_str[i] = (string(TO_HEX(d_dump.y[start_ind[i], 09 : 10]), $
        format = '(A2)')).join()
    endfor

    store_data, 'spp_fld_dcb_memory_RTS_chks', $
      data = {x: d_seq.x[start_ind], y: rts_str}
    store_data, 'spp_fld_dcb_memory_ATS_chks', $
      data = {x: d_seq.x[start_ind], y: ats_str}
  endif

  dmpchk_ind = where(d_adr.y eq 135412 and $
    d_nbytes.y eq 36, dmpchk_count)

  if dmpchk_count gt 0 then begin
    rts_str = strarr(dmpchk_count)
    ats_str = strarr(dmpchk_count)

    for i = 0, dmpchk_count - 1 do begin
      rts_str[i] = '!A' + (string(TO_HEX(d_dump.y[dmpchk_ind[i], 07 : 08]), $
        format = '(A2)')).join()
      ats_str[i] = '!A' + (string(TO_HEX(d_dump.y[dmpchk_ind[i], 09 : 10]), $
        format = '(A2)')).join()
    endfor

    store_data, 'spp_fld_dcb_memory_RTS_chkd', $
      data = {x: d_seq.x[dmpchk_ind], y: rts_str}
    store_data, 'spp_fld_dcb_memory_ATS_chkd', $
      data = {x: d_seq.x[dmpchk_ind], y: ats_str}

    options, 'spp_fld_dcb_memory_?TS_chkd', 'color', 6
  endif

  if start_count gt 0 or dmpchk_count gt 0 then begin
    store_data, 'spp_fld_dcb_memory_RTS_chk', $
      data = tnames('spp_fld_dcb_memory_RTS_chk?')
    store_data, 'spp_fld_dcb_memory_ATS_chk', $
      data = tnames('spp_fld_dcb_memory_ATS_chk?')
  endif

  if (tnames('spp_fld_dcb_memory_?TS_chk*'))[0] ne '' then begin
    options, 'spp_fld_dcb_memory_?TS_chk*', 'tplot_routine', 'strplot'
    options, 'spp_fld_dcb_memory_?TS_chk*', 'charsize', 1.15
    options, 'spp_fld_dcb_memory_?TS_chk*', 'orientation', 0.
    options, 'spp_fld_dcb_memory_?TS_chk*', 'yticks', 1
    options, 'spp_fld_dcb_memory_?TS_chk*', 'yrange', [-0.5, 1]
    options, 'spp_fld_dcb_memory_?TS_chk*', 'ytickname', [' ', ' ']
    options, 'spp_fld_dcb_memory_?TS_chk*', 'panel_size', 0.5

    options, 'spp_fld_dcb_memory_RTS_chk*', 'ytitle', 'RTS!CCHK'
    options, 'spp_fld_dcb_memory_ATS_chk*', 'ytitle', 'ATS!CCHK'
  endif
end