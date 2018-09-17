pro spp_fld_tmlib_select_server, server, server_string = server_string, $
  server_dir = server_dir

  if not keyword_set(server) then begin

    select_server_desc = [ $
      '0, LABEL, Select TMlib server, CENTER', $
      '0, BUTTON, ' + $
      '128.32.147.120  - EM server (rflab.ssl.berkeley.edu)|' + $
      '128.32.147.149  - FM server (spffmdb.ssl.berkeley.edu)|' + $
      '192.168.0.202   - EM server (accessed from inside 214)|' + $
      '192.168.0.203   - FM server (accessed from inside 214)|' + $
      '128.244.182.117 - FM server (I&T)|' + $
      '128.32.13.188   - SPFSOC2 (test),' + $
      'EXCLUSIVE,SET_VALUE=0, TAG=server_select', $
      '2, BUTTON, OK, QUIT, TAG=ok']

    server_form_str = cw_form(select_server_desc, /column)

    case server_form_str.server_select of
      0:server = 'rflab.ssl.berkeley.edu'
      1:server = 'spffmdb.ssl.berkeley.edu'
      2:server = '192.168.0.202'
      3:server = '192.168.0.203'
      4:server = '128.244.182.117'
      5:server = '128.32.13.188'
    endcase

    case server_form_str.server_select of
      0:server_string = 'rflab.ssl.berkeley.edu (EM server)'
      1:server_string = 'spffmdb.ssl.berkeley.edu (FM server)'
      2:server_string = '192.168.0.202 (EM server/LAN)'
      3:server_string = '192.168.0.203 (FM server/LAN)'
      4:server_string = '128.244.182.117 (IT server/LAN)'
      5:server_string = '128.32.13.188 (SPFSOC2)'
    endcase

    case server_form_str.server_select of
      0:server_dir = 'EM_ucb'
      1:server_dir = 'FM_ucb'
      2:server_dir = 'EM_ucb'
      3:server_dir = 'FM_ucb'
      4:server_dir = 'FM_apl'
      5:server_dir = 'FM_ucb'
    endcase

  endif

  defsysv, '!SPP_FLD_TMLIB', exists = exists

  if not keyword_set(exists) then begin

    spp_fld_tmlib_init, server = server

  endif else begin

    !SPP_FLD_TMLIB.server = server
    printdat, !SPP_FLD_TMLIB, /values, varname = '!spp_fld_tmlib'

  endelse

end