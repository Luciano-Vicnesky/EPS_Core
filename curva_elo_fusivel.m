function [I_elo, t_fus_min, t_int_tot] = curva_elo_fusivel(elo_str, I_max_plot)
% CURVA_ELO_FUSIVEL (Simplificada com Pontos Mínimos e Máximos - ABNT NBR 7282)
% Gera as curvas de Fusão Mínima e Máxima sem patamar horizontal em altas correntes.

if nargin < 2 || isempty(I_max_plot) || isnan(I_max_plot)
    I_max_plot = 0;
end

elo = strrep(upper(regexprep(strtrim(elo_str), '\s+', '')), ',', '.');

% Tabela ABNT NBR 7282: {Elo, I_min [t_longo, 10s, 0.1s], I_max [t_longo, 10s, 0.1s], t_longo}
tab = {
    '0.5H', [1.6,    4.0,    40.0], [2.3,    5.2,    55.0], 300;
    '1H',   [2.5,    6.8,    53.0], [3.3,    8.6,    80.0], 300;
    '2H',   [3.5,    9.2,    89.0], [4.3,   12.0,   130.0], 300;
    '3H',   [4.7,   11.3,    89.0], [5.9,   14.5,   130.0], 300;
    '5H',   [7.4,   15.3,    89.0], [9.2,   18.5,   130.0], 300;
    '6K',   [12.0,  13.5,    72.0], [14.4,  20.5,    86.4], 300;
    '8K',   [15.0,  18.0,    97.0], [18.0,  27.0,   116.0], 300;
    '10K',  [19.5,  22.4,   128.0], [23.4,  34.0,   154.0], 300;
    '12K',  [25.0,  29.5,   166.0], [30.0,  44.0,   199.0], 300;
    '15K',  [31.0,  37.0,   215.0], [37.2,  55.0,   258.0], 300;
    '20K',  [39.0,  48.0,   273.0], [47.0,  71.0,   328.0], 300;
    '25K',  [50.0,  60.0,   350.0], [60.0,  90.0,   420.0], 300;
    '30K',  [63.0,  77.5,   447.0], [76.0, 115.0,   546.0], 300;
    '40K',  [80.0,  96.0,   565.0], [96.0, 146.0,   680.0], 300;
    '50K',  [101.0, 126.0,  719.0], [121.0, 188.0,  862.0], 300;
    '65K',  [128.0, 159.0,  918.0], [153.6, 237.0, 1100.0], 300;
    '80K',  [160.0, 205.0, 1180.0], [192.0, 307.0, 1420.0], 300;
    '100K', [200.0, 258.0, 1520.0], [240.0, 388.0, 1820.0], 300;
    '140K', [310.0, 430.0, 2470.0], [372.0, 650.0, 2970.0], 600;
    '200K', [480.0, 760.0, 3880.0], [576.0, 1150.0, 4656.0], 600
    };

idx = find(strcmp(tab(:,1), elo), 1);
if ~isempty(idx)
    I_min   = tab{idx, 2};
    I_max   = tab{idx, 3};
    t_longo = tab{idx, 4};
else
    tok = regexp(elo, '(\d+\.?\d*)', 'tokens', 'once');
    In  = 25; if ~isempty(tok), In = str2double(tok{1}); end
    if isnan(In) || In <= 0, In = 25; end
    I_min   = In * [2.0, 2.4, 14.0];
    I_max   = In * [2.4, 3.6, 16.8];
    t_longo = 300 + 300 * (In > 100);
    warning('Elo "%s" fora da tabela NBR 7282. Usando aproximação proporcional.', elo);
end

% Constantes adiabáticas (I²t = cte a partir de 0,1s) e limite superior do eixo X
K_min = (I_min(3)^2) * 0.1;
K_max = (I_max(3)^2) * 0.1;
I_fim = max([I_max(3) * 10, I_max_plot * 1.5]);

% Pontos âncora de Fusão Mínima e Máxima
I_anc_min = [I_min(1) * 0.99, I_min, I_min(3) * sqrt(10), I_fim];
t_anc_min = [1000, t_longo, 10, 0.1, 0.01, K_min / (I_fim^2)];

I_anc_max = [I_max(1) * 0.99, I_max, I_max(3) * sqrt(10), I_fim];
t_anc_max = [1000, t_longo, 10, 0.1, 0.01, K_max / (I_fim^2)];

% Vetor de corrente unificado (inclui o início exato da curva máxima em 1000s)
I_elo = unique([logspace(log10(I_anc_min(1)), log10(I_fim), 500), I_anc_max(1)]);

% Interpolação log-log monotônica (pchip)
t_fus_min = exp(interp1(log(I_anc_min), log(t_anc_min), log(I_elo), 'pchip'));
t_int_tot = NaN(size(I_elo));
mask_max  = (I_elo >= I_anc_max(1));
t_int_tot(mask_max) = exp(interp1(log(I_anc_max), log(t_anc_max), log(I_elo(mask_max)), 'pchip'));
end