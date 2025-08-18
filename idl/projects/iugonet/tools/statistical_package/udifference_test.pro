;+
;NAME:
;　　udifference_test
;
;PURPOSE:
;  Perform the difference test for two pairs of time-series data sets and
;  test the fit of a normal distribution by χ-square test
;  If both data sets obey the normal distribution, the Welch test is applied.
;  If both data sets do not obey the normal distribution, 
;  only the Mann-Whitney test is used.
;  
;SYNTAX:
;  difference_test,vname1,vname2,sl=sl,test_sel=test_sel
;  
;KEYWORDS:
;  result:Test result.
;         The values '0' and '1' mean that the judgement of the Welch test is different
;         and same, respectively. Moreover, the values '2' and '3' mean that the judgement 
;         of the Mann-Whitney test is different and same, respectively.
;  sl:Significant level. 
;     The default is 0.05.
;  test_sel：Specify the test to be performed. The value '2' is the Mann-Whitney test, 
;           '1' is the Welch test, and '0' is to test the fit of a normal distribution 
;           by χ-square test
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

pro udifference_test,vname1,vname2,result,sl=sl,test_sel=test_sel

;***********************
;Keyword check test_sel:
;***********************
if not keyword_set(test_sel) then test_sel=0 

;Get data from two tplot variables:
if strlen(tnames(vname1)) * strlen(tnames(vname2)) eq 0 then begin
  print, 'Cannot find the tplot vars in argument!'
  return
endif
get_data,vname1,data=d1
get_data,vname2,data=d2

x=d1.y
y=d2.y

;Welch or Mann Whitney test:
if test_sel eq 1 then begin
   result=welch_test(x,y,sl=sl)
endif 
if test_sel eq 2 then begin
   result=mann_whitney_test(x,y,sl=sl)
endif

if test_sel eq 0 then begin
   x1=normality_test(x,sl=sl)
   y1=normality_test(y,sl=sl)
   if (x1 eq 0) and (y1 eq 0) then begin 
      result=welch_test(x,y,sl=sl)
   endif else begin
      result=mann_whitney_test(x,y,sl=sl)
   endelse
endif
;The end:    
end