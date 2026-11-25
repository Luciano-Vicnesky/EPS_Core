function tps = dimensionar_tps(cli, cfg)
% DIMENSIONAR_TPS
% Especifica os TPs de Proteção e o TP Auxiliar de Serviços (TPA)
% independentes, uso interno, classe térmica B, conforme Celesc / ABNT NBR 6855.

Vnom_kV = cli.Vnom_prim_kV;
iso     = lib_eletrica.nivel_isolamento(Vnom_kV);

% =========================================================================
% 1. TP DE PROTEÇÃO (3 TPs ESTRELA ATERRADA G2/G3 OU 2 TPs DELTA ABERTO G1)
% =========================================================================
arranjo = strtrim(cli.TP_Arranjo);
V2n_V   = 115.0;
FT_perm = 1.2;

if strcmp(arranjo, '2TP_DeltaAberto_Grupo1')
    qtd        = 2;
    ligacao    = 'Delta Aberto (V-V - Fase-Fase)';
    grupo      = 'Grupo 1 (Ligação entre fases)';
    FT_max     = 1.2; FT_dur = 'Contínuo';
    V1n_V      = Vnom_kV * 1000;
    V_sec_LL_V = V2n_V;
    V_prim_fmt = sprintf('%.2f kV (%.1f V)', Vnom_kV, V1n_V);
    rel_fmt    = sprintf('%.2f kV : 115 V', Vnom_kV);
else
    qtd        = 3;
    ligacao    = 'Estrela Aterrada (Y0/Y0 - Fase-Terra)';
    FT_max     = 1.9;
    V1n_V      = (Vnom_kV * 1000) / sqrt(3);
    V_sec_LL_V = V2n_V * sqrt(3);
    V_prim_fmt = sprintf('%.2f / sqrt(3) kV (%.1f V)', Vnom_kV, V1n_V);
    rel_fmt    = sprintf('(%.2f/sqrt(3)) kV : 115 V', Vnom_kV);
    if strcmp(arranjo, '3TP_Estrela_Grupo3')
        grupo = 'Grupo 3 (Sistema não eficazmente aterrado)'; FT_dur = '8 h';
    else
        arranjo = '3TP_Estrela_Grupo2';
        grupo = 'Grupo 2 (Sistema eficazmente aterrado)';     FT_dur = '30 s';
    end
end

RTP_prot_exato = V1n_V / V2n_V;
[RTP_prot, RTP_prot_ajustado] = ajustar_rtp_comercial(RTP_prot_exato);
V2_op_prot_V = V1n_V / RTP_prot;

classe_in = strrep(upper(strtrim(cli.TP_Classe)), '.', ',');
if strncmp(classe_in, '0,3', 3), exatidao_str = '0,3'; else, exatidao_str = '0,6'; end
Cn_alvo_VA = 75.0;

cb         = lib_eletrica.cabo_secundario(cli.Cabo_TP_Material, cli.Cabo_TP_Isolacao, cli.Cabo_TP_Secao_mm2, cli.Cabo_TP_Comp_m);
S_rele_VA  = cli.TP_Consumo_Rele_VA;
I_carga_A  = S_rele_VA / V2n_V;
S_cabo_VA  = (I_carga_A^2) * cb.Z_cabo;
S_total_VA = S_rele_VA + S_cabo_VA;

Cn_padrao        = [12.5, 25.0, 75.0, 200.0, 400.0];
cands_Cn         = Cn_padrao(Cn_padrao >= S_total_VA);
alerta_carga_max = isempty(cands_Cn);
if alerta_carga_max, Cn_min_calc = Cn_padrao(end); else, Cn_min_calc = cands_Cn(1); end

Cn_sel_VA    = max(Cn_alvo_VA, Cn_min_calc);
escalonou_Cn = (Cn_sel_VA > Cn_alvo_VA);
classe_final = sprintf('%sP%g', exatidao_str, Cn_sel_VA);
Pt_prot_VA   = max(500.0, Cn_sel_VA);

lim_dV_pct   = cfg.queda_tensao_max_tp_pct;
dV_real_V    = cb.Z_cabo * I_carga_A;
dV_real_pct  = (dV_real_V / V2n_V) * 100;
secao_min_dV = (2 * cb.rho_T * cli.Cabo_TP_Comp_m * I_carga_A) / ((lim_dV_pct / 100) * V2n_V);

prot = struct( ...
    'arranjo', arranjo, 'qtd', qtd, 'ligacao', ligacao, 'grupo', grupo, ...
    'instalacao', 'Interna (Resina Epóxi)', 'classe_temp', 'B (130 °C)', 'freq_Hz', 60, 'iso', iso, ...
    'V1n_V', V1n_V, 'V2n_V', V2n_V, 'V2_op_V', V2_op_prot_V, 'V_sec_LL_V', V_sec_LL_V, ...
    'V_prim_fmt', V_prim_fmt, 'rel_fmt', rel_fmt, ...
    'RTP', RTP_prot, 'RTP_exato', RTP_prot_exato, 'RTP_ajustado', RTP_prot_ajustado, ...
    'FT_perm', FT_perm, 'FT_max', FT_max, 'FT_dur', FT_dur, ...
    'exatidao_str', exatidao_str, 'classe_alvo', [exatidao_str 'P75'], 'classe_final', classe_final, ...
    'Cn_min_calc_VA', Cn_min_calc, 'Cn_sel_VA', Cn_sel_VA, 'Pt_nom_VA', Pt_prot_VA, ...
    'escalonou_Cn', escalonou_Cn, 'alerta_carga_max', alerta_carga_max, ...
    'cabo_secao_mm2', cli.Cabo_TP_Secao_mm2, 'cabo_material', strtrim(cli.Cabo_TP_Material), ...
    'cabo_isolacao', upper(strtrim(cli.Cabo_TP_Isolacao)), 'cabo_comp_m', cli.Cabo_TP_Comp_m, ...
    'T_op', cb.T_op, 'rho_T', cb.rho_T, 'R_cabo_km', cb.R_cabo_km, 'Z_cabo', cb.Z_cabo, ...
    'S_rele_VA', S_rele_VA, 'I_carga_A', I_carga_A, 'S_cabo_VA', S_cabo_VA, 'S_total_VA', S_total_VA, ...
    'ok_burden', S_total_VA <= Cn_sel_VA, 'lim_dV_pct', lim_dV_pct, ...
    'dV_real_V', dV_real_V, 'dV_real_pct', dV_real_pct, ...
    'ok_queda_tensao', dV_real_pct < lim_dV_pct, 'secao_min_mm2', secao_min_dV);

% =========================================================================
% 2. TP AUXILIAR PARA SERVIÇOS - TPA (INDEPENDENTE, FASE-FASE, 110 V)
% =========================================================================
V1n_tpa_V     = Vnom_kV * 1000;
V2n_tpa_V     = 110.0;
RTP_tpa_exato = V1n_tpa_V / V2n_tpa_V;
[RTP_tpa, RTP_tpa_ajustado] = ajustar_rtp_comercial(RTP_tpa_exato);

margem_pct        = cfg.margem_seg_tpa_pct;
P_prevista_VA     = cli.TPA_Carga_Prevista_VA;
P_req_VA          = P_prevista_VA * (1 + margem_pct / 100);
P_padrao          = [500, 1000, 1500, 2000, 3000, 5000];
cands_P           = P_padrao(P_padrao >= P_req_VA);
alerta_acima_5kVA = isempty(cands_P);
if alerta_acima_5kVA, P_nom_VA = ceil(P_req_VA / 1000) * 1000; else, P_nom_VA = cands_P(1); end

aux = struct( ...
    'qtd', 1, 'ligacao', 'Fase-Fase (Independente do TP de Proteção)', ...
    'grupo', 'Grupo 1 (Ligação entre fases)', 'instalacao', 'Interna (Resina Epóxi)', ...
    'classe_temp', 'B (130 °C)', 'freq_Hz', 60, 'iso', iso, ...
    'V1n_V', V1n_tpa_V, 'V2n_V', V2n_tpa_V, 'V2_op_V', V1n_tpa_V / RTP_tpa, ...
    'RTP', RTP_tpa, 'RTP_exato', RTP_tpa_exato, 'RTP_ajustado', RTP_tpa_ajustado, ...
    'rel_fmt', sprintf('%.2f kV : 110 V', Vnom_kV), ...
    'FT_perm', 1.2, 'FT_max', 1.2, 'FT_dur', 'Contínuo', ...
    'P_prevista_VA', P_prevista_VA, 'margem_pct', margem_pct, 'P_req_VA', P_req_VA, ...
    'P_nom_VA', P_nom_VA, 'margem_real_pct', ((P_nom_VA / P_prevista_VA) - 1) * 100, ...
    'I1n_A', P_nom_VA / V1n_tpa_V, 'I2n_A', P_nom_VA / V2n_tpa_V, ...
    'alerta_acima_5kVA', alerta_acima_5kVA);

tps = struct('prot', prot, 'aux', aux);
end

function [rtp_int, ajustado] = ajustar_rtp_comercial(rtp_exato)
if abs(rtp_exato - round(rtp_exato)) < 1e-6
    rtp_int = round(rtp_exato); ajustado = false;
else
    rtp_int = max(1, 5 * round(rtp_exato / 5)); ajustado = true;
end
end