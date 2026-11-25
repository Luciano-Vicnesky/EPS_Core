function est = otimizar_protecao(cel, cli, cfg, cc)
% OTIMIZAR_PROTECAO
% Executa todos os cálculos de proteção: transformadores, inrush, pickups,
% TC de proteção, TPs (proteção e auxiliar), 51NS, otimização e cabo MT.

t_disj     = 0.05; % Tempo típico de abertura do disjuntor MT (50 ms)
t_piso_con = 0.01;
M_max      = cfg.M_max_curva_iec;
if isnan(M_max) || M_max <= 0, M_max = Inf; end

% 1. Normalização da proteção a montante no PC (Celesc + Elo PC)
con = normalizar_conces(cel, cc);

% 2. Transformadores, ANSI/NANSI, Inrush e Demanda de Consumo
kVA   = lib_eletrica.parse_vetor_num(cli.Trafos_kVA);
Z_pct = lib_eletrica.parse_vetor_num(cli.Z_Trafos_pct);
tipos = strsplit(upper(strtrim(cli.Tipos_Trafos)));

Inom       = kVA ./ (sqrt(3) * cli.Vnom_prim_kV);
Inom_total = sum(Inom);
Iansi      = Inom ./ (Z_pct / 100);
Inansi     = Iansi / sqrt(3);

[kVA_maior, idx_m] = max(kVA);
I_maior  = Inom(idx_m);
I_demais = Inom_total - I_maior;
if strcmp(tipos{idx_m}, 'S'), mult_inr = cfg.k_inrush_seco; else, mult_inr = cfg.k_inrush_oleo; end
if kVA_maior > 2000
    warndlg('Transformador > 2000 kVA identificado. Verifique o multiplicador de Inrush no datasheet do fabricante.', 'Aviso Normativo');
end
I_inrush     = (mult_inr * I_maior) + I_demais;
I_inrush_lim = cfg.fator_norma_inrush * I_inrush;
I_demanda    = cli.Demanda_Consumo_kW / (sqrt(3) * cli.Vnom_prim_kV * cli.FP_demanda);

% 3. Pickups de Fase (51/50) e Pickup 51N (tolerância 1e-9 contra deriva binária IEEE-754)
Ip_51 = floor((cfg.fator_ip51_demanda * I_demanda) * 10 + 1e-9) / 10;
Ip_50 = ceil((cfg.fator_ip50_inrush * I_inrush) * 10 - 1e-9) / 10;
if Ip_50 >= cc.I3F
    warndlg(sprintf('O Inrush (%.1fA) gerou Instantâneo (%.1fA) >= Icc3F (%.1fA). Unidade 50 ficará INOPERANTE.', I_inrush, Ip_50, cc.I3F), 'Aviso');
end

Ip_51N_teto = floor((cfg.fator_ip51N_fase * Ip_51) * 100 + 1e-9) / 100;
Ip_51N      = Ip_51N_teto;
if ~isnan(con.Ip_51N) && (Ip_51N >= cfg.fator_teto_conces * con.Ip_51N)
    Ip_51N = floor((cfg.fator_teto_conces * con.Ip_51N) * 100 + 1e-9) / 100;
end
Ip_51N = max(Ip_51N, 0.05);

% 4. Dimensionamento dos Transformadores de Instrumentos (TC, TP Proteção e TPA)
tc  = dimensionar_tc_protecao(cli, cfg, cc, I_demanda, Ip_51, Ip_51N);
tps = dimensionar_tps(cli, cfg);

% 5. Verificação de Sensibilidade Residual (51NS / 51GS) e Pickup 50N
ns = configurar_51ns(Ip_51N, Ip_51N_teto, cc.I1F_40, tc, cfg);
[Ip_50N, det_50N] = calcular_pickup_50N(Ip_50, Ip_51N, I_inrush, cc.I1F, con, cli.t_50N_cli, cfg);

% 6. Otimização Unificada de Curvas: Fase e Neutro
p_fase = struct( ...
    'Ip_51', Ip_51, 'Ip_50', Ip_50, 't_50', cli.t_50_cli, 'Icc_max', cc.I3F, ...
    'Ip_51_con', con.Ip_51, 'DT_51_con', con.DT_51, 'Curva_con', con.Curva_51, ...
    'Ip_50_con', con.Ip_50, 't_50_con', con.t_50, ...
    'I_pt1', Iansi, 'I_pt2', Inansi, 'I_inrush', I_inrush, ...
    'I_falta_min', NaN, 't_51NS_backup', NaN);
res_F = otimizar_curva_canal(p_fase, con, cfg, t_disj, t_piso_con, M_max);

t_51NS_bkp = NaN;
if ns.habilitado && (cc.I1F_40 > ns.Ip_51NS), t_51NS_bkp = ns.t_51NS; end
p_neut = struct( ...
    'Ip_51', Ip_51N, 'Ip_50', Ip_50N, 't_50', cli.t_50N_cli, 'Icc_max', cc.I1F, ...
    'Ip_51_con', con.Ip_51N, 'DT_51_con', con.DT_51N, 'Curva_con', con.Curva_51N, ...
    'Ip_50_con', con.Ip_50N, 't_50_con', con.t_50N, ...
    'I_pt1', Inansi, 'I_pt2', [], 'I_inrush', NaN, ...
    'I_falta_min', cc.I1F_40, 't_51NS_backup', t_51NS_bkp);
res_N = otimizar_curva_canal(p_neut, con, cfg, t_disj, t_piso_con, M_max);

% 7. Coordenação iterativa final do 51NS (contra Celesc e Elo)
if ns.habilitado
    ns = coordenar_51ns(ns, Ip_51N, Ip_50N, cli.t_50N_cli, res_N.curva, res_N.dt, cc.I1F, con, tc, cfg, t_disj, t_piso_con, M_max);
    if cc.I1F_40 > ns.Ip_51NS
        t_51N_fin = calc_t_rele(cc.I1F_40, Ip_51N, res_N.dt, res_N.curva, Ip_50N, cli.t_50N_cli, cli.t_50N_cli, M_max);
        res_N.esc.t_falta_min = min([t_51N_fin, ns.t_51NS], [], 'omitnan');
    end
end

% 8. Limites da faixa instantânea frente à Celesc e verificação térmica do Cabo MT
lim_con_F = calc_limite_inst_conces(Ip_50,  cli.t_50_cli,  cc.I3F, con.Ip_51,  con.DT_51,  con.Curva_51,  con.Ip_50,  con.t_50,  cfg, t_piso_con);
lim_con_N = calc_limite_inst_conces(Ip_50N, cli.t_50N_cli, cc.I1F, con.Ip_51N, con.DT_51N, con.Curva_51N, con.Ip_50N, con.t_50N, cfg, t_piso_con);

cabo_mt = verificar_cabo_mt(cli, cc, Ip_51, res_F.dt, res_F.curva, Ip_50, ...
    Ip_51N, res_N.dt, res_N.curva, Ip_50N, t_disj, M_max);

% 9. Empacotamento estruturado dos resultados

est.M_max   = M_max;
est.t_disj  = t_disj;
est.conces  = con;
est.tc      = tc;
est.tps     = tps;
est.cabo_mt = cabo_mt;
est.trafos  = struct('kVA', kVA, 'Z_pct', Z_pct, 'tipos', {tipos}, 'Inom', Inom, ...
    'Inom_total', Inom_total, 'Iansi', Iansi, 'Inansi', Inansi, ...
    'I_maior', I_maior, 'I_demais', I_demais, 'mult_inrush', mult_inr, ...
    'I_inrush', I_inrush, 'I_inrush_lim', I_inrush_lim);
est.dem     = struct('P_consumo', cli.Demanda_Consumo_kW, 'I_demanda', I_demanda);

est.fase = res_F;
est.fase.Ip_51            = Ip_51;
est.fase.Ip_50            = Ip_50;
est.fase.t_50             = cli.t_50_cli;
est.fase.alerta_50_conces = ~isnan(con.Ip_50) && (Ip_50 >= con.Ip_50);
est.fase.I_lim_con        = lim_con_F;

est.neutro = res_N;
est.neutro.Ip_51N            = Ip_51N;
est.neutro.Ip_51N_teto_norma = Ip_51N_teto;
est.neutro.Ip_50N            = Ip_50N;
est.neutro.det_50N           = det_50N;
est.neutro.t_50N             = cli.t_50N_cli;
est.neutro.piso_50N_inrush   = det_50N.piso_inrush;
est.neutro.alerta_50N_conces = ~isnan(con.Ip_50N) && (Ip_50N >= con.Ip_50N);
est.neutro.I_lim_con         = lim_con_N;
est.neutro.ns                = ns;

end

%% --- SUBFUNÇÕES DO MOTOR DE PROTEÇÃO ---
function con = normalizar_conces(cel, cc)
con = struct( ...
    'Curva_51', upper(strtrim(cel.Curva_51)),   'Ip_51', cel.Ip_51,   'DT_51', cel.DT_51, ...
    'Ip_50', cel.Ip_50,   't_50', cel.t_50, ...
    'Curva_51N', upper(strtrim(cel.Curva_51N)), 'Ip_51N', cel.Ip_51N, 'DT_51N', cel.DT_51N, ...
    'Ip_50N', cel.Ip_50N, 't_50N', cel.t_50N, ...
    'tem_elo', strcmpi(strtrim(cel.Usa_Elo_PC), 'SIM'), ...
    'Elo_PC', strtrim(cel.Elo_PC), 'I_elo_ref', [], 't_fus_min_ref', []);

if isnan(con.Ip_50)  || con.Ip_50  <= 0, con.Ip_50  = NaN; con.t_50  = NaN; elseif isnan(con.t_50)  || con.t_50  <= 0, con.t_50  = 0.01; end
if isnan(con.Ip_50N) || con.Ip_50N <= 0, con.Ip_50N = NaN; con.t_50N = NaN; elseif isnan(con.t_50N) || con.t_50N <= 0, con.t_50N = 0.01; end

if con.tem_elo
    I_max_sis = max([cc.I3F, cc.I1F, con.Ip_50, con.Ip_50N], [], 'omitnan') * 1.5;
    [con.I_elo_ref, con.t_fus_min_ref, ~] = curva_elo_fusivel(con.Elo_PC, I_max_sis);
end
end

function ns = configurar_51ns(Ip_51N, Ip_51N_teto, I1F_40, tc, cfg)
ns = struct('habilitado', false, 'motivo', '', 'Ip_51NS', NaN, 't_51NS', NaN, ...
    'I_corte', NaN, 't_corte', NaN, 'alerta_sensib', false, ...
    'alerta_acima_com43', false, 'alerta_coord', false, ...
    'RTC_tor_max_com43', NaN, 'min_51NS_sec', cfg.sensib_rele_51NS_A);

I_falta_lim = cfg.fator_sensib_1F_min * I1F_40;
if Ip_51N > I_falta_lim
    ns.habilitado = true;
    ns.motivo = sprintf('Ajuste de %.0f%% (%.2fA) supera %.0f%% de I1F_min (%.1fA).', ...
        cfg.fator_ip51N_fase*100, Ip_51N, cfg.fator_sensib_1F_min*100, I_falta_lim);
elseif tc.Ip_51N_sec < tc.min_51N_sec
    ns.habilitado = true;
    ns.motivo = sprintf('Com TC %g/%gA, %.2fA prim (%.4fA sec) fica abaixo do mínimo do relé (%.4fA sec).', ...
        tc.Iprim, tc.Isec, Ip_51N, tc.Ip_51N_sec, tc.min_51N_sec);
end

if ns.habilitado
    RTC_tor_ref          = 100;
    Ip_min_prim          = max(0.5, cfg.sensib_rele_51NS_A * RTC_tor_ref);
    ns.Ip_51NS           = floor(min([cfg.Ip_51NS_padrao_A, Ip_51N_teto, I_falta_lim * 0.5]) * 100 + 1e-9) / 100;
    ns.RTC_tor_max_com43 = floor(Ip_51N_teto / max(cfg.sensib_rele_51NS_A, 1e-6));
    if ns.Ip_51NS < Ip_min_prim
        ns.Ip_51NS       = Ip_min_prim;
        ns.alerta_sensib = true;
    end
    ns.alerta_acima_com43 = (ns.Ip_51NS > Ip_51N_teto);
    ns.t_51NS = cfg.t_51NS_padrao_s;

    msg = sprintf('ATENÇÃO: Restrição de Sensibilidade no Neutro.\nMotivo: %s\n\nFunção 51NS/51GS (TC Toroidal) ativada.', ns.motivo);
    if ns.alerta_acima_com43
        msg = sprintf(['%s\n\nALERTA CRÍTICO (51NS): Com sensib. toroidal = %.3f A sec e RTC %d/1, ' ...
            'o piso mínimo (%.2f A) supera o limite de neutro (%.2f A).\nRevise a sensibilidade 51GS no manual ' ...
            'ou utilize TC toroidal <= %d/1 A.'], msg, cfg.sensib_rele_51NS_A, RTC_tor_ref, ...
            ns.Ip_51NS, Ip_51N_teto, max(1, ns.RTC_tor_max_com43));
    end
    warndlg(msg, 'Sensibilidade de Neutro');
end
end

function [Ip_50N, det] = calcular_pickup_50N(Ip_50, Ip_51N, I_inrush, I1F, con, t_50N, cfg)
base_50     = cfg.fator_ip50N_fase * Ip_50;
piso_51N    = 2.0 * Ip_51N;
piso_inrush = cfg.fator_piso_50N_inrush * I_inrush;
piso_seg    = max(piso_51N, piso_inrush);
teto_I1F    = cfg.fator_teto_50N_icc1f * I1F;

Ip_50N = min(max(base_50, piso_seg), teto_I1F);

teto_con_50N = NaN;
if ~isnan(con.Ip_50N)
    teto_con_50N = cfg.fator_teto_conces * con.Ip_50N;
    Ip_50N = min(Ip_50N, teto_con_50N);
end

teto_con_curva = NaN;
I_sup = max(I1F, Ip_50N * 1.2);
if I_sup > con.Ip_51N * 1.01
    I_var = logspace(log10(con.Ip_51N * 1.01), log10(I_sup), 1000);
    t_con = calc_t_rele(I_var, con.Ip_51N, con.DT_51N, con.Curva_51N, NaN, NaN, 0.01);
    idx   = find(t_con < (t_50N + cfg.delta_t_seletividade_s), 1, 'first');
    if ~isempty(idx)
        teto_con_curva = I_var(idx) * 0.95;
        Ip_50N = min(Ip_50N, teto_con_curva);
    end
end

Ip_50N = round(max(Ip_50N, piso_51N) * 10) / 10;

det = struct('base_50', base_50, 'piso_51N', piso_51N, 'piso_inrush', piso_inrush, ...
    'piso_seg', piso_seg, 'teto_I1F', teto_I1F, ...
    'teto_con_50N', teto_con_50N, 'teto_con_curva', teto_con_curva);
end

function res = otimizar_curva_canal(p, con, cfg, t_disj, t_piso_con, M_max)

% Motor unificado de otimização IEC 60255 com pré-cálculo da curva base (DT = 1)
curvas    = {'NI', 'MI', 'EI'};
dts       = round(cfg.dt_min_rele : cfg.dt_passo_rele : cfg.dt_max_rele, 6);
n_c       = numel(curvas);
n_dt      = numel(dts);
t_lim     = cfg.t_ansi_limite_rele_s;
dt_sel    = cfg.delta_t_seletividade_s;
f_elo     = cfg.fator_seg_elo;
t_min_inr = cfg.t_inrush_nominal_s + cfg.margem_coord_inrush_s;

% Malhas de avaliação (Celesc, Elo e ranking de folga)
I_min_c = max(p.Ip_51 * 1.01, p.Ip_51_con * 1.02);
I_max_c = min(p.Ip_50 * 0.99, p.Icc_max);
if I_max_c > I_min_c
    I_eval = logspace(log10(I_min_c), log10(I_max_c), 300);
    t_con  = calc_t_rele(I_eval, p.Ip_51_con, p.DT_51_con, p.Curva_con, p.Ip_50_con, p.t_50_con, t_piso_con);
else
    I_eval = []; t_con = [];
end

I_elo_ev = []; t_elo_ev = [];
if con.tem_elo
    I_min_e = max(p.Ip_51 * 1.01, con.I_elo_ref(1) * 1.02);
    I_max_e = min(p.Ip_50 * 0.9999, p.Icc_max);
    if I_max_e > I_min_e
        I_elo_ev = logspace(log10(I_min_e), log10(I_max_e), 300);
        t_elo_ev = exp(interp1(log(con.I_elo_ref), log(con.t_fus_min_ref), log(I_elo_ev), 'pchip', Inf));
    end
end

M_ini  = min(4.0, max(1.5, 0.50 * (p.Ip_50 / p.Ip_51)));
M_fim  = max(M_ini * 1.25, min(15.0, 0.95 * (p.Ip_50 / p.Ip_51)));
I_rank = logspace(log10(p.Ip_51 * M_ini), log10(p.Ip_51 * M_fim), 25);

unprot_1  = any(p.I_pt1 <= p.Ip_51 * 1.001);
unprot_2  = ~isempty(p.I_pt2) && any(p.I_pt2 <= p.Ip_51 * 1.001);
tem_pt2   = ~isempty(p.I_pt2);
tem_inr   = ~isnan(p.I_inrush);
tem_fmin  = ~isnan(p.I_falta_min);
tem_eval  = ~isempty(I_eval);
tem_elo_v = con.tem_elo && ~isempty(I_elo_ev);

mask_pt1  = (p.I_pt1 >= p.Ip_50);
mask_pt2  = (p.I_pt2 >= p.Ip_50);
mask_inr  = tem_inr  && (p.I_inrush    >= p.Ip_50);
mask_fmin = tem_fmin && (p.I_falta_min >= p.Ip_50);
t_elo_min = (p.t_50 + t_disj) / f_elo;

% Pré-alocação do vetor de resultados
n_tot = n_c * n_dt;
molde = struct('curva', '', 'dt', 0, 't_inrush', NaN, 'score', 0, ...
    'min_margem_celesc', Inf, 'max_t_pt1', Inf, 'max_t_pt2', NaN, ...
    't_falta_min', NaN, 'min_margem_elo', Inf, 'min_folga_elo', Inf, 'penalidade', Inf);
todas       = repmat(molde, 1, n_tot);
is_sem_bloq = false(1, n_tot);
is_com_bloq = false(1, n_tot);
idx_g       = 0;

for c = 1:n_c
    tc = curvas{c};
    % Pré-cálculo das curvas unitárias (DT = 1, sem piso) via calc_t_rele
    tb_rank = calc_t_rele(I_rank, p.Ip_51, 1, tc, Inf, NaN, 0, M_max);
    tb_pt1  = calc_t_rele(p.I_pt1, p.Ip_51, 1, tc, Inf, NaN, 0, M_max);
    if tem_pt2,   tb_pt2  = calc_t_rele(p.I_pt2,       p.Ip_51, 1, tc, Inf, NaN, 0, M_max); else, tb_pt2  = []; end
    if tem_inr,   tb_inr  = calc_t_rele(p.I_inrush,    p.Ip_51, 1, tc, Inf, NaN, 0, M_max); else, tb_inr  = NaN; end
    if tem_fmin,  tb_fmin = calc_t_rele(p.I_falta_min, p.Ip_51, 1, tc, Inf, NaN, 0, M_max); else, tb_fmin = NaN; end
    if tem_eval,  tb_eval = calc_t_rele(I_eval,        p.Ip_51, 1, tc, Inf, NaN, 0, M_max); else, tb_eval = []; end
    if tem_elo_v, tb_elo  = calc_t_rele(I_elo_ev,      p.Ip_51, 1, tc, Inf, NaN, 0, M_max); else, tb_elo  = []; end

    for d = 1:n_dt
        dt    = dts(d);
        idx_g = idx_g + 1;

        t_rk  = aplicar_dt(tb_rank, false, dt, p.t_50);
        score = exp(mean(log(max(t_rk, 1e-4)), 'omitnan'));

        [ok1, max_t1, def1] = avaliar_pts_dt(tb_pt1, mask_pt1, unprot_1, dt, p.t_50, t_lim);
        if tem_pt2
            [ok2, max_t2, def2] = avaliar_pts_dt(tb_pt2, mask_pt2, unprot_2, dt, p.t_50, t_lim);
        else
            ok2 = true; max_t2 = NaN; def2 = 0;
        end

        if tem_inr
            t_inr  = aplicar_dt(tb_inr, mask_inr, dt, p.t_50);
            ok_inr = ~isnan(t_inr) && (t_inr >= t_min_inr);
        else
            t_inr = NaN; ok_inr = true;
        end

        if tem_fmin
            t_f51   = aplicar_dt(tb_fmin, mask_fmin, dt, p.t_50);
            t_fmin  = min([t_f51, p.t_51NS_backup], [], 'omitnan');
            ok_fmin = ~isnan(t_fmin) && (t_fmin <= t_lim);
            if isnan(t_fmin), def_fmin = 10; else, def_fmin = max(0, t_fmin - t_lim); end
        else
            t_fmin = NaN; ok_fmin = true; def_fmin = 0;
        end

        min_m_cel = Inf; ok_cel = true;
        if tem_eval
            t_cli = aplicar_dt(tb_eval, false, dt, p.t_50);
            mk    = ~isnan(t_con) & ~isnan(t_cli) & (t_con > 0) & (t_cli > 0);
            if sum(mk) >= 5
                m_vec     = t_con(mk) - t_cli(mk);
                min_m_cel = min(m_vec);
                ok_cel    = all(m_vec >= dt_sel);
            end
        end

        min_m_elo = Inf; min_f_elo = Inf; def_cruz_elo = 0; ok_elo = true;
        if tem_elo_v
            t_ce  = aplicar_dt(tb_elo, false, dt, p.t_50);
            m_all = ~isnan(t_elo_ev) & ~isinf(t_elo_ev) & ~isnan(t_ce);
            m_crd = m_all & (t_elo_ev >= t_elo_min);
            if any(m_crd)
                t_tot     = t_ce(m_crd) + t_disj;
                min_f_elo = min(f_elo * t_elo_ev(m_crd) - t_tot);
                min_m_elo = min(t_elo_ev(m_crd) - t_tot);
                ok_elo    = (min_f_elo >= 0);
            end
            if any(m_all)
                t_tot_all    = t_ce(m_all) + t_disj;
                def_cruz_elo = max(0, max(t_tot_all - t_elo_ev(m_all)));
                if ~any(m_crd)
                    min_m_elo = min(t_elo_ev(m_all) - t_tot_all);
                    min_f_elo = min(f_elo * t_elo_ev(m_all) - t_tot_all);
                    ok_elo    = (min_f_elo >= 0);
                end
            end
        end

        pen = 1000*(max(0, -min_m_cel) + def_cruz_elo) + ...
              200*(def1 + def2 + def_fmin) + 150*max(0, -min_f_elo) + ...
              100*max(0, dt_sel - min_m_cel) + 10*max(0, dt - cfg.dt_teto_com43);

        todas(idx_g) = struct('curva', tc, 'dt', dt, 't_inrush', t_inr, 'score', score, ...
            'min_margem_celesc', min_m_cel, 'max_t_pt1', max_t1, 'max_t_pt2', max_t2, ...
            't_falta_min', t_fmin, 'min_margem_elo', min_m_elo, 'min_folga_elo', min_f_elo, 'penalidade', pen);

        if ok1 && ok2 && ok_fmin && ok_cel && ok_elo
            if ok_inr, is_sem_bloq(idx_g) = true; else, is_com_bloq(idx_g) = true; end
        end
    end
end

bloqueio = false;
status   = 'OK (Todas as restrições atendidas)';
dt_teto  = cfg.dt_teto_com43;

arr_sb = todas(is_sem_bloq);
arr_cb = todas(is_com_bloq);
if ~isempty(arr_sb), sb_ok = arr_sb([arr_sb.dt] <= dt_teto + 1e-9); else, sb_ok = []; end
if ~isempty(arr_cb), cb_ok = arr_cb([arr_cb.dt] <= dt_teto + 1e-9); else, cb_ok = []; end

if ~isempty(sb_ok)
    [~, ix] = max([sb_ok.score]); esc = sb_ok(ix);
elseif ~isempty(cb_ok)
    [~, ix] = max([cb_ok.score]); esc = cb_ok(ix); bloqueio = true;
elseif ~isempty(arr_sb)
    [~, ix] = min([arr_sb.dt]); esc = arr_sb(ix);
    status = sprintf('ATENÇÃO (DT=%.2f > desejável %.2f exige justificativa)', esc.dt, dt_teto);
elseif ~isempty(arr_cb)
    [~, ix] = min([arr_cb.dt]); esc = arr_cb(ix); bloqueio = true;
    status = sprintf('ATENÇÃO (DT=%.2f > desejável %.2f exige justificativa)', esc.dt, dt_teto);
else
    [~, ix] = min([todas.penalidade]); esc = todas(ix);
    bloqueio = tem_inr && (isnan(esc.t_inrush) || esc.t_inrush < t_min_inr);
    status   = 'PARCIAL (Restrição não atendida - ver Diagnóstico abaixo)';
end

res = struct('curva', esc.curva, 'dt', esc.dt, 't_inrush', esc.t_inrush, ...
    'bloqueio_inrush', bloqueio, 'status', status, 'esc', esc, ...
    'unprot_pt1', unprot_1, 'unprot_pt2', unprot_2);
end

function t = aplicar_dt(tb, mask_inst, dt, t_50)
t   = dt * tb;
idx = ~isnan(t);
t(idx) = max(t(idx), t_50);
if any(mask_inst), t(mask_inst) = t_50; end
end

function [ok, max_t, def] = avaliar_pts_dt(tb, mask_i, unprot, dt, t_50, t_lim)
if unprot
    ok = false; max_t = Inf; def = 50; return;
end
t_calc = aplicar_dt(tb, mask_i, dt, t_50);
if any(isnan(t_calc))
    ok = false; max_t = Inf; def = 50;
else
    max_t = max(t_calc);
    ok    = (max_t <= t_lim);
    def   = max(0, max_t - t_lim);
end
end

function ns = coordenar_51ns(ns, Ip_51N, Ip_50N, t_50N, curva, dt, I1F, con, tc, cfg, t_disj, t_piso_con, M_max)
I_min_51N = tc.min_51N_sec * tc.RTC;
I_lo      = max(ns.Ip_51NS, Ip_51N * 1.0001);
I_hi      = max([Ip_50N, I1F, I_lo * 1.1]);
I_busca   = logspace(log10(I_lo), log10(I_hi), 2000);
t_busca   = calc_t_rele(I_busca, Ip_51N, dt, curva, Ip_50N, t_50N, t_50N, M_max);

for k = 1:5 %#ok<FXUP>
    t_prev = ns.t_51NS;
    idx_tr = find((I_busca >= I_min_51N) & (t_busca <= ns.t_51NS), 1, 'first');
    if isempty(idx_tr), I_lim = Ip_50N; else, I_lim = I_busca(idx_tr); end

    t_teto_con = Inf;
    if I_lim > con.Ip_51N * 1.02
        Iv   = logspace(log10(con.Ip_51N * 1.02), log10(I_lim), 100);
        tc_v = calc_t_rele(Iv, con.Ip_51N, con.DT_51N, con.Curva_51N, con.Ip_50N, con.t_50N, t_piso_con);
        tm   = min(tc_v, [], 'omitnan');
        if ~isempty(tm) && ~isnan(tm), t_teto_con = tm - cfg.delta_t_seletividade_s; end
    end

    t_teto_elo = Inf;
    if con.tem_elo && (I_lim > con.I_elo_ref(1) * 1.02)
        Iv = logspace(log10(max(ns.Ip_51NS * 1.01, con.I_elo_ref(1) * 1.02)), log10(I_lim), 100);
        te = exp(interp1(log(con.I_elo_ref), log(con.t_fus_min_ref), log(Iv), 'pchip', Inf));
        tm = min((cfg.fator_seg_elo * te) - t_disj, [], 'omitnan');
        if ~isempty(tm) && ~isnan(tm), t_teto_elo = tm; end
    end

    t_teto = min(t_teto_con, t_teto_elo);
    if ~isinf(t_teto) && ~isnan(t_teto)
        if t_teto < 0.05
            ns.t_51NS = 0.05; ns.alerta_coord = true;
        elseif ns.t_51NS > t_teto
            ns.t_51NS = floor(t_teto * 100 + 1e-9) / 100;
        end
    end
    if abs(ns.t_51NS - t_prev) < 1e-6, break; end
end

I_ref = max([ns.Ip_51NS, Ip_51N * 1.0001, I_min_51N]);
t_ref = calc_t_rele(I_ref, Ip_51N, dt, curva, Ip_50N, t_50N, t_50N, M_max);
if ~isnan(t_ref) && (t_ref <= ns.t_51NS)
    ns.I_corte = I_ref;
    ns.t_corte = t_ref;
    ns.t_51NS  = t_ref;
else
    idx2 = find((I_busca >= I_ref) & (t_busca <= ns.t_51NS), 1, 'first');
    if isempty(idx2), ns.I_corte = Ip_50N; ns.t_corte = ns.t_51NS;
    else,             ns.I_corte = I_busca(idx2); ns.t_corte = t_busca(idx2);
    end
end
end

function I_lim_con = calc_limite_inst_conces(Ip_50, t_50, Icc, Ip51_c, DT_c, Curva_c, Ip50_c, t50_c, cfg, t_piso_con)
I_lim_con = NaN;
I_ini = max(Ip_50, Ip51_c * 1.01);
if Icc > I_ini
    Iv = logspace(log10(I_ini), log10(Icc), 300);
    if ~isnan(Ip50_c) && Ip50_c >= I_ini && Ip50_c <= Icc
        Iv = unique([Iv, Ip50_c]);
    end
    tc = calc_t_rele(Iv, Ip51_c, DT_c, Curva_c, Ip50_c, t50_c, t_piso_con);
    ix = find(tc < (t_50 + cfg.delta_t_seletividade_s), 1, 'first');
    if ~isempty(ix), I_lim_con = Iv(ix); end
end
end

function cb = verificar_cabo_mt(cli, cc, Ip51, DT51, Curva51, Ip50, Ip51N, DT51N, Curva51N, Ip50N, t_disj, M_max)
t_r3 = calc_t_rele(cc.I3F, Ip51, DT51, Curva51, Ip50, cli.t_50_cli, cli.t_50_cli, M_max);
t_r1 = calc_t_rele(cc.I1F, Ip51N, DT51N, Curva51N, Ip50N, cli.t_50N_cli, cli.t_50N_cli, M_max);
t_e3 = t_r3 + t_disj;
t_e1 = t_r1 + t_disj;
if cc.I3F >= cc.I1F, t_tc = t_e3; else, t_tc = t_e1; end

K     = lib_eletrica.fator_k_adiabatico(cli.Cabo_Entrada_Material, cli.Cabo_Entrada_Isolacao, cli.Cabo_Entrada_Tipo);
n_c   = max(1, round(cli.Cabo_Entrada_Num_Cond));
S_tot = cli.Cabo_Entrada_Secao_mm2 * n_c;
t_m3  = ((K * S_tot) / cc.I3F)^2;
t_m1  = ((K * S_tot) / cc.I1F)^2;

if isnan(t_e3), s3 = Inf; else, s3 = ((cc.I3F / n_c) * sqrt(max(t_e3, 0.01))) / K; end
if isnan(t_e1), s1 = Inf; else, s1 = ((cc.I1F / n_c) * sqrt(max(t_e1, 0.01))) / K; end
S_min = max(s3, s1);

if ~isnan(t_e3) && ~isnan(t_e1) && (t_e3 <= t_m3) && (t_e1 <= t_m1)
    st = 'APROVADO (Protegido termicamente contra Icc3F e Icc1F)';
else
    st = sprintf('ATENÇÃO: Risco térmico no cabo MT (Seção mín. necessária: %.1f mm²)', S_min);
end

cb = struct('K', K, 't_rele_3F', t_r3, 't_rele_1F', t_r1, ...
    't_elim_3F', t_e3, 't_elim_1F', t_e1, 't_max_3F', t_m3, ...
    't_max_1F', t_m1, 'S_min', S_min, 'status', st, 't_atuacao_tc', t_tc);
end