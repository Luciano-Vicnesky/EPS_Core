classdef lib_eletrica
    % LIB_ELETRICA
    % Utilitários compartilhados (fonte única de verdade para cabos, isolamento MT e parsing).

    methods (Static)
        function eh_al = eh_aluminio(material)
            m     = upper(strtrim(char(material)));
            eh_al = strcmp(m, 'ALUMINIO') || strcmp(m, 'ALUMÍNIO');
        end

        function iso = nivel_isolamento(Vnom_kV)
            % Níveis de isolamento nominais para uso interno (ABNT NBR 6855 / NBR 6856)
            if Vnom_kV <= 15.0
                iso = struct('classe_kV', 15.0, 'Um_kV', 15.0, 'V_freq_ind_kV', 34.0, 'Ni_kV', 95.0);
            elseif Vnom_kV <= 24.2
                iso = struct('classe_kV', 24.2, 'Um_kV', 24.2, 'V_freq_ind_kV', 50.0, 'Ni_kV', 125.0);
            else
                iso = struct('classe_kV', 36.2, 'Um_kV', 36.2, 'V_freq_ind_kV', 70.0, 'Ni_kV', 170.0);
            end
        end

        function c = cabo_secundario(material, isolacao, secao_mm2, comp_m)
            % Resistência corrigida por temperatura e impedância de ida e volta (TC / TP)
            eh_al = lib_eletrica.eh_aluminio(material);
            if eh_al
                rho20 = 0.02826; alpha_T = 0.00403;
            else
                rho20 = 0.01724; alpha_T = 0.00393;
            end
            if ismember(upper(strtrim(char(isolacao))), {'EPR', 'XLPE'})
                T_op = 90;
            else
                T_op = 70;
            end
            rho_T     = rho20 * (1 + alpha_T * (T_op - 20));
            R_cabo_km = (rho_T * 1000) / secao_mm2;
            Z_cabo    = 2 * R_cabo_km * (comp_m / 1000);

            c = struct('eh_al', eh_al, 'rho20', rho20, 'alpha_T', alpha_T, ...
                'T_op', T_op, 'rho_T', rho_T, 'R_cabo_km', R_cabo_km, 'Z_cabo', Z_cabo);
        end

        function K = fator_k_adiabatico(material, isolacao, tipo)
            % Constante térmica K (A.s^0.5/mm²) para verificação adiabática I²t <= K²S²
            eh_al  = lib_eletrica.eh_aluminio(material);
            eh_nu  = strcmpi(strtrim(char(tipo)), 'Aereo_Nu') || strcmpi(strtrim(char(isolacao)), 'NU');
            eh_epr = ismember(upper(strtrim(char(isolacao))), {'EPR', 'XLPE'});

            if eh_nu,      K = 132 - 45 * eh_al;
            elseif eh_epr, K = 143 - 49 * eh_al;
            else,          K = 115 - 39 * eh_al;
            end
        end

        function v = parse_vetor_num(texto)
            txt = strtrim(strrep(char(texto), ',', '.'));
            if isempty(txt)
                v = [];
                return;
            end
            v = str2double(strsplit(txt));
        end
    end
end