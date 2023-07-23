; $LastChangedBy: ali $
; $LastChangedDate: 2022-03-03 12:58:24 -0800 (Thu, 03 Mar 2022) $
; $LastChangedRevision: 30647 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_log_decomp.pro $


function swfo_stis_log_decomp,bdata,ctype,compress=compress

  if n_elements(ctype) eq 0 then ctype = 19

  clog_19_8=[$
    0,      1,      2,      3,      4,      5,      6,      7,      8,      9,      10,     11,     12,     13,     14,     15,$
    16,     17,     18,     19,     20,     21,     22,     23,     24,     25,     26,     27,     28,     29,     30,     31,$
    32,     34,     36,     38,     40,     42,     44,     46,     48,     50,     52,     54,     56,     58,     60,     62,$
    64,     68,     72,     76,     80,     84,     88,     92,     96,     100,    104,    108,    112,    116,    120,    124,$
    128,    136,    144,    152,    160,    168,    176,    184,    192,    200,    208,    216,    224,    232,    240,    248,$
    256,    272,    288,    304,    320,    336,    352,    368,    384,    400,    416,    432,    448,    464,    480,    496,$
    512,    544,    576,    608,    640,    672,    704,    736,    768,    800,    832,    864,    896,    928,    960,    992,$
    1024,   1088,   1152,   1216,   1280,   1344,   1408,   1472,   1536,   1600,   1664,   1728,   1792,   1856,   1920,   1984,$
    2048,   2176,   2304,   2432,   2560,   2688,   2816,   2944,   3072,   3200,   3328,   3456,   3584,   3712,   3840,   3968,$
    4096,   4352,   4608,   4864,   5120,   5376,   5632,   5888,   6144,   6400,   6656,   6912,   7168,   7424,   7680,   7936,$
    8192,   8704,   9216,   9728,   10240,  10752,  11264,  11776,  12288,  12800,  13312,  13824,  14336,  14848,  15360,  15872,$
    16384,  17408,  18432,  19456,  20480,  21504,  22528,  23552,  24576,  25600,  26624,  27648,  28672,  29696,  30720,  31744,$
    32768,  34816,  36864,  38912,  40960,  43008,  45056,  47104,  49152,  51200,  53248,  55296,  57344,  59392,  61440,  63488,$
    65536,  69632,  73728,  77824,  81920,  86016,  90112,  94208,  98304,  102400, 106496, 110592, 114688, 118784, 122880, 126976,$
    131072, 139264, 147456, 155648, 163840, 172032, 180224, 188416, 196608, 204800, 212992, 221184, 229376, 237568, 245760, 253952,$
    262144, 278528, 294912, 311296, 327680, 344064, 360448, 376832, 393216, 409600, 425984, 442368, 458752, 475136, 491520, 507904]

  clog_17_6=[$
    0,     1,     2,     3,$
    4,     5,     6,     7,$
    8,     10,    12,    14,$
    16,    20,    24,    28,$
    32,    40,    48,    56,$
    64,    80,    96,    112,$
    128,   160,   192,   224,$
    256,   320,   384,   448,$
    512,   640,   768,   896,$
    1024,  1280,  1536,  1792,$
    2048,  2560,  3072,  3584,$
    4096,  5120,  6144,  7168,$
    8192,  10240, 12288, 14336,$
    16384, 20480, 24576, 28672,$
    32768, 40960, 49152, 57344,$
    65536, 81920, 98304, 114688]

  clog_16_5=[$
    0,     1,$
    2,     3,$
    4,     6,$
    8,     12,$
    16,    24,$
    32,    48,$
    64,    96,$
    128,   192,$
    256,   384,$
    512,   768,$
    1024,  1536,$
    2048,  3072,$
    4096,  6144,$
    8192,  12288,$
    16384, 24576,$
    32768, 49152]

  clog_12_8=[$
    0,    1,    2,    3,    4,    5,    6,    7,    8,    9,    10,   11,   12,   13,   14,   15,   16,   17,   18,   19,   20,   21,   22,   23,   24,   25,   26,   27,   28,   29,   30,   31,$
    32,   33,   34,   35,   36,   37,   38,   39,   40,   41,   42,   43,   44,   45,   46,   47,   48,   49,   50,   51,   52,   53,   54,   55,   56,   57,   58,   59,   60,   61,   62,   63,$
    64,   66,   68,   70,   72,   74,   76,   78,   80,   82,   84,   86,   88,   90,   92,   94,   96,   98,   100,  102,  104,  106,  108,  110,  112,  114,  116,  118,  120,  122,  124,  126,$
    128,  132,  136,  140,  144,  148,  152,  156,  160,  164,  168,  172,  176,  180,  184,  188,  192,  196,  200,  204,  208,  212,  216,  220,  224,  228,  232,  236,  240,  244,  248,  252,$
    256,  264,  272,  280,  288,  296,  304,  312,  320,  328,  336,  344,  352,  360,  368,  376,  384,  392,  400,  408,  416,  424,  432,  440,  448,  456,  464,  472,  480,  488,  496,  504,$
    512,  528,  544,  560,  576,  592,  608,  624,  640,  656,  672,  688,  704,  720,  736,  752,  768,  784,  800,  816,  832,  848,  864,  880,  896,  912,  928,  944,  960,  976,  992,  1008,$
    1024, 1056, 1088, 1120, 1152, 1184, 1216, 1248, 1280, 1312, 1344, 1376, 1408, 1440, 1472, 1504, 1536, 1568, 1600, 1632, 1664, 1696, 1728, 1760, 1792, 1824, 1856, 1888, 1920, 1952, 1984, 2016,$
    2048, 2112, 2176, 2240, 2304, 2368, 2432, 2496, 2560, 2624, 2688, 2752, 2816, 2880, 2944, 3008, 3072, 3136, 3200, 3264, 3328, 3392, 3456, 3520, 3584, 3648, 3712, 3776, 3840, 3904, 3968, 4032]

  case ctype of
    19: clog=clog_19_8
    17: clog=clog_17_6
    16: clog=clog_16_5
    12: clog=clog_12_8
  endcase

  ;clog = [[clog_19_8],[clog_12_8]]
  ;printdat,clog
  ;clog = ctype and 1 ? clog_12_8 : clog_19_8
  if keyword_set(compress) then begin
    comp = interp(indgen(256),clog*.99999,bdata,index=i)
    return,fix(i)
  endif

  return, clog[byte(bdata)]

end
