# EPS-Core — Estudo de Proteção e Seletividade em Média Tensão

**Versão:** `v.1.0` | **Data de Publicação:** `25-11-2026` | **Plataforma:** MATLAB

O **EPS-Core** é uma ferramenta computacional desenvolvida em **MATLAB** para elaboração, otimização e auditoria de Estudos de Proteção e Seletividade (EPS) em subestações consumidoras de média tensão ($13{,}8\text{ kV}$ e $23{,}1\text{ kV}$). A base de cálculos e critérios técnicos segue os requisitos normativos da **Celesc**, **IEC 60255** e normas **ABNT NBR 6855**, **NBR 6856** e **NBR 7282**, com arquitetura modular e persistência padronizada para fácil adaptação.

---

## Principais Funcionalidades

* **Interface Gráfica Responsiva e Persistência Padronizada:** Coleta de parâmetros via formulários modais multicoluna com listas suspensas, validação automática de consistência e salvamento contínuo no arquivo.
* **Cálculo de Curtos-Circuitos (PC e Interno c/ Ramal MT):** Determinação das correntes de curto-circuito trifásico ($I_{cc3F}$), bifásico ($I_{cc2F}$), monofásico franco ($I_{cc1F}$), monofásico resistivo ($I_{cc1F,\min}$ com $R_f$) e correntes assimétricas ($I_{cc3F,\text{assim}}$ e $I_{cc1F,\text{assim}}$, via relação $X/R$ e fator $K_a$), acompanhadas de tabela comparativa com e sem a impedância do ramal de entrada MT.
* **Transformadores, Inrush e Pontos ANSI/NANSI:** Suporte a múltiplos transformadores em paralelo (óleo $8 \times I_n$ e seco/epóxi $14 \times I_n$, cálculo dos pontos ANSI e NANSI, além de separação configurável entre o limite mínimo normativo de Inrush ($1{,}40 \times I_{\text{inrush}}$) e o multiplicador adotado no ajuste da unidade instantânea `50` (padrão $1{,}45 \times I_{\text{inrush}}$).
* **Otimização Unificada de Curvas (`51/50` e `51N/50N`):** Varredura otimizada das curvas IEC 60255 (`NI`, `MI` e `EI`) com pré-cálculo unitário, modelagem da saturação do relé ($M_{\max}$) e dial de tempo (`DT`) ajustável, coordenando simultaneamente:
  * Proteção a montante no Ponto de Conexão ($\Delta t \ge 0{,}20\text{ s}$);
  * Elo fusível no PC segundo ABNT NBR 7282 na zona temporizada ($t_{\text{relé}} + t_{\text{disj}} \le 75\%$ da curva de fusão mínima, considerando $t_{\text{disj}} = 50\text{ ms}$);
  * Proteção térmica dos transformadores nos pontos ANSI e NANSI ($t \le 1{,}70\text{ s}$);
  * Verificação automática de sensibilidade residual com ativação e coordenação iterativa da função **`51NS / 51GS`** (TC toroidal).
* **Verificação Térmica do Cabo de Entrada MT:** Validação do critério $I^2 t \le K^2 S^2$ para faltas trifásicas e monofásicas (tempo de atuação do relé + $50\text{ ms}$ do disjuntor) com cálculo da seção mínima térmica admissível por condutor.
* **Dimensionamento e Auditoria de TCs de Proteção (ABNT NBR 6856):** Operação nos modos `AUTO` e `MANUAL`, verificando critério do ajuste `51`, regra $I_{cc}/FS$, limite superior de $20 \times I_{\text{demanda}}$, carga secundária, não saturação em regime simétrico e transitório ($1 + X/R$), sensibilidade residual, suportabilidade térmica ($I_{th}$ em $1\text{ s}$), fator térmico ($FT = 1{,}5$ até $15\text{ kV}$ e $FT = 1{,}2$ acima de $15\text{ kV}$) e níveis de isolamento ($N_i$).
* **Especificação de TPs de Proteção e TP Auxiliar (ABNT NBR 6855):** Dimensionamento dos arranjos `3TP_Estrela_Grupo2`, `3TP_Estrela_Grupo3` e `2TP_DeltaAberto_Grupo1` (uso interno em resina epóxi, classe térmica B — $130^\circ\text{C}$, classes `0,6P75` ou `0,3P75` com escalonamento automático de carga e verificação de queda de tensão $< 1\%$ no cabo secundário) e do TP Auxiliar de Serviços independente (`TPA`, fase-fase / $110\text{ V}$, com margem de segurança configurável).
* **Relatórios Auditáveis e Coordenogramas Bilog A4:** Emissão de 4 relatórios técnicos detalhados no *Command Window* e geração de coordenogramas log-log independentes de Fase e Neutro em formato A4 vertical (eixo de tempo até $100\text{ s}$, linha de limite mínimo de Inrush, $\Delta t$ mínimo na legenda e aviso visual de bloqueio de 2ª harmônica quando requerido).

---

## Pré-requisitos

* **MATLAB R2018b ou superior.**
* Não requer *toolboxes* adicionais.

---

## Estrutura do Projeto (`EPS-Core v.1.0`)

| Arquivo | Função no Projeto |
| :--- | :--- |
| `main.m` | Script principal que orquestra sequencialmente as 5 etapas do estudo. |
| `coletar_dados_estudo.m` | Carrega/inicializa `dados_eps_core.mat`, gerencia os formulários de entrada e valida todos os parâmetros. |
| `dialogo_formulario.m` | Interface gráfica modal responsiva com layout multicoluna e listas suspensas. |
| `calc_curtos_sistema.m` | Equacionamento de Thévenin (correntes simétricas e assimétricas eficazes) e impedância do ramal MT. |
| `otimizar_protecao.m` | Motor de proteção: transformadores, inrush, pickups (`50/51/50N/51N/51NS`), otimização IEC e cabo MT. |
| `calc_t_rele.m` | Cálculo dos tempos de atuação IEC 60255 (`NI`, `MI`, `EI`) com piso físico e saturação $M_{\max}$. |
| `curva_elo_fusivel.m` | Banco de curvas de fusão mínima e interrupção máxima de elos fusíveis (ABNT NBR 7282). |
| `dimensionar_tc_protecao.m` | Dimensionamento automático e auditoria de TCs de proteção (ABNT NBR 6856). |
| `dimensionar_tps.m` | Especificação dos TPs de proteção e do TP auxiliar de serviços — TPA (ABNT NBR 6855). |
| `lib_eletrica.m` | Biblioteca estática compartilhada (cabos secundários, fator adiabático $K$, níveis de isolamento MT e *parsing*). |
| `gerar_relatorios_estudo.m` | Emite os 4 relatórios técnicos completos e auditáveis no *Command Window*. |
| `plotar_coordenogramas.m` | Gera os coordenogramas bilog de Fase e Neutro em formato A4 vertical. |
| `dados_eps_core.mat` | Arquivo binário com os últimos dados salvos (`dados_concessionaria`, `dados_cliente` e `dados_calculo`), recriado automaticamente com os padrões de fábrica caso não exista. |

---

## Fluxo de Execução e Saídas

1. **Clone ou baixe o repositório** para uma pasta local:
   ```bash
   git clone https://github.com/Luciano-Vicnesky/EPS-Core.git
   ```
2. **Abra o MATLAB** e defina a pasta do projeto como *Current Folder*.
3. **Execute o script principal** no *Command Window*:
   ```matlab
   main
   ```
4. **Conduza o fluxo interativo:**
   * Selecione **Atualizar** ou **Manter Salvos** em cada etapa (*Dados da Concessionária*, *Dados do Projeto* e *Dados de Cálculo*).
   * Confira os **4 relatórios técnicos** emitidos no *Command Window*:
     1. **Relatório 1:** Dados de Entrada do Estudo (PC, Consumidor, Infraestrutura e Critérios Normativos).
     2. **Relatório 2:** Memória de Cálculo (Curtos-Circuitos, Tabela Comparativa do Ramal MT, Demanda, Transformadores, Pickups, Otimização, Diagnóstico e Verificação Térmica do Cabo MT).
     3. **Relatório 3:** Dimensionamento / Auditoria do TC de Proteção (ABNT NBR 6856) e complemento `51NS/51GS` quando aplicável.
     4. **Relatório 4:** Dimensionamento dos TPs de Proteção e do TP Auxiliar de Serviços — TPA (ABNT NBR 6855).
   * Inspecione os **2 coordenogramas bilog A4 verticais** (*Fase* e *Neutro*) exibidos em janelas dedicadas.

---

## Dicas de Uso

* **Consulta rápida no MATLAB:** execute `help main` no *Command Window* para visualizar as orientações integradas.
* **Múltiplos transformadores em paralelo:** informe os valores separados por espaço nos respectivos campos (ex.: Potências `500 300`, Impedâncias `5.0 4.5` e Tipos `O O`, onde `O` = Óleo e `S` = Seco/Epóxi).
* **Restaurar padrões de fábrica:** apague o arquivo `dados_eps_core.mat` da pasta do projeto e execute `main` novamente.
* **Limpar cache após editar códigos:** caso altere qualquer arquivo `.m` ou a classe `lib_eletrica.m`, execute:
  ```matlab
  clear classes; clear functions; main
  ```

---

## Aviso de Responsabilidade e Aplicação da Ferramenta

O **EPS-Core** é uma ferramenta de apoio computacional destinada a estudos de proteção de engenharia elétrica para âmbito educacional. Todos os resultados, curvas de seletividade, relatórios e especificações de equipamentos (relés, TCs, TPs e TPA) devem ser rigorosamente revisados e validados durante o desenvolvimento dos estudos possíveis com o auxílio da ferramenta. 

O criador não se responsabiliza por alterações no código disponibilizado. 

Cópias e reproduções totais ou parciais do conteúdo da ferramenta, inclusive as de intuito comercial e educacionais são expressamente proibidas sem prévia autorização por escrito do criador.
