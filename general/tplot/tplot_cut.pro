;+  This routine is in development ... Expect changes

pro tplot_cut,name,time,value

get_data,name,ptr=p,alim=alim
if not keyword_set(p) then return


ind=dindgen(n_elements(*p.x))
i = round(interp(ind,*p.x,time,/no_extrapolate))

;jmm, 24-jul-2009, fix crash where i is set to -2147483648 when cursor
;is scrolled off the plot
i = i > 0L & i = i < (n_elements(*p.x)-1)

ndy = size(/n_dimen,*p.y)

case  ndy of
 3:    begin
          str_element,alim,'irange',irange
          ;printdat,irange
          im = reform( (*p.y)[i,*,*] )
         ; print,minmax(im)
          tv,bytescale(im,range=irange,log=zlog)
       end
 2:    begin
          y = reform( (*p.y)[i,*] )
          ndv = size(/n_dimen,*p.v)
          if ndv eq 2 then v = reform( (*p.v)[i,*] )
          if ndv eq 1 then v = reform( (*p.v) )
          if ndv gt 0 then plot,v,y
       end
 else:
endcase

end

