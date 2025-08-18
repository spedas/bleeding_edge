FUNCTION dotp,v,w            ;   array(N) = dotp(array1(N,M),array2(N,M))
                             ;or array(N) = dotp(array1(N,M),array2(M)  )
                             ;or array(N) = dotp(array1(M  ),array2(N,M))
  vv = reform(v)
  ww = reform(w)
  sv = size(vv)
  sw = size(ww)
  IF (sv(0) NE 1 AND sv(0) NE 2) OR (sw(0) NE 1 AND sw(0) NE 2) THEN $
    GOTO,size_error

  IF sv(0) NE sw(0) THEN BEGIN 
    m = 2
    IF sw(0) EQ 1 THEN BEGIN 
      IF sw(1) NE sv(2) THEN GOTO,size_error
      ww = ww ## make_array(sv(1),value=ww(0)-ww(0)+1) 
    ENDIF ELSE BEGIN                ;sv(0) eq 1
      IF sv(1) NE sw(2) THEN GOTO,size_error
      vv = vv ## make_array(sw(1),value=vv(0)-vv(0)+1)
    ENDELSE 
  ENDIF ELSE BEGIN 
    m = sv(0)                       ;m = 1 or 2
    FOR i=1,m DO IF sv(i) NE sw(i) THEN GOTO,size_error
  ENDELSE 

  return,total(vv*ww,m)

size_error:
  print,string2('dotp: ')+'inputs have incompatible sizes:'
  return,!values.f_nan
  
END

;i used make_array because using the keyword VALUE preserves the array type
;try findgen(3)##[1,1,1,1,1] to see what dotp(findgen(5,3),findgen(3)) would do

