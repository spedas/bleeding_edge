;+
;NAME:
; thm_roi_bar
;PURPOSE:
; creates the roi bar for overview plots
;CALLING SEQUENCE:
; p = thm_roi_bar(in_data)
;
; INPUT:
;  in_data: the name of the roi variable to
;           be plotted(generally something like 'thb_state_roi'
;
;OUTPUT:
; p = the variable name of the roi_bar, set to '' if not
; successfule
;HISTORY:
; 2007-02-28 pcruce@ssl.berkeley.edu
; 
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-01-25 15:07:47 -0800 (Fri, 25 Jan 2008) $
; $LastChangedRevision: 2315 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/themis/common/thm_sample_rate_bar.pro $
;-

function thm_roi_bar,in_data

compile_opt idl2

bit_mask = [1,1,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,1]

get_data,in_data,data=d,dlimit=dl

if ~is_struct(d) then begin

  store_data,'dummy_roi_bar',data={x:[0,0],y:[0,0]}
  options,'dummy_roi_bar',panel_size=.3
  return,'dummy_roi_bar
  
endif

in = d.y
out = ulonarr(n_elements(in))

j = 0
;packs all the requested bits to the left
for i = 0,n_elements(bit_mask)-1 do begin

   out += ishft(in and ishft(bit_mask[i],i),-j)

   if ~bit_mask[i] then j++

endfor

t = total(bit_mask)

if t le 16 then begin

   out = uint(out)

endif

d = {x:d.x,y:out}

str_element,dl,'ysubtitle',/delete
store_data,in_data+'_bar',data=d,dlimit=dl

;set aesthetic options

;colors alternate
options,in_data+'_bar',colors=10+indgen(t)*7*245/t mod 245
options,in_data+'_bar',tplot_routine='bitplot'
options,in_data+'_bar',numbits=t
options,in_data+'_bar',ytitle='ROI'
options,in_data+'_bar',panel_size=.3
options,in_data+'_bar',psyms=6
options,in_data+'_bar',symsize=.0125
;kill the ticks
options,in_data+'_bar',ticklen=0
options,in_data+'_bar',yticks=1
options,in_data+'_bar',ytickname=[' ',' ']

return,in_data+'_bar'

end
