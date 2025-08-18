;+
;NAME:
;  welch_test
;PURPOSE:
;  Test whether two pairs of average value of time series data is the same or. 
;  It is assumed that both distibutions of the data sets are normal distribution 
;  and have different variance.
;  
;SYNTAX:
;  result=Welch_test(x,y,sl=sl,mv=mv)
;
;KEYWORDS:
;  sl:Significant level. 
;     The default is 0.05.
;  mv:Missing value.
;     If not set, Only the NaN value is dealt with.
;  z:Statistical test value
;  t_sl:Critical value of t-distribution in the significant level.
;
;NOTES:
;  The test result is output as a value of 1 and 0 if the average value is the same
;  and different, respectively.
;
;CODE:
; R. Hamaguchi, 13/12/2012.
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

function welch_test,a,b,sl=sl,mv=mv

;Array elements of data a and b
na=n_elements(a)
nb=n_elements(b)

if keyword_set(mv) then begin
   for i=0L,na-1 do begin
      if(float(a[i]) eq mv) or (not finite(a[i])) then continue
      append_array,x,float(a[i])
   endfor
   for j=0L,nb-1 do begin
      if(float(b[j]) eq mv) or (not finite(b[j])) then continue
      append_array,y,float(b[j])
   endfor
endif else begin
   for i=0L,na-1 do begin
      if (not finite(a[i])) then continue
      append_array,x,float(a[i])
   endfor
   for j=0L,nb-1 do begin
      if (not finite(b[j])) then continue
      append_array,y,float(b[j])
   endfor
endelse

;Define of arrays nx and ny:
nx=double(n_elements(x))
ny=double(n_elements(y))

;Calculation of average value of data x and y:
x_mean=mean(x)
y_mean=mean(y)

;Calculation of standard deviation of data x and y:
x_sd=stddev(x)
y_sd=stddev(y)
x_uv=x_sd^2
y_uv=y_sd^2

;Calculation of statistical test value using the Welch test:
t1=abs(x_mean-y_mean)
t2=sqrt(x_uv/nx+y_uv/ny)
t=t1/t2
v1=(x_uv/nx+y_uv/ny)^2
v2=x_sd^4/(nx^2*(nx-1))+y_sd^4/(ny^2*(ny-1))
v0=v1/v2

if(not keyword_set (sl)) then sl=0.05

z=t_cvf(sl/2.0,v0)
c1=' There is no difference between these data with significance level = '
c2=' There is a significant difference between these data with significance level = '

;Output the Welch test result on the console:
print,'-----------------Welch test result--------------------------'

if (t lt z) then begin
   c=c1
   result=1
endif else begin
   c=c2
   result=0
endelse

print,'t',t,'     t0',z
print,c,sl
print,'-------------------------------------------------------------'
return,result
end