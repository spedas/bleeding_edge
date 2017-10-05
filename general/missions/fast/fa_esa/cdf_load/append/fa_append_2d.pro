;Merges array2 (with pointers index2) with array1 (with pointers index1) without condensing array1.
pro fa_append_2d,array1,array2,index1,index2,array,index,max_index,map

ndimensions1=size(array1,/dimensions)
ndimensions2=size(array2,/dimensions)
if ndimensions1[0] NE ndimensions2[0] then begin
	print,'Error: Dimensions Do Not Agree'
	return
endif
if ndimensions1[1] NE ndimensions2[1] then begin
	print,'Error: Dimensions Do Not Agree'
	return
endif
if n_elements(ndimensions1) EQ 2 then ndimensions1=[ndimensions1[0],ndimensions1[1],1]
if n_elements(ndimensions2) EQ 2 then ndimensions2=[ndimensions2[0],ndimensions2[1],1]
max_index=ndimensions1[2]-1
mod_index2=index2
map=intarr(ndimensions2[2])

array=replicate(array1[0],ndimensions1[0],ndimensions1[1],ndimensions1[2]+ndimensions2[2])
array[*,*,0:max_index]=array1

for iii=0,ndimensions2[2]-1 do begin
	flag=1
	for jjj=0,ndimensions1[2]-1 do begin
		test=equal_arrays(array2[*,*,iii],array1[*,*,jjj],tolerance=.001,/silence)
		if test EQ 1 then begin
			map[iii]=jjj
			wherearray=where(index2 EQ iii)
			if wherearray[0] NE -1 then mod_index2[wherearray]=jjj
			flag=0
			break
		endif
	endfor
	if flag then begin
		++max_index
		map[iii]=max_index
		wherearray=where(index2 EQ iii)
		if wherearray[0] NE -1 then mod_index2[wherearray]=max_index
		array[*,*,max_index]=array2[*,*,iii]
	endif
endfor

index=[index1,mod_index2]
array=array[*,*,0:max_index]

return

end