function cc = calc_curtos_sistema(cel, cli)
% CALC_CURTOS_SISTEMA
% Calcula curtos-circuitos simétricos e assimétricos eficazes (sem corrente de pico)
% no PC (Ponto de Conexão) e no ponto interno (somando a impedância do ramal MT).

pc    = calc_thevenin(cel.Sbase_MVA, cel.Vbase_kV, cel.R0, cel.X0, cel.R1, cel.X1, cel.Rf);
ramal = calc_impedancia_ramal(cli, cel.Sbase_MVA, cel.Vbase_kV);

R1_int  = cel.R1 + ramal.R1_pu;  X1_int = cel.X1 + ramal.X1_pu;
R0_int  = cel.R0 + ramal.R0_pu;  X0_int = cel.X0 + ramal.X0_pu;
interno = calc_thevenin(cel.Sbase_MVA, cel.Vbase_kV, R0_int, X0_int, R1_int, X1_int, cel.Rf);

usar_ramal = strcmpi(strtrim(cli.Considerar_Imp_Ramal), 'SIM') && (cli.Cabo_Entrada_Comp_m > 0);
if usar_ramal
    eff = interno;
    tag = 'INTERNA C/ RAMAL MT';
else
    eff = pc;
    tag = 'PC (SEM IMP. RAMAL)';
end

cc             = eff;
cc.Rf_ohm      = cel.Rf;
cc.usar_ramal  = usar_ramal;
cc.tag_base_cc = tag;
cc.pc          = pc;
cc.int         = interno;
cc.ramal       = ramal;
end

%% --- EQUACIONAMENTO THÉVENIN (SIMÉTRICAS E ASSIMÉTRICAS EFICAZES) ---
function res = calc_thevenin(Sbase_MVA, Vbase_kV, R0, X0, R1, X1, Rf_ohm)
Sbase_VA = Sbase_MVA * 1e6;
Vbase_V  = Vbase_kV * 1e3;
Ibase    = Sbase_VA / (sqrt(3) * Vbase_V);
Zbase    = (Vbase_V^2) / Sbase_VA;

Z1    = R1 + 1i * X1;
Z0    = R0 + 1i * X0;
Rf_pu = Rf_ohm / Zbase;
Z_1F  = 2*Z1 + Z0;

I3F    = (1 / abs(Z1)) * Ibase;
I2F    = (sqrt(3) / 2) * I3F;
I1F    = (3 / abs(Z_1F)) * Ibase;
I1F_40 = (3 / abs(Z_1F + 3*Rf_pu)) * Ibase;

[XR_3F, Ka_3F] = fator_assimetria_rms(R1, X1);
[XR_1F, Ka_1F] = fator_assimetria_rms(real(Z_1F), imag(Z_1F));

res = struct( ...
    'Zbase', Zbase, 'Ibase', Ibase, 'R1_pu', R1, 'X1_pu', X1, 'R0_pu', R0, 'X0_pu', X0, ...
    'I3F', I3F, 'I3F_assim', Ka_3F * I3F, 'I2F', I2F, ...
    'I1F', I1F, 'I1F_assim', Ka_1F * I1F, 'I1F_40', I1F_40, ...
    'XR_3F', XR_3F, 'XR_1F', XR_1F, 'Ka_3F', Ka_3F, 'Ka_1F', Ka_1F);
end

function [XR, Ka] = fator_assimetria_rms(R, X)
% Fator de assimetria eficaz (RMS) no 1º meio ciclo: Ka = sqrt(1 + 2*exp(-2*pi/(X/R)))
if R > 0, XR = X / R; else, XR = Inf; end
if isinf(XR),     Ka = sqrt(3);
elseif XR <= 0,   Ka = 1.0;
else,             Ka = sqrt(1 + 2 * exp(-2*pi / XR));
end
end

%% --- IMPEDÂNCIA DO RAMAL DE ENTRADA MT (NBR NM 280 + CARSON 60 Hz) ---
function info = calc_impedancia_ramal(cli, Sbase_MVA, Vbase_kV)
n_cond      = max(1, round(cli.Cabo_Entrada_Num_Cond));
secao_mm2   = cli.Cabo_Entrada_Secao_mm2;
comp_m      = max(0, cli.Cabo_Entrada_Comp_m);
tipo_limpo  = upper(strtrim(cli.Cabo_Entrada_Tipo));
iso_limpa   = upper(strtrim(cli.Cabo_Entrada_Isolacao));
eh_aluminio = lib_eletrica.eh_aluminio(cli.Cabo_Entrada_Material);

secoes = [16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400];
if eh_aluminio
    R20_tab = [1.91, 1.20, 0.868, 0.641, 0.443, 0.320, 0.253, 0.206, 0.164, 0.125, 0.100, 0.0778];
    rho20 = 0.02826; alpha_T = 0.00403;
else
    R20_tab = [1.15, 0.727, 0.524, 0.387, 0.268, 0.193, 0.153, 0.124, 0.0991, 0.0754, 0.0601, 0.0470];
    rho20 = 0.01724; alpha_T = 0.00393;
end

if secao_mm2 >= secoes(1) && secao_mm2 <= secoes(end)
    R20_km = exp(interp1(log(secoes), log(R20_tab), log(secao_mm2), 'linear'));
else
    R20_km = (rho20 * 1000) / secao_mm2;
end

if strcmp(tipo_limpo, 'AEREO_NU') || strcmp(iso_limpa, 'NU'), T_op = 75;
elseif ismember(iso_limpa, {'EPR', 'XLPE'}),                  T_op = 90;
else,                                                         T_op = 70;
end

r1_par_km = (R20_km * (1 + alpha_T * (T_op - 20)) * 1.015) / n_cond;
sec_clamp = min(max(secao_mm2, secoes(1)), secoes(end));

switch tipo_limpo
    case 'AEREO_COMPACTO'
        x1_tab = [0.340, 0.330, 0.320, 0.310, 0.300, 0.290, 0.285, 0.280, 0.275, 0.270, 0.265, 0.260];
        x1_par_km = interp1(log(secoes), x1_tab, log(sec_clamp), 'linear') / n_cond;
        r0_par_km = r1_par_km + 0.178;
        x0_par_km = 3.2 * x1_par_km;
    case 'AEREO_NU'
        x1_tab = [0.440, 0.430, 0.420, 0.410, 0.400, 0.390, 0.385, 0.380, 0.375, 0.370, 0.365, 0.360];
        x1_par_km = interp1(log(secoes), x1_tab, log(sec_clamp), 'linear') / n_cond;
        r0_par_km = r1_par_km + 0.178;
        x0_par_km = 3.5 * x1_par_km;
    otherwise
        tipo_limpo = 'SUBTERRANEO';
        x1_tab = [0.170, 0.160, 0.155, 0.148, 0.140, 0.134, 0.130, 0.126, 0.123, 0.119, 0.116, 0.113];
        x1_par_km = interp1(log(secoes), x1_tab, log(sec_clamp), 'linear') / n_cond;
        r0_par_km = max(3.0 * r1_par_km, r1_par_km + 0.178);
        x0_par_km = 3.2 * x1_par_km;
end

L_km  = comp_m / 1000;
Zbase = (Vbase_kV^2) / Sbase_MVA;

info = struct( ...
    'tipo', tipo_limpo, 'material', strtrim(cli.Cabo_Entrada_Material), 'isolacao', iso_limpa, ...
    'secao_mm2', secao_mm2, 'comp_m', comp_m, 'n_cond', n_cond, 'T_op', T_op, ...
    'R1_ohm', r1_par_km*L_km, 'X1_ohm', x1_par_km*L_km, 'R0_ohm', r0_par_km*L_km, 'X0_ohm', x0_par_km*L_km, ...
    'R1_pu', (r1_par_km*L_km)/Zbase, 'X1_pu', (x1_par_km*L_km)/Zbase, ...
    'R0_pu', (r0_par_km*L_km)/Zbase, 'X0_pu', (x0_par_km*L_km)/Zbase);
end