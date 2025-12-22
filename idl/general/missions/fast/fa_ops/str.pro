;	@(#)str.pro	1.2	02/12/02

function Str,arg, _extra=e

return,strcompress(string(arg,_extra=e),/remove_all)
end
