;+
; NAME: 
;    THM_ASI_STATIONS.PRO
;
; PURPOSE: 
;    define quantities for GBO stations
;
; CATEGORY:
;    None
;
; CALLING SEQUENCE:
;    thm_asi_stations,labels,location
;
; INPUTS:
;    None
;
; OPTIONAL INPUTS:
;    None
;
; KEYWORD PARAMETERS:
;    id		IP Adress of stations, now obsolete but we keep them for now
;    epo        names and locations of EPO sites
;
; OUTPUTS:
;    labels	Names of GBO stations
;    location	Geographic location of stations
;
; OPTIONAL OUTPUTS:
;    None
;
; COMMON BLOCKS:
;    None
;
; SIDE EFFECTS:
;    None
;
; RESTRICTIONS:
;    None
;
; EXAMPLE:
; 
;
; MODIFICATION HISTORY:
;    Written by: Harald Frey
;                Version 1.0 August, 23, 2006
;                        1.1 09/29/06 changed order of UMIJ and CHBG
;			 1.2 10/04/06 replaced UMIJ with SNKQ
;                        1.3 03/19/07 added EPO, corrected typo
;			 1.4 11/16/07 exchanged NAIN for KUUJ
;			 1.5 03/17/08 added YKNF
;                        1.6 10/09/08 added NRSQ
;
; VERSION:
;   $LastChangedBy: hfrey $
;   $LastChangedDate: 2008-11-19 14:50:04 -0800 (Wed, 19 Nov 2008) $
;   $LastChangedRevision: 4004 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_asi_stations.pro $
;     
;-

pro thm_asi_stations,labels,location,id=id,epo=epo

	; initialize
labels=['XXXX']
idn='  '
location=[0.,0.]

	; fill
location=[[location],[66.971 ,  199.562 ]]  &   labels=[labels,'KIAN']	& idn=[idn,'/0.0.0.0/'] 		; 200 67
location=[[location],[62.953 ,  204.404 ]]  &   labels=[labels,'MCGR']	& idn=[idn,'/24.237.246.14/'  ] 	; 205 63	; starting  04/07/2006
location=[[location],[66.560 ,  214.786 ]]  &   labels=[labels,'FYKN']	& idn=[idn,'/137.229.18.46/'  ] 	; 215 66	; starting 02/10/06
location=[[location],[62.407 ,  214.842 ]]  &   labels=[labels,'GAKO']	& idn=[idn,'/0.0.0.0/'] 		; 215 62
location=[[location],[68.413 ,  226.230 ]]  &   labels=[labels,'INUV']	& idn=[idn,'/69.156.233.194/' ] 	; 226 68
location=[[location],[61.010 ,  224.777 ]]  &   labels=[labels,'WHIT']	& idn=[idn,'/207.189.243.18/' ] 	; 225 61
location=[[location],[61.762 ,  238.779 ]]  &   labels=[labels,'FSIM']	& idn=[idn,'/0.0.0.0/'] 		; 239 62
location=[[location],[53.815 ,  237.172 ]]  &   labels=[labels,'PGEO']	& idn=[idn,'/69.156.232.74/'  ] 	; 237 54
location=[[location],[64.733 ,  249.330 ]]  &   labels=[labels,'EKAT']	& idn=[idn,'/57.68.50.198/'   ] 	; 249 65
location=[[location],[59.984 ,  248.158 ]]  &   labels=[labels,'FSMI']	& idn=[idn,'/69.156.233.146/' ] 	; 248 60
location=[[location],[54.714 ,  246.686 ]]  &   labels=[labels,'ATHA']	& idn=[idn,'/131.232.13.26/'  ] 	; 246 55
location=[[location],[53.994 ,  259.059 ]]  &   labels=[labels,'TPAS']	& idn=[idn,'/69.156.233.178/' ] 	; 259 54
location=[[location],[62.828 ,  267.887 ]]  &   labels=[labels,'RANK']	& idn=[idn,'/216.126.240.6/'  ] 	; 267 62
location=[[location],[56.354 ,  265.344 ]]  &   labels=[labels,'GILL']	& idn=[idn,'/69.156.232.66/'  ] 	; 265 56
location=[[location],[50.163 ,  263.934 ]]  &   labels=[labels,'PINA']	& idn=[idn,'/206.186.45.191/' ] 	; 264 50
location=[[location],[49.392 ,  277.680 ]]  &   labels=[labels,'KAPU']	& idn=[idn,'/206.47.241.178/' ] 	; 277 49
location=[[location],[56.536 ,  280.769 ]]  &   labels=[labels,'SNKQ']	& idn=[idn,'/0.0.0.0/'] 		; 291 52
location=[[location],[49.814 ,  285.581 ]]  &   labels=[labels,'CHBG']	& idn=[idn,'/0.0.0.0/'] 		; 292 55
location=[[location],[58.155 ,  291.468 ]]  &   labels=[labels,'KUUJ']	& idn=[idn,'/0.0.0.0/'] 		; 298 56
location=[[location],[53.316 ,  299.540 ]]  &   labels=[labels,'GBAY']	& idn=[idn,'/207.236.9.182/'  ] 	; 299 53
location=[[location],[62.520 ,  245.687 ]]  &   labels=[labels,'YKNF']	& idn=[idn,'/0.0.0.0/'  ] 		; 
location=[[location],[63.580 ,  249.130 ]]  &   labels=[labels,'SNAP']	& idn=[idn,'/0.0.0.0/'  ] 		; 
location=[[location],[61.162 ,  314.558 ]]  &   labels=[labels,'NRSQ']	& idn=[idn,'/0.0.0.0/'  ] 		; 
location=[[location],[69.546 ,  266.423 ]]  &   labels=[labels,'TALO']	& idn=[idn,'/0.0.0.0/'  ] 		; 
; pgeo ist 7
;label[7]='TALO'	; Taloyoak
;location[*,7]=[69.546667,360.-93.576667]

	; old IP-Addresses
;location=[[location],[62.953 ,  204.404 ]]  &   labels=[labels,'MCGR']	& idn=[idn,'/24.237.236.231/' ] 	; 205 63  ; before 04/01/06
;location=[[location],[66.560 ,  214.786 ]]  &   labels=[labels,'FYKN']	& idn=[idn,'/137.229.27.85/'  ] 	; 215 66  ; before 02/09/2006

	; EPO sites
if Keyword_set(epo) then begin

	; Bay Mills is inofficial THEMIS-EPO site, but we keep it
   school=['Petersburg CS','Western Nevada CC',$
        'Ukiah School','Hot Springs HS','Red Cloud HS','Fort Yates PS',$
        'Shawano Community HS','Chippewa Hills HS','Bay Mills CC','N. Bedford County HS',$
        'North Country Union Jr HS','San Gabriel','Table Mountain']
   city=['Petersburg, AK','Carson City, NV',$
        'Ukiah OR','Hot Springs, MT','Pine Ridge, SD','Fort Yates, ND',$
        'Shawano, WI','Remus, MI','Brimley, MI','Loysburg, PA',$
        'Derby, VT','San Gabriel, CA','Table Mountain, CA']
   code=['PTRS','CCNV','UKIA','HOTS','PINE','FYTS','SWNO','RMUS','BMLS','LOYS','DRBY','SGD1','TBLE']
   latitude=[56.83,39.19,$
             45.13,47.59,43.11,46.09,$
             44.78,43.60,46.24,40.17,$
             44.95,34.20,34.38]
   longitude=[-133.16,-119.78,$
              -118.93,-114.66,-102.60,-100.65,$
              -88.60,-85.16,-84.34,-78.38,$
              -72.13,-117.85,-117.68]
   epo=create_struct('school',school,'city',city,'code',code,'latitude',latitude,'longitude',longitude)
   endif


	; return values
labels=labels[1:*]
location=location[*,1:*]
if keyword_set(id) then id=idn[1:*]

end
