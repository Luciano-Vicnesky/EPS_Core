function plotar_coordenogramas(cel, cli, cfg, cc, est)
% PLOTAR_COORDENOGRAMAS
% Gera os coordenogramas de Fase e Neutro em formato A4 Vertical (fonte única de curvas).

scr   = get(0, 'ScreenSize');
h_fig = round(scr(4) * 0.85);
w_fig = round(h_fig * (21.0 / 29.7));
x_F   = max(20, round((scr(3) - 2*w_fig - 30) / 2));
x_N   = min(scr(3) - w_fig - 20, x_F + w_fig + 30);
y_A4  = max(40, round((scr(4) - h_fig) / 2));

pal = struct( ...
    'lw', 2.0, 'cli', [0.75 0.10 0.10], 'con', [0.10 0.20 0.70], 'dem', [0.00 0.40 0.10], ...
    'elo', [0.80 0.35 0.00], 'i2', [0.00 0.50 0.50], 'i3', [0.50 0.10 0.50], 'inr', [0.20 0.20 0.20], ...
    'trafos', {{[0.85 0.32 0.09], [0.49 0.18 0.55], [0.00 0.44 0.74], [0.46 0.67 0.18], [0.63 0.07 0.18], ...
                [0.00 0.55 0.70], [0.75 0.55 0.00], [0.35 0.35 0.35], [0.80 0.30 0.50], [0.55 0.27 0.07]}});

plotar_fase(cli, cfg, cc, est, [x_F, y_A4, w_fig, h_fig], pal);
plotar_neutro(cel, cfg, cc, est, [x_N, y_A4, w_fig, h_fig], pal);
end

%% --- COORDENOGRAMA DE FASE ---
function plotar_fase(cli, cfg, cc, est, pos, pal)
F = est.fase; con = est.conces; tr = est.trafos; tc = est.tc;

I_max_ref = max([cc.I3F, cc.I2F, F.Ip_50, tr.I_inrush_lim, max(tr.Iansi), con.Ip_50], [], 'omitnan');
x_min = max(0.1, 10^floor(log10(est.dem.I_demanda * cfg.fator_xlim_min)));
x_max = max(I_max_ref, 10^ceil(log10(I_max_ref * cfg.fator_xlim_max)));

[fig, ax] = criar_figura_a4('Coordenograma de Fase - Celesc (A4 Vertical)', pos, F.bloqueio_inrush);

[I_cli, t_cli, t50_c] = montar_curva_rele(F.Ip_51, F.dt, F.curva, F.Ip_50, F.t_50, x_max, F.t_50, est.M_max);
[I_con, t_con, t50_k] = montar_curva_rele(con.Ip_51, con.DT_51, con.Curva_51, con.Ip_50, con.t_50, x_max, 0.01, Inf);

str_50c = '';
if ~isnan(con.Ip_50), str_50c = sprintf(' | Ip50=%.1fA (%.2fs)', con.Ip_50, t50_k); end

loglog(ax, I_cli, t_cli, '-',  'Color', pal.cli, 'LineWidth', pal.lw, ...
    'DisplayName', sprintf('Cliente (51/50): %s DT=%.2f | Ip51=%.1fA | Ip50=%.1fA (%.2fs) | TC %g/%g', F.curva, F.dt, F.Ip_51, F.Ip_50, t50_c, tc.Iprim, tc.Isec));
loglog(ax, I_con, t_con, '--', 'Color', pal.con, 'LineWidth', pal.lw, ...
    'DisplayName', sprintf('Celesc (51/50): %s DT=%.2f | Ip51=%.1fA%s', con.Curva_51, con.DT_51, con.Ip_51, str_50c));
adicionar_legenda_dt(ax, F.esc.min_margem_celesc, cfg.delta_t_seletividade_s, '51');

xline(ax, est.dem.I_demanda, '--', 'Color', pal.dem, 'LineWidth', pal.lw, ...
    'DisplayName', sprintf('Demanda Consumo (%.1fA @ %.1fkV, FP=%.2f)', est.dem.I_demanda, cli.Vnom_prim_kV, cli.FP_demanda));
xline(ax, F.Ip_51, ':', 'Color', pal.cli, 'LineWidth', pal.lw, ...
    'DisplayName', sprintf('Corrente de pickup 51 (%.2fx In Demanda = %.1fA)', cfg.fator_ip51_demanda, F.Ip_51));

loglog(ax, tr.I_inrush, cfg.t_inrush_nominal_s, 'ks', 'MarkerFaceColor', 'k', 'MarkerSize', 7, ...
    'DisplayName', sprintf('Inrush Nominal (%.1fA / %.1fs)', tr.I_inrush, cfg.t_inrush_nominal_s));
xline(ax, tr.I_inrush_lim, '--', 'Color', pal.inr, 'LineWidth', pal.lw, ...
    'DisplayName', sprintf('Limite Mín. Inrush p/ 50 (%.2fx Inrush = %.1fA)', cfg.fator_norma_inrush, tr.I_inrush_lim));

if con.tem_elo
    [I_elo, t_min, t_max] = curva_elo_fusivel(con.Elo_PC, x_max);
    loglog(ax, I_elo, t_min, '-', 'Color', pal.elo, 'LineWidth', pal.lw, 'DisplayName', sprintf('Elo %s (Fusão Mín.)', con.Elo_PC));
    loglog(ax, I_elo, t_max, ':', 'Color', pal.elo, 'LineWidth', pal.lw, 'DisplayName', sprintf('Elo %s (Interrupção Máx.)', con.Elo_PC));
end

plotar_pontos_trafo(ax, tr.Iansi, cfg.t_ansi_ponto_s, tr.kVA, 'o', 'Ponto ANSI', pal.trafos);

xline(ax, cc.I2F, '-.', 'Color', pal.i2, 'LineWidth', pal.lw, 'DisplayName', sprintf('Icc Bifásico (%.1fA)', cc.I2F));
xline(ax, cc.I3F, '-.', 'Color', pal.i3, 'LineWidth', pal.lw, 'DisplayName', sprintf('Icc Trifásico (%.1fA)', cc.I3F));

lgd = finalizar_eixos(ax, x_min, x_max, F.t_50, 'COORDENOGRAMA DE FASE');

if F.bloqueio_inrush
    drawnow;
    pos_lgd = lgd.Position;
    h_box   = 0.036;
    y_box   = max(0.008, pos_lgd(2) - h_box - 0.008);
    w_box   = min(0.90, max(pos_lgd(3), 0.78));
    x_box   = max(0.05, min(pos_lgd(1), 0.95 - w_box));
    annotation(fig, 'textbox', [x_box, y_box, w_box, h_box], ...
        'String', 'ATENÇÃO: ATIVAR BLOQUEIO DE INRUSH (2ª HARMÔNICA)', ...
        'EdgeColor', [0.80 0.00 0.00], 'LineWidth', 1.8, 'BackgroundColor', [1.00 0.94 0.78], ...
        'Color', [0.70 0.00 0.00], 'FontWeight', 'bold', 'FontSize', 8.5, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FitBoxToText', 'off');
end
end

%% --- COORDENOGRAMA DE NEUTRO ---
function plotar_neutro(cel, cfg, cc, est, pos, pal)
N = est.neutro; ns = N.ns; con = est.conces; tr = est.trafos; tc = est.tc;

min_pk    = N.Ip_51N;
if ns.habilitado, min_pk = min(min_pk, ns.Ip_51NS); end
I_max_ref = max([cc.I1F, cc.I1F_40, N.Ip_50N, con.Ip_50N, max(tr.Inansi)], [], 'omitnan');
x_min     = max(0.01, 10^floor(log10(min_pk * cfg.fator_xlim_min)));
x_max     = max(I_max_ref, 10^ceil(log10(I_max_ref * cfg.fator_xlim_max)));

[~, ax] = criar_figura_a4('Coordenograma de Neutro (A4 Vertical)', pos, false);

[I_cli, t_cli, t50N_c] = montar_curva_rele(N.Ip_51N, N.dt, N.curva, N.Ip_50N, N.t_50N, x_max, N.t_50N, est.M_max);
[I_con, t_con, t50N_k] = montar_curva_rele(con.Ip_51N, con.DT_51N, con.Curva_51N, con.Ip_50N, con.t_50N, x_max, 0.01, Inf);

if ns.habilitado
    if ns.I_corte > ns.Ip_51NS
        I_ns = [ns.Ip_51NS, ns.Ip_51NS, ns.I_corte]; t_ns = [1000, ns.t_51NS, ns.t_51NS];
    else
        I_ns = [ns.Ip_51NS, ns.Ip_51NS]; t_ns = [1000, ns.t_corte];
    end
    if ns.I_corte >= N.Ip_50N
        I_cli = [N.Ip_50N, N.Ip_50N, x_max]; t_cli = [ns.t_corte, t50N_c, t50N_c];
    else
        mk = I_cli > ns.I_corte;
        I_cli = [ns.I_corte, I_cli(mk)]; t_cli = [ns.t_corte, t_cli(mk)];
    end
end

str_50Nc = '';
if ~isnan(con.Ip_50N), str_50Nc = sprintf(' | Ip50N=%.1fA (%.2fs)', con.Ip_50N, t50N_k); end

loglog(ax, I_cli, t_cli, '-',  'Color', pal.cli, 'LineWidth', pal.lw, ...
    'DisplayName', sprintf('Cliente (51N/50N): %s DT=%.2f | Ip51N=%.2fA | Ip50N=%.1fA (%.2fs) | TC %g/%g', N.curva, N.dt, N.Ip_51N, N.Ip_50N, t50N_c, tc.Iprim, tc.Isec));
loglog(ax, I_con, t_con, '--', 'Color', pal.con, 'LineWidth', pal.lw, ...
    'DisplayName', sprintf('Celesc (51N/50N): %s DT=%.2f | Ip51N=%.1fA%s', con.Curva_51N, con.DT_51N, con.Ip_51N, str_50Nc));
adicionar_legenda_dt(ax, N.esc.min_margem_celesc, cfg.delta_t_seletividade_s, '51N');

if ~ns.habilitado
    xline(ax, N.Ip_51N, '--', 'Color', pal.cli, 'LineWidth', pal.lw, 'DisplayName', sprintf('Corrente de pickup 51N (%.2fA)', N.Ip_51N));
else
    loglog(ax, I_ns, t_ns, '-', 'Color', pal.dem, 'LineWidth', pal.lw, 'DisplayName', sprintf('Cliente (51NS): Tempo Definido Ip=%.2fA | t=%.2fs', ns.Ip_51NS, ns.t_51NS));
end

plotar_pontos_trafo(ax, tr.Inansi, cfg.t_ansi_ponto_s, tr.kVA, 's', 'Ponto NANSI', pal.trafos);

xline(ax, cc.I1F_40, '-.', 'Color', pal.i2, 'LineWidth', pal.lw, 'DisplayName', sprintf('Icc Monofásico %g \\Omega (%.1fA)', cel.Rf, cc.I1F_40));
xline(ax, cc.I1F,    '-.', 'Color', pal.i3, 'LineWidth', pal.lw, 'DisplayName', sprintf('Icc Monofásico Franco (%.1fA)', cc.I1F));

finalizar_eixos(ax, x_min, x_max, N.t_50N, 'COORDENOGRAMA DE NEUTRO');
end

%% --- HELPERS GRÁFICOS COMPARTILHADOS ---
function adicionar_legenda_dt(ax, margem_min, meta_dt, zona)
if isinf(margem_min)
    txt = sprintf('Diferencial de tempo (\\Delta t): Sem sobreposição na zona %s (Meta >= %.2fs)', zona, meta_dt);
else
    txt = sprintf('Diferencial de tempo (\\Delta t mín. Celesc): %.2fs (Meta >= %.2fs)', margem_min, meta_dt);
end
loglog(ax, NaN, NaN, 'LineStyle', 'none', 'Marker', 'none', 'DisplayName', txt);
end

function [I_plot, t_plot, t_50_eff] = montar_curva_rele(Ip_51, DT, curva, Ip_50, t_50, x_max, t_piso, M_max)
I_ini = Ip_51 * 1.0001;
if ~isnan(Ip_50) && Ip_50 > 0
    t_50_lim = max(t_50, t_piso);
    x_fim    = max(x_max, Ip_50);
    if Ip_50 > Ip_51 * 1.001
        I_51 = logspace(log10(I_ini), log10(Ip_50 * 0.9999), 500);
        t_51 = calc_t_rele(I_51, Ip_51, DT, curva, Inf, NaN, t_piso, M_max);
        if t_51(1) < 1000, I_51 = [I_ini, I_51]; t_51 = [1000, t_51]; end
        t_50_eff = min(t_50_lim, t_51(end));
        I_plot   = [I_51, Ip_50, x_fim];
        t_plot   = [t_51, t_50_eff, t_50_eff];
    else
        t_50_eff = t_50_lim;
        I_plot   = [Ip_50, Ip_50, x_fim];
        t_plot   = [1000, t_50_eff, t_50_eff];
    end
else
    t_50_eff = NaN;
    I_plot   = logspace(log10(I_ini), log10(max(x_max, I_ini * 1.05)), 500);
    t_plot   = calc_t_rele(I_plot, Ip_51, DT, curva, Inf, NaN, t_piso, M_max);
    if t_plot(1) < 1000, I_plot = [I_ini, I_plot]; t_plot = [1000, t_plot]; end
end
end

function [fig, ax] = criar_figura_a4(nome, pos, tem_banner)
fig = figure('Name', nome, 'Color', 'w', 'Units', 'pixels', 'Position', pos, ...
    'PaperType', 'a4', 'PaperOrientation', 'portrait', 'PaperUnits', 'centimeters', ...
    'PaperSize', [21.0, 29.7], 'PaperPositionMode', 'manual', 'PaperPosition', [1.2, 1.2, 18.6, 27.3]);
if tem_banner, op = [0.02, 0.068, 0.95, 0.917]; else, op = [0.02, 0.020, 0.95, 0.965]; end
ax = axes('Parent', fig, 'OuterPosition', op);
set(ax, 'XScale', 'log', 'YScale', 'log');
hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
end

function plotar_pontos_trafo(ax, I_pts, t_pt, kVAs, marcador, prefixo, cores)
[unicos, ~, idx_map] = unique(I_pts, 'stable');
for i = 1:numel(unicos)
    idxs = find(idx_map == i);
    tag  = strjoin(arrayfun(@(k) sprintf('T%d', k), idxs, 'UniformOutput', false), ', ');
    cor  = cores{mod(i-1, numel(cores)) + 1};
    loglog(ax, unicos(i), t_pt, marcador, 'MarkerSize', 7, 'MarkerEdgeColor', cor, 'MarkerFaceColor', cor, ...
        'DisplayName', sprintf('%s %s (%g kVA: %.1fA)', prefixo, tag, kVAs(idxs(1)), unicos(i)));
end
end

function lgd = finalizar_eixos(ax, x_min, x_max, t_inst, titulo)
y_min = min(5e-3, t_inst * 0.5);
xlim(ax, [x_min, x_max]);
ylim(ax, [y_min, 1e2]);
xt = 10.^(floor(log10(x_min)):ceil(log10(x_max)));
yt = 10.^(min(-2, floor(log10(y_min))):2);
set(ax, 'XTick', xt, 'XTickLabel', arrayfun(@(v) sprintf('%g', v), xt, 'UniformOutput', false));
set(ax, 'YTick', yt, 'YTickLabel', arrayfun(@(v) sprintf('%g', v), yt, 'UniformOutput', false));
set(ax, 'XMinorGrid', 'on', 'YMinorGrid', 'on', 'GridAlpha', 0.5);
xlabel(ax, 'Corrente Primária (A)', 'FontWeight', 'bold', 'FontSize', 9.5);
ylabel(ax, 'Tempo de Atuação (s)',  'FontWeight', 'bold', 'FontSize', 9.5);
title(ax, titulo, 'FontWeight', 'bold', 'FontSize', 10.5);
lgd = legend(ax, 'Location', 'southoutside', 'NumColumns', 1, 'FontSize', 8);
lgd.Box = 'on';
end