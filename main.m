%% ========================================================================
%  EPS-Core - FERRAMENTA DE ESTUDO DE PROTEÇÃO E SELETIVIDADE (MÉDIA TENSÃO)
%  Padrão     : Celesc / IEC 60255 / ABNT NBR 6855, NBR 6856 e NBR 7282
%  Versão     : v.1.0
%  Publicação : 25-11-2026
%  Requisitos : MATLAB R2018b ou superior (sem toolboxes adicionais)
%  ========================================================================
%
%  DESCRIÇÃO:
%
%    Gerencia e realiza o Estudo de Proteção e Seletividade (EPS) em subestações 
%    de média tensão (13,8 kV e 23,1 kV), executando cálculo de curto-circuito
%    (no Ponto de Conexão - PC - e interno com ramal MT), otimização das funções 
%    50/51/50N/51N e 51NS, verificação térmica do cabo MT, dimensionamento/auditoria 
%    de TCs, especificação de TPs de proteção e TPA, emissão de 4 relatórios
%    técnicos auditáveis e geração de coordenogramas bilog em formato A4.
%
%  ORIENTAÇÕES DE USO:
%
%    1. Defina a pasta do EPS-Core como Current Folder no MATLAB.
%    2. Execute "main" no Command Window (use "help main" para esta ajuda).
%    3. Nas caixas de diálogo, selecione "Atualizar" para editar os dados
%       da Concessionária (PC), do Cliente/Infraestrutura/TC/TPs ou dos
%       Parâmetros Normativos de Cálculo, ou clique em "Manter Salvos" para
%       executar com o último cenário salvo em "dados_eps_core.mat".
%    4. Para múltiplos transformadores em paralelo, informe os valores
%       separados por espaço (ex.: Trafos = "500 300" | Z% = "5.0 4.5" |
%       Tipos = "O O", sendo O = Óleo e S = Seco/Epóxi).
%    5. Para restaurar os parâmetros padrão de fábrica, apague o arquivo
%       "dados_eps_core.mat" da pasta e execute "main" novamente.
%    6. Após editar qualquer arquivo .m ou a classe lib_eletrica.m, execute:
%       >> clear classes; clear functions; main
%
%  SAÍDAS GERADAS:
%
%    - Relatório 1: Dados de Entrada do Estudo (PC, Consumidor e Critérios)
%    - Relatório 2: Memória de Cálculo (Curtos, Trafos, Proteções e Cabo MT)
%    - Relatório 3: Dimensionamento / Auditoria do TC de Proteção (NBR 6856)
%    - Relatório 4: Dimensionamento dos TPs de Proteção e TPA (NBR 6855)
%    - Gráficos   : Coordenogramas bilog de Fase e Neutro (A4 Vertical)
%
%  AVISO DE RESPONSABILIDADE TÉCNICA:
%
%    Ferramenta de auxílio computacional. Todos os resultados, curvas e
%    especificações gerados devem ser revisados e validados por Engenheiro
%    Eletricista legalmente habilitado (CREA/ART) antes de submissão à
%    concessionária ou parametrização em campo.
%
%  ========================================================================

clear; clc; close all;

% 1. Carrega os dados salvos do arquivo ".mat" e gerencia a interface de
% entrada/validação dos dados
[cel, cli, cfg, ok] = coletar_dados_estudo('dados_eps_core.mat');
if ~ok, return; end

% 2. Curtos-circuitos (PC e Interno com impedância do ramal MT)
cc = calc_curtos_sistema(cel, cli);

% 3. Dimensionamento de TC, TPs/TPA, ajustes 50/51/50N/51N/51NS, otimização e cabo MT
est = otimizar_protecao(cel, cli, cfg, cc);

% 4. Emissão dos 4 relatórios técnicos no Command Window
gerar_relatorios_estudo(cel, cli, cfg, cc, est);

% 5. Geração dos coordenogramas de Fase e Neutro (A4 Vertical)
plotar_coordenogramas(cel, cli, cfg, cc, est);