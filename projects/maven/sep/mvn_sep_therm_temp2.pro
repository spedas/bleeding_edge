function thermistor_temp,R,parameter=p,b2252=b2252,L1000=L1000
if not keyword_set(p) then begin
   p = {func:'thermistor_temp',note:'YSI 46006 (H10000)',R0:10000.,  $
      T0:24.988792d, t1:-24.809236d, t2:1.6864476d, t3:-0.12038317d, $
      t4:0.0081576555d, t5:-0.00057545026d ,t6:3.1337558d-005}
   if keyword_set(B2252) then p={func:'thermistor_temp',note:'YSI (B2252)',R0:2252.,  $
      T0:24.990713d, t1:-22.808501d, t2:1.5334736d, t3:-0.10485403d, $
      t4:0.0076653446d, t5:-0.00084656440d ,t6:6.1095571d-005}
if keyword_set(L1000) then p={func:'thermistor_temp',note:'YSI (L1000)',R0:1000.,  $
      T0:25.00077d, t1:-27.123102d, t2:2.2371834d, t3:-0.20295066d, $
      t4:0.022239779d, t5:-0.0024144851d ,t6:0.00013611146d}
endif
if n_params() eq 0 then return,p

x = alog(R/p.r0)
T = p.t0 + p.t1*x + p.t2*x^2 + p.t3*x^3 + p.t4*x^4 +p.t5*x^5 +p.t6*x^6
return,t

end




function mvn_sep_therm_temp2,dval,parameter=p
if not keyword_set (p) then begin
   p = {func:'mvn_sep_therm_temp2',R1:10000d, xmax:1023d, Rv:1d7, thm:thermistor_temp()}
endif

if n_params() eq 0 then return,p

x = dval/p.xmax
rt = p.r1*(x/(1-x*(1+p.R1/p.Rv)))
tc = thermistor_temp(rt,param=p.thm)
return,tc
end


;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10, 2.69E-06,  -2.33E-02, 9.33E+01]

