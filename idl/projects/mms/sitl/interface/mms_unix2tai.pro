function mms_unix2tai, tinput

; Call generic spd_unix2tai, then convert to long integers

tai_times = spd_unix2tai(tinput)

return, ulong(tai_times)

end