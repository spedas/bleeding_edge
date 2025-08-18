;+
;PROCEDURE:   mvn_lpw_prd_lp_iv_cal
;
;
;INPUTS:
; - None directly required by user.
;KEYWORDS:
;  data=data,limit=limit,dlimit=dlimit
;EXAMPLE:
; mvn_lpw_prd_lp_iv_cal,data=data,limit=limit,dlimit=dlimit
;
;CREATED BY:   Michiko Morooka  13-05-14
;FILE:         mvn_lpw_prd_lp_iv_cal.pro
;VERSION:      0.0
;LAST MODIFICATION:
;
;-

pro mvn_lpw_prd_lp_iv_cal,data=data,limit=limit,dlimit=dlimit
  ;--------------------- Constants ------------------------------------
  t_routine=SYSTIME(0)
  pdr_ver= 'pdr_lp_iv_cal_ver 0.0'
  ;--------------------
  
  x = data.x & y = data.y & v = data.v
  dy = data.dy & dv = data.dv
  good = make_array(n_elements(x),/integer,value=1)  
  for ii=0,n_elements(x)-1 do begin
    t = x[ii] & voltage = v[ii,*] & current = y[ii,*]
    
    ; --- Sometimes the voltage information is sometimes wrong and all zero ---
    ; --- skip if all voltage = zero
    n_zeros = where(voltage eq 0)
    if n_elements(n_zeros) eq n_elements(voltage) then begin
      good(ii)=0 ;& print, 'no good: '+ string(ii,format='(I4)')
      continue
    endif
    
    ; --- Some times current offset seems wrong and current value all negative ---
    ; --- skip if 2/3 current smaller than 0 ---
    n_zeros = where(current le 0)
 ;   print, n_elements(n_zeros), ': ', n_elements(current)
    if n_elements(n_zeros) gt 2*n_elements(voltage)/3 then begin
      good(ii)=0 & print, 'no good: '+ string(ii,format='(I4)')
      continue
    endif
    
    ; ------------------------------
    y[ii,*] = current
  endfor

  good = where(good eq 1)
  x = x(good) & y = y(good,*) & v = v(good,*) & dy = dy(good,*) & dv = dv(good,*)
  new_data = create_struct('x',x,'y',y,'v',v,'dy',dy,'dv',dv)

  ; -----------------------------------------------------------------  
  ; --------- replace data to the calibrated one --------------------
  data = new_data  
  ; ----- Edit limit
  limit.zrange = [min(data.y), max(data.y)]
  
end