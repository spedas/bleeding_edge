pro mav_sep_lut_decom,lut,brr=brr,labels=labels,colors=colors,binstr=binstr

names = strsplit('X O T OT F FO FT FTO',/extract)
names = transpose([[names+'_0'],[names+'_1']])
colors =     [0,0,2,2,4,4,1,1,6,6,0,0,3,3,5,5]
multiplier = [0,0,1,1,1,1,2,2,1,1,0,0,2,2,4,4]
names[[0,1,10,11]] = 'X'

lutt = reform(lut,4096,16)

over=0
brr=0
if arg_present(binstr) then binstr ={foo:1}
for t=0,16-1 do begin
    if names[t] eq 'X' then continue
    luts = reform(lutt[*,t])
;    cgplot,over=over,luts,color=colors[t]
    over=1
    br= minmax(luts)
    mlt = multiplier[t]
    if arg_present(binstr) then begin
        bins=0
        for b = br[0],br[1] do begin
;    dprint,names[t],br
            adc = where(luts eq b,nb)
            if nb ne 0 then begin
                range = (minmax(adc)+[0,1]) * mlt - [0,1]
                append_array,bins,{bin:b, adc:range,  width:nb *mlt, ok:nb eq (range[1]-range[0]+1)}
            endif
        endfor
        binstr =    create_struct(binstr,names[t],bins)
    endif
    append_array,brr,br
    append_array,labels,[names[t],'      '+names[t]]
endfor

;savetomain,labels

end



