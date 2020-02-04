;+
;
;
;
; SPP_SWP_SWEEPV_NEW_FSLUT_V2
;
; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2020-02-03 14:37:14 -0800 (Mon, 03 Feb 2020) $
; $LastChangedRevision: 28269 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_sweepv_new_fslut_v2.pro $
;
;-

PRO spp_swp_sweepv_new_fslut_v2, sweepv,defv1,defv2,spv,index,nen=nen, e0=e0,emax=emax, version=version,plot=plot,spfac=spfac,new_defl=new_defl
  
  ;; NOTE: Need to add peak-detect bit to 
  ;; this when I make it into a table
  
  ;; Number of energies in coarse sweep 
  ;; (full table has 4x as many)
  if not keyword_set(nen) then nen = 32 

  ;; Create new S-LUT
  spp_swp_sweepv_new_v2,sweepv,defv1,defv2,spv, plot = plot, nen=nen * 4,e0=e0,emax=emax,spfac=spfac,version=version,new_defl=new_defl
  
  ;; Number of angles in coarse sweep, 
  ;; taking into account sub-steps
  nang = 256/nen * 4            
  
  index = []
  if ~ keyword_set(version) then version = 2
  
  ;; This makes sure we go one way w/ deflectors 
  ;; on even steps, and the other on odds
  
  if  version ge 2 then begin    
    for e=0,nen-1 do begin
      ind = (e*4+2) * nang + indgen(nang)
      if e mod 2 then ind = reverse(ind)
      index = [index, ind]
    endfor
  endif else begin
    for i = 0,nen-1 do begin
      flip = i mod 2
      index = [index,(i*4+2-flip)*nang+indgen(nang)]
    endfor    
  endelse



  if keyword_set(plot) then begin
     ;print,nen,nang
     wi,2
     !p.multi = [0,1,3]
     plot,sweepv[index],psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage',$
          yrange = [0,4000],$
          charsize = 2,/xstyle
     oplot,defv1[index]*sweepv[index],color = 50,psym = 10
     oplot,defv2[index]*sweepv[index],color = 250,psym = 10
     plot,sweepv[index],psym=10,$
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage (Log)',$
          yrange = [0.1,4000],$
          /ylog,$
          charsize = 2,$
          /ystyle,/xstyle
     oplot,defv1[index]*sweepv[index],color = 50,psym = 10
     oplot,defv2[index]*sweepv[index],color = 250,psym = 10
     oplot,spv[index]*sweepv[index],color = 150,psym = 10     
     plot,defv1[index],psym = 10, $
          xtitle = 'Time Step',$
          ytitle = 'Sweep Voltage Ratio',$
          charsize = 2,$
          yrange = [0,12],/xstyle
     oplot,defv1[index],psym=10,color = 50
     oplot,defv2[index],color = 250,psym = 10
     oplot,spv[index],color = 150,psym = 10
     !p.multi = 0          
     wi,4     
     symsize = .6
     plot,sweepv,defv1-defv2,$,xstyle=3,ystyle=3
          psym = 7,$
          symsize=symsize,$
          /xlog,/xstyle,/ystyle, $
          xtitle = 'V_SWEEP (Volts)',$
          ytitle = 'V_DEF/V_SWEEP (D1+, D2-)',$
          charsize = 2, yrange = [-12., 12.]
     plots,sweepv[index],defv1[index]-defv2[index], $
           psym = 7,color = 150,symsize=symsize
     oplot,sweepv[index],defv1[index]-defv2[index],symsize=symsize,  psym = -4,color = 2
  endif
  
end
