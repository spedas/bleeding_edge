;+
;procedure:  crib_calc.pro
;
;purpose: demonstrate how to use the mini-language program 'calc'
;
;usage:
; .run crib_calc
;
;
;Warning: this crib uses some data from the THEMIS branch.  You'll require those routines to run this crib
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-06-16 16:39:01 -0700 (Thu, 16 Jun 2016) $
; $LastChangedRevision: 21333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_calc.pro $
;
;-


;the mini-language is a language written in IDL that can be run on the
;idl virtual machine.  It follows most of the syntactical rules of IDL
;with the exception that tplot variables are treated as first-class
;data types in the mini-language.  They are denoted with "quotes" the
;same way that you would denote strings in normal IDL.
;All statements in the mini-language must be assignment statements 
;(ie variable = expression)


;Example 1 var = number

;sets a equal to 5
calc,'a = 5'

stop

;Example 2 binary operation.

;This performs multiplication on "b", you can use any of the idl
;operators with calc
b = 7
calc,'seven_pi = b * 3.14159'

stop

;Example 3 function/exponential notation

;This performs a function call. Also note that calc can read the same
;numerical format code as IDL.  The default type, if unspecified is a
;float rather than a short int, as floats are much more common in
;scientific applications
calc,'log_result = log(1e-2)'  ;log base 10

calc,'log_result = ln(1e-2)' ; log base e

stop

;Example 4 tvar = number

;creates a tplot variable named 'a' with the y component of its data
;struct equal to 5.  Because the number 5 doesn't have any
;associated time information, neither will "a"
calc,'"a"=5'

stop

;Example 5 real tvar

;load some real data
timespan,'2007-03-23'
thm_load_state,probe='a'

;performs division on tplot variable
;Note that calc does not yet accept globbing operators
; like '?' and '*', so 'th?_state_pos' is currently an invalid name.
;We plan to add this feature soon.

calc,"'tha_pos_re' = 'tha_state_pos'/6371.2"

stop

;example 6 combined tvar/var

;you can combine normal and tplot variables in the same expression
dpi = !DPI
calc,'"tha_pos_sin" = sin("tha_pos_re"*dpi)'

stop

;example 7 getting tvar data with cacl

;you can use calc as an easy way to read the data component of a tplot
;variable, after this call, data will have the data component of tha_state_pos

calc,'data = "tha_state_pos"'

stop

;example 8 order of operation

;calc follows the same order of operations
;and numerical type codes as IDL.  If unspecified,
;the default type is float(not short int like IDL)
calc,'out = 5.1 + 6.02e-3 ^ 2b * 7.6D'

stop

;example 9 errors

;note that calc does not report errors by stopping execution or
;printing to the command line.  If an error occurs, it returns a
;struct describing this error in a keyword called 'error'

calc,'out = "?%3"',error=e

help,/str,e
print,e.value

stop

;example 10 verbose

;you can use the /verbose option to print the error rather than return the struct
calc,'out= "?%3"',/verbose

stop

;example 11 function and operator lists

;calc will return a list all the available functions(and syntax) and operators 

calc,function_list=f,operator_list=o

print,'Functions: ',f
print,'Operators: ',o

stop

;example 12 multi argument functions

;some functions take multiple arguments
;a second argument to 'log', is an alternate base
;also note that 'ln' is a base e logarithm

calc,'log_2 = log(64,2)'

stop

;example 13 more multi argument functions

;some functions take the dimension over which the operation
;should be performed

calc,'t = total("tha_state_pos")' ;total over all dimensions
;t is 1 element

calc,'t = total("tha_state_pos",1)' ; total over time
;t is 3 elements

calc,'t = total("tha_state_pos",2)' ; total over x,y,z
;t is 1440 elements

stop

;example 14 exp

;exp also takes a base as an optional argument. 

calc,'ex = exp(2)'  ; ex = e^2

calc,'ex = exp(6,2)' ; ex = 2^6 = 64.0

calc,'ex = exp(log(64,2),2)' ; ex = 2^log_2(64) = 64

stop

;example 15 keywords

;Some functions accept keywords.  Use function_list(see example above) to see syntax
;Like IDL, the keywords can be in any order, and can be abbreviated

calc,'t = total("tha_state_pos",/cumulative)' ;cumulative total all dimensions
;t is 1440 x 3 elements

calc,'t = total("tha_state_pos",/nan,/c,1)' ; cumulative total across time dimension, nans ignored 
;t is 1440 x 3 elements

calc,'t = median("tha_state_pos",2,/even)' ; median across x,y,z, using the median /even keyword(see IDL documentation)
;t is 1440 elements

stop

;example 16 interpolation

;Not all tplot variables have the same cadence.
;With the interpolate keyword, calc performs interpolation automatically
;This allows data with different number of elements to be used in the same 
;  calculation,

thm_load_fit,probe='a'

calc,'"out" = "tha_state_pos" + "tha_fgs"',/interp ; interpolates to variable on the left of each binary operation("tha_state_pos" in this case)

calc,'"out" = "tha_state_pos" + "tha_fgs"',interp="tha_fgs" ;interpolate to the specified variable

calc,'"out" = "tha_state_pos" + "tha_fgs"',/interp,/quadratic ;can use keywords accepted by tinterpol.pro

stop

;example 17 globbing
;If you put a globbing character(e.g. ?*) in a right hand variable and a left hand variable, it will match all tplot-variables on the right
;and fill in the matching value in the left-hand output

thm_load_state,probe='*'

calc,'"th?_state_pos_re" = "th?_state_pos"/6371.2' ;globbing

stop

;example 18 line continuation
;You can use built in IDL mechanisms if you want to do long lines with the continuation ($) operator


thm_load_state,probe='*'

calc,'"tha_state_pos_re" = ' + $
     '"tha_state_pos"/6371.2' 

stop

;example 19 string concatenation
;You can use the $+ operator to concatenate strings
var = ["a","b"]
thm_load_state,probe='*'

calc,'"th" $+ var $+ "_state_pos_re"  = "th" $+ var $+ "_state_pos"/6371.2'

stop

;example 20 unary string variables
;You can also use the $+ operator unarily to lookup tplot names in variables 
var1 = ["tha_state_pos","thb_state_pos"]
var2 = ["tha_state_pos_re","thb_state_pos_re"]
thm_load_state,probe='*'

calc,' $+var2  = $+var1/6371.2'

  stop

;example 21 returning values from keywords

var1 = [2,3,4,1,5]
calc,' var2  = min(var1,/subscript=s)'
print,s

;because of some limitations in the parser, keywords that return values still need to be prefixed with a '/' unlike normal IDL 

stop
end
