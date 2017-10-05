function datin,fname,ncol,d
openr,1,fname
s=''
first=-1l
last=-1l
i=0l
while not eof(1) and last EQ -1l do begin
  readf,1,s
  ss = strmid(strcompress(s,/remove_all),0,1)
  linetype=strpos('0123456789.-',ss)
  if strlen(ss) EQ 0 then linetype=-1
  if first GE  0l and linetype EQ -1 then last=i-1l
  if first EQ -1l and linetype GE  0l then first=i
  i=i+1
end
if last EQ -1l then last=i-1l
close,1
openr,1,fname
d=dblarr(ncol,last-first+1)
for i=0l,first-1l do readf,1,s 
readf,1,d
close,1
return,last-first+1l
end
