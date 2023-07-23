pro spp_fld_dcb_memory_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_dcb_memory_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  get_data, 'spp_fld_dcb_memory_CCSDS_Sequence_Number', dat = d_seq

  if size(/type, d_seq) NE 8 then return

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

  start_ind = where(d_seq.y EQ 1 and $
    d_adr.y EQ 133174 and $
    d_nbytes.y EQ 64, start_count)

  if start_count GT 0 then begin

    rts_str = strarr(start_count)
    ats_str = strarr(start_count)

    for i = 0, start_count - 1 do begin

      rts_str[i] = (string(to_hex(d_dump.y[start_ind[i],07:08]), $
        format = '(A2)')).Join()
      ats_str[i] = (string(to_hex(d_dump.y[start_ind[i],09:10]), $
        format = '(A2)')).Join()
        
    endfor

    store_data, 'spp_fld_dcb_memory_RTS_chk', $
      data = {x:d_seq.x[start_ind], y:rts_str}
    store_data, 'spp_fld_dcb_memory_ATS_chk', $
      data = {x:d_seq.x[start_ind], y:ats_str}

    options, 'spp_fld_dcb_memory_?TS_chk', 'tplot_routine', 'strplot'
    options, 'spp_fld_dcb_memory_?TS_chk', 'charsize', 1.15
    options, 'spp_fld_dcb_memory_?TS_chk', 'orientation', 0.
    options, 'spp_fld_dcb_memory_?TS_chk', 'yticks', 1
    options, 'spp_fld_dcb_memory_?TS_chk', 'yrange', [-0.5,1]
    options, 'spp_fld_dcb_memory_?TS_chk', 'ytickname', [' ',' ']
    options, 'spp_fld_dcb_memory_?TS_chk', 'panel_size', 0.5
    
    options, 'spp_fld_dcb_memory_RTS_chk', 'ytitle', 'RTS!CCHK'
    options, 'spp_fld_dcb_memory_ATS_chk', 'ytitle', 'ATS!CCHK'


  endif


end