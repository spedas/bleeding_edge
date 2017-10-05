function get_plot_state

common plot_state_com, pstates
ps = {plot_state,d:!d,p:!p,x:!x,y:!y,z:!z}

if ~keyword_set(pstates) then  pstates = replicate(fill_nan(ps),32)
w = !d.window
pstates[w] = ps

return,ps
end
