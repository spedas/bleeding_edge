;+
;NAME
; normality_test
;
;PURPOSE
; Test whether time-series data obey the normal distribution or not 
; with the chi-square goodness-of-fit test. 
; 
;SYNTAX
; result=normality_test(x,sl=sl,mv=mv)
; 
;KEYWORDS:
;  x:Input data
;  sl:Significant level
;     The default is 0.05.
;  mv:Missing value.
;     If not set, only the NaN value is dealt with.
;
;NOTES:
;  Output the value '0' if the input data obey the normal distribution and
;  '1' if not obey.
;
;CODE:
;R. Hamaguchi, 13/02/2012.
;
;MODIFICATIONS:
;A. Shinbori, 01/05/2013.
;A. Shinbori, 10/07/2013.
;
;ACKNOWLEDGEMENT:
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-08-01 11:03:38 -0700 (Wed, 01 Aug 2018) $
; $LastChangedRevision: 25538 $
; $URL $
;-

function normality_test,x,sl=sl,mv=mv

nx=n_elements(x)

if keyword_set(mv) then begin
    for i=0L,nx-1 do begin
        if(float(x[i]) eq mv) or (not finite(x[i])) then continue
        append_array,c,float(x[i])
    endfor
endif else begin
    for i=0L,nx-1 do begin
        if (not finite(x[i])) then continue
        append_array,c,float(x[i])
    endfor
endelse

nc=n_elements(c)
x_max=max(c)
x_min=min(c)
x_mean=mean(c)
x_stddev=stddev(c)
;The number of intervals is （data points/40）. 
;If the data points is less than 400, the number of intervals is fixed as 10.
if nc ge 400 then begin
    nK=round(nc/40.0)             
endif else begin
    nK=10.0
endelse
x_d=(x_max-x_min)/nK

for j=0L,nK-2 do begin
    r1=where(c ge (x_min+x_d*j) and c lt (x_min+x_d*(j+1)))
    if r1[0] ne -1 then begin
        append_array,y,n_elements(r1)             ;Actually measured frequency
    endif else begin
        append_array,y,0
    endelse
    append_array,z1,x_min+x_d*j
endfor

rx=where(c ge (x_min+x_d*(nK-1)) and c le (x_max))
append_array,y,n_elements(rx)
append_array,z1,x_min+x_d*(nK-1)
append_array,z1,x_min+x_d*nK

for i=0L,nK do begin
    append_array,z2,gaussint((z1[i]-x_mean)/x_stddev)
endfor


for i=0L,nK-1 do begin
    append_array,z3,(z2[i+1]-z2[i])*nc          ;Expected frequency
endfor

if nK ge 15 then begin                       ;Section is cut the ends of large errors more than 15.
    for i=round(nK/20.0),nK-round(nK/20.0)-1 do begin           
        append_array,z4,((y[i]-z3[i])^2.0)/z3[i]
    endfor
endif else begin
    for i=0L,nK-1 do begin           
        append_array,z4,((y[i]-z3[i])^2.0)/z3[i]
    endfor
endelse

;print,total(z3),total(y)
sum_z4=total(z4)

;print,z2,z3,y
;print,total(z3),total(y)
window, 2, xsize=850, ysize=410
        !P.MULTI = [0,1,1]
plot,y
oplot,z3
        
if keyword_set(sl) then begin 
    v=chisqr_cvf(sl,nK-1-2)
    if (sum_z4 le v) then begin
    char='   NORMAL DISTRIBUTION with significance level ='
    result=0
    endif else begin
    char='   NOT NORMAL DISTRIBUTION with significance level ='
    result=1
    endelse
    print,'comment:',char,sl
endif else begin
    v=chisqr_cvf(0.05,nK-1-2)   
    if (sum_z4 le v) then begin
    char='   NORMAL DISTRIBUTION with significance level = 0.05'
    result=0
    endif else begin
    char='   NOT NORMAL DISTRIBUTION with significance level = 0.05'
    result=1
    endelse
    print,'comment:',char
endelse

return,result
end