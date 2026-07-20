function mms_tai2unix, tinput

  ; The generic routine returns double precision unix times, which need no further conversion here
  
  return,spd_tai2unix(tinput)

end