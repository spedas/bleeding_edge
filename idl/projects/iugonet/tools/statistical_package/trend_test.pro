;+
;
;NAME:
;  trend_test
;PURPOSE:
;  Test the trend of the data.
;SYNTAX:
;  trend_test,y
;KEYWORDS:
;    y:Input data
;    Z:Statistical test value.
;    sl:Significant level. The default is 0.05.
;
;CODE:
; R. Hamaguchi, 17/01/2013.
;
;MODIFICATIONS:
; A. Shinbori, 01/05/2013.
; A. Shinbori, 10/07/2013.
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

pro trend_test,$
    y0,Z,sl=sl
;*****************
;Keyword check s1:
;*****************
if ~keyword_set(sl) then begin
   sl=0.05
endif
for i=0,n_elements(y0)-1 do begin
   if finite(y0[i]) then append_array,y1,y0[i]
endfor    

;Define of arrays n and y2:
n=float(n_elements(y1))
y2=fltarr(n)

;Calculation of statistical test value using the trend test:
E=(n^3-n)/6.0
V=(n^2*(n+1)^2*(n-1))/36.0

counter=1
y_tmp=y1

;Ranking the data y:
while max(y_tmp) ne -1e4 do begin
   aaa=where(y_tmp eq max(y_tmp))
   bbb=n_elements(aaa)
   rank=counter+(bbb-1)/2.0
   y2[aaa]=rank
   y_tmp[aaa]=-1e4
   counter=counter+bbb
endwhile

;Confidence interval of regression curve:
x=findgen(n)
Sxx=total((x-mean(x))^2)
Syy=total((y1-mean(y1))^2)
Sxy=total((x-mean(x))*(y1-mean(y1)))
b1=Sxy/Sxx;(total(x*y1) - total(x)*total(y1)/n)/Sxx
b0=mean(y1)-b1*mean(x);total(y1)/n - b1*total(x)/n
y1b=b1*x+b0
e2=total((y1b-y1)^2)
b1_thr=t_cvf(sl/2.0,n-2)*sqrt((e2/(n-2))/Sxx)
;b0_thr=t_cvf(sl/2.0,n-2)*sqrt((e2/(n-2))(1.0/n + mean(x)^2/Sxx))/10

y1b_p=(b1+b1_thr)*x+b0;-a_thr
y1b_n=(b1-b1_thr)*x+b0;+a_thr

;y1s=sort(sort(y1))+1
y2D=1.0/3.0*n*(n+1)*(2*n+1)-2*total(y2*(findgen(n)+1))
Z=(y2D-E)/sqrt(V)

;Output of the trend test result on the console:
print,'t=',Z
thr_t=0
for i=-5000,0 do begin
   if sl*10000 eq round(gaussint(i*0.001)*10000) then thr_t=i*0.001
endfor
print,'Max　|t| =',E/sqrt(V)
print,'Threshold (at S_Level    =',sl,')   :',-thr_t

print,'slope',b1
print,'error of slope',b1_thr

window, 3, xsize=1000, ysize=450
    !P.MULTI = [0,1,1]
plot,y1
oplot,y1b,color=60
oplot,y1b_p,color=220
oplot,y1b_n,color=230

end