;+
;
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-02-24 16:27:51 -0800 (Fri, 24 Feb 2023) $
; $LastChangedRevision: 31520 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_crib.pro $
; $ID: $
;-


;

function integration_width_matrix,x_edges,bin_centers,bin_widths   ; not finished yet
  ns = n_elements(x_edges)
  nb = n_elements(bin_centers)
  matrix = dblarr(nb,ns)
  xmid = (x_edges[0:-2] + x_edges[1:-1])/2d    ; size ns-1
  ;xmid = [x_edges[0], xmid, x_edges[-1] ]      ; size ns+1
  xwid = [0, abs(xmid[1:-1] - xmid[0:-2] ) ]               ; size ns
  for b=0,nb-1 do begin
    center = bin_centers[b]
    width  = bin_widths[b]
    bmin = center-width/2.d
    bmax = center+width/2.d
    ;r = x_edges ge bmin and x_edges le bmax
    indf = interp(dindgen(ns),x_edges,[bmin,bmax],index=i)
    
    w = where( x_edge  ,nw,/null)
    printdat,indf,i,xmid
    
    ;matrix[b,*] = r * xwid      ; 
  ;  i1 = interp(dindgen(ns-1), xsample[0:-2], r )
  ;  i2 = interp(dindgen(ns-1), xsample[1:-1], r )
  endfor

  return,reform(matrix)
end






function swfo_stis_adc_map, data_sample=data_sample

  common swfo_stis_adc_map_common,adcmap
  
  if ~isa(adcmap,'dictionary') then begin
    adcmap = dictionary()
    adcmap.codes = 0
  endif
  adcmap.codes = 0
  
  lut_map        = struct_value(data_sample,'lut_map',default=6)
  lut_mode       = struct_value(data_sample,'xxxx',default=1)
  linear_mode    = struct_value(data_sample,'SCI_NONLUT_MODE',default=0) ne 0
  resolution     = fix(struct_value(data_sample,'SCI_RESOLUTION',default=3))
  translate      = fix(struct_value(data_sample,'SCI_TRANSLATE',default=32))
  
  codes = [translate,resolution,linear_mode,lut_mode,lut_map]
  
  if array_equal(codes,adcmap.codes) then return,adcmap

  adcmap.codes = codes
  
  dprint,'Generating new ADC map: ',codes,dlevel=3

  ftoi_n = intarr(48,14)
  adc0_n = lonarr(48,14)
  dadc_n = lonarr(48,14)
  clog_17_6=[  0,     1,     2,     3,     4,     5,     6,     7,     8,     10,    12,     14,$
    16,    20,    24,    28,    32,    40,    48,    56,    64,     80,    96,    112,$
    128,   160,   192,   224,   256,   320,   384,   448,   512,    640,   768,    896,$
    1024,  1280,  1536,  1792,  2048,  2560,  3072,  3584,  4096,   5120,  6144,   7168,$
    2L^13    ]

  ftoi = orderedhash()
  ftoi['o1'] =2
  ftoi['o2'] =4
  ftoi['o3'] =8
  ftoi['f1'] =3
  ftoi['f2'] =5
  ftoi['f3'] =9
  wh = orderedhash()
  
  center_adc_bins = [    234.06952     ,  228.35745    ,  231.78710     ,  232.06377      ,  232.78850      ,  231.65691    ]  

  
  ;channel = orderedhash('o1',1,'o2',2,'o3',3,'f1',4,'f2',5,'f3',6)
  ;kev_per_adc = 59.5 / ( [25.12, 22.58, 25.65, 25.48, 23.61,  24.7 ] *8)
  ;kev_per_adc = 5500. / ( [5500.,5500.,5500.,5500.,5500.,5500.] * 4)
  kev_per_adc = 59.5 / center_adc_bins
  kev_per_adc = [!values.f_nan,kev_per_adc]
  geomfactor  = .2  * [.01,1,1,.01,1,1]
  geomfactor  = [!values.f_nan,geomfactor]
  channel_n = [1,4,2,5,0,0,3,6,0,0,0,0,0,0]
  conv_n = replicate(!values.f_nan,48,14)
  geom_n = replicate(!values.f_nan,48,14)

;  foreach c, channel, k do begin
;    conv[wh[k]]
;  endforeach
  
  for n= 0,13 do begin
    if linear_mode then begin
      adc0 =[ 0,  ( (lindgen(47)+1) * 2L ^ resolution ) + translate  < 2L^15 , 2L^15 ]
      d_adc0 = shift(adc0 ,-1) - adc0
      adc0 = adc0[0:47]
      d_adc0 = d_adc0[0:47]
    endif else begin
      adc0 = [0, (clog_17_6[1:*])  * 4  + translate < 2L^15 , 2L^15 ]      ; low adc threshold
      d_adc0 = shift(adc0 ,-1) - adc0
      adc0 = adc0[0:47]               ; this might be incorrect for some pattern
      d_adc0 = d_adc0[0:47] 
    endelse
    
    ftoi_n[*,n] = n+2
    adc0_n[*,n] = adc0
    dadc_n[*,n] = d_adc0
    
    conv_n[*,n] = kev_per_adc[ channel_n[n] ] 
    geom_n[*,n] = geomfactor[ channel_n[n] ]

  endfor

  foreach p, ftoi, k do begin
    wh[k] = where(ftoi_n eq p,/null)
  endforeach

  adc_n  = adc0_n + dadc_n/2.


  adcmap.wh   = wh
  adcmap.ftoi = ftoi_n
  adcmap.adc0 = adc0_n
  adcmap.dadc = dadc_n
  adcmap.adc  = adc_n
  adcmap.nrg  = adc_n * conv_n
  adcmap.dnrg = dadc_n * conv_n
  adcmap.geom = geom_n
  
  if min(adcmap.dnrg) le 0 then begin
    dprint,dlevel=2,'Coding error', min(adcmap.dnrg)
  endif
  
  return,adcmap
  
end




;
;ws_4 = [4]*6 + [8]*6 + [16,32,64,128,256]
;wd_4 = [2]*6 + [4]*6 + [8,16,32,64,128]
;wt_4 = [1]*6 + [2]*6 + [4,8,16,32,64]
;
;map4={'id':4, 'channels':[
;{'name':'O',  'tid':0,'fto':1,'widths':ws_4} ,
;{'name':'T',  'tid':0,'fto':2,'widths':ws_4} ,
;{'name':'F',  'tid':0,'fto':4,'widths':ws_4} ,
;{'name':'OT', 'tid':0,'fto':3,'widths':wd_4} ,
;{'name':'FT', 'tid':0,'fto':6,'widths':wd_4} ,
;{'name':'FO', 'tid':0,'fto':5,'widths':wd_4} ,
;{'name':'FTO','tid':0,'fto':7,'widths':wt_4} ,
;{'name':'O',  'tid':1,'fto':1,'widths':ws_4} ,
;{'name':'T',  'tid':1,'fto':2,'widths':ws_4} ,
;{'name':'F',  'tid':1,'fto':4,'widths':ws_4} ,
;{'name':'OT', 'tid':1,'fto':3,'widths':wd_4} ,
;{'name':'FT', 'tid':1,'fto':6,'widths':wd_4} ,
;{'name':'FO', 'tid':1,'fto':5,'widths':wd_4} ,
;{'name':'FTO','tid':1,'fto':7,'widths':wt_4} ] }
;

;def memmap4(map= map4):
;sstcmd(0x090000)
;for tid in range(2):
;startbin = tid * 128
;for ch in map['channels']:
;print(ch)
;fto = ch['fto']
;tid = ch['tid']
;memfilladr(fto,tid,level=0)
;print(startbin, ch['name'], tid, ch['fto'], ch['widths'])
;startbin = memfill_list(startbin=startbin,widths=ch['widths'])
;print(startbin)
;sstcmd(0x090000 + map['id'])




