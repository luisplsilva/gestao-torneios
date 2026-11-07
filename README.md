# Sistema de Gestão de Torneios Eliminatórios

Trabalho Prático de Programação Funcional — **Fase 1: Modelação e Núcleo Funcional**

**Grupo:** PL05GR06

| Nome | Número |
|------|--------|
| _[Luís Pedro Leitão da Silva]_ | _[2024145446]_ |
| _[Hugo Ramos Pinheiro]_ | _[2024149658]_ |

## Descrição

Aplicação em Haskell para gerir **torneios eliminatórios de futebol**: as
equipas e os seus jogadores, os jogos de cada fase (oitavos, quartos,
meias-finais e final), quem avança, o campeão e as estatísticas de equipas e
de jogadores.

Num torneio eliminatório a equipa que perde sai. O número de equipas é uma
potência de 2 (2, 4, 8 ou 16), por isso cada ronda reduz as equipas para
metade. A primeira ronda é feita por **seeds**: o melhor com o pior (1 vs 8,
2 vs 7, 3 vs 6, 4 vs 5), para os favoritos só se encontrarem nas rondas finais.

**Regra de empate configurável.** Quando um jogo acaba empatado, é o
administrador do torneio que escolhe o que acontece (campo `regraEmpate` da
`Configuracao`):

| Regra | O que acontece num jogo empatado |
|-------|----------------------------------|
| `Penaltis` | avança quem ganhar nas grandes penalidades |
| `AvancaEquipaA` | avança a primeira equipa do jogo (a "da casa") |
| `AvancaMelhorSeed` | avança a equipa com menor id (melhor seed) |

Nesta fase está implementado o **modelo de dados** e o **núcleo funcional**
(funções puras). A leitura de ficheiros, o parsing e uma interface com menu
ficam para as fases seguintes.

## O que a Fase 1 pede e onde está

| Pedido no enunciado | Onde está |
|---------------------|-----------|
| Modelo de domínio (`data`, `type`, records, relações) | `src/Model.hs` |
| Estrutura do projeto (módulos iniciais) | `src/`, `app/`, `test/`, `data/` |
| Funções essenciais (puras, com assinaturas) | `src/Domain.hs` |
| Recursão | `src/Domain.hs` (secções "Listas de jogos", "Emparelhamentos" e "Estatísticas individuais") |
| Dados de teste | `src/SampleData.hs` e `data/*.csv` |
| README | este ficheiro |
| Git | histórico do repositório |

## Requisitos

- GHC (testado com 9.4.7)
- cabal-install (testado com 3.8)

O projeto só usa a biblioteca `base`, por isso não é preciso instalar mais nada.

## Compilar, executar e testar

Na pasta do projeto (onde está o ficheiro `gestao-torneios.cabal`):

```bash
cabal build                  # compila tudo
cabal run gestao-torneios    # executa a demonstração
cabal test                   # corre os testes
```

Também é possível experimentar as funções no interpretador:

```bash
cabal repl
ghci> import SampleData
ghci> import Domain
ghci> campeao Penaltis jogosExemplo
Just 1
ghci> emparelharSeeds [1 .. 8]
[(1,8),(2,7),(3,6),(4,5)]
```

## Estrutura do projeto

```
gestao-torneios/
├── README.md
├── cabal.project
├── gestao-torneios.cabal
├── src/
│   ├── Model.hs        -- tipos de dados do domínio
│   ├── Domain.hs       -- regras do domínio (funções puras)
│   ├── Display.hs      -- formatação de dados em texto (funções puras)
│   └── SampleData.hs   -- dados de teste (8 equipas, 7 jogos)
├── app/
│   └── Main.hs         -- demonstração (único módulo com IO)
├── test/
│   └── Spec.hs         -- testes das funções puras
└── data/
    ├── equipas.csv     -- as mesmas 8 equipas de SampleData.hs
    ├── jogadores.csv   -- os 24 jogadores
    └── jogos.csv       -- os 7 jogos
```

Os ficheiros de `data/` ainda **não são lidos** pelo programa: nesta fase os
dados usados são os de `src/SampleData.hs`. Os CSV guardam os mesmos dados no
formato que se prevê ler na Fase 3.

## Modelo de dados

Definido em `src/Model.hs`:

| Tipo | Descrição |
|------|-----------|
| `IdEquipa` (`type`) | Identificador de uma equipa (`Int`). Serve também de seed. |
| `Posicao` | `GuardaRedes`, `Defesa`, `MedioCampo`, `Avancado`. |
| `Jogador` (record) | Nome, camisola, posição e estatísticas individuais: golos, assistências, cartões amarelos e vermelhos, jogos. |
| `Equipa` (record) | Id, nome, cidade e plantel (`[Jogador]`). |
| `Fase` | `OitavosFinal`, `QuartosFinal`, `MeiaFinal`, `Final`. |
| `RegraEmpate` | `Penaltis`, `AvancaEquipaA`, `AvancaMelhorSeed`. |
| `Configuracao` (record) | Regra de empate e número de equipas, escolhidos pelo administrador. |
| `Jogo` (record) | Fase, ids das equipas A e B, golos de cada uma e penalidades (`Maybe (Int, Int)`). |
| `EstatisticasEquipa` (record) | Jogos, vitórias, derrotas, golos marcados e sofridos de uma equipa. |
| `Torneio` (record) | Nome, configuração, equipas e jogos. |

**Relações entre entidades.** Uma `Equipa` contém uma lista de `Jogador`
(composição). Um `Jogo` não contém as equipas, apenas os seus `IdEquipa`;
assim os dados não se repetem e a equipa obtém-se com `procurarEquipaPorId`.
Um `Torneio` agrega a configuração, as equipas e os jogos. As estatísticas de
uma equipa não são guardadas: calculam-se a partir dos jogos.

## Funções principais

Definidas em `src/Domain.hs`. Todas são puras e têm assinatura de tipo
explícita.

| Grupo | Funções |
|-------|---------|
| Fases e configuração | `equipasNaFase`, `proximaFase`, `fasesDesde`, `faseInicial`, `potenciaDeDois`, `numeroDeRondas`, `configuracaoValida` |
| Um jogo | `participa`, `golosMarcadosNoJogo`, `golosSofridosNoJogo`, `vencedor`, `perdedor`, `jogoValido` |
| Listas de jogos | `jogosDaFase`, `jogosDaEquipa`, `jogosValidos`, `contarJogos`, `golosMarcadosEquipa`, `golosSofridosEquipa`, `contarVitorias`, `contarDerrotas`, `foiEliminada`, `vencedoresDaFase`, `campeao` |
| Estatísticas de equipa | `estatisticasEquipa`, `tabelaEstatisticas` |
| Emparelhamentos | `emparelhar`, `emparelharSeeds`, `idsDasEquipas`, `primeiraRonda`, `proximaRonda` |
| Pesquisa | `procurarEquipaPorId`, `procurarEquipaPorNome`, `nomeDaEquipa`, `procurarJogador` |
| Estatísticas individuais | `golosPlantel`, `assistenciasPlantel`, `cartoesPlantel`, `golosEquipa`, `contarPorPosicao`, `melhorMarcador`, `melhorMarcadorTorneio` |

### Recursão

Nesta fase, os problemas sobre listas são resolvidos por **recursão explícita
com pattern matching e guards** (caso base `[]` e caso recursivo `(x : xs)`):

- `contarJogos`, `golosMarcadosEquipa`, `contarVitorias`, `golosPlantel`, ...: somar ou contar percorrendo uma lista;
- `jogosDaFase`, `jogosDaEquipa`, `jogosValidos`: filtrar uma lista de jogos;
- `vencedoresDaFase`: percorre os jogos e junta quem os ganhou;
- `emparelhar`: junta os elementos dois a dois. Os vencedores de uma fase formam os jogos da seguinte (`proximaRonda`);
- `emparelharSeeds`: primeiro com último, segundo com penúltimo, e assim por diante (a primeira ronda);
- `fasesDesde`: todas as fases desde uma até à final;
- `potenciaDeDois` e `numeroDeRondas`: recursão sobre números (dividir por 2);
- `melhorMarcador` e `melhorMarcadorTorneio`: o melhor da cauda comparado com a cabeça.

## Dados de teste

Em `src/SampleData.hs`: um torneio de exemplo com 8 equipas (`Aguias FC`,
`Dragoes FC`, `Leoes FC`, `Falcoes FC`, `Lobos FC`, `Tubaroes FC`, `Touros FC`
e `Corvos FC`), 3 jogadores por equipa e 7 jogos. Os golos dos jogadores de
cada equipa somam os golos que a equipa marcou nos jogos.

| Fase | Jogos | Quem avança |
|------|-------|-------------|
| Quartos de final | 1-8: 3-0 · 2-7: 1-1 (penaltis 4-3) · 3-6: 2-1 · 4-5: 0-2 | 1, 2, 3, 5 |
| Meias-finais | 1-2: 2-0 · 3-5: 1-1 (penaltis 3-4) | 1, 5 |
| Final | 1-5: 3-1 | **campeão: Aguias FC (1)** |

Há dois jogos empatados decididos nas grandes penalidades (um nos quartos e
outro nas meias-finais). A meia-final 3-5 mostra como a regra de empate muda o
resultado: com `Penaltis` passa a equipa 5, e com `AvancaEquipaA` ou
`AvancaMelhorSeed` passa a equipa 3.
O melhor marcador do torneio é Tiago Ramos (6 golos).

## Testes

`cabal test` executa 156 testes (em `test/Spec.hs`) às funções puras do
núcleo, incluindo casos limite: listas vazias, ids inexistentes, jogos
inválidos, empates sem penalidades, penalidades empatadas, número ímpar de
equipas e configurações inválidas. Os testes usam apenas a biblioteca `base`.

## Fases seguintes (previsão)

- **Fase 2:** funções de ordem superior (`map`, `filter`, `foldr`), composição,
  `Maybe`/`Either` para validação, rankings e mais estatísticas.
- **Fase 3:** leitura e escrita de ficheiros (os CSV de `data/`), parsing,
  menu no terminal e relatórios.

## Trabalho em grupo (Git)

O repositório está no GitHub e todos os elementos contribuem com commits.
Fluxo de trabalho: `git pull` antes de começar, depois `git add .`,
`git commit -m "..."` e `git push`.
