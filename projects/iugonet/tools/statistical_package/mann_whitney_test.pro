;+
;NAME:
;  Mann_Whitney_test
;  
;PURPOSE:
;   Test the difference for distributions between two data sets.
;   Distribution of the population does not matter.
;   
;KEYWORDS:
;  sl:significance level 
;     If you don't set sl, sl = 0.05 
;  mv:missing value
;     If you don't set mv, mv = only NaN 
;  z:Statistical test value.
;  Z0:Critical value of the standard normal distribution at significance level
;  c:Comment
;
;NOTES:
;  The output result is 3 or 2 if both distributions is same or different.
;  
;CODE:
;R. Hamaguchi, 13/02/2012.
;
;MODIFICATIONS:
;A. Shinbori, 01/05/2013.
;A. Shinbori, 10/07/2013.
;
;ACKNOWLEDGEMENT:
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-01-22 15:54:40 -0800 (Wed, 22 Jan 2014) $
; $LastChangedRevision: 13976 $
; $URL $
;-

function mann_whitney_test,x,y,sl=sl,mv=mv
print,'mann whitney test'
nx=n_elements(x)
ny=n_elements(y)

if keyword_set(mv) then begin
   for i=0L,nx-1 do begin
      if(float(x[i]) eq mv) or (not finite(x[i])) then continue
      append_array,c,float(x[i])
   endfor
   for j=0L,ny-1 do begin
      if(float(y[j]) eq mv) or (not finite(y[j])) then continue
      append_array,d,float(y[j])
   endfor
endif else begin
   for i=0L,nx-1 do begin
      if (not finite(x[i])) then continue
      append_array,c,float(x[i])
   endfor
   for j=0L,ny-1 do begin
      if (not finite(y[j])) then continue
      append_array,d,float(y[j])
   endfor
endelse

nc=double(n_elements(c))
nd=double(n_elements(d))
c_total=total(c)
d_total=total(d)
e=[c,d]
;g=sort(sort(e))
counter=1
e_tmp=e
h=dblarr(nc+nd)
while min(e_tmp) ne 1e10 do begin
    aaa=where(e_tmp eq min(e_tmp))
    bbb=n_elements(aaa)
    rank=counter+(bbb-1)/2.0
    h(aaa)=rank
    e_tmp(aaa)=1e10
    counter=counter+bbb
endwhile

for i=0L,nc-1 do begin
    append_array,k1,double(h[i])
endfor
for i=nc,nc+nd-1 do begin
    append_array,k,double(h[i])
endfor
j_total=total(k1)
k_total=total(k)
if (j_total ge k_total) then begin
U=j_total-nc*(nc+1)/2
endif else begin
U=k_total-nd*(nd+1)/2
endelse
u_mean=float(nc*nd)/2
u_std=sqrt(double(nc*nd*(nc+nd+1))/12.0)
z=(U-u_mean)/u_std

if(not keyword_set(sl)) then sl=0.05
Z0=gauss_cvf(float(sl)/2.0)
;print,RS_TEST(x,y)

print,'-----------------Mann Whitney test result--------------------------'
print,'t',abs(z),'      t0',Z0;u_mean,u_std,z

if (abs(z) lt Z0) then begin
   c='There is no difference between these data with significance level = '
   result=3
endif else begin
   c='There is significant difference between these data with significance level = '
   result=2
endelse
print,c,sl
print,'-------------------------------------------------------------------'
return,result
end
