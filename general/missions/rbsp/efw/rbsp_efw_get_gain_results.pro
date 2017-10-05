;+
; NAME:
;   rbsp_efw_get_gain_results
;
; PURPOSE:
;   return structure with freq-dependent calibration curves for the searchcoil and EDC 
;	channnels on EFW. Also includes notes on how to apply the calibration
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   x = rbsp_efw_get_gain_results()
;
; ARGUMENTS:
;
; KEYWORDS:
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2013-05-15: Created by Aaron Breneman (UMN)
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2013-05-16 13:03:08 -0700 (Thu, 16 May 2013) $
; $LastChangedRevision: 12351 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_get_gain_results.pro $
;
;-


function rbsp_efw_get_gain_results


;Different freqs tested during the CIT freq-sweep test
freq_cit = [2.14,4.27,6.41,8.55,10.68,12.82,14.95,17.09,19.23,21.36,23.5,25.63,27.77,30.98,$
	35.25,39.52,43.79,49.13,55.54,63.02,71.56,80.11,89.72,100.4,112.2,126,142.1,159.2,$
	178.4,199.7,224.3,252.1,282,316.2,354.6,398.4,447.5,502.1,562.9,631.3,709.2,795.8,$
	891.9,1001,1124,1261,1415,1587,1781,1998,2243,2516,2823,3168,3555,3988,4474,5020,$
	5633,6320,7091,7956,8927,10020]

;Peak-to-peak counts for SCM channel with bandwidth limiter and attenuator ON
NscmU_a = [487,994,1358,1774,2077,2174,2390,2541,2657,2731,2800,2899,2930,3013,3023,3096,$
		3057,3191,3141,3126,3142,3133,3144,3104,3103,2979,2959,2937,2805,2768,2720,2521,$
		2435,2331,2228,2112,1971,1879,1675,1519,1441,1352,1243,1148,1017,932,882,806,721,$
		695,636,610,574,509,522,427,500,393,437,415,422,404,365,323]
NscmV_a = [422,840,1194,1518,1781,1973,2142,2261,2423,2508,2573,2678,2688,2739,2789,2785,$
		2881,2900,2857,2916,2850,2863,2830,2804,2754,2716,2713,2650,2535,2504,2402,2315,$
		2203,2128,2000,1871,1764,1617,1466,1364,1270,1139,1094,994,856,808,729,668,608,$
		574,520,494,443,372,401,333,376,284,272,274,321,319,257,219]
NscmW_a = [529,1087,1402,1711,2010,2129,2275,2479,2573,2752,2707,2873,2847,2918,2994,3061,$
		3045,3140,3138,3121,3118,3119,3093,3112,3086,2985,2938,2909,2773,2808,2762,2561,$
		2540,2377,2255,2137,2102,1919,1783,1639,1505,1406,1325,1219,1169,1008,1016,938,$
		849,802,801,694,674,600,664,593,640,499,565,558,601,467,454,415]
NscmU_b = [601,1193,1538,1882,2154,2376,2551,2542,2774,2879,2900,2945,2990,3068,3175,$
		3189,3195,3231,3202,3233,3188,3180,3274,3188,3130,3155,3053,2954,2894,2881,2714,$
		2596,2518,2379,2312,2219,1981,1936,1777,1718,1486,1371,1359,1191,1189,1061,1025,$
		974,810,849,797,790,764,679,679,642,594,563,549,628,557,506,506,510]
NscmV_b = [480,839,1249,1535,1708,1888,2121,2198,2380,2440,2526,2566,2640,2733,2779,$
		2851,2795,2746,2795,2941,2854,2861,2882,2782,2824,2717,2682,2635,2592,2504,2454,$
		2340,2264,2159,2057,1884,1799,1651,1585,1448,1371,1226,1114,1036,989,942,894,798,$
		660,691,657,684,508,526,541,510,394,412,452,456,454,386,303,304]
NscmW_b = [581,1042,1453,1701,1953,2161,2432,2407,2456,2671,2701,2882,2808,2915,2946,$
		3074,3036,3010,3047,3234,3106,3116,3103,3041,3007,3037,3056,2861,2832,2746,2632,$
		2503,2616,2346,2342,2172,2003,1887,1868,1599,1533,1355,1311,1156,1148,1102,1058,$
		1010,832,817,834,759,640,617,660,665,532,522,563,559,554,525,466,497]

;Peak-to-peak counts for EDC channels with attenuator and bandwidth limiters OFF
Ne12DC_a = [86,86,86,86,88,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,$
			86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,86,84,84,84,84,82,$
			82,80,78,78,76,74,70,66,62,56,52,44,36]
Ne34DC_a = [87,88,86,88,88,87,87,88,87,87,87,88,87,87,87,87,88,87,87,87,88,88,87,87,87,86,$
			87,87,87,87,87,87,86,87,87,87,88,87,87,86,87,86,86,85,86,86,85,84,86,84,84,83,$
			83,80,79,77,74,72,67,63,57,51,44,37]
Ne56DC_a = [85,86,85,86,85,85,86,85,85,85,85,85,85,85,86,85,86,86,85,85,86,86,86,86,86,86,$
			86,85,86,85,85,85,85,85,86,85,86,85,85,85,84,85,85,85,85,83,83,83,83,82,82,81,$
			79,78,77,75,71,68,65,63,56,50,43,36]

;At the moment I don't have the values for the freq-sweep test for RBSP-B
Ne12DC_b = Ne12DC_a

Ne34DC_b = Ne34DC_a

Ne56DC_b = Ne56DC_a


;Turn counts into volts for SCM
Gscm = 2.
Gedc = 50.
adc = (2.5/32768.)


VscmU_a = NscmU_a * adc * Gscm
VscmV_a = NscmV_a * adc * Gscm
VscmW_a = NscmW_a * adc * Gscm
Ve12DC_a = Ne12DC_a * adc * Gedc
Ve34DC_a = Ne34DC_a * adc * Gedc
Ve56DC_a = Ne56DC_a * adc * Gedc

VscmU_b = NscmU_b * adc * Gscm
VscmV_b = NscmV_b * adc * Gscm
VscmW_b = NscmW_b * adc * Gscm
Ve12DC_b = Ne12DC_b * adc * Gedc
Ve34DC_b = Ne34DC_b * adc * Gedc
Ve56DC_b = Ne56DC_b * adc * Gedc




;----------------------------------------------------------
;FREQ-RESPONSE TEST FOR THE EFW DC-COUPLED CHANNEL
;----------------------------------------------------------


;Since the EDC channel is DC-coupled its gain is unity at zero freq
Gain_e12DC_a = 1/(Ve12DC_a/Ve12DC_a[0])
Gain_e34DC_a = 1/(Ve34DC_a/Ve34DC_a[0])
Gain_e56DC_a = 1/(Ve56DC_a/Ve56DC_a[0])
Gain_e12DC_b = 1/(Ve12DC_b/Ve12DC_b[0])
Gain_e34DC_b = 1/(Ve34DC_b/Ve34DC_b[0])
Gain_e56DC_b = 1/(Ve56DC_b/Ve56DC_b[0])



notes_EDC = ['Heres how to go from a signal in counts to volts:',$
			'signal_V = signal_cnts * Gedc * adc',$
			'(V) = (counts) * (unitless) * (V/counts)',$
			'Now we correct for gain as a function of frequency',$
			'signal_V = signal_V * Gain_e12DC']

;----------------------------------------------------------
;FREQ-RESPONSE TEST FOR THE SEARCHCOIL
;----------------------------------------------------------


;Steps:
;1) the scope inputs a signal of 0.328 volts p-p
;2) this is applied to the stimulus coil which is in the mu-metal box. The mu-metal 
;	box changes the 0.328 volts signal into nT. This curve is a function of freq
;3) the searchcoil instrument detects this Bw signal, changing it back into volts
;4) the signal then propagates through the EMFISIS attenuator. 


;#1
Vin = 0.328   ;input signal from oscilloscope during CIT (volts p-p)

;#2

;Frequencies from the stimulus coil test (from Hospodarsky)
fstim = [2.14000,4.27000,6.41000,8.55000,10.6800,12.8200,14.9500,$
	17.0900,19.2300,21.3600,23.5000,25.6300,27.7700,30.9800,$
	35.2500,39.5200,43.7900,49.1300,55.5400,63.0200,71.5600,$
	80.1100,89.7200,100.400,112.200,126.000,142.100,159.200,$
	178.400,199.700,224.300,252.100,282.000,316.200,354.600,$
	398.400,447.500,502.100,562.900,631.300,709.200,795.800,$
	891.900,1001.00,1124.00,1261.00,1415.00,1587.00,1781.00,$
	1998.00,2243.00,2516.00,2823.00,3168.00,3555.00,3988.00,$
	4474.00,5020.00,5633.00,6320.00,7091.00,7956.00,8927.00,$
	10020.0,11240.0]

stimcoil_nTv_Ua = [2.35000,2.35000,2.35000,2.35000,2.35000,2.35000,2.35000,$
			2.35000,2.35000,2.35000,2.35000,2.35000,2.35000,2.35000,$
			2.33429,2.31452,2.29680,2.28690,2.25571,2.23387,2.22000,$
			2.21000,2.18281,2.17000,2.15000,2.13412,2.10333,2.07740,$
			2.05402,2.04452,2.03000,2.01424,2.00487,1.98017,1.95528,$
			1.93515,1.91011,1.89516,1.86080,1.84558,1.81547,1.79110,$
			1.76584,1.74590,1.71587,1.69197,1.66607,1.63624,1.60630,$
			1.57643,1.54644,1.51658,1.48668,1.45350,1.42366,1.38696,$
			1.35417,1.31718,1.28453,1.24737,1.21747,1.18758,1.15767,$
			1.12541,1.09569]
stimcoil_nTv_Va = [2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,$
			2.22000,2.22000,2.22000,2.22000,2.21000,2.20106,2.19000,$
			2.17429,2.15452,2.14680,2.12690,2.11571,2.10000,2.08000,$
			2.06239,2.05000,2.03337,2.01418,2.00000,1.98333,1.96370,$
			1.95402,1.93000,1.91444,1.89424,1.87487,1.85509,1.83528,$
			1.81515,1.79506,1.77516,1.75540,1.72558,1.70547,1.68555,$
			1.66584,1.63590,1.61587,1.58599,1.56607,1.53624,1.51261,$
			1.48643,1.45644,1.43317,1.40336,1.37350,1.33683,1.30696,$
			1.27417,1.24436,1.20453,1.17474,1.13747,1.10758,1.07534,$
			1.04541,1.01569]
stimcoil_nTv_Wa = [2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,$
			2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,$
			2.22000,2.21000,2.20000,2.18690,2.17000,2.15387,2.15000,$
			2.12239,2.10281,2.10000,2.08418,2.07000,2.05333,2.04000,$
			2.02402,2.00905,1.98888,1.97000,1.96000,1.94509,1.92528,$
			1.91515,1.89011,1.85032,1.83000,1.81558,1.79547,1.78000,$
			1.75584,1.73590,1.71587,1.69197,1.66607,1.64248,1.61630,$
			1.59286,1.56287,1.53317,1.50336,1.47350,1.43683,1.40392,$
			1.36708,1.33436,1.29726,1.26474,1.23495,1.19758,1.16767,$
			1.13771,1.10569]
stimcoil_nTv_Ub = [2.33000,2.33000,2.33000,2.33000,2.33000,2.33000,2.33000,$
			2.32941,2.32000,2.32000,2.30437,2.29934,2.28553,2.27000,$
			2.25429,2.23452,2.21680,2.19690,2.17571,2.15387,2.14189,$
			2.12239,2.11000,2.09337,2.07418,2.05412,2.03333,2.02000,$
			2.00402,1.97452,1.96444,1.94424,1.92487,1.90017,1.87528,$
			1.86515,1.84011,1.81000,1.79540,1.76558,1.74000,1.71555,$
			1.69585,1.66590,1.64587,1.61599,1.59214,1.56248,1.53261,$
			1.50643,1.47287,1.44317,1.41336,1.37675,1.34366,1.30696,$
			1.27417,1.23436,1.20453,1.16474,1.13495,1.09758,1.06534,$
			1.03541,1.00569]
stimcoil_nTv_Vb = [2.10000,2.10000,2.10000,2.10000,2.10000,2.10000,2.10000,$
			2.10000,2.10000,2.10000,2.10000,2.10000,2.10000,2.09663,$
			2.08000,2.06452,2.05680,2.04000,2.03000,2.01000,2.00000,$
			1.98239,1.97000,1.95337,1.93418,1.92000,1.90333,1.89000,$
			1.87402,1.85452,1.83444,1.81848,1.79974,1.78509,1.76528,$
			1.74515,1.72506,1.70516,1.68080,1.65558,1.63547,1.61555,$
			1.59584,1.56590,1.54587,1.52599,1.49607,1.47624,1.44630,$
			1.42286,1.39644,1.36658,1.33668,1.30675,1.27683,1.24696,$
			1.21417,1.18436,1.14726,1.11737,1.08747,1.05758,1.02767,$
			0.997706,0.975689]
stimcoil_nTv_Wb = [2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,$
			2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,2.22000,$
			2.22000,2.21000,2.19680,2.18000,2.16571,2.15000,2.14000,$
			2.12239,2.11281,2.10000,2.08418,2.07000,2.04333,2.02370,$
			2.00402,1.99452,1.98000,1.96424,1.93487,1.92000,1.91528,$
			1.88544,1.87000,1.85516,1.83080,1.81558,1.79547,1.77000,$
			1.74584,1.72590,1.70587,1.67598,1.65607,1.62624,1.60261,$
			1.57643,1.54644,1.51658,1.48336,1.45350,1.42366,1.38392,$
			1.35417,1.31436,1.28453,1.24737,1.21495,1.18515,1.15534,$
			1.12541,1.09569]


;Interpolate George's mu-metal can nT/V correction to the freqs of the CIT test
stimcoil_nTv2_Ua = interpol(stimcoil_nTv_Ua,fstim,freq_cit)
stimcoil_nTv2_Va = interpol(stimcoil_nTv_Va,fstim,freq_cit)
stimcoil_nTv2_Wa = interpol(stimcoil_nTv_Wa,fstim,freq_cit)
stimcoil_nTv2_Ub = interpol(stimcoil_nTv_Ub,fstim,freq_cit)
stimcoil_nTv2_Vb = interpol(stimcoil_nTv_Vb,fstim,freq_cit)
stimcoil_nTv2_Wb = interpol(stimcoil_nTv_Wb,fstim,freq_cit)

;#4
Gain_U_a = Vin/VscmU_a
Gain_V_a = Vin/VscmV_a
Gain_W_a = Vin/VscmW_a
Gain_U_b = Vin/VscmU_b
Gain_V_b = Vin/VscmV_b
Gain_W_b = Vin/VscmW_b




notes_SCM = ['Heres how to go from a signal in counts to nT:',$
			 'signal_nT = signal_cnts * Gscm * stimcoil_nTv2_Ua * adc',$
			 '(nT) = (counts) * (unitless) * (nT/V) * (V/counts)',$
			 'Now we correct for the fact that EMFISIS has attenuated the signal.',$
			 'signal_nT = signal_nT * Gain_U']




;-----------------------------------------------------------
;Now extrapolate these gain curves to filterbank center bins
;-----------------------------------------------------------

;low freq of bin
fbk13_binsL = [0.8,1.5,3,6,12,25,50,100,200,400,800,1600,3200]
fbk7_binsL = fbk13_binsL[lindgen(7)*2]
;high freq of bin
fbk13_binsH = [1.5,3,6,12,25,50,100,200,400,800,1600,3200,6500]
fbk7_binsH = fbk13_binsH[lindgen(7)*2]
;center freq of bin
fbk13_binsC = (fbk13_binsH + fbk13_binsL)/2.
fbk7_binsC = (fbk7_binsH + fbk7_binsL)/2.



stimcoil_nTv2_Ua_fbk13 = interpol(stimcoil_nTv2_Ua,freq_cit,fbk13_binsC)
stimcoil_nTv2_Va_fbk13 = interpol(stimcoil_nTv2_Va,freq_cit,fbk13_binsC)
stimcoil_nTv2_Wa_fbk13 = interpol(stimcoil_nTv2_Wa,freq_cit,fbk13_binsC)
stimcoil_nTv2_Ub_fbk13 = interpol(stimcoil_nTv2_Ub,freq_cit,fbk13_binsC)
stimcoil_nTv2_Vb_fbk13 = interpol(stimcoil_nTv2_Vb,freq_cit,fbk13_binsC)
stimcoil_nTv2_Wb_fbk13 = interpol(stimcoil_nTv2_Wb,freq_cit,fbk13_binsC)

stimcoil_nTv2_Ua_fbk7 = interpol(stimcoil_nTv2_Ua,freq_cit,fbk7_binsC)
stimcoil_nTv2_Va_fbk7 = interpol(stimcoil_nTv2_Va,freq_cit,fbk7_binsC)
stimcoil_nTv2_Wa_fbk7 = interpol(stimcoil_nTv2_Wa,freq_cit,fbk7_binsC)
stimcoil_nTv2_Ub_fbk7 = interpol(stimcoil_nTv2_Ub,freq_cit,fbk7_binsC)
stimcoil_nTv2_Vb_fbk7 = interpol(stimcoil_nTv2_Vb,freq_cit,fbk7_binsC)
stimcoil_nTv2_Wb_fbk7 = interpol(stimcoil_nTv2_Wb,freq_cit,fbk7_binsC)


Gain_U_a_fbk13 = interpol(Gain_U_a,freq_cit,fbk13_binsC)
Gain_V_a_fbk13 = interpol(Gain_V_a,freq_cit,fbk13_binsC)
Gain_W_a_fbk13 = interpol(Gain_W_a,freq_cit,fbk13_binsC)
Gain_U_b_fbk13 = interpol(Gain_U_b,freq_cit,fbk13_binsC)
Gain_V_b_fbk13 = interpol(Gain_V_b,freq_cit,fbk13_binsC)
Gain_W_b_fbk13 = interpol(Gain_W_b,freq_cit,fbk13_binsC)

Gain_U_a_fbk7 = interpol(Gain_U_a,freq_cit,fbk7_binsC)
Gain_V_a_fbk7 = interpol(Gain_V_a,freq_cit,fbk7_binsC)
Gain_W_a_fbk7 = interpol(Gain_W_a,freq_cit,fbk7_binsC)
Gain_U_b_fbk7 = interpol(Gain_U_b,freq_cit,fbk7_binsC)
Gain_V_b_fbk7 = interpol(Gain_V_b,freq_cit,fbk7_binsC)
Gain_W_b_fbk7 = interpol(Gain_W_b,freq_cit,fbk7_binsC)


Gain_e12DC_a_fbk13 = interpol(Gain_e12DC_a,freq_cit,fbk13_binsC)
Gain_e34DC_a_fbk13 = interpol(Gain_e34DC_a,freq_cit,fbk13_binsC)
Gain_e56DC_a_fbk13 = interpol(Gain_e56DC_a,freq_cit,fbk13_binsC)
Gain_e12DC_b_fbk13 = interpol(Gain_e12DC_b,freq_cit,fbk13_binsC)
Gain_e34DC_b_fbk13 = interpol(Gain_e34DC_b,freq_cit,fbk13_binsC)
Gain_e56DC_b_fbk13 = interpol(Gain_e56DC_b,freq_cit,fbk13_binsC)

Gain_e12DC_a_fbk7 = interpol(Gain_e12DC_a,freq_cit,fbk7_binsC)
Gain_e34DC_a_fbk7 = interpol(Gain_e34DC_a,freq_cit,fbk7_binsC)
Gain_e56DC_a_fbk7 = interpol(Gain_e56DC_a,freq_cit,fbk7_binsC)
Gain_e12DC_b_fbk7 = interpol(Gain_e12DC_b,freq_cit,fbk7_binsC)
Gain_e34DC_b_fbk7 = interpol(Gain_e34DC_b,freq_cit,fbk7_binsC)
Gain_e56DC_b_fbk7 = interpol(Gain_e56DC_b,freq_cit,fbk7_binsC)






;-----------------------------------------------------------
;Now extrapolate these gain curves to spectral center bins
;-----------------------------------------------------------



;start and end values of each bin
fspec36_binsL = [indgen(8)*8,indgen(4)*16+64,$
		indgen(4)*32+128,indgen(4)*64+256,$
		indgen(4)*128+512,indgen(4)*256+1024,$
		indgen(4)*512+2048,indgen(4)*1024+4096]
fspec36_binsH = [(indgen(8)+1)*8,(indgen(4)+1)*16+64,$
		(indgen(4)+1)*32+128,(indgen(4)+1)*64+256,$
		(indgen(4)+1)*128+512,(indgen(4)+1)*256+1024,$
		(indgen(4)+1)*512+2048,(indgen(4)+1)*1024+4096]

fspec36_binsC = (fspec36_binsL + fspec36_binsH)/2


fspec64_binsL=[indgen(16)*8, indgen(8)*16+128, $
			indgen(8)*32+256, indgen(8)*64+512,$
			indgen(8)*128+1024, indgen(8)*256+2048, $
			indgen(8)*512+4096]
fspec64_binsH=[(indgen(16)+1)*8, (indgen(8)+1)*16+128, $
			(indgen(8)+1)*32+256, (indgen(8)+1)*64+512,$
			(indgen(8)+1)*128+1024, (indgen(8)+1)*256+2048, $
			(indgen(8)+1)*512+4096]

fspec64_binsC = (fspec64_binsL + fspec64_binsH)/2


fspec112_binsL = [indgen(32)*8,indgen(16)*16+256,$
		indgen(16)*32+512,indgen(16)*64+1024,$
		indgen(16)*128+2048,indgen(16)*256+4096]
fspec112_binsH = [(indgen(32)+1)*8,(indgen(16)+1)*16+256,$
		(indgen(16)+1)*32+512,(indgen(16)+1)*64+1024,$
		(indgen(16)+1)*128+2048,(indgen(16)+1)*256+4096]

fspec112_binsC = (fspec112_binsL + fspec112_binsH)/2





stimcoil_nTv2_Ua_spec36 = interpol(stimcoil_nTv2_Ua,freq_cit,fspec36_binsC)
stimcoil_nTv2_Va_spec36 = interpol(stimcoil_nTv2_Va,freq_cit,fspec36_binsC)
stimcoil_nTv2_Wa_spec36 = interpol(stimcoil_nTv2_Wa,freq_cit,fspec36_binsC)
stimcoil_nTv2_Ub_spec36 = interpol(stimcoil_nTv2_Ub,freq_cit,fspec36_binsC)
stimcoil_nTv2_Vb_spec36 = interpol(stimcoil_nTv2_Vb,freq_cit,fspec36_binsC)
stimcoil_nTv2_Wb_spec36 = interpol(stimcoil_nTv2_Wb,freq_cit,fspec36_binsC)

stimcoil_nTv2_Ua_spec64 = interpol(stimcoil_nTv2_Ua,freq_cit,fspec64_binsC)
stimcoil_nTv2_Va_spec64 = interpol(stimcoil_nTv2_Va,freq_cit,fspec64_binsC)
stimcoil_nTv2_Wa_spec64 = interpol(stimcoil_nTv2_Wa,freq_cit,fspec64_binsC)
stimcoil_nTv2_Ub_spec64 = interpol(stimcoil_nTv2_Ub,freq_cit,fspec64_binsC)
stimcoil_nTv2_Vb_spec64 = interpol(stimcoil_nTv2_Vb,freq_cit,fspec64_binsC)
stimcoil_nTv2_Wb_spec64 = interpol(stimcoil_nTv2_Wb,freq_cit,fspec64_binsC)

stimcoil_nTv2_Ua_spec112 = interpol(stimcoil_nTv2_Ua,freq_cit,fspec112_binsC)
stimcoil_nTv2_Va_spec112 = interpol(stimcoil_nTv2_Va,freq_cit,fspec112_binsC)
stimcoil_nTv2_Wa_spec112 = interpol(stimcoil_nTv2_Wa,freq_cit,fspec112_binsC)
stimcoil_nTv2_Ub_spec112 = interpol(stimcoil_nTv2_Ub,freq_cit,fspec112_binsC)
stimcoil_nTv2_Vb_spec112 = interpol(stimcoil_nTv2_Vb,freq_cit,fspec112_binsC)
stimcoil_nTv2_Wb_spec112 = interpol(stimcoil_nTv2_Wb,freq_cit,fspec112_binsC)



Gain_U_a_spec36 = interpol(Gain_U_a,freq_cit,fspec36_binsC)
Gain_V_a_spec36 = interpol(Gain_V_a,freq_cit,fspec36_binsC)
Gain_W_a_spec36 = interpol(Gain_W_a,freq_cit,fspec36_binsC)
Gain_U_b_spec36 = interpol(Gain_U_b,freq_cit,fspec36_binsC)
Gain_V_b_spec36 = interpol(Gain_V_b,freq_cit,fspec36_binsC)
Gain_W_b_spec36 = interpol(Gain_W_b,freq_cit,fspec36_binsC)

Gain_U_a_spec64 = interpol(Gain_U_a,freq_cit,fspec64_binsC)
Gain_V_a_spec64 = interpol(Gain_V_a,freq_cit,fspec64_binsC)
Gain_W_a_spec64 = interpol(Gain_W_a,freq_cit,fspec64_binsC)
Gain_U_b_spec64 = interpol(Gain_U_b,freq_cit,fspec64_binsC)
Gain_V_b_spec64 = interpol(Gain_V_b,freq_cit,fspec64_binsC)
Gain_W_b_spec64 = interpol(Gain_W_b,freq_cit,fspec64_binsC)

Gain_U_a_spec112 = interpol(Gain_U_a,freq_cit,fspec112_binsC)
Gain_V_a_spec112 = interpol(Gain_V_a,freq_cit,fspec112_binsC)
Gain_W_a_spec112 = interpol(Gain_W_a,freq_cit,fspec112_binsC)
Gain_U_b_spec112 = interpol(Gain_U_b,freq_cit,fspec112_binsC)
Gain_V_b_spec112 = interpol(Gain_V_b,freq_cit,fspec112_binsC)
Gain_W_b_spec112 = interpol(Gain_W_b,freq_cit,fspec112_binsC)



Gain_e12DC_a_spec36 = interpol(Gain_e12DC_a,freq_cit,fspec36_binsC)
Gain_e34DC_a_spec36 = interpol(Gain_e34DC_a,freq_cit,fspec36_binsC)
Gain_e56DC_a_spec36 = interpol(Gain_e56DC_a,freq_cit,fspec36_binsC)
Gain_e12DC_b_spec36 = interpol(Gain_e12DC_b,freq_cit,fspec36_binsC)
Gain_e34DC_b_spec36 = interpol(Gain_e34DC_b,freq_cit,fspec36_binsC)
Gain_e56DC_b_spec36 = interpol(Gain_e56DC_b,freq_cit,fspec36_binsC)

Gain_e12DC_a_spec64 = interpol(Gain_e12DC_a,freq_cit,fspec64_binsC)
Gain_e34DC_a_spec64 = interpol(Gain_e34DC_a,freq_cit,fspec64_binsC)
Gain_e56DC_a_spec64 = interpol(Gain_e56DC_a,freq_cit,fspec64_binsC)
Gain_e12DC_b_spec64 = interpol(Gain_e12DC_b,freq_cit,fspec64_binsC)
Gain_e34DC_b_spec64 = interpol(Gain_e34DC_b,freq_cit,fspec64_binsC)
Gain_e56DC_b_spec64 = interpol(Gain_e56DC_b,freq_cit,fspec64_binsC)

Gain_e12DC_a_spec112 = interpol(Gain_e12DC_a,freq_cit,fspec112_binsC)
Gain_e34DC_a_spec112 = interpol(Gain_e34DC_a,freq_cit,fspec112_binsC)
Gain_e56DC_a_spec112 = interpol(Gain_e56DC_a,freq_cit,fspec112_binsC)
Gain_e12DC_b_spec112 = interpol(Gain_e12DC_b,freq_cit,fspec112_binsC)
Gain_e34DC_b_spec112 = interpol(Gain_e34DC_b,freq_cit,fspec112_binsC)
Gain_e56DC_b_spec112 = interpol(Gain_e56DC_b,freq_cit,fspec112_binsC)




















;Define some structures

scmU_a = {stimcoil_nT2V:stimcoil_nTv2_Ua,gain_vs_freq:Gain_U_a}
scmU_b = {stimcoil_nT2V:stimcoil_nTv2_Ub,gain_vs_freq:Gain_U_b}
scmV_a = {stimcoil_nT2V:stimcoil_nTv2_Va,gain_vs_freq:Gain_V_a}
scmV_b = {stimcoil_nT2V:stimcoil_nTv2_Vb,gain_vs_freq:Gain_V_b}
scmW_a = {stimcoil_nT2V:stimcoil_nTv2_Wa,gain_vs_freq:Gain_W_a}
scmW_b = {stimcoil_nT2V:stimcoil_nTv2_Wb,gain_vs_freq:Gain_W_b}
e12DC_a = {gain_vs_freq:Gain_e12DC_a}
e34DC_a = {gain_vs_freq:Gain_e34DC_a}
e56DC_a = {gain_vs_freq:Gain_e56DC_a}
e12DC_b = {gain_vs_freq:Gain_e12DC_b}
e34DC_b = {gain_vs_freq:Gain_e34DC_b}
e56DC_b = {gain_vs_freq:Gain_e56DC_b}

scmU_a_fbk13 = {stimcoil_nT2V:stimcoil_nTv2_Ua_fbk13,gain_vs_freq:Gain_U_a_fbk13}
scmU_b_fbk13 = {stimcoil_nT2V:stimcoil_nTv2_Ub_fbk13,gain_vs_freq:Gain_U_b_fbk13}
scmV_a_fbk13 = {stimcoil_nT2V:stimcoil_nTv2_Va_fbk13,gain_vs_freq:Gain_V_a_fbk13}
scmV_b_fbk13 = {stimcoil_nT2V:stimcoil_nTv2_Vb_fbk13,gain_vs_freq:Gain_V_b_fbk13}
scmW_a_fbk13 = {stimcoil_nT2V:stimcoil_nTv2_Wa_fbk13,gain_vs_freq:Gain_W_a_fbk13}
scmW_b_fbk13 = {stimcoil_nT2V:stimcoil_nTv2_Wb_fbk13,gain_vs_freq:Gain_W_b_fbk13}

scmU_a_fbk7 = {stimcoil_nT2V:stimcoil_nTv2_Ua_fbk7,gain_vs_freq:Gain_U_a_fbk7}
scmU_b_fbk7 = {stimcoil_nT2V:stimcoil_nTv2_Ub_fbk7,gain_vs_freq:Gain_U_b_fbk7}
scmV_a_fbk7 = {stimcoil_nT2V:stimcoil_nTv2_Va_fbk7,gain_vs_freq:Gain_V_a_fbk7}
scmV_b_fbk7 = {stimcoil_nT2V:stimcoil_nTv2_Vb_fbk7,gain_vs_freq:Gain_V_b_fbk7}
scmW_a_fbk7 = {stimcoil_nT2V:stimcoil_nTv2_Wa_fbk7,gain_vs_freq:Gain_W_a_fbk7}
scmW_b_fbk7 = {stimcoil_nT2V:stimcoil_nTv2_Wb_fbk7,gain_vs_freq:Gain_W_b_fbk7}


scmU_a_spec36 = {stimcoil_nT2V:stimcoil_nTv2_Ua_spec36,gain_vs_freq:Gain_U_a_spec36}
scmU_b_spec36 = {stimcoil_nT2V:stimcoil_nTv2_Ub_spec36,gain_vs_freq:Gain_U_b_spec36}
scmV_a_spec36 = {stimcoil_nT2V:stimcoil_nTv2_Va_spec36,gain_vs_freq:Gain_V_a_spec36}
scmV_b_spec36 = {stimcoil_nT2V:stimcoil_nTv2_Vb_spec36,gain_vs_freq:Gain_V_b_spec36}
scmW_a_spec36 = {stimcoil_nT2V:stimcoil_nTv2_Wa_spec36,gain_vs_freq:Gain_W_a_spec36}
scmW_b_spec36 = {stimcoil_nT2V:stimcoil_nTv2_Wb_spec36,gain_vs_freq:Gain_W_b_spec36}

scmU_a_spec64 = {stimcoil_nT2V:stimcoil_nTv2_Ua_spec64,gain_vs_freq:Gain_U_a_spec64}
scmU_b_spec64 = {stimcoil_nT2V:stimcoil_nTv2_Ub_spec64,gain_vs_freq:Gain_U_b_spec64}
scmV_a_spec64 = {stimcoil_nT2V:stimcoil_nTv2_Va_spec64,gain_vs_freq:Gain_V_a_spec64}
scmV_b_spec64 = {stimcoil_nT2V:stimcoil_nTv2_Vb_spec64,gain_vs_freq:Gain_V_b_spec64}
scmW_a_spec64 = {stimcoil_nT2V:stimcoil_nTv2_Wa_spec64,gain_vs_freq:Gain_W_a_spec64}
scmW_b_spec64 = {stimcoil_nT2V:stimcoil_nTv2_Wb_spec64,gain_vs_freq:Gain_W_b_spec64}

scmU_a_spec112 = {stimcoil_nT2V:stimcoil_nTv2_Ua_spec112,gain_vs_freq:Gain_U_a_spec112}
scmU_b_spec112 = {stimcoil_nT2V:stimcoil_nTv2_Ub_spec112,gain_vs_freq:Gain_U_b_spec112}
scmV_a_spec112 = {stimcoil_nT2V:stimcoil_nTv2_Va_spec112,gain_vs_freq:Gain_V_a_spec112}
scmV_b_spec112 = {stimcoil_nT2V:stimcoil_nTv2_Vb_spec112,gain_vs_freq:Gain_V_b_spec112}
scmW_a_spec112 = {stimcoil_nT2V:stimcoil_nTv2_Wa_spec112,gain_vs_freq:Gain_W_a_spec112}
scmW_b_spec112 = {stimcoil_nT2V:stimcoil_nTv2_Wb_spec112,gain_vs_freq:Gain_W_b_spec112}






e12DC_a_fbk13 = {gain_vs_freq:Gain_e12DC_a_fbk13}
e34DC_a_fbk13 = {gain_vs_freq:Gain_e34DC_a_fbk13}
e56DC_a_fbk13 = {gain_vs_freq:Gain_e56DC_a_fbk13}
e12DC_b_fbk13 = {gain_vs_freq:Gain_e12DC_b_fbk13}
e34DC_b_fbk13 = {gain_vs_freq:Gain_e34DC_b_fbk13}
e56DC_b_fbk13 = {gain_vs_freq:Gain_e56DC_b_fbk13}

e12DC_a_fbk7 = {gain_vs_freq:Gain_e12DC_a_fbk7}
e34DC_a_fbk7 = {gain_vs_freq:Gain_e34DC_a_fbk7}
e56DC_a_fbk7 = {gain_vs_freq:Gain_e56DC_a_fbk7}
e12DC_b_fbk7 = {gain_vs_freq:Gain_e12DC_b_fbk7}
e34DC_b_fbk7 = {gain_vs_freq:Gain_e34DC_b_fbk7}
e56DC_b_fbk7 = {gain_vs_freq:Gain_e56DC_b_fbk7}

e12DC_a_spec36 = {gain_vs_freq:Gain_e12DC_a_spec36}
e34DC_a_spec36 = {gain_vs_freq:Gain_e34DC_a_spec36}
e56DC_a_spec36 = {gain_vs_freq:Gain_e56DC_a_spec36}
e12DC_b_spec36 = {gain_vs_freq:Gain_e12DC_b_spec36}
e34DC_b_spec36 = {gain_vs_freq:Gain_e34DC_b_spec36}
e56DC_b_spec36 = {gain_vs_freq:Gain_e56DC_b_spec36}

e12DC_a_spec64 = {gain_vs_freq:Gain_e12DC_a_spec64}
e34DC_a_spec64 = {gain_vs_freq:Gain_e34DC_a_spec64}
e56DC_a_spec64 = {gain_vs_freq:Gain_e56DC_a_spec64}
e12DC_b_spec64 = {gain_vs_freq:Gain_e12DC_b_spec64}
e34DC_b_spec64 = {gain_vs_freq:Gain_e34DC_b_spec64}
e56DC_b_spec64 = {gain_vs_freq:Gain_e56DC_b_spec64}

e12DC_a_spec112 = {gain_vs_freq:Gain_e12DC_a_spec112}
e34DC_a_spec112 = {gain_vs_freq:Gain_e34DC_a_spec112}
e56DC_a_spec112 = {gain_vs_freq:Gain_e56DC_a_spec112}
e12DC_b_spec112 = {gain_vs_freq:Gain_e12DC_b_spec112}
e34DC_b_spec112 = {gain_vs_freq:Gain_e34DC_b_spec112}
e56DC_b_spec112 = {gain_vs_freq:Gain_e56DC_b_spec112}


cal_cit = {	   freq_cit:freq_cit,$
			   e12DC_a_cit:e12DC_a,$
			   e34DC_a_cit:e34DC_a,$
			   e56DC_a_cit:e56DC_a,$
			   e12DC_b_cit:e12DC_b,$
			   e34DC_b_cit:e34DC_b,$
			   e56DC_b_cit:e56DC_b,$
			   scmU_a_cit:scmU_a,$
			   scmV_a_cit:scmV_a,$
			   scmW_a_cit:scmW_a,$
			   scmU_b_cit:scmU_b,$
			   scmV_b_cit:scmV_b,$
			   scmW_b_cit:scmW_b}


cal_fbk = {	   freq_fbk7L:fbk7_binsL,$
			   freq_fbk7H:fbk7_binsH,$
			   freq_fbk7C:fbk7_binsC,$
			   freq_fbk13L:fbk13_binsL,$
			   freq_fbk13H:fbk13_binsH,$
			   freq_fbk13C:fbk13_binsC,$
			   e12DC_a_fbk13:e12DC_a_fbk13,$
			   e34DC_a_fbk13:e34DC_a_fbk13,$
			   e56DC_a_fbk13:e56DC_a_fbk13,$
			   e12DC_b_fbk13:e12DC_b_fbk13,$
			   e34DC_b_fbk13:e34DC_b_fbk13,$
			   e56DC_b_fbk13:e56DC_b_fbk13,$
			   scmU_a_fbk13:scmU_a_fbk13,$
			   scmV_a_fbk13:scmV_a_fbk13,$
			   scmW_a_fbk13:scmW_a_fbk13,$
			   scmU_b_fbk13:scmU_b_fbk13,$
			   scmV_b_fbk13:scmV_b_fbk13,$
			   scmW_b_fbk13:scmW_b_fbk13,$
			   e12DC_a_fbk7:e12DC_a_fbk7,$
			   e34DC_a_fbk7:e34DC_a_fbk7,$
			   e56DC_a_fbk7:e56DC_a_fbk7,$
			   e12DC_b_fbk7:e12DC_b_fbk7,$
			   e34DC_b_fbk7:e34DC_b_fbk7,$
			   e56DC_b_fbk7:e56DC_b_fbk7,$
			   scmU_a_fbk7:scmU_a_fbk7,$
			   scmV_a_fbk7:scmV_a_fbk7,$
			   scmW_a_fbk7:scmW_a_fbk7,$
			   scmU_b_fbk7:scmU_b_fbk7,$
			   scmV_b_fbk7:scmV_b_fbk7,$
			   scmW_b_fbk7:scmW_b_fbk7}


cal_spec = {   freq_spec36L:fspec36_binsL,$
			   freq_spec36H:fspec36_binsH,$
			   freq_spec36C:fspec36_binsC,$
			   freq_spec64L:fspec64_binsL,$
			   freq_spec64H:fspec64_binsH,$
			   freq_spec64C:fspec64_binsC,$
			   freq_spec112L:fspec112_binsL,$
			   freq_spec112H:fspec112_binsH,$
			   freq_spec112C:fspec112_binsC,$
			   e12DC_a_spec36:e12DC_a_spec36,$
			   e34DC_a_spec36:e34DC_a_spec36,$
			   e56DC_a_spec36:e56DC_a_spec36,$
			   e12DC_b_spec36:e12DC_b_spec36,$
			   e34DC_b_spec36:e34DC_b_spec36,$
			   e56DC_b_spec36:e56DC_b_spec36,$
			   e12DC_a_spec64:e12DC_a_spec64,$
			   e34DC_a_spec64:e34DC_a_spec64,$
			   e56DC_a_spec64:e56DC_a_spec64,$
			   e12DC_b_spec64:e12DC_b_spec64,$
			   e34DC_b_spec64:e34DC_b_spec64,$
			   e56DC_b_spec64:e56DC_b_spec64,$
			   e12DC_a_spec112:e12DC_a_spec112,$
			   e34DC_a_spec112:e34DC_a_spec112,$
			   e56DC_a_spec112:e56DC_a_spec112,$
			   e12DC_b_spec112:e12DC_b_spec112,$
			   e34DC_b_spec112:e34DC_b_spec112,$
			   e56DC_b_spec112:e56DC_b_spec112,$
			   scmU_a_spec36:scmU_a_spec36,$
			   scmV_a_spec36:scmV_a_spec36,$
			   scmW_a_spec36:scmW_a_spec36,$
			   scmU_b_spec36:scmU_b_spec36,$
			   scmV_b_spec36:scmV_b_spec36,$
			   scmW_b_spec36:scmW_b_spec36,$
			   scmU_a_spec64:scmU_a_spec64,$
			   scmV_a_spec64:scmV_a_spec64,$
			   scmW_a_spec64:scmW_a_spec64,$
			   scmU_b_spec64:scmU_b_spec64,$
			   scmV_b_spec64:scmV_b_spec64,$
			   scmW_b_spec64:scmW_b_spec64,$
			   scmU_a_spec112:scmU_a_spec112,$
			   scmV_a_spec112:scmV_a_spec112,$
			   scmW_a_spec112:scmW_a_spec112,$
			   scmU_b_spec112:scmU_b_spec112,$
			   scmV_b_spec112:scmV_b_spec112,$
			   scmW_b_spec112:scmW_b_spec112}




notes = ['values from rbsp_gain_results.pro. Used to calibrate a waveform in counts to volts or nT',$
		'cal_cit = CIT frequency sweep bench testing: frequencies, gain curves and for SCM the nT/V sq can conversion',$
		'cal_fbk = same as cal_cit but with values interpolated to the filterbank 7 and 13 center frequency bins',$
		'cal_spec = same as cal_cit but with values interpolated to the spectral 36, 64, 112 center frequency bins']

calibration = {notes:notes,$
			   notes_EDC:notes_EDC,$
			   notes_SCM:notes_SCM,$
			   cal_cit:cal_cit,$
			   cal_fbk:cal_fbk,$
			   cal_spec:cal_spec}


return,calibration


end















