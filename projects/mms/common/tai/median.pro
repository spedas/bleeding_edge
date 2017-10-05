pro median, x, n, xmed

sort_x= x(sort(x))

n2= n/2
if (2*n2 eq n) then begin
	xmed= 0.5*(sort_x(n2-1)+sort_x(n2))
endif else begin
	xmed= sort_x(n2)
endelse

end

