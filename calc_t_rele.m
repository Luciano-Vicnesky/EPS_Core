function t_calc = calc_t_rele(I_vetor, Ip_51, DT, tipo_curva, Ip_50, t_50, t_min_fisico, M_max)
% CALC_T_RELE - Calcula o tempo de atuação IEC 60255 respeitando o piso físico e saturação do relé
if nargin < 7 || isempty(t_min_fisico) || isnan(t_min_fisico)
    t_min_fisico = 0.01;
end
if nargin < 8 || isempty(M_max) || isnan(M_max) || M_max <= 0
    M_max = Inf;
end

switch upper(tipo_curva)
    case 'NI', k = 0.14;  alpha = 0.02;
    case 'MI', k = 13.5;  alpha = 1.0;
    case 'EI', k = 80.0;  alpha = 2.0;
    otherwise, error('Curva %s não reconhecida. Use NI, MI ou EI.', tipo_curva);
end

if isnan(Ip_51) || Ip_51 <= 0 || isnan(DT) || DT <= 0
    t_calc = NaN(size(I_vetor));
    return;
end

if isnan(Ip_50) || Ip_50 <= 0
    Ip_50 = Inf; 
end

t_calc = NaN(size(I_vetor));
M = I_vetor / Ip_51;

% ZONA 1: Atuação Temporizada (Acima do 51 e abaixo do 50)
idx_temp = (M > 1) & (I_vetor < Ip_50);
if any(idx_temp)
    M_eff = min(M(idx_temp), M_max);
    t_temp = DT * (k ./ (M_eff.^alpha - 1));
    t_calc(idx_temp) = max(t_temp, t_min_fisico);
end

% ZONA 2: Atuação Instantânea (Atinge ou ultrapassa o 50, mesmo se Ip_50 <= Ip_51)
idx_inst = (I_vetor >= Ip_50);
if any(idx_inst) && ~isnan(t_50)
    t_50_eff = max(t_50, t_min_fisico);
    if Ip_50 > Ip_51
        M_50_eff = min(Ip_50 / Ip_51, M_max);
        t_ultimo_temp = max(DT * (k ./ (M_50_eff^alpha - 1)), t_min_fisico);
        t_calc(idx_inst) = min(t_50_eff, t_ultimo_temp);
    else
        t_calc(idx_inst) = t_50_eff;
    end
end
end