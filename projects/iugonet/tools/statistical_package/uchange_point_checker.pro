;+
;
;NAME:
;uchange_point_checker
;  
;PURPOSE:
;Identify the change point of time-serise data.
;  
;SYNTAX:
;uchange_point_checker,vname1
;  
;
;CODE:
;R. Hamaguchi, 17/01/2013.
;
;MODIFICATIONS:
;A. Shinbori, 08/05/2013.
; 
;ACKNOWLEDGEMENT:
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-01-22 15:54:40 -0800 (Wed, 22 Jan 2014) $
; $LastChangedRevision: 13976 $
; $URL $
;-

pro uchange_point_checker,vname1

;Get data from two tplot variables:
if strlen(tnames(vname1)) eq 0 then begin
   print, 'Cannot find the tplot vars in argument!'
   return
endif
get_data,vname1,data=d1

    
nX = n_elements(d1.x)
X1 = d1.y
X2 = d1.y
X3 = d1.y
a0=alpha0(X1)
mu0=mu(X1,a0)

for i=0,nX-1 do begin
   append_array,SSEred0, (X1(i) - mu0 - a0*(i+1))^2
endfor

SSEred=total(SSEred0)
    
for i=2,nX-1 do begin
   SSEfull=SSEfull(X1,i)
   append_array,Fc1,((SSEred - SSEfull)*(nX-4))/(2.0*(SSEfull))
endfor

c=300
a1=alpha1(c,X1)
a2=alpha1(nX-c,X1(c:nX-1))
mu1=mean(X1(0:c-1)) - a1*(c+1)/2.0    
mu2=mean(X1(c:nX-1)) - a2*(c+nX+1)/2.0 
    
tmp=findgen(nX)
Sxx=total((tmp-mean(tmp))^2)
Syy=total((X1-mean(X1))^2)
Sxy=total((tmp-mean(tmp))*(X1-mean(X1)))
b1=Sxy/Sxx;(total(x*y1) - total(x)*total(y1)/n)/Sxx
b0=mean(X1)-b1*mean(tmp)

;window, 1, xsize=1050, ysize=610
;!P.MULTI = [0,1,2]
;plot,X1,xtitle='Time',ytitle='amplitude'
;oplot,b0+b1*tmp,color=250
;oplot,mu0+a0*tmp,color=200
;oplot,tmp(0:299),mu1+a1*tmp(0:299),color=100
;oplot,tmp(300:999),mu2+a2*tmp(300:999),color=100
;plot,Fc1,xtitle='Time',ytitle='F'
    
;a0=alpha0(X2)
;mu0=mu(X2,a0)
;SSEred0=0
    
;for i=0,nX-1 do begin
;   append_array,SSEred0, (X2(i) - mu0 - a0*(i+1))^2
;endfor

;SSEred=total(SSEred0)
;for i=2,nX-1 do begin
;   SSEfull=SSEfull(X2,i)
;   append_array,Fc2,((SSEred - SSEfull)*(nX-4))/(2.0*(SSEfull))
;endfor

;window, 2, xsize=1050, ysize=610
;!P.MULTI = [0,1,2]
;plot,X2,xtitle='Time',ytitle='amplitude'
;plot,Fc2,xtitle='Time',ytitle='F'
    
a0=alpha0(X3)
mu0=mu(X3,a0)
SSEred0=0
    
for i=0,nX-1 do begin
   append_array,SSEred0, (X3(i) - mu0 - a0*(i+1))^2
endfor

SSEred=total(SSEred0)
for i=2,nX-1 do begin
   SSEfull=SSEfull(X3,i)
   append_array,Fc3,((SSEred - SSEfull)*(nX-4))/(2.0*(SSEfull))
endfor

window, 3, xsize=1050, ysize=610
!P.MULTI = [0,1,2]
plot,X3,xtitle='Time',ytitle='amplitude'
plot,Fc3,xtitle='Time',ytitle='F'
    
print,where(Fc1 eq max(Fc1)),where(Fc2 eq max(Fc2)),where(Fc3 eq max(Fc3))
end

function SSEfull,X,c

nX = n_elements(X)
;a1=alpha0(X(0:c-1))
a1=alpha1(c,X)
a2=alpha1(nX-c,X(c:nX-1))
mu1=mean(X(0:c-1)) - a1*(c+1)/2.0    
mu2=mean(X(c:nX-1)) - a2*(c+nX+1)/2.0 
    
for i=0,c-1 do begin
   append_array,SSEfull0, (X(i) - mu1 - a1*(i+1))^2
endfor

for i=c,nX-1 do begin
   append_array,SSEfull0, (X(i) - mu2 - a2*(i+1))^2 
endfor
SSEfull=total(SSEfull0)
return,SSEfull

end

function mu,X,a0
nX = n_elements(X)
sum = 0
for i=0,nX-1 do begin
   sum = sum + (X(i) - a0*(i+1))
endfor
return,sum/nX    
end

function alpha0,X
sum = 0
nX = n_elements(X)
Xmean = mean(X)
for i=0,nX-1 do begin
   sum = sum + (i+1)*(X(i) - Xmean)
endfor
result=(sum*12)/(nX*(nX+1)*(nX-1))
return,result    
end


function alpha1,c,X
sum = 0
c_mean = (c+1)/2.0
X1mean = mean(X(0:c-1))
for i=0,c-1 do begin
        ;sum = sum + (i + 1)*(X(i) - X1mean)
   sum = sum + (i + 1 - c_mean)*(X(i) - X1mean)
        ;if c eq 400 then begin
        ;    print,X(i) - X1mean
        ;endif
endfor
result=(sum*12)/(float(c)*(float(c)+1)*(float(c)-1))
return,result    
end

function alpha2,c,X
nX = n_elements(X)
sum = 0
c_mean = (c+nX+1)/2.0
X2mean = mean(X(c:nX-1))
for i=c,nX-1 do begin
    sum = sum + (i + 1)*(X(i) - X2mean)
        ;sum = sum + (i + 1 - c_mean)*(X(i) - X2mean)
endfor
result=(sum*12)/((nX-c)*(nX-c+1)*(nX-c-1))
return,result   
end
