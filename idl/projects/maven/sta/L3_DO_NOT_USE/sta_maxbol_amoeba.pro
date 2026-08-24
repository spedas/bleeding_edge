function sta_maxbol_amoeba, p

;  if not keyword_set(params) then begin
;    params =  { pk   : 1d6 , $ ; some density-like constant 
;      T    :   0.01d  , $   ;  temperature (eV)
;      vb    : 1.0d } ; velocity offset km/s 
;    return, params
;  endif

common stambfit, m_int, v, df
  
  m = m_int * 938.28d6 / (3d5)^2 ;; eV / (km/s)^2 
  
  pk = p[0] ;; c6 df units 
  vb = p[1] ;; km/s
  T = p[2] ;; eV 
  
  z = m*(v-vb)^2 / (2.*T) ;; unitless positive 

  f = pk * exp(-z) ;;c6 df units
  
  res = df - f ;;c6 df units
     
 return, max(abs(res))

            ;;;; let's try and minimize the difference between the areas under the curve 
;            dv = shift(v,-1) - v 
;            int1 = total(df[1:-2]*dv[1:-2]*v[1:-2]^2) 
;            int2 = total(f[1:-2]*dv[1:-2]*v[1:-2]^2) 
;            res = abs(int2 - int1) 
;            return, res 



end