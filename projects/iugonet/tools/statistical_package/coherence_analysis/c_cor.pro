

pro C_COR,$
    x,$
    y,$
    cross_cor,$
    cross_spectrum,$
    sl=sl,$
    mv=mv,$
    low_lag=low_lag,$
    high_lag=high_lag,$
    x_cor,$
    y_cor

for i=0,n_elements(x)-1 do begin
    if (finite(x[i])) and (finite(y[i])) then begin
        append_array,x1,double(x[i])
        append_array,y1,double(y[i])
    endif
endfor

;for i=0,n_elements(x0)-1 do begin
;        append_array,x1,double(x0[i])-mean(x0)
;        append_array,y1,double(y0[i])-mean(y0)
;endfor

;low_lag=0ではkeyword_setは0を返す。
if ~keyword_set(low_lag) then begin
    low_lag=-n_elements(x1)/2
endif
if ~keyword_set(high_lag) then begin
    high_lag=n_elements(x1)/2
endif

cross_cor=dblarr(high_lag-low_lag+1)
x_cor=dblarr(high_lag-low_lag+1)
y_cor=dblarr(high_lag-low_lag+1)

for i=low_lag,high_lag do begin
            cross_cor[i-low_lag]=C_CORRELATE(x1,y1,i)
            x_cor[i-low_lag]=A_CORRELATE(x1,i)
            y_cor[i-low_lag]=A_CORRELATE(y1,i)
endfor

;ccc=fft(cross_cor,-1,/double)
;;ccc=temporary(ccc[1:n_elements(cross_cor)/2,*])
;cross_spectrum=abs(ccc)

;検定統計量の計算
max_corr=max(cross_cor)
max_zure=where(cross_cor eq max(cross_cor))+low_lag
max_stat=[abs(max_corr)]*[sqrt((n_elements(x1)-abs(max_zure)-2)/(1-max_corr^2))]

min_corr=min(cross_cor)
min_zure=where(cross_cor eq min(cross_cor))+low_lag
min_stat=[abs(min_corr)]*[sqrt((n_elements(x1)-abs(min_zure)-2)/(1-min_corr^2))]

;指定した有意水準でのｔ分布の値の計算
if ~keyword_set(sl) then begin
    sl=0.05
endif
result=t_cvf(sl/2.0,n_elements(x1)-2)

append_array,cor,max_corr
append_array,cor,max_zure
append_array,cor,max_stat

;lagが正のときは後者が遅れていることを示す
print,'-----------------cross correlation status--------------------------'
print,'|        maximun correlation coefficient       =',max_corr
print,'|               lag of max correlation         =',max_zure
if (max_stat ge result) then begin
print,'|statistically significant (significance Lv    =',sl,')'
endif else begin
print,'|NOT statistically significant (significance Lv    =',sl,')'
;print,'|There is statistically no correlation between two data sets on this lag case.(significance Lv    =',sl,')'
endelse
print,'|        minimun correlation coefficient       =',min_corr
print,'|               lag of min correlation         =',min_zure
if (min_stat ge result) then begin
print,'|statistically significant (significance Lv    =',sl,')'
endif else begin
print,'|NOT statistically significant (significance Lv    =',sl,')'
endelse

print,'-------------------------------------------------------------------'



end 