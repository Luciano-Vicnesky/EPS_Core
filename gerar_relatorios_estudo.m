function gerar_relatorios_estudo(cel, cli, cfg, cc, est)
% GERAR_RELATORIOS_ESTUDO
% Emite os 4 relatórios técnicos completos e auditáveis no Command Window.

relatorio_1_entradas(cel, cli, cfg, cc, est.conces, est.tc);
relatorio_2_protecoes(cel, cli, cfg, cc, est);
relatorio_3_tc(est.tc, est.cabo_mt.t_atuacao_tc, est.neutro.ns);
relatorio_4_tps(est.tps);
end

%% --- RELATÓRIO 1: DADOS DE ENTRADA ---
function relatorio_1_entradas(cel, cli, cfg, cc, con, tc)
fprintf('========================================================================\n');
fprintf('                  RELATÓRIO 1 - DADOS DE ENTRADA DO ESTUDO\n');
fprintf('========================================================================\n\n');

str50  = fmt_inst('50',  con.Ip_50,  con.t_50);
str50N = fmt_inst('50N', con.Ip_50N, con.t_50N);

fprintf('1. DADOS DA CONCESSIONÁRIA (CELESC - PC: PONTO DE CONEXÃO)\n');
fprintf('   Base Elétrica       : Vbase = %.2f kV | Sbase = %.2f MVA | Rf = %.1f Ohms\n', cel.Vbase_kV, cel.Sbase_MVA, cel.Rf);
fprintf('   Impedâncias no PC   : Z1 = %.5f + j%.5f p.u. | Z0 = %.5f + j%.5f p.u.\n', cel.R1, cel.X1, cel.R0, cel.X0);
fprintf('   Proteção Fase PC    : Curva %s | Ip51 = %.1f A | DT = %.2f | %s\n', con.Curva_51, con.Ip_51, con.DT_51, str50);
fprintf('   Proteção Neutro PC  : Curva %s | Ip51N = %.1f A | DT = %.2f | %s\n', con.Curva_51N, con.Ip_51N, con.DT_51N, str50N);
fprintf('   Chave Fusível PC    : %s (Elo: %s)\n\n', cel.Usa_Elo_PC, cel.Elo_PC);

str_tc_man = '';
if strcmpi(strtrim(cli.TC_Modo), 'MANUAL')
    str_tc_man = sprintf(' | Informado: %g/%g A (Vs = %g V)', cli.RTC_Primario, cli.Isec_TC, cli.TC_Tensao_Sat_V);
end
fprintf('2. DADOS DO CONSUMIDOR E INFRAESTRUTURA\n');
fprintf('   Consumidor          : %s | CNPJ: %s | %s (%s)\n', cli.Razao_Social, cli.CNPJ, cli.Cidade_UF, cli.Finalidade);
fprintf('   Operação / Demanda  : Vnom = %.2f kV | Demanda Consumo = %.1f kW (FP = %.2f)\n', ...
    cli.Vnom_prim_kV, cli.Demanda_Consumo_kW, cli.FP_demanda);
fprintf('   Transformadores     : Potências [kVA] = [%s] | Z [%%] = [%s] | Tipos = [%s]\n', cli.Trafos_kVA, cli.Z_Trafos_pct, cli.Tipos_Trafos);
fprintf('   Ramal Entrada MT    : %s | %dx %g mm² %s %s | L = %.1f m | Usar Imp. no Curto: %s\n', ...
    cli.Cabo_Entrada_Tipo, cli.Cabo_Entrada_Num_Cond, cli.Cabo_Entrada_Secao_mm2, ...
    cli.Cabo_Entrada_Material, cli.Cabo_Entrada_Isolacao, cli.Cabo_Entrada_Comp_m, cli.Considerar_Imp_Ramal);
fprintf('   Cabo Circuito TC    : %g mm² %s %s | Comprimento ida = %.1f m\n', ...
    cli.Cabo_TC_Secao_mm2, cli.Cabo_TC_Material, cli.Cabo_TC_Isolacao, cli.Cabo_TC_Comp_m);
fprintf('   TC de Proteção      : Modo = %s | Isec = %g A | Classe Alvo = %g%s | FS = %g | FT = %g | R_contato = %.2f Ohm%s\n', ...
    cli.TC_Modo, cli.Isec_TC, cli.TC_Exatidao_pct, cli.TC_Classe_Servico, cfg.FS_tc_protecao, tc.FT, cfg.R_contato_tc_ohm, str_tc_man);
fprintf('   TP de Proteção      : %s | Classe = %s | Cabo = %g mm² %s %s (L = %.1f m)\n', ...
    cli.TP_Arranjo, cli.TP_Classe, cli.Cabo_TP_Secao_mm2, cli.Cabo_TP_Material, cli.Cabo_TP_Isolacao, cli.Cabo_TP_Comp_m);
fprintf('   TP Auxiliar (TPA)   : Independente | Fase-Fase / 110 V | Carga Prevista = %.1f VA (+%g%% margem)\n', ...
    cli.TPA_Carga_Prevista_VA, cfg.margem_seg_tpa_pct);
fprintf('   Relé de Proteção    : %s | Consumo entrada I = %.2f VA | Consumo entrada V = %.2f VA/fase | t_50 = %.3f s | t_50N = %.3f s\n', ...
    cli.Modelo_Rele, cli.Consumo_Rele_VA, cli.TP_Consumo_Rele_VA, cli.t_50_cli, cli.t_50N_cli);
fprintf('   Sensib. Mín. Relé   : 51N mín. = %.2f%% Isec (%.4f A sec) | 51NS toroidal mín. = %.3f A sec\n', ...
    cfg.sensib_rele_51N_pct, (cfg.sensib_rele_51N_pct/100)*cli.Isec_TC, cfg.sensib_rele_51NS_A);
fprintf('   Base de Curto Ativa : %s | Instalação TC/TPs: Interna\n\n', cc.tag_base_cc);

fprintf('3. PARÂMETROS NORMATIVOS E CRITÉRIOS DE CÁLCULO\n');
fprintf('   Inrush              : k_oleo = %g | k_seco = %g | t_inrush = %.2fs | Margem 51 = %.2fs\n', ...
    cfg.k_inrush_oleo, cfg.k_inrush_seco, cfg.t_inrush_nominal_s, cfg.margem_coord_inrush_s);
fprintf('                         Limite mínimo Inrush para definição da função 50 = %.2fx Inrush\n', cfg.fator_norma_inrush);
fprintf('   Pickups Fase        : Ip51 = %.2fx Idem | Ip50 = %.2fx Inrush (adotado >= %.2fx)\n', ...
    cfg.fator_ip51_demanda, cfg.fator_ip50_inrush, cfg.fator_norma_inrush);
fprintf('   Pickups Neutro      : Ip51N <= %.2fx Ip51 | Ip50N = %.4fx Ip50 (piso %.2fx Inrush, teto %.2fx I1F)\n', ...
    cfg.fator_ip51N_fase, cfg.fator_ip50N_fase, cfg.fator_piso_50N_inrush, cfg.fator_teto_50N_icc1f);
fprintf('   Ajuste Padrão 51NS  : Pickup padrão = %.1f A | Tempo definido padrão = %.2f s\n', ...
    cfg.Ip_51NS_padrao_A, cfg.t_51NS_padrao_s);
M_max_show = cfg.M_max_curva_iec;
if isnan(M_max_show) || M_max_show <= 0
    str_sat = 'Sem saturação (Inf)';
else
    str_sat = sprintf('%g x Ipickup', M_max_show);
end
fprintf('   Seletividade / IEC  : Delta_t >= %.2fs | Curva vs Elo atua em t <= %.0f%% | Curva no ponto ANSI/NANSI atua em t <= %.2fs\n', ...
    cfg.delta_t_seletividade_s, cfg.fator_seg_elo*100, cfg.t_ansi_limite_rele_s);
fprintf('                         DT = %.2f..%.2f (Desejável <= %.2f) | Saturação da Curva no relé = %s\n', ...
    cfg.dt_min_rele, cfg.dt_max_rele, cfg.dt_teto_com43, str_sat);
fprintf('   Critérios TPs       : Limite queda de tensão TP < %g%% | Margem TPA = +%g%% | Instalação = Interna (60 Hz)\n', ...
    cfg.queda_tensao_max_tp_pct, cfg.margem_seg_tpa_pct);
fprintf('========================================================================\n\n');
end

%% --- RELATÓRIO 2: MEMÓRIA DE CÁLCULO (CURTOS + PROTEÇÕES) E DIAGNÓSTICO ---
function relatorio_2_protecoes(cel, cli, cfg, cc, est)
rm = cc.ramal; tr = est.trafos; F = est.fase; N = est.neutro; ns = N.ns; cb = est.cabo_mt; con = est.conces;
Z1    = cc.R1_pu + 1i*cc.X1_pu;
Z0    = cc.R0_pu + 1i*cc.X0_pu;
Rf_pu = cc.Rf_ohm / cc.Zbase;
Z1F   = 2*Z1 + Z0;
Z1F40 = Z1F + 3*Rf_pu;

fprintf('========================================================================\n');
fprintf('     RELATÓRIO 2 - MEMÓRIA DE CÁLCULO (CURTO-CIRCUITO E PROTEÇÕES)\n');
fprintf('========================================================================\n\n');

fprintf('1. PARÂMETROS DE BASE DO SISTEMA (REDE CELESC)\n');
fprintf('   Fórmula Ibase : Ibase = Sbase / (sqrt(3) * Vbase)\n');
fprintf('   Cálculo Ibase : Ibase = %g MVA / (sqrt(3) * %.2f kV) = %.2f A\n', cel.Sbase_MVA, cel.Vbase_kV, cc.Ibase);
fprintf('   Fórmula Zbase : Zbase = Vbase^2 / Sbase\n');
fprintf('   Cálculo Zbase : Zbase = %.2f^2 / %g = %.4f Ohms\n\n', cel.Vbase_kV, cel.Sbase_MVA, cc.Zbase);

fprintf('2. CORRENTES DE CURTO-CIRCUITO (%s)\n', cc.tag_base_cc);
fprintf('   Ramal MT      : %s | %dx %g mm² %s %s | L = %.1f m (T_op = %d°C)\n', ...
    rm.tipo, rm.n_cond, rm.secao_mm2, rm.material, rm.isolacao, rm.comp_m, rm.T_op);
fprintf('   Z_ramal       : Z1_ramal = %.4f + j%.4f Ohms (%.5f + j%.5f p.u.)\n', ...
    rm.R1_ohm, rm.X1_ohm, rm.R1_pu, rm.X1_pu);
fprintf('                   Z0_ramal = %.4f + j%.4f Ohms (%.5f + j%.5f p.u.)\n', ...
    rm.R0_ohm, rm.X0_ohm, rm.R0_pu, rm.X0_pu);
if cc.usar_ramal
    fprintf('   Fórmula Z_eff : Z1_eff = Z1_PC + Z1_ramal  |  Z0_eff = Z0_PC + Z0_ramal\n');
    fprintf('   Cálculo Z1_eff: (%.5f + j%.5f) + (%.5f + j%.5f) = %.5f + j%.5f p.u. (|Z1_eff| = %.5f p.u.)\n', ...
        cel.R1, cel.X1, rm.R1_pu, rm.X1_pu, real(Z1), imag(Z1), abs(Z1));
    fprintf('   Cálculo Z0_eff: (%.5f + j%.5f) + (%.5f + j%.5f) = %.5f + j%.5f p.u. (|Z0_eff| = %.5f p.u.)\n\n', ...
        cel.R0, cel.X0, rm.R0_pu, rm.X0_pu, real(Z0), imag(Z0), abs(Z0));
else
    fprintf('   Fórmula Z_eff : Z1_eff = Z1_PC  |  Z0_eff = Z0_PC (impedância do ramal MT não somada)\n');
    fprintf('   Resultado     : Z1_eff = %.5f + j%.5f p.u. (|Z1_eff| = %.5f p.u.)\n', real(Z1), imag(Z1), abs(Z1));
    fprintf('                   Z0_eff = %.5f + j%.5f p.u. (|Z0_eff| = %.5f p.u.)\n\n', real(Z0), imag(Z0), abs(Z0));
end

fprintf('   A) Curto-Circuito Trifásico Simétrico (Icc3F):\n');
fprintf('      Fórmula: Icc3F = (1 / |Z1_eff|) * Ibase\n');
fprintf('      Cálculo: Icc3F = (1 / %.5f) * %.2f = %.1f A\n\n', abs(Z1), cc.Ibase, cc.I3F);

fprintf('   B) Curto-Circuito Trifásico Assimétrico (Icc3F_assim - 1º meio ciclo):\n');
fprintf('      Fórmulas: (X/R)_3F = X1_eff / R1_eff  |  Ka_3F = sqrt(1 + 2 * exp(-2*pi / (X/R)_3F))\n');
fprintf('                Icc3F_assim = Ka_3F * Icc3F\n');
fprintf('      Cálculo : (X/R)_3F = %.5f / %.5f = %.3f  |  Ka_3F = %.4f\n', imag(Z1), real(Z1), cc.XR_3F, cc.Ka_3F);
fprintf('                Icc3F_assim = %.4f * %.1f = %.1f A (eficaz)\n\n', cc.Ka_3F, cc.I3F, cc.I3F_assim);

fprintf('   C) Curto-Circuito Bifásico Franco Simétrico (Icc2F):\n');
fprintf('      Fórmula: Icc2F = Icc3F * (sqrt(3) / 2)\n');
fprintf('      Cálculo: Icc2F = %.1f * 0.8660 = %.1f A\n\n', cc.I3F, cc.I2F);

fprintf('   D) Curto-Circuito Monofásico Franco Simétrico (Icc1F):\n');
fprintf('      Fórmula: Z_eq,1F = 2*Z1_eff + Z0_eff  |  Icc1F = (3 / |Z_eq,1F|) * Ibase\n');
fprintf('      Cálculo: Z_eq,1F = %.5f + j%.5f p.u. -> |Z_eq,1F| = %.5f p.u.\n', real(Z1F), imag(Z1F), abs(Z1F));
fprintf('               Icc1F = (3 / %.5f) * %.2f = %.1f A\n\n', abs(Z1F), cc.Ibase, cc.I1F);

fprintf('   E) Curto-Circuito Monofásico Assimétrico (Icc1F_assim - 1º meio ciclo):\n');
fprintf('      Fórmulas: (X/R)_1F = (2*X1_eff + X0_eff) / (2*R1_eff + R0_eff)\n');
fprintf('                Ka_1F = sqrt(1 + 2 * exp(-2*pi / (X/R)_1F))  |  Icc1F_assim = Ka_1F * Icc1F\n');
fprintf('      Cálculo : (X/R)_1F = %.5f / %.5f = %.3f  |  Ka_1F = %.4f\n', imag(Z1F), real(Z1F), cc.XR_1F, cc.Ka_1F);
fprintf('                Icc1F_assim = %.4f * %.1f = %.1f A (eficaz)\n\n', cc.Ka_1F, cc.I1F, cc.I1F_assim);

fprintf('   F) Curto-Circuito Monofásico Mínimo / Resistivo (Rf = %.1f Ohms):\n', cc.Rf_ohm);
fprintf('      Fórmula: Rf_pu = Rf / Zbase  |  Z_eq,1F_min = 2*Z1_eff + Z0_eff + 3*Rf_pu\n');
fprintf('               Icc1F_min = (3 / |Z_eq,1F_min|) * Ibase\n');
fprintf('      Cálculo: Rf_pu = %.1f / %.4f = %.4f p.u.\n', cc.Rf_ohm, cc.Zbase, Rf_pu);
fprintf('               Z_eq,1F_min = %.5f + j%.5f p.u. -> |Z_eq,1F_min| = %.5f p.u.\n', real(Z1F40), imag(Z1F40), abs(Z1F40));
fprintf('               Icc1F_min = (3 / %.5f) * %.2f = %.1f A\n\n', abs(Z1F40), cc.Ibase, cc.I1F_40);

fprintf('   ----------------------------------------------------------------------------\n');
fprintf('   TABELA COMPARATIVA DE CURTO-CIRCUITO (SEM vs. COM IMPEDÂNCIA DO RAMAL MT)\n');
fprintf('   ----------------------------------------------------------------------------\n');
fprintf('   Grandeza                       |  Sem Ramal (PC) | Com Ramal (Int) | Variacao\n');
fprintf('   ----------------------------------------------------------------------------\n');
linha_cc('Icc Trifásico Sim.  (Icc3F)',     cc.pc.I3F,       cc.int.I3F,       'A');
linha_cc('Icc Trif. Assim.    (I3F_as)',  cc.pc.I3F_assim, cc.int.I3F_assim, 'A');
linha_cc('Icc Bifásico Sim.   (Icc2F)',   cc.pc.I2F,       cc.int.I2F,       'A');
linha_cc('Icc Monof. Sim.     (Icc1F)',   cc.pc.I1F,       cc.int.I1F,       'A');
linha_cc('Icc Monof. Assim    (I1F_as)',  cc.pc.I1F_assim, cc.int.I1F_assim, 'A');
linha_cc('Icc Monof. Mínimo   (I1F_min)',   cc.pc.I1F_40,    cc.int.I1F_40,    'A');
linha_cc('Relação X/R Trifásica',         cc.pc.XR_3F,     cc.int.XR_3F,     '');
linha_cc('Relação X/R Monofásica',        cc.pc.XR_1F,     cc.int.XR_1F,     '');
fprintf('   ----------------------------------------------------------------------------\n');
fprintf('   >> BASE ATIVA NO DIMENSIONAMENTO (CORRENTES SIMÉTRICAS EFICAZES): %s\n\n', cc.tag_base_cc);

fprintf('3. DEMANDA DE CONSUMO (BASE PARA 50/51/50N/51N @ Vnom = %.2f kV)\n', cli.Vnom_prim_kV);
fprintf('   Fórmula: Idem = Demanda_Consumo_kW / (sqrt(3) * Vnom_prim * FP)\n');
fprintf('   Cálculo: Idem = %.1f kW / (sqrt(3) * %.2f kV * %.2f) = %.1f A\n\n', est.dem.P_consumo, cli.Vnom_prim_kV, cli.FP_demanda, est.dem.I_demanda);

fprintf('4. TRANSFORMADORES, PONTOS ANSI/NANSI E INRUSH (@ Vnom = %.2f kV)\n', cli.Vnom_prim_kV);
fprintf('   Fórmulas: Inom = S_kVA / (sqrt(3) * Vnom_kV)\n');
fprintf('             I_ANSI  = Inom / (Z%% / 100)        [Curto 3F na BT refletido no primário]\n');
fprintf('             I_NANSI = I_ANSI / sqrt(3)         [58%% do ANSI - Curto 1F na BT em trafo Delta-Yn]\n');
for i = 1:numel(tr.kVA)
    fprintf('   Trafo %d (%g kVA, Z = %.1f%%): Inom = %.1f A | ANSI = %.1f A | NANSI (58%%) = %.1f A\n', ...
        i, tr.kVA(i), tr.Z_pct(i), tr.Inom(i), tr.Iansi(i), tr.Inansi(i));
end
fprintf('   Fórmula Inrush : I_inrush = (K * Inom_maior) + Inom_demais\n');
fprintf('   Cálculo Inrush : I_inrush = (%g * %.1f A) + %.1f A = %.1f A\n', tr.mult_inrush, tr.I_maior, tr.I_demais, tr.I_inrush);
fprintf('   Limite mínimo Inrush para definição da função 50 = %.2f * %.1f A = %.1f A\n\n', ...
    cfg.fator_norma_inrush, tr.I_inrush, tr.I_inrush_lim);

fprintf('5. PICKUPS CALCULADOS E OTIMIZAÇÃO DAS CURVAS\n');
fprintf('   --- FASE (51 / 50) ---\n');
fprintf('   Fórmula Ip_51 : Ip_51 = %.2f * Idem (truncado em 0,1 A)\n', cfg.fator_ip51_demanda);
fprintf('   Cálculo Ip_51 : %.2f * %.2f = %.2f A -> Adotado: %.1f A | Curva = %s | DT = %.2f\n', ...
    cfg.fator_ip51_demanda, est.dem.I_demanda, cfg.fator_ip51_demanda * est.dem.I_demanda, F.Ip_51, F.curva, F.dt);
fprintf('   Fórmula Ip_50 : Ip_50 = %.2f * I_inrush (>= limite mínimo %.2fx = %.1f A, arredondado em 0,1 A)\n', ...
    cfg.fator_ip50_inrush, cfg.fator_norma_inrush, tr.I_inrush_lim);
fprintf('   Cálculo Ip_50 : %.2f * %.2f = %.2f A -> Adotado: %.1f A (Tempo: %.3fs)\n', ...
    cfg.fator_ip50_inrush, tr.I_inrush, cfg.fator_ip50_inrush * tr.I_inrush, F.Ip_50, F.t_50);
fprintf('   Status Coordenação Fase : %s\n', F.status);
fprintf('   Diagnóstico da Proteção de Fase:\n');
if isinf(F.esc.min_margem_celesc)
    fprintf('   - Margem Celesc (51)      : Sem sobreposição na zona temporizada (50 atua antes do pickup 51 Celesc)\n');
else
    fprintf('   - Margem Celesc (51)      : Menor separação de tempo = %.3fs (Critério: >= %.2fs)\n', F.esc.min_margem_celesc, cfg.delta_t_seletividade_s);
end
fprintf('   - Proteção Trafo (ANSI)   : Tempo máx. de atuação no ponto ANSI 3F = %.3fs (Critério: <= %.2fs)\n', F.esc.max_t_pt1, cfg.t_ansi_limite_rele_s);
fprintf('   - Proteção Trafo (58%%)    : Tempo máx. no ponto ANSI deslocado 1F = %.3fs (Critério: <= %.2fs)\n', F.esc.max_t_pt2, cfg.t_ansi_limite_rele_s);
imprimir_diag_elo('Fase', con, F.esc, cfg, est.t_disj);
if F.unprot_pt1 || F.unprot_pt2, fprintf('   ALERTA CRÍTICO (TRAFO)    : Existe trafo com ponto ANSI ou 58%% <= Ip_51 (%.1fA)!\n', F.Ip_51); end
if F.alerta_50_conces,           fprintf('   ALERTA 50 x CELESC        : Ip_50 cliente (%.1fA) >= Ip_50 Celesc (%.1fA)!\n', F.Ip_50, con.Ip_50); end
if ~isnan(F.I_lim_con)
    fprintf('   AVISO CELESC (FASE)       : Curva Celesc cai abaixo de %.2fs acima de %.1fA (I3F=%.1fA)\n', F.t_50 + cfg.delta_t_seletividade_s, F.I_lim_con, cc.I3F);
end
fprintf('   - Inrush (%.1fA)         : Tempo da curva 51 = %.3fs (Mín. sem bloqueio: %.3fs) -> %s\n\n', ...
    tr.I_inrush, F.t_inrush, cfg.t_inrush_nominal_s + cfg.margem_coord_inrush_s, ...
    tern(F.bloqueio_inrush, 'BLOQUEIO DE 2ª HARMÔNICA ATIVADO', 'Livre (sem necessidade de bloqueio)'));

fprintf('   --- NEUTRO (51N / 50N) ---\n');
fprintf('   Fórmula Ip_51N: Ip_51N <= %.2f * Ip_51 (truncado em 0,01 A) e <= %.2f * Ip_51N_Celesc\n', cfg.fator_ip51N_fase, cfg.fator_teto_conces);
fprintf('   Cálculo Ip_51N: %.2f * %.1f = %.3f A -> Adotado: %.2f A (%.2f%% de Ip51) | Curva = %s | DT = %.2f\n', ...
    cfg.fator_ip51N_fase, F.Ip_51, cfg.fator_ip51N_fase*F.Ip_51, N.Ip_51N, (N.Ip_51N/F.Ip_51)*100, N.curva, N.dt);
if ns.habilitado
    fprintf('   Ajuste 51NS (Toroidal)    : Pickup = %.2f A | Tempo Definido = %.2fs (Transição p/ 51N em %.1fA)\n', ns.Ip_51NS, ns.t_51NS, ns.I_corte);
    if ns.alerta_sensib, fprintf('   AVISO SENSIB. 51NS        : Pickup limitado ao piso toroidal (%.2f A).\n', ns.Ip_51NS); end
    if ns.alerta_acima_com43
        fprintf('   ALERTA CRÍTICO 51NS       : Pickup (%.2fA) > Limite de neutro (%.2fA)! Revisar sensib. 51GS (%.3fA) ou toroidal <= %d/1 A.\n', ...
            ns.Ip_51NS, N.Ip_51N_teto_norma, ns.min_51NS_sec, max(1, ns.RTC_tor_max_com43));
    end
    if ns.alerta_coord, fprintf('   ALERTA COORD. 51NS        : Margem < %.2fs mesmo em 0,05s!\n', cfg.delta_t_seletividade_s); end
end
d50n = N.det_50N;
fprintf('   Definição da Função 50N:\n');
fprintf('   - Fórmula Base : max(%.4f * Ip_50, 2 * Ip_51N, %.2f * I_inrush), limitado a %.2f * Icc1F e coordenação Celesc\n', ...
    cfg.fator_ip50N_fase, cfg.fator_piso_50N_inrush, cfg.fator_teto_50N_icc1f);
fprintf('   - Parcelas     : Base (%.4f*Ip50) = %.1f A | Piso (2*Ip51N = %.1f A; %.2f*Inrush = %.1f A) = %.1f A | Teto 1F = %.1f A\n', ...
    cfg.fator_ip50N_fase, d50n.base_50, d50n.piso_51N, cfg.fator_piso_50N_inrush, d50n.piso_inrush, d50n.piso_seg, d50n.teto_I1F);
if ~isnan(d50n.teto_con_50N) || ~isnan(d50n.teto_con_curva)
    fprintf('   - Tetos Celesc : Teto 50N Celesc = %s | Teto Curva 51N Celesc = %s\n', fmt_opt(d50n.teto_con_50N, '%.1f A'), fmt_opt(d50n.teto_con_curva, '%.1f A'));
end
fprintf('   - Adotado 50N  : Ip_50N = %.1f A (Tempo: %.3fs)\n', N.Ip_50N, N.t_50N);
fprintf('   Status Coordenação Neutro : %s\n', N.status);
fprintf('   Diagnóstico da Proteção de Neutro:\n');
if isinf(N.esc.min_margem_celesc)
    fprintf('   - Margem Celesc (51N)     : Sem sobreposição na zona temporizada (50N atua antes do pickup 51N Celesc)\n');
else
    fprintf('   - Margem Celesc (51N)     : Menor separação de tempo = %.3fs (Critério: >= %.2fs)\n', N.esc.min_margem_celesc, cfg.delta_t_seletividade_s);
end
fprintf('   - Proteção Trafo (NANSI)  : Tempo máx. de atuação no ponto NANSI = %.3fs (Critério: <= %.2fs)\n', N.esc.max_t_pt1, cfg.t_ansi_limite_rele_s);
fprintf('   - Falta Mínima (I1F_min)  : Tempo de atuação em %.1fA (Rf=%.1f Ohms) = %.3fs (Critério: <= %.2fs)\n', cc.I1F_40, cc.Rf_ohm, N.esc.t_falta_min, cfg.t_ansi_limite_rele_s);
imprimir_diag_elo('Neutro', con, N.esc, cfg, est.t_disj);
if N.unprot_pt1,                  fprintf('   ALERTA CRÍTICO (NANSI)    : Existe trafo com ponto NANSI <= Ip_51N (%.2fA)!\n', N.Ip_51N); end
if N.alerta_50N_conces,           fprintf('   ALERTA 50N x CELESC       : Ip_50N cliente (%.1fA) >= Ip_50N Celesc (%.1fA)!\n', N.Ip_50N, con.Ip_50N); end
if N.Ip_50N < N.piso_50N_inrush,  fprintf('   AVISO INRUSH (50N)        : Ip_50N (%.1fA) < piso inrush residual (%.1fA). Recomenda-se bloqueio 2ª harm.\n', N.Ip_50N, N.piso_50N_inrush); end
if N.Ip_50N >= cc.I1F,            fprintf('   AVISO (50N)               : Ip_50N (%.1fA) >= Icc1F (%.1fA). Unidade 50N inoperante.\n', N.Ip_50N, cc.I1F); end
if ~isnan(N.I_lim_con)
    fprintf('   AVISO CELESC (NEUTRO)     : Curva Celesc cai abaixo de %.2fs acima de %.1fA (I1F=%.1fA)\n', N.t_50N + cfg.delta_t_seletividade_s, N.I_lim_con, cc.I1F);
end

fprintf('\n6. VERIFICAÇÃO TÉRMICA ADIABÁTICA DO CABO DE ENTRADA MT\n');
fprintf('   Cabo Instalado  : %s | %dx %.1f mm² %s %s | L = %.1f m | Fator térmico K = %d\n', ...
    rm.tipo, rm.n_cond, rm.secao_mm2, rm.material, rm.isolacao, rm.comp_m, cb.K);
fprintf('   Fórmulas I²t    : t_elim = t_rele + t_disjuntor (%.3fs)  |  t_suportável = ((K * S_total) / Icc)^2\n', est.t_disj);
fprintf('                     S_min_cond = ((Icc / n_cond) * sqrt(t_elim)) / K\n');
fprintf('   Curto 3F (%.1fA): t_elim = %.3fs (relé) + %.3fs (disj.) = %.3fs  <=  t_suportável do cabo = %.3fs\n', ...
    cc.I3F, cb.t_rele_3F, est.t_disj, cb.t_elim_3F, cb.t_max_3F);
fprintf('   Curto 1F (%.1fA): t_elim = %.3fs (relé) + %.3fs (disj.) = %.3fs  <=  t_suportável do cabo = %.3fs\n', ...
    cc.I1F, cb.t_rele_1F, est.t_disj, cb.t_elim_1F, cb.t_max_1F);
fprintf('   Seção Mínima    : S_min = %.1f mm²/condutor (menor seção térmica admissível para t_elim; instalada: %.1f mm²)\n', ...
    cb.S_min, rm.secao_mm2);
fprintf('   Status Cabo MT  : %s\n', cb.status);
fprintf('========================================================================\n');
end

%% --- RELATÓRIO 3: DIMENSIONAMENTO DO TC DE PROTEÇÃO ---
function relatorio_3_tc(tc, t_elim_icc, ns)
t_th_eff   = max(0.10, min(t_elim_icc, 3.0));
Ith_req_1s = tc.Icc_max_sim * sqrt(t_th_eff);
Ith_ref_1s = 100 * tc.Iprim;
ok_s       = @(c) tern(c, 'APROVADO', 'REPROVADO');
cmp_s      = @(c) tern(c, '<=', '>');

fprintf('\n========================================================================\n');
fprintf('     RELATÓRIO 3 - DIMENSIONAMENTO DO TC DE PROTEÇÃO (ABNT NBR 6856)\n');
fprintf('========================================================================\n');
fprintf('   Modo: %s | Instalação: %s | Freq.: %d Hz\n', tc.modo, tc.instalacao, tc.freq_Hz);
fprintf('   Fatores: FS (Sobrecorrente) = %g | FT (Fator Térmico) = %g | Isolamento: %.1f / %.0f / %.0f kV\n\n', ...
    tc.FS, tc.FT, tc.iso.Um_kV, tc.iso.V_freq_ind_kV, tc.iso.Ni_kV);

fprintf('1. CRITÉRIOS DE CORRENTE PRIMÁRIA NOMINAL (I1n)\n');
fprintf('   Critério Ajuste 51 : I1n >= Ip_51 = %.1f A\n', tc.I1n_min_nom);
fprintf('   Regra Icc / FS     : I1n >= Icc_max_sim / FS = %.1f A / %g = %.2f A\n', tc.Icc_max_sim, tc.FS, tc.I1n_min_sat);
fprintf('   Corrente mínima do primário solicitada : I1n_min = max(%.1f A, %.2f A) = %.2f A\n', tc.I1n_min_nom, tc.I1n_min_sat, tc.I1n_min_req);
fprintf('   Limite 20x Demanda : I1n <= 20 * I_demanda = 20 * %.1f A = %.1f A\n', tc.I_demanda, tc.I1n_max_dem);
fprintf('   TC Adotado         : %g / %g A (RTC = %.2f) | Ajuste 51: [%s] | Icc/FS: [%s] | <=20xIdem: [%s]\n', ...
    tc.Iprim, tc.Isec, tc.RTC, ok_s(tc.ok_nominal), ok_s(tc.ok_regra_icc_fs), ok_s(tc.ok_limite_20x_dem));

fprintf('\n2. CARGA SECUNDÁRIA (BURDEN) E IMPEDÂNCIAS DO CIRCUITO\n');
fprintf('   Cabo TC        : %g mm² %s %s | L_ida = %.1f m | T_op = %d°C\n', ...
    tc.cabo_secao_mm2, tc.cabo_material, tc.cabo_isolacao, tc.cabo_comp_m, tc.T_op);
fprintf('   Resistividade  : rho(T) = rho20 * (1 + alpha*(T - 20)) = %.5f * (1 + %.5f*(%d - 20)) = %.5f Ohm.mm²/m\n', ...
    tc.rho20, tc.alpha_T, tc.T_op, tc.rho_T);
fprintf('   Resist. Cabo   : R_cabo = (rho(T) * 1000) / S = (%.5f * 1000) / %g = %.3f Ohm/km\n', ...
    tc.rho_T, tc.cabo_secao_mm2, tc.R_cabo_km);
fprintf('   Imped. Cabo    : Z_cabo = 2 * R_cabo * L_km = 2 * %.3f * %.4f = %.4f Ohm\n', ...
    tc.R_cabo_km, tc.cabo_comp_m/1000, tc.Z_cabo);
fprintf('   Imped. Relé    : Z_rele = S_rele / Isec^2 = %.2f / %g^2 = %.4f Ohm\n', ...
    tc.consumo_rele_VA, tc.Isec, tc.Z_rele);
fprintf('   Contatos       : R_contato = %.4f Ohm (S_contato = R_contato * Isec^2 = %.2f VA)\n', ...
    tc.R_contato_ohm, tc.R_contato_ohm * (tc.Isec^2));
fprintf('   Imped. Externa : Z_ext = Z_cabo + Z_rele + R_contato = %.4f + %.4f + %.4f = %.4f Ohm\n', ...
    tc.Z_cabo, tc.Z_rele, tc.R_contato_ohm, tc.Z_ext);
fprintf('   Burden Externo : S_ext = Z_ext * Isec^2 = %.4f * %g^2 = %.2f VA  (%s Cn = %.1f VA) -> [%s]\n', ...
    tc.Z_ext, tc.Isec, tc.S_ext_VA, cmp_s(tc.ok_burden_ext), tc.Cn_VA, ok_s(tc.ok_burden_ext));
fprintf('   Enrol. Interno : Z_tc  = (5/Isec)^2 * (0,00234*(I1n/5) + 0,0262) = %.4f Ohm\n', tc.Z_tc);
fprintf('   Imped. Total   : Z_tot = Z_tc + Z_ext = %.4f + %.4f = %.4f Ohm\n', tc.Z_tc, tc.Z_ext, tc.Z_total);
fprintf('   Burden Total   : S_tot = Z_tot * Isec^2 = %.4f * %g^2 = %.2f VA (Informativo c/ Z_tc interno)\n', ...
    tc.Z_total, tc.Isec, tc.S_total_VA);

fprintf('\n3. VERIFICAÇÃO DE NÃO SATURAÇÃO POR TENSÃO SECUNDÁRIA\n');
fprintf('   Fórmula Icc_sec  : Icc_sec = Icc_max_sim / RTC\n');
fprintf('   Cálculo Icc_sec  : Icc_sec = %.1f / %.2f = %.2f A\n', tc.Icc_max_sim, tc.RTC, tc.Icc_sec_sim);
fprintf('   Fórmula Vs_max   : Vs_max = (FS / Isec) * Cn\n');
fprintf('   Cálculo Vs_max   : Vs_max = (%g / %g) * %.1f = %.1f V\n', tc.FS, tc.Isec, tc.Cn_VA, tc.Vs_max);
fprintf('   Fórmula Vs_sim   : Vs_sim = Z_tot * Icc_sec\n');
fprintf('   Cálculo Vs_sim   : Vs_sim = %.4f * %.2f = %.2f V  (%s Vs_max = %.1f V) -> %s\n', ...
    tc.Z_total, tc.Icc_sec_sim, tc.Vs_sim, cmp_s(tc.ok_sat_sim), tc.Vs_max, tc.status_sim);
fprintf('   Fórmula Vs_trans : Vs_trans = Vs_sim * (1 + X/R)\n');
fprintf('   Cálculo Vs_trans : Vs_trans = %.2f * (1 + %.2f) = %.2f V  (%s Vs_max = %.1f V) -> %s\n', ...
    tc.Vs_sim, tc.XR_tc, tc.Vs_trans, cmp_s(tc.ok_sat_trans), tc.Vs_max, tc.status_trans);

fprintf('\n4. VERIFICAÇÃO DE SENSIBILIDADE RESIDUAL E SUPORTABILIDADE TÉRMICA (Ith)\n');
fprintf('   Fórmula Ip_51N_sec : Ip_51N_sec = Ip_51N / RTC\n');
fprintf('   Cálculo Ip_51N_sec : Ip_51N_sec = %.2f / %.2f = %.4f A sec  (Mínimo do relé: %.4f A sec)\n', ...
    tc.Ip_51N, tc.RTC, tc.Ip_51N_sec, tc.min_51N_sec);
if tc.ok_sensib_51N && ~ns.habilitado
    fprintf('   Status Sensib.     : APROVADO\n');
else
    fprintf('   Status Sensib.     : REQUER TC TOROIDAL (51NS/51GS) -> Pickup = %.2f A | t = %.2f s\n', ns.Ip_51NS, ns.t_51NS);
end
fprintf('   Fórmula Ith (1s)   : Ith_req(1s) = Icc_max_sim * sqrt(t_ref)  |  Ref. padrão = 100 * I1n\n');
fprintf('   Cálculo Ith (1s)   : Ith_req(1s) = %.1f * sqrt(%.3f) = %.1f A  (t_elim = %.3fs; %s Ref. = %.1f A) -> [%s]\n', ...
    tc.Icc_max_sim, t_th_eff, Ith_req_1s, t_elim_icc, cmp_s(Ith_req_1s <= Ith_ref_1s), Ith_ref_1s, ok_s(Ith_req_1s <= Ith_ref_1s));

if tc.classe_A_alerta,         fprintf('   AVISO CLASSE A     : Validar pela curva de excitação do fabricante.\n'); end
if ~tc.ok_limite_20x_dem,      fprintf('   AVISO 20x DEMANDA  : I1n (%g A) > 20*Idem (%.1f A) devido ao piso Icc/FS ou saturação.\n', tc.Iprim, tc.I1n_max_dem); end
if tc.flag_sim_relaxado,       fprintf('   ALERTA CRÍTICO     : Nenhum TC até %g A atendeu saturação simétrica/burden.\n', tc.I1n_max_banco);
elseif tc.flag_trans_relaxado, fprintf('   AVISO TRANSITÓRIO  : Nenhum TC até %g A satisfez Vs_trans <= Vs_max; adotado menor TC simétrico.\n', tc.I1n_max_banco);
end

aprovado = tc.ok_nominal && tc.ok_regra_icc_fs && tc.ok_limite_20x_dem && tc.ok_burden_ext && tc.ok_sat_sim && tc.ok_sat_trans;
fprintf('------------------------------------------------------------------------\n');
if strcmpi(tc.modo, 'MANUAL')
    fprintf('   >> AUDITORIA DO TC EXISTENTE (MODO MANUAL - %s):\n', tern(aprovado, 'APROVADO', 'VER CRITÉRIOS REPROVADOS'));
else
    fprintf('   >> ESPECIFICAÇÃO DO TC DE PROTEÇÃO RECOMENDADO (3 UNIDADES - FASES):\n');
end
fprintf('      Relação Nominal : %g / %g A (RTC = %.2f) | Freq.: %d Hz | %s\n', tc.Iprim, tc.Isec, tc.RTC, tc.freq_Hz, tc.instalacao);
fprintf('      Classe / Carga  : %s  |  Carga Nominal = %.1f VA (Zn = %.2f Ohm)  |  FS = %g  |  FT = %g\n', tc.classe_formatada, tc.Cn_VA, tc.Zn_ohm, tc.FS, tc.FT);
fprintf('      Isolamento      : Classe %.1f kV (Um = %.1f kV | 60 Hz 1 min = %.0f kV | Ni = %.0f kV)\n', tc.iso.classe_kV, tc.iso.Um_kV, tc.iso.V_freq_ind_kV, tc.iso.Ni_kV);
fprintf('      Curta Duração   : Ith >= %.2f kA (1s)  [Ref. 100xIn = %.2f kA]\n', Ith_req_1s/1000, Ith_ref_1s/1000);
if ns.habilitado
    fprintf('   >> COMPLEMENTO OBRIGATÓRIO DE NEUTRO SENSÍVEL (51NS / 51GS):\n');
    fprintf('      TC Toroidal     : Janela compatível c/ cabos MT | Relação típica 100/1 A (ou 50/1 A)\n');
    fprintf('      Ajuste 51NS     : Pickup = %.2f A | Tempo Definido = %.2f s\n', ns.Ip_51NS, ns.t_51NS);
end
fprintf('------------------------------------------------------------------------\n');
end

%% --- RELATÓRIO 4: DIMENSIONAMENTO DOS TPs DE PROTEÇÃO E AUXILIAR (ABNT NBR 6855) ---
function relatorio_4_tps(tps)
p = tps.prot;
a = tps.aux;
ok_s = @(c) tern(c, 'APROVADO', 'REPROVADO');

if p.FT_max > p.FT_perm
    str_ft_p = sprintf('FT = %.2f (Regime Permanente) / %.2f (%s)', p.FT_perm, p.FT_max, p.FT_dur);
else
    str_ft_p = sprintf('FT = %.2f (Regime Permanente / Contínuo)', p.FT_perm);
end
str_ft_a = sprintf('FT = %.2f (Regime Permanente / Contínuo)', a.FT_perm);

if p.RTP_ajustado
    str_rtp_p = sprintf('%d:1 (exato: %.2f:1 | V2 operacional = %.1f V)', p.RTP, p.RTP_exato, p.V2_op_V);
else
    str_rtp_p = sprintf('%d:1', p.RTP);
end
if a.RTP_ajustado
    str_rtp_a = sprintf('%d:1 (exato: %.2f:1 | V2 operacional = %.1f V)', a.RTP, a.RTP_exato, a.V2_op_V);
else
    str_rtp_a = sprintf('%d:1', a.RTP);
end

if p.S_cabo_VA < 0.01
    str_scabo = sprintf('%.6f VA (%.3f mVA)', p.S_cabo_VA, p.S_cabo_VA * 1000);
    str_stot  = sprintf('%.6f VA', p.S_total_VA);
else
    str_scabo = sprintf('%.4f VA', p.S_cabo_VA);
    str_stot  = sprintf('%.4f VA', p.S_total_VA);
end

fprintf('\n========================================================================\n');
fprintf(' RELATÓRIO 4 - DIMENSIONAMENTO DOS TPs DE PROTEÇÃO E AUXILIAR (ABNT NBR 6855)\n');
fprintf('========================================================================\n\n');

% --- PARTE A: TP DE PROTEÇÃO ---
fprintf('PARTE A - TRANSFORMADOR DE POTENCIAL DE PROTEÇÃO\n');
fprintf('1. CONFIGURAÇÃO, ISOLAMENTO E FATORES NORMATIVOS\n');
fprintf('   Arranjo / Grupo : %d unidades | %s | %s\n', p.qtd, p.ligacao, p.grupo);
fprintf('   Instalação      : %s | Classe Térmica: %s | Frequência: %d Hz\n', p.instalacao, p.classe_temp, p.freq_Hz);
fprintf('   Nível Isolam.   : Classe %.1f kV (Um = %.1f kV | 60 Hz 1 min = %.0f kV | Ni = %.0f kV)\n', ...
    p.iso.classe_kV, p.iso.Um_kV, p.iso.V_freq_ind_kV, p.iso.Ni_kV);
fprintf('   Sobretensão     : %s\n', str_ft_p);
fprintf('   Tensões / RTP   : Primário = %s | Secundário = %.1f V (V_LL nom = %.1f V)\n', ...
    p.V_prim_fmt, p.V2n_V, p.V_sec_LL_V);
fprintf('   Relação (RTP)   : %s\n\n', str_rtp_p);

fprintf('2. CÁLCULO DE CARGA (BURDEN) E QUEDA DE TENSÃO NO CABO SECUNDÁRIO\n');
fprintf('   Cabo TP         : %g mm² %s %s | L_ida = %.1f m | T_op = %d°C | R_cabo = %.3f Ohm/km\n', ...
    p.cabo_secao_mm2, p.cabo_material, p.cabo_isolacao, p.cabo_comp_m, p.T_op, p.R_cabo_km);
fprintf('   Impedância Laço : Z_cabo = 2 * %.3f * %.4f = %.4f Ohm\n', p.R_cabo_km, p.cabo_comp_m/1000, p.Z_cabo);
fprintf('   Corrente Carga  : I_sec = %.2f VA / %.1f V = %.4f A\n', p.S_rele_VA, p.V2n_V, p.I_carga_A);
fprintf('   Perda no Cabo   : S_cabo = I_sec^2 * Z_cabo = %s\n', str_scabo);
fprintf('   Carga Total     : S_tot = S_rele (%.2f VA) + S_cabo = %s  [%s <= %.1f VA]\n', ...
    p.S_rele_VA, str_stot, ok_s(p.ok_burden), p.Cn_sel_VA);
fprintf('   Carga Mín. NBR  : P%g (%.1f VA) -> Adotada conforme classe selecionada: %s (%.1f VA)\n', ...
    p.Cn_min_calc_VA, p.Cn_min_calc_VA, p.classe_final, p.Cn_sel_VA);
fprintf('   Queda de Tensão : dV = %.4f * %.4f = %.4f V (%.4f%%)  (Limite < %g%%) -> [%s]\n', ...
    p.Z_cabo, p.I_carga_A, p.dV_real_V, p.dV_real_pct, p.lim_dV_pct, ok_s(p.ok_queda_tensao));

if p.escalonou_Cn
    fprintf('   AVISO BURDEN    : Carga total (%s) superou 75 VA; classe escalonada de %s para %s.\n', str_stot, p.classe_alvo, p.classe_final);
end
if p.alerta_carga_max
    fprintf('   ALERTA CRÍTICO  : Carga total (%s) excede o limite padrão P400 (400 VA) da ABNT NBR 6855!\n', str_stot);
end
if ~p.ok_queda_tensao
    fprintf('   ALERTA QUEDA V  : Queda de tensão (%.3f%%) >= %g%%! Aumentar cabo do TP para >= %.2f mm².\n', ...
        p.dV_real_pct, p.lim_dV_pct, p.secao_min_mm2);
end

fprintf('------------------------------------------------------------------------\n');
fprintf('   >> ESPECIFICAÇÃO DO TP DE PROTEÇÃO (%d UNIDADES - USO INTERNO):\n', p.qtd);
fprintf('      Ligação / Grupo : %s | %s\n', p.ligacao, p.grupo);
fprintf('      Relação Nominal : %s  (RTP = %d:1) | Freq.: %d Hz | Classe Térm.: %s\n', p.rel_fmt, p.RTP, p.freq_Hz, p.classe_temp);
fprintf('      Classe / Carga  : %s (%.1f VA) | Pot. Térmica >= %.0f VA\n', p.classe_final, p.Cn_sel_VA, p.Pt_nom_VA);
fprintf('      Sobretensão     : %s\n', str_ft_p);
fprintf('      Isolamento      : Classe %.1f kV (Um = %.1f kV | 60 Hz 1 min = %.0f kV | Ni = %.0f kV) | %s\n', ...
    p.iso.classe_kV, p.iso.Um_kV, p.iso.V_freq_ind_kV, p.iso.Ni_kV, p.instalacao);
fprintf('------------------------------------------------------------------------\n\n');

% --- PARTE B: TP AUXILIAR PARA SERVIÇOS (TPA) ---
fprintf('PARTE B - TRANSFORMADOR DE POTENCIAL AUXILIAR DE SERVIÇOS (TPA)\n');
fprintf('1. CONFIGURAÇÃO, ISOLAMENTO E FATORES NORMATIVOS\n');
fprintf('   Configuração    : %d unidade exclusiva | %s\n', a.qtd, a.ligacao);
fprintf('   Grupo / Instal. : %s | %s | Classe Térmica: %s | Freq.: %d Hz\n', a.grupo, a.instalacao, a.classe_temp, a.freq_Hz);
fprintf('   Nível Isolam.   : Classe %.1f kV (Um = %.1f kV | 60 Hz 1 min = %.0f kV | Ni = %.0f kV)\n', ...
    a.iso.classe_kV, a.iso.Um_kV, a.iso.V_freq_ind_kV, a.iso.Ni_kV);
fprintf('   Sobretensão     : %s\n', str_ft_a);
fprintf('   Tensões / RTP   : %s | RTP = %s\n\n', a.rel_fmt, str_rtp_a);

fprintf('2. DIMENSIONAMENTO DA POTÊNCIA TÉRMICA NOMINAL\n');
fprintf('   Carga Prevista  : P_prev = %.1f VA\n', a.P_prevista_VA);
fprintf('   Margem Segur.   : +%g%% -> P_req = %.1f * %.3f = %.1f VA\n', a.margem_pct, a.P_prevista_VA, 1 + a.margem_pct/100, a.P_req_VA);
fprintf('   Potência Adot.  : P_nom = %.0f VA (Margem efetiva real: +%.1f%%)\n', a.P_nom_VA, a.margem_real_pct);
fprintf('   Correntes Nom.  : I1n = %.4f A (primário) | I2n = %.2f A (secundário @ %.0f V)\n', a.I1n_A, a.I2n_A, a.V2n_V);
if a.alerta_acima_5kVA
    fprintf('   AVISO POTÊNCIA  : P_req (%.1f VA) > 5000 VA. Avaliar transformador de serviços auxiliares dedicado (10/15 kVA).\n', a.P_req_VA);
end

fprintf('------------------------------------------------------------------------\n');
fprintf('   >> ESPECIFICAÇÃO DO TP AUXILIAR - TPA (1 UNIDADE INDEPENDENTE - USO INTERNO):\n');
fprintf('      Ligação / Grupo : Fase-Fase | %s\n', a.grupo);
fprintf('      Relação Nominal : %s  (RTP = %d:1) | Freq.: %d Hz | Classe Térm.: %s\n', a.rel_fmt, a.RTP, a.freq_Hz, a.classe_temp);
fprintf('      Potência Térm.  : %.0f VA contínua | I1n = %.4f A | I2n = %.2f A\n', a.P_nom_VA, a.I1n_A, a.I2n_A);
fprintf('      Sobretensão     : %s\n', str_ft_a);
fprintf('      Isolamento      : Classe %.1f kV (Um = %.1f kV | 60 Hz 1 min = %.0f kV | Ni = %.0f kV) | %s\n', ...
    a.iso.classe_kV, a.iso.Um_kV, a.iso.V_freq_ind_kV, a.iso.Ni_kV, a.instalacao);
fprintf('------------------------------------------------------------------------\n\n');
end

%% --- HELPERS DE FORMATAÇÃO ---
function s = fmt_inst(tag, Ip, t)
if isnan(Ip) || Ip <= 0
    s = ['Sem ' tag];
else
    s = sprintf('Ip%s = %.1f A (%.2f s)', tag, Ip, t);
end
end

function linha_cc(nome, v_pc, v_int, un)
var_pct = ((v_int - v_pc) / max(v_pc, 1e-9)) * 100;
if isempty(un)
    fprintf('   %-30s | %15.2f | %15.2f | %+7.2f%%\n', nome, v_pc, v_int, var_pct);
else
    fprintf('   %-30s | %13.1f %s | %13.1f %s | %+7.2f%%\n', nome, v_pc, un, v_int, un, var_pct);
end
end

function imprimir_diag_elo(canal, con, esc, cfg, t_disj)
if ~con.tem_elo, return; end
if isinf(esc.min_folga_elo)
    fprintf('   - Elo %s (%s)        : Sem sobreposição na zona temporizada (instantâneo atua antes da curva do elo)\n', con.Elo_PC, canal);
else
    fprintf('   - Elo %s (%s)        : Folga sobre %.0f%% = %+.3fs | Dist. fusão mín. = %.3fs (Relé+Disj.%.0fms <= %.0f%%)\n', ...
        con.Elo_PC, canal, cfg.fator_seg_elo*100, esc.min_folga_elo, esc.min_margem_elo, t_disj*1000, cfg.fator_seg_elo*100);
end
end

function s = tern(cond, s1, s2)
if cond
    s = s1;
else
    s = s2;
end
end

function s = fmt_opt(v, fmt)
if isnan(v), s = 'N/A'; else, s = sprintf(fmt, v); end
end