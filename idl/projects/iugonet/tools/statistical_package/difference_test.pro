;+
;Name:
;　　difference_test
;Purpose:
;  平均値検定を行うプログラム。
;  χ二乗検定によって正規分布との適合を検定する。
;  どちらも正規分布に従う場合はWelch検定
;  どちらかが正規分布に従わない場合はマンホイットニー検定のみを用いる。
;Syntax:
;  difference_test,x,y,result,sl=**
;Keywords:
;  result:検定結果を'0'：ウェルチ検定使用-判定は異,'1'：ウェルチ検定使用-判定は同,'2'：マンホイットニー-異,'3'：マンホイットニー-同、で返す
;  sl:有意水準。指定しない場合はsl=0.05で検定。
;  test_sel：行う検定を指定。'2'はマンホイットニー検定、'1'はウェルチ検定、'0'はχ二乗検定によって正規分布との適合を検定
;  2012/12/13 改変　by 濵口
;-

pro difference_test,x,y,result,sl=sl,test_sel=test_sel

;***********************
;Keyword check test_sel:
;***********************
if not keyword_set(test_sel) then test_sel=0 

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