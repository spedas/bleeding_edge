function get_plot_state

common plot_state_com, pstates
ps = {d:!d,p:!p,x:!x,y:!y,z:!z,map:!map}

if ~keyword_set(pstates) then  pstates = replicate(fill_nan(ps),64)
w = !d.window
pstates[w] = ps

return,ps
end
