pro mav_log_message_handler,control=control,cmnblk
common mav_log_message_handler_com, print_control
    if n_elements(control) ne 0 then print_control = control
    if not keyword_set(cmnblk) then return

    str = string(cmnblk.buffer)
    if keyword_set(print_control) && ~array_equal(cmnblk.buffer,[10b]) then $
        dprint,dlevel=2,strjoin(string(/print,time_string(cmnblk.time),'  ',cmnblk.data_size,' ',cmnblk.seq_cntr,'  ',str))

;    str = string(cmnblk.buffer)
;    if keyword_set(print_control) then $
;        dprint,dlevel=2,time_string(cmnblk.time),'  ',cmnblk.data_size,' ',cmnblk.seq_cntr,'  ',str

end