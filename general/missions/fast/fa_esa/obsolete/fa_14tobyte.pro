;Compresses 14 bit integers to bytes the slow way.

function fa_14tobyte,counts

ncounts=n_elements(counts)
if ncounts GT 1 then begin
	output_byte=bytarr(ncounts)
	for j=0,ncounts-1 do $
		output_byte[j]=fa_14tobyte(counts[j])
	return,output_byte
endif

if counts EQ 0 then return,0b
bitsarray=intarr(16)

for i=0,15 do bitsarray[i]=((2^(i) AND counts) NE 0)
msl=max(where(bitsarray EQ 1))

case msl of
	
	0: output=bitsarray[0:7]
	
	1: output=bitsarray[0:7]
	
	2: output=bitsarray[0:7]
	
	3: output=[bitsarray[0:2],1,0,0,0,0]
	
	4: output=[bitsarray[1:3],0,1,0,0,0]
	
	5: output=[bitsarray[2:4],1,1,0,0,0]
	
	6: output=[bitsarray[2:5],0,1,0,0]
	
	7: output=[bitsarray[3:6],1,1,0,0]
	
	8: output=[bitsarray[4:7],0,0,1,0]
	
	9: output=[bitsarray[5:8],1,0,1,0]
	
	10: output=[bitsarray[5:9],1,1,0]
	
	11: output=[bitsarray[6:10],0,0,1]
	
	12: output=[bitsarray[7:11],1,0,1]
	
	13: output=[bitsarray[7:12],1,1]
	
	else: begin
	print,'Overflow Error!'
	print,'Returning Nonsense...'
	output=bitsarray[0:7]
	end
	
endcase

for i=0,7 do output[i]*=2^i
output_byte=byte(total(output))

return,output_byte
end