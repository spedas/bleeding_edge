pro alfven_plot,num

if not keyword_set(num) then num=1

title = 'Low frequency Waves'
case num of
2: sum='wi_B3_mag wi_B3_th wi_B3_phi wi_B3_wvs_pow wi_B3_wvs_rat_par wi_B3_wvs_pol_perp wi_B3_Vp_xwv_d_p-a spiral_angle'
3: sum='Np Vp_mag Vth/V wi_B3_mag wi_B3_th wi_B3_phi wi_B3_wvs_pow wi_B3_wvs_rat_par wi_B3_wvs_pol_perp wi_B3_Vp_xwv_d_p-a spiral_angle'
else:  sum='wi_B3_mag wi_B3_th wi_B3_phi wi_B3_wv_pow wi_B3_wv_rat_par wi_B3_wv_pol_perp wi_B3_Vp_xwv_d_p-a spiral_angle'
endcase
tplot,sum,title=title

end
