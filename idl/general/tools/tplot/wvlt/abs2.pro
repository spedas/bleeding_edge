function real,x
type = size(x,/type)
format = intarr(20)
format[[5,9]] = 1
return, format[type] ? double(x) : float(x)
end
 


function abs2,x
return, real(x)^2 + imaginary(x)^2
end
