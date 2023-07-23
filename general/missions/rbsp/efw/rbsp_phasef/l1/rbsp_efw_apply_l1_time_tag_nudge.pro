;+
; Shift the EFW time tag backward in time by the data cadence.
; This is needed b/c the timg tags are off by 1/16 or 1/32 sec.
;-

pro rbsp_efw_apply_l1_time_tag_nudge, l1_var

;---Shift time tags.
    get_data, l1_var, times, data
    time_step = sdatarate(times)
    store_data, l1_var, times-time_step, data

end
