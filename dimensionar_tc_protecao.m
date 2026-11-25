function tc = dimensionar_tc_protecao(cli, cfg, cc, I_demanda, Ip_51, Ip_51N)
% DIMENSIONAR_TC_PROTECAO
% Dimensiona (AUTO) ou audita (MANUAL) o TC de proteção pela ABNT NBR 6856 / Celesc.

Isec_nom       = cli.Isec_TC;
exatidao_pct   = cli.TC_Exatidao_pct;
classe_servico = upper(strtrim(cli.TC_Classe_Servico));
modo_tc        = upper(strtrim(cli.TC_Modo));
FS_tc          = cfg.FS_tc_protecao;
Z_contato      = max(0, cfg.R_contato_tc_ohm);
iso            = lib_eletrica.nivel_isolamento(cli.Vnom_prim_kV);
if cli.Vnom_prim_kV <= 15.0, FT_tc = 1.5; else, FT_tc = 1.2; end

if cc.I3F >= cc.I1F
    Icc_sim = cc.I3F; XR_tc = cc.XR_3F;
else
    Icc_sim = cc.I1F; XR_tc = cc.XR_1F;
end

I1n_padrao = [10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 120, 150, 200, 250, 300, ...
              400, 500, 600, 800, 1000, 1200, 1500, 2000, 2500, 3000];
if Isec_nom == 5, Cn_padrao = [2.5, 5.0, 12.5, 25.0, 50.0, 100.0];
else,             Cn_padrao = [2.5, 5.0, 12.5, 25.0, 50.0];
end

% 1. Impedância externa (cabo + relé + resistência de contato)
cb     = lib_eletrica.cabo_secundario(cli.Cabo_TC_Material, cli.Cabo_TC_Isolacao, cli.Cabo_TC_Secao_mm2, cli.Cabo_TC_Comp_m);
Z_rele = cli.Consumo_Rele_VA / (Isec_nom^2);
Z_ext  = cb.Z_cabo + Z_rele + Z_contato;
S_ext  = Z_ext * (Isec_nom^2);

% 2. Limites de corrente primária
I1n_min_nom = Ip_51;
I1n_min_sat = Icc_sim / FS_tc;
I1n_min_req = max(I1n_min_nom, I1n_min_sat);
I1n_max_dem = 20.0 * I_demanda;
min_51N_sec = (cfg.sensib_rele_51N_pct / 100) * Isec_nom;

flag_trans_relaxado = false;
flag_sim_relaxado   = false;

% 3. Seleção automática em cascata de prioridades ou auditoria manual
if strcmp(modo_tc, 'AUTO')
    cands_all = I1n_padrao(I1n_padrao >= I1n_min_req);
    if isempty(cands_all), cands_all = I1n_padrao(end); end
    cands_lim = cands_all(cands_all <= I1n_max_dem);

    tentativas = {cands_lim, true; cands_lim, false; cands_all, true; cands_all, false};
    achou = false;
    for t = 1:size(tentativas, 1)
        if isempty(tentativas{t, 1}), continue; end
        [Iprim_sel, Cn_sel, achou] = buscar_tc(tentativas{t, 1}, Cn_padrao, tentativas{t, 2}, ...
            Isec_nom, FS_tc, Icc_sim, XR_tc, Z_ext, S_ext);
        if achou
            flag_trans_relaxado = ~tentativas{t, 2};
            break;
        end
    end
    if ~achou
        flag_trans_relaxado = true;
        flag_sim_relaxado   = true;
        Iprim_sel = cands_all(end);
        Cn_sel    = Cn_padrao(end);
    end
else
    Iprim_sel = cli.RTC_Primario;
    Cn_sel    = (cli.TC_Tensao_Sat_V * Isec_nom) / FS_tc;
end

% 4. Avaliação definitiva do TC selecionado
[Vs_sim, Vs_trans, Vs_max, Z_tc, Z_total] = avaliar_tc(Iprim_sel, Cn_sel, Isec_nom, FS_tc, Icc_sim, XR_tc, Z_ext);
RTC        = Iprim_sel / Isec_nom;
S_total    = Z_total * (Isec_nom^2);
Ip_51N_sec = Ip_51N / RTC;

if Vs_sim <= Vs_max,   st_sim = 'APROVADO (NÃO SATURA em regime simétrico - ABNT NBR 6856)';
else,                  st_sim = 'REPROVADO (SATURA em regime simétrico - aumentar classe/RTC ou cabo)';
end
if Vs_trans <= Vs_max, st_trn = 'APROVADO (NÃO SATURA em regime transitório c/ X/R)';
else,                  st_trn = 'REPROVADO (SATURA em regime transitório - fator 1+X/R excede Vs_max)';
end

tc = struct( ...
    'modo', modo_tc, 'instalacao', 'Interna (Resina Epóxi)', 'freq_Hz', 60, 'iso', iso, ...
    'Iprim', Iprim_sel, 'Isec', Isec_nom, 'RTC', RTC, ...
    'exatidao_pct', exatidao_pct, 'classe_servico', classe_servico, 'FS', FS_tc, 'FT', FT_tc, ...
    'Cn_VA', Cn_sel, 'Zn_ohm', Cn_sel / (Isec_nom^2), 'Vs_max', Vs_max, ...
    'classe_formatada', sprintf('%g%s%g', exatidao_pct, classe_servico, round(Vs_max)), ...
    'I1n_max_banco', I1n_padrao(end), 'I_demanda', I_demanda, 'Ip_51', Ip_51, 'Ip_51N', Ip_51N, ...
    'Icc_max_sim', Icc_sim, 'Icc_sec_sim', Icc_sim / RTC, 'XR_tc', XR_tc, ...
    'I1n_min_nom', I1n_min_nom, 'I1n_min_sat', I1n_min_sat, 'I1n_min_req', I1n_min_req, ...
    'I1n_max_dem', I1n_max_dem, 'cabo_secao_mm2', cli.Cabo_TC_Secao_mm2, ...
    'cabo_material', strtrim(cli.Cabo_TC_Material), 'cabo_isolacao', upper(strtrim(cli.Cabo_TC_Isolacao)), ...
    'cabo_comp_m', cli.Cabo_TC_Comp_m, 'T_op', cb.T_op, 'rho20', cb.rho20, 'alpha_T', cb.alpha_T, ...
    'rho_T', cb.rho_T, 'R_cabo_km', cb.R_cabo_km, ...
    'consumo_rele_VA', cli.Consumo_Rele_VA, 'R_contato_ohm', Z_contato, ...
    'Z_cabo', cb.Z_cabo, 'Z_rele', Z_rele, 'Z_ext', Z_ext, 'S_ext_VA', S_ext, ...
    'Z_tc', Z_tc, 'Z_total', Z_total, 'S_total_VA', S_total, ...
    'Vs_sim', Vs_sim, 'Vs_trans', Vs_trans, 'status_sim', st_sim, 'status_trans', st_trn, ...
    'Ip_51N_sec', Ip_51N_sec, 'min_51N_sec', min_51N_sec, 'sensib_51N_pct', cfg.sensib_rele_51N_pct, ...
    'ok_nominal', Iprim_sel >= I1n_min_nom, 'ok_regra_icc_fs', Iprim_sel >= I1n_min_sat, ...
    'ok_limite_20x_dem', Iprim_sel <= I1n_max_dem, ...
    'ok_burden_ext', S_ext <= Cn_sel, 'ok_sat_sim', Vs_sim <= Vs_max, ...
    'ok_sat_trans', Vs_trans <= Vs_max, 'ok_sensib_51N', Ip_51N_sec >= min_51N_sec, ...
    'classe_A_alerta', strcmp(classe_servico, 'A'), ...
    'flag_trans_relaxado', flag_trans_relaxado, 'flag_sim_relaxado', flag_sim_relaxado);
end

function [Iprim_sel, Cn_sel, achou] = buscar_tc(cands, Cn_padrao, exigir_trans, Isec, FS, Icc_sim, XR, Z_ext, S_ext)
achou = false; Iprim_sel = cands(end); Cn_sel = Cn_padrao(end);
for i = 1:numel(cands)
    for j = 1:numel(Cn_padrao)
        [Vs_s, Vs_t, Vs_m] = avaliar_tc(cands(i), Cn_padrao(j), Isec, FS, Icc_sim, XR, Z_ext);
        if (S_ext <= Cn_padrao(j)) && (Vs_s <= Vs_m) && (~exigir_trans || Vs_t <= Vs_m)
            Iprim_sel = cands(i); Cn_sel = Cn_padrao(j); achou = true;
            return;
        end
    end
end
end

function [Vs_sim, Vs_trans, Vs_max, Z_tc, Z_total] = avaliar_tc(Iprim, Cn_VA, Isec, FS, Icc_sim, XR, Z_ext)
Z_tc     = ((5 / Isec)^2) * (0.00234 * (Iprim / 5) + 0.0262);
Z_total  = Z_tc + Z_ext;
Vs_sim   = Z_total * (Icc_sim / (Iprim / Isec));
Vs_trans = Vs_sim * (1 + max(0, XR));
Vs_max   = (FS / Isec) * Cn_VA;
end