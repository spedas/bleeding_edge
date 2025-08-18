;+
; FUNCTION: GET_PULSECODE_EISCAT
;    pulse_out = get_pulsecode_eiscat(pulse_in, mode)
;
; :DESCRIPTION:
;    Convert pulse_code_id of the EISCAT radar observation to 
;        pulse_code or vice versa. 
;
; :KEYWORDS:
;    pulse_in:  pulse_code_id(integer) or pulse_code(string)
;    mode:      0(default) :     id     ---> pulse_code
;               others     : pulse_code --->     id
;    pulse_out: output (pulse_code or id)
;
; Written by Y.-M. Tanaka, June 15, 2012 (ytanaka at nipr.ac.jp)
;-

function get_pulsecode_eiscat, pulse_in, mode

if ~keyword_set(mode) then mode=0
if ~keyword_set(pulse_in) then begin
    print, 'No input data!'
    stop
endif

;----- pulse_code_id --> pulse_code -----;
if mode eq 0 then begin
    if size(pulse_in, /type) ne 2 then begin
        print, 'The pulse_in must be an integer for this mode.'
        pulse_out=''
    endif else begin
        case pulse_in of
           0    :  pulse_out='cp0'
           1    :  pulse_out='cp1'
           2    :  pulse_out='cp2'
           3    :  pulse_out='cp3'
           4    :  pulse_out='cp4'
           5    :  pulse_out='cp5'
           6    :  pulse_out='cp6'
           7    :  pulse_out='cp7'
           8    :  pulse_out='cp8'
           9    :  pulse_out='cp9'
           10   :  pulse_out='tau0'
           11   :  pulse_out='tau1'
           12   :  pulse_out='tau2'
           13   :  pulse_out='tau3'
           14   :  pulse_out='tau4'
           15   :  pulse_out='tau5'
           16   :  pulse_out='tau6'
           17   :  pulse_out='tau7'
           18   :  pulse_out='tau8'
           19   :  pulse_out='tau9'
           20   :  pulse_out='t2pl'
           31   :  pulse_out='ipy0'
           32   :  pulse_out='beat'
           33   :  pulse_out='taro'
           34   :  pulse_out='folk'
           35   :  pulse_out='arc1'
           36   :  pulse_out='mand'
           37   :  pulse_out='stef'
           38   :  pulse_out='hild'
           39   :  pulse_out='pia0'
           40   :  pulse_out='gup0'
           41   :  pulse_out='gup1'
           42   :  pulse_out='gup2'
           43   :  pulse_out='gup3'
           50   :  pulse_out='cp0e'
           51   :  pulse_out='cp0f'
           52   :  pulse_out='cp0g'
           53   :  pulse_out='cp0h'
           54   :  pulse_out='cp1c'
           55   :  pulse_out='cp1d'
           56   :  pulse_out='cp1e'
           57   :  pulse_out='cp1f'
           58   :  pulse_out='cp1h'
           59   :  pulse_out='cp1i'
           60   :  pulse_out='cp1j'
           61   :  pulse_out='cp1k'
           62   :  pulse_out='cp1l'
           63   :  pulse_out='cp2b'
           64   :  pulse_out='cp2c'
           65   :  pulse_out='cp2d'
           66   :  pulse_out='cp2e'
           67   :  pulse_out='cp2f'
           68   :  pulse_out='cp2h'
           69   :  pulse_out='cp2i'
           70   :  pulse_out='cp2j'
           71   :  pulse_out='cp2k'
           72   :  pulse_out='cp3b'
           73   :  pulse_out='cp3c'
           74   :  pulse_out='cp3d'
           75   :  pulse_out='cp3e'
           76   :  pulse_out='cp3f'
           77   :  pulse_out='cp3h'
           78   :  pulse_out='cp3i'
           79   :  pulse_out='cp3j'
           80   :  pulse_out='cp3k'
           81   :  pulse_out='cp4a'
           82   :  pulse_out='cp4b'
           83   :  pulse_out='cp5a'
           84   :  pulse_out='cp5b'
           85   :  pulse_out='cp5c'
           86   :  pulse_out='cp6a'
           87   :  pulse_out='cp6b'
           88   :  pulse_out='cp6c'
           89   :  pulse_out='cp7a'
           90   :  pulse_out='cp7b'
           91   :  pulse_out='cp7c'
           92   :  pulse_out='cp7d'
           93   :  pulse_out='cp7e'
           94   :  pulse_out='cp7f'
           95   :  pulse_out='cp7g'
           96   :  pulse_out='cp7h'
           97   :  pulse_out='sp00'
           98   :  pulse_out='sp1c'
           99   :  pulse_out='sp1d'
           100  :  pulse_out='sp1e'
           101  :  pulse_out='sp1f'
           102  :  pulse_out='sp1h'
           103  :  pulse_out='sp1i'
           104  :  pulse_out='sp1j'
           105  :  pulse_out='sp1k'
           106  :  pulse_out='sp2b'
           107  :  pulse_out='sp2c'
           108  :  pulse_out='sp2d'
           109  :  pulse_out='sp2e'
           110  :  pulse_out='sp2f'
           111  :  pulse_out='sp2h'
           112  :  pulse_out='sp2i'
           113  :  pulse_out='CP1H'
           114  :  pulse_out='CP1K'
           115  :  pulse_out='CP3F'
           116  :  pulse_out='PULS'
           117  :  pulse_out='CONV'
           else :  begin
		       print, 'The pulse_code_id is not supported.'
                       pulse_out=''
                   end
        endcase
    endelse

;----- pulse_code --> pulse_code_id -----;
endif else begin
    if size(pulse_in, /type) ne 7 then begin
        print, 'The pulse_in must be an string for this mode.'
        pulse_out=-1
    endif else begin
        case pulse_in of
          'cp0': pulse_out=0
          'cp1': pulse_out=1
          'cp2': pulse_out=2
          'cp3': pulse_out=3
          'cp4': pulse_out=4
          'cp5': pulse_out=5
          'cp6': pulse_out=6
          'cp7': pulse_out=7
          'cp8': pulse_out=8
          'cp9': pulse_out=9
          'tau0': pulse_out=10
          'tau1': pulse_out=11 
          'tau2': pulse_out=12 
          'tau3': pulse_out=13 
          'tau4': pulse_out=14 
          'tau5': pulse_out=15 
          'tau6': pulse_out=16 
          'tau7': pulse_out=17 
          'tau8': pulse_out=18 
          'tau9': pulse_out=19
          't2pl': pulse_out=20
          'ipy0': pulse_out=31
          'beat': pulse_out=32
          'taro':  pulse_out=33
          'folk':  pulse_out=34
          'arc1':  pulse_out=35
          'mand':  pulse_out=36
          'stef':  pulse_out=37
          'hild':  pulse_out=38
          'pia0':  pulse_out=39
          'gup0':  pulse_out=40
          'gup1':  pulse_out=41
          'gup2':  pulse_out=42
          'gup3':  pulse_out=43
          'cp0e':  pulse_out=50
          'cp0f':  pulse_out=51
          'cp0g':  pulse_out=52
          'cp0h':  pulse_out=53
          'cp1c':  pulse_out=54
          'cp1d':  pulse_out=55
          'cp1e':  pulse_out=56
          'cp1f':  pulse_out=57
          'cp1h':  pulse_out=58
          'cp1i':  pulse_out=59
          'cp1j':  pulse_out=60
          'cp1k':  pulse_out=61
          'cp1l':  pulse_out=62
          'cp2b':  pulse_out=63
          'cp2c':  pulse_out=64
          'cp2d':  pulse_out=65
          'cp2e':  pulse_out=66
          'cp2f':  pulse_out=67
          'cp2h':  pulse_out=68
          'cp2i':  pulse_out=69
          'cp2j':  pulse_out=70
          'cp2k':  pulse_out=71
          'cp3b':  pulse_out=72
          'cp3c':  pulse_out=73
          'cp3d':  pulse_out=74
          'cp3e':  pulse_out=75
          'cp3f':  pulse_out=76
          'cp3h':  pulse_out=77
          'cp3i':  pulse_out=78
          'cp3j':  pulse_out=79
          'cp3k':  pulse_out=80
          'cp4a':  pulse_out=81
          'cp4b':  pulse_out=82
          'cp5a':  pulse_out=83
          'cp5b':  pulse_out=84
          'cp5c':  pulse_out=85
          'cp6a':  pulse_out=86
          'cp6b':  pulse_out=87
          'cp6c':  pulse_out=88
          'cp7a':  pulse_out=89
          'cp7b':  pulse_out=90
          'cp7c':  pulse_out=91
          'cp7d':  pulse_out=92
          'cp7e':  pulse_out=93
          'cp7f':  pulse_out=94
          'cp7g':  pulse_out=95
          'cp7h':  pulse_out=96
          'sp00':  pulse_out=97
          'sp1c':  pulse_out=98
          'sp1d':  pulse_out=99
          'sp1e':  pulse_out=100
          'sp1f':  pulse_out=101
          'sp1h':  pulse_out=102
          'sp1i':  pulse_out=103
          'sp1j':  pulse_out=104
          'sp1k':  pulse_out=105
          'sp2b':  pulse_out=106
          'sp2c':  pulse_out=107
          'sp2d':  pulse_out=108
          'sp2e':  pulse_out=109
          'sp2f':  pulse_out=110
          'sp2h':  pulse_out=111
          'sp2i':  pulse_out=112
          'CP1H':  pulse_out=113
          'CP1K':  pulse_out=114
          'CP3F':  pulse_out=115
          'PULS':  pulse_out=116
          'CONV':  pulse_out=117
          else  :  begin
		       print, 'The pulse_code is not supported.'
                       pulse_out=-1
                   end
        endcase
    endelse
endelse

return, pulse_out

end
