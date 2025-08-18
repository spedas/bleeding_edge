;+
;
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-07-21 09:58:52 -0700 (Mon, 21 Jul 2025) $
; $LastChangedRevision: 33476 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_adc_map.pro $
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


;+
;FUNCTION:  SWFO_STIS_ADC_MAP
;PURPOSE: Generates the bins and bin widths used by SWFO STIS
; depending on:
; - uselut_flag: 1 if uploaded LUT is in-use, else 0.
;     The "U" in PTCU_BITS. Typically False
; - linear_mode: 1 if NONLUT_MODE is not 0, else 0.
;     Second bit in DETECTOR_BITS. Typically 0 (AKA logarithmic bins).
; - resolution: the pulse height resolution in ADC units, used only if linear_mode.
;     Typically 3
; - translate: offset of the pulse height in ADC units
;     Typically 16
;
; Function returns a dictionary containing multiple 48 (# pulse height bins)
; x 14 (# coincidences) arrays:
; - adc0: lower edge of the bin in ADC units
; - dadc: width of bin in ADC units
; - adc_n: midpoint of bin in ADC units
; - mnrg: measured energy
; - geom: Geometric factor
; - ftoi

; Test the function using :
; map = swfo_stis_adc_map(data_sample={ptcu_bits: [0, 0, 1, 0], detector_bits: [1, 0, 63], sci_resolution: 3, sci_translate: 16})
;
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-07-21 09:58:52 -0700 (Mon, 21 Jul 2025) $
; $LastChangedRevision: 33476 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_adc_map.pro $
; $ID: $
;-


function swfo_stis_adc_map, data_sample=data_sample, cal=cal

  common swfo_stis_adc_map_common,adcmap
  
  if ~isa(adcmap,'dictionary') then begin
    adcmap = dictionary()
    adcmap.codes = 0
  endif
  ; adcmap.codes = 0
  
  ; These are the old struct value commands that returned a default
  ; but don't make sense since these are defined:
  ; lut_map        = struct_value(data_sample,'lut_map',default=6)
  ; lut_mode       = struct_value(data_sample,'xxxx',default=1)
  ; linear_mode    = struct_value(data_sample,'SCI_NONLUT_MODE',default=0) ne 0
  ; resolution     = fix(struct_value(data_sample,'SCI_RESOLUTION',default=3))
  ; translate      = fix(struct_value(data_sample,'SCI_TRANSLATE',default=32))

  ; LUT mode:
  ptcu_bits = data_sample.ptcu_bits
  if n_elements(ptcu_bits) eq 4 then uselut_bit = ptcu_bits[3] else uselut_bit = ptcu_bits and 1
  uselut_flag = uselut_bit ne 0
  ; NOAA detector bits are three elements with the second
  ; representing the nonlut mode (AKA linear mode)
  detector_bits = data_sample.detector_bits 
  if n_elements(detector_bits) eq 3 then linear_mode = detector_bits[1] else $
    linear_mode = (detector_bits and 64) ne 0
  resolution = data_sample.sci_resolution
  translate = data_sample.sci_translate
 

 ; stop 
  codes = [translate,resolution,linear_mode,uselut_flag]

 ; print, codes  
  if array_equal(codes,adcmap.codes) then return,adcmap

  if ~isa(cal,'dictionary') then cal = swfo_stis_inst_response_calval()

  adcmap.codes = codes
  
  dprint,'Generating new ADC map: ',codes,dlevel=2

  ftoi_n = intarr(48,14)
  adc0_n = lonarr(48,14)
  dadc_n = lonarr(48,14)
  ; clog_17_6=[  0,     1,     2,     3,     4,     5,     6,     7,     8,     10,    12,     14,$
  ;   16,    20,    24,    28,    32,    40,    48,    56,    64,     80,    96,    112,$
  ;   128,   160,   192,   224,   256,   320,   384,   448,   512,    640,   768,    896,$
  ;   1024,  1280,  1536,  1792,  2048,  2560,  3072,  3584,  4096,   5120,  6144,   7168,$
  ;   2L^13    ]
  clog_17_6 = cal.nonlut_adc_min
  kev_per_adc = cal.detector_keV_per_adc
  geomfactor = cal.geometric_factor
  ftoi = cal.coincidence_map
  coincidence_index = cal.geometric_factor_coincidence_index
  adcm = cal.adc_coincidence_multiplier

  ; center_adc_bins = [    234.06952     ,  228.35745    ,  231.78710     ,  232.06377      ,  232.78850      ,  231.65691    ]  
  ;kev_per_adc = 59.5 / ( [25.12, 22.58, 25.65, 25.48, 23.61,  24.7 ] *8)
  ;kev_per_adc = 5500. / ( [5500.,5500.,5500.,5500.,5500.,5500.] * 4)
  ; kev_per_adc = 59.5 / center_adc_bins
  ; kev_per_adc = [!values.f_nan,kev_per_adc]
  ; geomfactor  = .2  * [.01,1,1,.01,1,1]
  ; geomfactor  = [!values.f_nan,geomfactor]
  ; channel_n = [1,4,2,5,0,0,3,6,0,0,0,0,0,0]
  conv_n = replicate(!values.f_nan,48,14)
  geom_n = replicate(!values.f_nan,48,14)
  
  ; ADC bins for all 14 coincidences are the same*
  ; (as long as non-LUT mode) but are scaled by
  ; 2 (3) for double (triple) coincidences
  if linear_mode then begin
    adc0 =[ 0,  ( (lindgen(47)+1) * 2L ^ resolution ) + translate  < 2L^15 , 2L^15 ]
    ; adc0 =[ 0,  ( (lindgen(47)+1) * resolution ) + translate  < 2L^15 , 2L^15 ]
    d_adc0 = shift(adc0 ,-1) - adc0
    adc0 = adc0[0:47]
    d_adc0 = d_adc0[0:47]
  endif else begin
    adc0 = [0, (clog_17_6[1:*])  * 4  + translate < 2L^15 , 2L^15 ]      ; low adc threshold
    d_adc0 = shift(adc0 ,-1) - adc0
    adc0 = adc0[0:47]               ; this might be incorrect for some pattern
    d_adc0 = d_adc0[0:47] 
  endelse


  for n= 0,13 do begin

    ftoi_n[*,n] = n
    adc0_n[*,n] = adc0 * adcm[n]
    dadc_n[*,n] = d_adc0 * adcm[n]
    
    conv_n[*,n] = kev_per_adc[coincidence_index[n]] 
    geom_n[*,n] = geomfactor[coincidence_index[n]]


  endfor

  wh = orderedhash()
  foreach p, ftoi, k do wh[k] = where(ftoi_n eq p,/null)

  adc_n  = adc0_n + dadc_n/2.

 dprint, dlevel=2, 'First ten energies: ', (adc_n * conv_n)[0:10]

  adcmap.wh   = wh
  adcmap.ftoi = ftoi_n
  adcmap.adc0 = adc0_n
  adcmap.dadc = dadc_n
  adcmap.adc  = adc_n
  adcmap.nrg  = adc_n * conv_n  ; measured energy
  adcmap.dnrg = dadc_n * conv_n
  adcmap.geom = geom_n
  
  if min(adcmap.dnrg) le 0 then begin
    dprint,dlevel=3,'Coding error', min(adcmap.dnrg)
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




