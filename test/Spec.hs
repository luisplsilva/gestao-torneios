-- |
-- Testes das funções puras do núcleo (Fase 1).
-- Usa apenas a biblioteca base, por isso não precisa de instalar nada extra.
-- Executar com: cabal test
module Main (main) where

import System.Exit (exitFailure, exitSuccess)

import Display
import Domain
import Model
import SampleData

-- ---------------------------------------------------------------------------
-- Mini-framework de testes
-- ---------------------------------------------------------------------------

-- | Um teste: descrição, se passou e detalhe a mostrar quando falha.
data Teste = Teste
  { descricao :: String
  , passou    :: Bool
  , detalhe   :: String
  }

-- | Teste que verifica se duas expressões são iguais.
igual :: (Eq a, Show a) => String -> a -> a -> Teste
igual d obtido esperado =
  Teste d (obtido == esperado)
    ("esperado: " ++ show esperado ++ " | obtido: " ++ show obtido)

-- | Teste que verifica uma condição booleana.
verdade :: String -> Bool -> Teste
verdade d b = Teste d b "a condicao era falsa"

-- | Executa um teste e escreve o resultado.
executar :: Teste -> IO Bool
executar t
  | passou t = do
      putStrLn ("  [OK]    " ++ descricao t)
      return True
  | otherwise = do
      putStrLn ("  [FALHA] " ++ descricao t)
      putStrLn ("          " ++ detalhe t)
      return False

-- ---------------------------------------------------------------------------
-- Dados auxiliares dos testes
-- ---------------------------------------------------------------------------

-- | Os ids das 8 equipas.
ids :: [IdEquipa]
ids = [1, 2, 3, 4, 5, 6, 7, 8]

-- | Jogo normal: a equipa 1 vence a 8 por 3-0.
jogoNormal :: Jogo
jogoNormal = Jogo QuartosFinal 1 8 3 0 Nothing

-- | Jogo empatado decidido por penalidades (4-3 para a equipa A).
jogoPenaltis :: Jogo
jogoPenaltis = Jogo QuartosFinal 2 7 1 1 (Just (4, 3))

-- | Jogo empatado sem penalidades registadas.
jogoEmpateSemPenaltis :: Jogo
jogoEmpateSemPenaltis = Jogo QuartosFinal 4 6 0 0 Nothing

-- | Jogo empatado com penalidades também empatadas (não resolve).
jogoPenaltisEmpatados :: Jogo
jogoPenaltisEmpatados = Jogo QuartosFinal 4 6 2 2 (Just (3, 3))

-- | A meia-final em que a regra de empate faz diferença.
meiaFinalEmpatada :: Jogo
meiaFinalEmpatada = Jogo MeiaFinal 3 5 1 1 (Just (3, 4))

-- | Plantel com dois melhores marcadores empatados (para testar o desempate).
plantelEmpatado :: [Jogador]
plantelEmpatado =
  [ Jogador "Primeiro" 1 Avancado 5 0 0 0 3
  , Jogador "Segundo"  2 Avancado 5 0 0 0 3
  , Jogador "Terceiro" 3 Defesa   2 0 0 0 3
  ]

-- | Plantel da equipa com o id dado (vazio se a equipa não existir).
plantelDe :: IdEquipa -> [Jogador]
plantelDe i =
  case procurarEquipaPorId i equipasExemplo of
    Just e  -> plantel e
    Nothing -> []

-- | Estatísticas de exemplo da equipa dada, com a regra das penalidades.
estExemplo :: IdEquipa -> EstatisticasEquipa
estExemplo i = estatisticasEquipa Penaltis i jogosExemplo

-- | Nome do melhor marcador do plantel.
nomeMelhor :: [Jogador] -> Maybe String
nomeMelhor js = fmap nomeJogador (melhorMarcador js)

-- ---------------------------------------------------------------------------
-- Testes
-- ---------------------------------------------------------------------------

testes :: [Teste]
testes =
  -- Fases
  [ igual "equipasNaFase: 16, 8, 4 e 2"
      (map equipasNaFase [OitavosFinal, QuartosFinal, MeiaFinal, Final]) [16, 8, 4, 2]
  , igual "proximaFase QuartosFinal" (proximaFase QuartosFinal) (Just MeiaFinal)
  , igual "proximaFase OitavosFinal" (proximaFase OitavosFinal) (Just QuartosFinal)
  , igual "proximaFase Final nao tem seguinte" (proximaFase Final) Nothing
  , igual "fasesDesde QuartosFinal"
      (fasesDesde QuartosFinal) [QuartosFinal, MeiaFinal, Final]
  , igual "fasesDesde OitavosFinal tem 4 fases" (length (fasesDesde OitavosFinal)) 4
  , igual "fasesDesde Final" (fasesDesde Final) [Final]
  , igual "faseInicial 16" (faseInicial 16) (Just OitavosFinal)
  , igual "faseInicial 8"  (faseInicial 8) (Just QuartosFinal)
  , igual "faseInicial 2"  (faseInicial 2) (Just Final)
  , igual "faseInicial 6 (invalido)" (faseInicial 6) Nothing

  -- Configuração
  , verdade "potenciaDeDois 1, 2, 4, 8 e 16"
      (and (map potenciaDeDois [1, 2, 4, 8, 16]))
  , verdade "potenciaDeDois: 0, 3, 6 e 12 nao sao"
      (not (or (map potenciaDeDois [0, 3, 6, 12])))
  , verdade "potenciaDeDois: negativo nao e" (not (potenciaDeDois (-4)))
  , igual "numeroDeRondas 8 = 3" (numeroDeRondas 8) 3
  , igual "numeroDeRondas 16 = 4" (numeroDeRondas 16) 4
  , igual "numeroDeRondas 2 = 1" (numeroDeRondas 2) 1
  , igual "numeroDeRondas 1 = 0" (numeroDeRondas 1) 0
  , verdade "configuracaoValida: 8 equipas" (configuracaoValida (Configuracao Penaltis 8))
  , verdade "configuracaoValida: 2 equipas" (configuracaoValida (Configuracao AvancaMelhorSeed 2))
  , verdade "configuracaoValida: 6 equipas e invalida"
      (not (configuracaoValida (Configuracao Penaltis 6)))
  , verdade "configuracaoValida: 32 equipas e invalida (fora do intervalo)"
      (not (configuracaoValida (Configuracao Penaltis 32)))
  , verdade "configuracaoValida: 1 equipa e invalida"
      (not (configuracaoValida (Configuracao Penaltis 1)))
  , verdade "configuracaoValida: configuracaoExemplo" (configuracaoValida configuracaoExemplo)

  -- Um jogo: participação e golos
  , verdade "participa: equipa A" (participa 1 jogoNormal)
  , verdade "participa: equipa B" (participa 8 jogoNormal)
  , verdade "participa: equipa que nao jogou" (not (participa 5 jogoNormal))
  , igual "golosMarcadosNoJogo (A)" (golosMarcadosNoJogo 1 jogoNormal) 3
  , igual "golosMarcadosNoJogo (B)" (golosMarcadosNoJogo 8 jogoNormal) 0
  , igual "golosMarcadosNoJogo: equipa que nao jogou" (golosMarcadosNoJogo 5 jogoNormal) 0
  , igual "golosSofridosNoJogo (A)" (golosSofridosNoJogo 1 jogoNormal) 0
  , igual "golosSofridosNoJogo (B)" (golosSofridosNoJogo 8 jogoNormal) 3
  , igual "golosSofridosNoJogo: equipa que nao jogou" (golosSofridosNoJogo 5 jogoNormal) 0

  -- Vencedor e perdedor
  , igual "vencedor: ganha a equipa A" (vencedor Penaltis jogoNormal) (Just 1)
  , igual "vencedor: ganha a equipa B" (vencedor Penaltis (Jogo QuartosFinal 4 5 0 2 Nothing)) (Just 5)
  , igual "vencedor: empate decidido por penaltis (A)" (vencedor Penaltis jogoPenaltis) (Just 2)
  , igual "vencedor: empate decidido por penaltis (B)" (vencedor Penaltis meiaFinalEmpatada) (Just 5)
  , igual "vencedor: empate sem penaltis nao se decide" (vencedor Penaltis jogoEmpateSemPenaltis) Nothing
  , igual "vencedor: penaltis empatados nao se decide" (vencedor Penaltis jogoPenaltisEmpatados) Nothing
  , igual "vencedor: AvancaEquipaA avanca a equipa A" (vencedor AvancaEquipaA meiaFinalEmpatada) (Just 3)
  , igual "vencedor: AvancaMelhorSeed avanca o menor id" (vencedor AvancaMelhorSeed meiaFinalEmpatada) (Just 3)
  , igual "vencedor: AvancaMelhorSeed com A de seed pior"
      (vencedor AvancaMelhorSeed (Jogo MeiaFinal 5 3 0 0 Nothing)) (Just 3)
  , igual "vencedor: a regra nao muda um jogo sem empate"
      (map (\r -> vencedor r jogoNormal) [Penaltis, AvancaEquipaA, AvancaMelhorSeed])
      [Just 1, Just 1, Just 1]
  , igual "perdedor: jogo normal" (perdedor Penaltis jogoNormal) (Just 8)
  , igual "perdedor: decidido por penaltis" (perdedor Penaltis meiaFinalEmpatada) (Just 3)
  , igual "perdedor: sem decisao" (perdedor Penaltis jogoEmpateSemPenaltis) Nothing

  -- Validação de jogos
  , verdade "jogoValido: jogo normal" (jogoValido jogoNormal)
  , verdade "jogoValido: jogo com penaltis" (jogoValido jogoPenaltis)
  , verdade "jogoValido: 0-0 sem penaltis e valido" (jogoValido jogoEmpateSemPenaltis)
  , verdade "jogoValido: golos negativos (A) e invalido"
      (not (jogoValido (Jogo Final 1 2 (-1) 0 Nothing)))
  , verdade "jogoValido: golos negativos (B) e invalido"
      (not (jogoValido (Jogo Final 1 2 0 (-1) Nothing)))
  , verdade "jogoValido: equipa contra si propria e invalido"
      (not (jogoValido (Jogo Final 3 3 1 0 Nothing)))
  , verdade "jogoValido: penaltis num jogo sem empate e invalido"
      (not (jogoValido (Jogo Final 1 2 2 0 (Just (3, 1)))))
  , verdade "jogoValido: penaltis negativos e invalido"
      (not (jogoValido (Jogo Final 1 2 1 1 (Just (-1, 2)))))
  , verdade "jogoValido: jogoInvalidoExemplo e invalido" (not (jogoValido jogoInvalidoExemplo))
  , igual "jogosValidos: os jogos de exemplo sao todos validos"
      (jogosValidos jogosExemplo) jogosExemplo
  , igual "jogosValidos: remove o jogo invalido"
      (jogosValidos [jogoNormal, jogoInvalidoExemplo, jogoPenaltis])
      [jogoNormal, jogoPenaltis]
  , igual "jogosValidos []" (jogosValidos []) []

  -- Listas de jogos (recursão)
  , igual "jogosDaFase QuartosFinal: 4 jogos" (length (jogosDaFase QuartosFinal jogosExemplo)) 4
  , igual "jogosDaFase MeiaFinal: 2 jogos" (length (jogosDaFase MeiaFinal jogosExemplo)) 2
  , igual "jogosDaFase Final: 1 jogo" (length (jogosDaFase Final jogosExemplo)) 1
  , igual "jogosDaFase OitavosFinal: nenhum" (jogosDaFase OitavosFinal jogosExemplo) []
  , igual "jogosDaFase []" (jogosDaFase Final []) []
  , igual "jogosDaEquipa 1: 3 jogos" (length (jogosDaEquipa 1 jogosExemplo)) 3
  , igual "jogosDaEquipa: equipa inexistente" (jogosDaEquipa 99 jogosExemplo) []
  , igual "jogosDaEquipa []" (jogosDaEquipa 1 []) []
  , igual "contarJogos: jogos de cada equipa"
      (map (\e -> contarJogos e jogosExemplo) ids) [3, 2, 2, 1, 3, 1, 1, 1]
  , igual "contarJogos []" (contarJogos 1 []) 0
  , igual "golosMarcadosEquipa: de cada equipa"
      (map (\e -> golosMarcadosEquipa e jogosExemplo) ids) [8, 1, 3, 0, 4, 1, 1, 0]
  , igual "golosSofridosEquipa: de cada equipa"
      (map (\e -> golosSofridosEquipa e jogosExemplo) ids) [1, 3, 2, 2, 4, 2, 1, 3]
  , igual "golosMarcadosEquipa []" (golosMarcadosEquipa 1 []) 0
  , igual "contarVitorias (penaltis): de cada equipa"
      (map (\e -> contarVitorias Penaltis e jogosExemplo) ids) [3, 1, 1, 0, 2, 0, 0, 0]
  , igual "contarDerrotas (penaltis): de cada equipa"
      (map (\e -> contarDerrotas Penaltis e jogosExemplo) ids) [0, 1, 1, 1, 1, 1, 1, 1]
  , igual "contarVitorias []" (contarVitorias Penaltis 1 []) 0
  , igual "contarDerrotas []" (contarDerrotas Penaltis 1 []) 0
  , verdade "foiEliminada: a equipa 1 (campea) nunca perde"
      (not (foiEliminada Penaltis 1 jogosExemplo))
  , verdade "foiEliminada: a equipa 5 perdeu a final"
      (foiEliminada Penaltis 5 jogosExemplo)
  , verdade "foiEliminada: a equipa 8 perdeu nos quartos"
      (foiEliminada Penaltis 8 jogosExemplo)
  , verdade "foiEliminada: com AvancaEquipaA a equipa 3 nao e eliminada"
      (not (foiEliminada AvancaEquipaA 3 jogosExemplo))
  , verdade "foiEliminada []" (not (foiEliminada Penaltis 1 []))
  , igual "vencedoresDaFase: quartos de final (penaltis)"
      (vencedoresDaFase Penaltis QuartosFinal jogosExemplo) [1, 2, 3, 5]
  , igual "vencedoresDaFase: meias-finais (penaltis)"
      (vencedoresDaFase Penaltis MeiaFinal jogosExemplo) [1, 5]
  , igual "vencedoresDaFase: meias-finais (AvancaEquipaA)"
      (vencedoresDaFase AvancaEquipaA MeiaFinal jogosExemplo) [1, 3]
  , igual "vencedoresDaFase: final" (vencedoresDaFase Penaltis Final jogosExemplo) [1]
  , igual "vencedoresDaFase: fase sem jogos" (vencedoresDaFase Penaltis OitavosFinal jogosExemplo) []
  , igual "vencedoresDaFase: ignora jogos que nao se decidem"
      (vencedoresDaFase Penaltis QuartosFinal [jogoNormal, jogoEmpateSemPenaltis]) [1]
  , igual "campeao (penaltis)" (campeao Penaltis jogosExemplo) (Just 1)
  , igual "campeao: ainda sem final" (campeao Penaltis (jogosDaFase QuartosFinal jogosExemplo)) Nothing
  , igual "campeao []" (campeao Penaltis []) Nothing
  , igual "campeao: final empatada sem decisao"
      (campeao Penaltis [Jogo Final 1 2 1 1 Nothing]) Nothing

  -- Estatísticas de equipa
  , igual "estatisticasEquipa 1 (Aguias FC)" (estExemplo 1) (EstatisticasEquipa 1 3 3 0 8 1)
  , igual "estatisticasEquipa 2 (Dragoes FC)" (estExemplo 2) (EstatisticasEquipa 2 2 1 1 1 3)
  , igual "estatisticasEquipa 5 (Lobos FC)" (estExemplo 5) (EstatisticasEquipa 5 3 2 1 4 4)
  , igual "estatisticasEquipa 8 (Corvos FC)" (estExemplo 8) (EstatisticasEquipa 8 1 0 1 0 3)
  , verdade "estatisticas: jogos = vitorias + derrotas (todas as equipas)"
      (and [ estJogos s == estVitorias s + estDerrotas s
           | s <- tabelaEstatisticas Penaltis equipasExemplo jogosExemplo ])
  , verdade "estatisticas: golos marcados = golos sofridos (no total)"
      (somaMarcados (tabelaEstatisticas Penaltis equipasExemplo jogosExemplo)
         == somaSofridos (tabelaEstatisticas Penaltis equipasExemplo jogosExemplo))
  , igual "tabelaEstatisticas: uma linha por equipa"
      (length (tabelaEstatisticas Penaltis equipasExemplo jogosExemplo)) 8
  , igual "tabelaEstatisticas []" (tabelaEstatisticas Penaltis [] jogosExemplo) []

  -- Emparelhamentos
  , igual "emparelhar [1,2,3,4]" (emparelhar [1, 2, 3, 4 :: Int]) [(1, 2), (3, 4)]
  , igual "emparelhar: elemento a mais e ignorado" (emparelhar [1, 2, 3 :: Int]) [(1, 2)]
  , igual "emparelhar []" (emparelhar ([] :: [Int])) []
  , igual "emparelharSeeds [1..8]"
      (emparelharSeeds [1 .. 8 :: Int]) [(1, 8), (2, 7), (3, 6), (4, 5)]
  , igual "emparelharSeeds [1..4]" (emparelharSeeds [1 .. 4 :: Int]) [(1, 4), (2, 3)]
  , igual "emparelharSeeds [1,2]" (emparelharSeeds [1, 2 :: Int]) [(1, 2)]
  , igual "emparelharSeeds [1,2,3]: o do meio sobra" (emparelharSeeds [1, 2, 3 :: Int]) [(1, 3)]
  , igual "emparelharSeeds []" (emparelharSeeds ([] :: [Int])) []
  , igual "emparelharSeeds [1]" (emparelharSeeds [1 :: Int]) []
  , igual "idsDasEquipas" (idsDasEquipas equipasExemplo) ids
  , igual "idsDasEquipas []" (idsDasEquipas []) []
  , igual "primeiraRonda"
      (primeiraRonda equipasExemplo) [(1, 8), (2, 7), (3, 6), (4, 5)]
  , igual "primeiraRonda coincide com os jogos dos quartos de final"
      (primeiraRonda equipasExemplo)
      [ (equipaA j, equipaB j) | j <- jogosDaFase QuartosFinal jogosExemplo ]
  , igual "proximaRonda: meias-finais (penaltis)"
      (proximaRonda Penaltis QuartosFinal jogosExemplo) [(1, 2), (3, 5)]
  , igual "proximaRonda coincide com os jogos das meias-finais"
      (proximaRonda Penaltis QuartosFinal jogosExemplo)
      [ (equipaA j, equipaB j) | j <- jogosDaFase MeiaFinal jogosExemplo ]
  , igual "proximaRonda: final (penaltis)" (proximaRonda Penaltis MeiaFinal jogosExemplo) [(1, 5)]
  , igual "proximaRonda: final (AvancaEquipaA)"
      (proximaRonda AvancaEquipaA MeiaFinal jogosExemplo) [(1, 3)]
  , igual "proximaRonda: sem jogos" (proximaRonda Penaltis QuartosFinal []) []

  -- Pesquisa
  , igual "procurarEquipaPorId 3 devolve Leoes FC"
      (fmap nomeEquipa (procurarEquipaPorId 3 equipasExemplo)) (Just "Leoes FC")
  , igual "procurarEquipaPorId: id inexistente"
      (fmap nomeEquipa (procurarEquipaPorId 99 equipasExemplo)) Nothing
  , igual "procurarEquipaPorNome devolve o id certo"
      (fmap idEquipa (procurarEquipaPorNome "Lobos FC" equipasExemplo)) (Just 5)
  , igual "procurarEquipaPorNome: nome inexistente"
      (fmap idEquipa (procurarEquipaPorNome "Ninguem FC" equipasExemplo)) Nothing
  , igual "nomeDaEquipa: equipa existente" (nomeDaEquipa 4 equipasExemplo) "Falcoes FC"
  , igual "nomeDaEquipa: equipa inexistente" (nomeDaEquipa 99 equipasExemplo) "Equipa desconhecida"
  , igual "procurarJogador: encontra o golos certo"
      (fmap golosJogador (procurarJogador "Ruben Costa" equipasExemplo)) (Just 3)
  , igual "procurarJogador: jogador inexistente"
      (fmap golosJogador (procurarJogador "Ninguem" equipasExemplo)) Nothing
  , igual "procurarJogador: sem equipas" (procurarJogador "Ruben Costa" []) Nothing

  -- Estatísticas individuais
  , igual "golosPlantel: Aguias FC" (golosPlantel (plantelDe 1)) 8
  , igual "golosPlantel []" (golosPlantel []) 0
  , igual "assistenciasPlantel: Aguias FC" (assistenciasPlantel (plantelDe 1)) 5
  , igual "assistenciasPlantel []" (assistenciasPlantel []) 0
  , igual "cartoesPlantel: Aguias FC (so amarelos)" (cartoesPlantel (plantelDe 1)) 2
  , igual "cartoesPlantel: Dragoes FC (amarelos e vermelho)" (cartoesPlantel (plantelDe 2)) 4
  , igual "cartoesPlantel []" (cartoesPlantel []) 0
  , verdade "golosEquipa coincide com os golos marcados nos jogos (todas as equipas)"
      (and [ golosEquipa e == golosMarcadosEquipa (idEquipa e) jogosExemplo
           | e <- equipasExemplo ])
  , igual "contarPorPosicao: 1 avancado nas Aguias FC" (contarPorPosicao Avancado (plantelDe 1)) 1
  , igual "contarPorPosicao: 1 guarda-redes nas Aguias FC" (contarPorPosicao GuardaRedes (plantelDe 1)) 1
  , igual "contarPorPosicao: nenhum defesa nas Aguias FC" (contarPorPosicao Defesa (plantelDe 1)) 0
  , igual "contarPorPosicao []" (contarPorPosicao Avancado []) 0
  , igual "melhorMarcador: Aguias FC" (nomeMelhor (plantelDe 1)) (Just "Tiago Ramos")
  , igual "melhorMarcador: Lobos FC" (nomeMelhor (plantelDe 5)) (Just "Ruben Costa")
  , igual "melhorMarcador: plantel vazio" (nomeMelhor []) Nothing
  , igual "melhorMarcador: empate fica o primeiro da lista"
      (nomeMelhor plantelEmpatado) (Just "Primeiro")
  , igual "melhorMarcador: todos a zero fica o primeiro"
      (nomeMelhor (plantelDe 4)) (Just "Filipe Rocha")
  , igual "melhorMarcadorTorneio"
      (fmap nomeJogador (melhorMarcadorTorneio equipasExemplo)) (Just "Tiago Ramos")
  , igual "melhorMarcadorTorneio: sem equipas" (melhorMarcadorTorneio []) Nothing
  , igual "melhorMarcadorTorneio: equipas sem jogadores"
      (melhorMarcadorTorneio [Equipa 1 "Vazia" "Lisboa" []]) Nothing

  -- Apresentação (funções de formatação)
  , igual "alinharEsquerda 5 \"ab\"" (alinharEsquerda 5 "ab") "ab   "
  , igual "alinharDireita 5 \"ab\""  (alinharDireita 5 "ab") "   ab"
  , igual "alinharEsquerda: texto maior que a largura fica igual" (alinharEsquerda 2 "abcd") "abcd"
  , igual "alinharDireita: texto maior que a largura fica igual" (alinharDireita 2 "abcd") "abcd"
  , igual "repetir 3 'x'" (repetir 3 'x') "xxx"
  , igual "repetir 0 'x'" (repetir 0 'x') ""
  , igual "repetir: negativo da lista vazia" (repetir (-2) 'x') ""
  , igual "nomeDaFase: as 4 fases"
      (map nomeDaFase [OitavosFinal, QuartosFinal, MeiaFinal, Final])
      ["Oitavos de final", "Quartos de final", "Meias-finais", "Final"]
  , igual "mostrarJogo: jogo normal"
      (mostrarJogo equipasExemplo jogoNormal)
      "Quartos de final: Aguias FC 3 - 0 Corvos FC"
  , igual "mostrarJogo: jogo com penaltis"
      (mostrarJogo equipasExemplo jogoPenaltis)
      "Quartos de final: Dragoes FC 1 - 1 Touros FC (penaltis 4-3)"
  , igual "mostrarEstatisticas: cabecalho + 8 linhas"
      (length (mostrarEstatisticas equipasExemplo
                 (tabelaEstatisticas Penaltis equipasExemplo jogosExemplo)))
      9
      , igual "proximaFase MeiaFinal" (proximaFase MeiaFinal) (Just Final)
  , igual "fasesDesde MeiaFinal" (fasesDesde MeiaFinal) [MeiaFinal, Final]
  , igual "numeroDeRondas 4 = 2" (numeroDeRondas 4) 2
  , igual "faseInicial 4" (faseInicial 4) (Just MeiaFinal)
  ]

-- | Soma dos golos marcados de uma lista de estatísticas.
somaMarcados :: [EstatisticasEquipa] -> Int
somaMarcados []       = 0
somaMarcados (s : ss) = estGolosMarcados s + somaMarcados ss

-- | Soma dos golos sofridos de uma lista de estatísticas.
somaSofridos :: [EstatisticasEquipa] -> Int
somaSofridos []       = 0
somaSofridos (s : ss) = estGolosSofridos s + somaSofridos ss

-- ---------------------------------------------------------------------------
-- Execução
-- ---------------------------------------------------------------------------

main :: IO ()
main = do
  putStrLn "A executar os testes da Fase 1..."
  resultados <- mapM executar testes
  let total  = length resultados
      falhas = length (filter not resultados)
  putStrLn ""
  putStrLn (show (total - falhas) ++ "/" ++ show total ++ " testes passaram.")
  if falhas == 0 then exitSuccess else exitFailure
