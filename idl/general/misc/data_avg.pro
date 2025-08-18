function data_average_str_1,data,nan=nan
   nt = n_tags(data)
   d = data(0)
   for i=0,nt-1 do begin
      ndim = ndimen(data.(i))
      d.(i) = average(data.(i),ndim,nan=nan)
   endfor
   return,d
end


function data_avg, data, times

n = n_elements(data)
d0 = data(0)
nt = n_elements(times)

dtype = data_type(d,/struct)

d = replicate(d0,nt)
got_some = 0

for i=0,nt-2 do begin
   d(i).time = times(i)
   w = where(data.time ge times(i) and data.time lt times(i+1),c)
   if c eq 1 then d(i) = data(w)
   if c gt 1 then d(i) = data_average_str_1(data(w),nan=nan)
   if c eq 0 and got_some then d(i) = d(i-1) else got_some=1
endfor

i=nt-1
d(i).time = times(i)
timediff = times(i) - times(i-1)
w = where(data.time ge times(i) and data.time lt times(i)+timediff,c)
if c eq 1 then d(i) = data(w)
if c gt 1 then d(i) = data_average_str_1(data(w),nan=nan)
if c eq 0 and got_some then d(i) = d(i-1)


return,d
end