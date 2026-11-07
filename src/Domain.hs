-- |
-- Módulo      : Domain
-- Descrição   : Regras do domínio (funções puras) de um torneio eliminatório.
--
-- Todas as funções deste módulo são puras (não fazem IO). Nesta fase, as
-- funções sobre listas são definidas por recursão explícita e pattern
-- matching, em vez de usar funções de ordem superior (que ficam para a
-- Fase 2).
module Domain
  ( -- * Fases e configuração
    equipasNaFase
  , proximaFase
  , fasesDesde
  , faseInicial
  , potenciaDeDois
  , numeroDeRondas
  , configuracaoValida
    -- * Um jogo
  , participa
  , golosMarcadosNoJogo
  , golosSofridosNoJogo
  , vencedor
  , perdedor
  , jogoValido
    -- * Listas de jogos (recursão)
  , jogosDaFase
  , jogosDaEquipa
  , jogosValidos
  , contarJogos
  , golosMarcadosEquipa
  , golosSofridosEquipa
  , contarVitorias
  , contarDerrotas
  , foiEliminada
  , vencedoresDaFase
  , campeao
    -- * Estatísticas de equipa
  , estatisticasEquipa
  , tabelaEstatisticas
    -- * Emparelhamentos (chaveamento)
  , emparelhar
  , emparelharSeeds
  , idsDasEquipas
  , primeiraRonda
  , proximaRonda
    -- * Pesquisa
  , procurarEquipaPorId
  , procurarEquipaPorNome
  , nomeDaEquipa
  , procurarJogador
    -- * Estatísticas individuais
  , golosPlantel
  , assistenciasPlantel
  , cartoesPlantel
  , golosEquipa
  , contarPorPosicao
  , melhorMarcador
  , melhorMarcadorTorneio
  ) where

import Model

-- ---------------------------------------------------------------------------
-- Fases e configuração
-- ---------------------------------------------------------------------------

-- | Número de equipas que jogam numa fase.
equipasNaFase :: Fase -> Int
equipasNaFase OitavosFinal = 16
equipasNaFase QuartosFinal = 8
equipasNaFase MeiaFinal    = 4
equipasNaFase Final        = 2

-- | A fase que vem a seguir (a final não tem fase seguinte).
proximaFase :: Fase -> Maybe Fase
proximaFase OitavosFinal = Just QuartosFinal
proximaFase QuartosFinal = Just MeiaFinal
proximaFase MeiaFinal    = Just Final
proximaFase Final        = Nothing

-- | Todas as fases, desde uma fase até à final.
--
-- >>> fasesDesde QuartosFinal
-- [QuartosFinal,MeiaFinal,Final]
fasesDesde :: Fase -> [Fase]
fasesDesde f =
  case proximaFase f of
    Nothing -> [f]
    Just p  -> f : fasesDesde p

-- | Fase em que um torneio começa, conforme o número de equipas.
faseInicial :: Int -> Maybe Fase
faseInicial 16 = Just OitavosFinal
faseInicial 8  = Just QuartosFinal
faseInicial 4  = Just MeiaFinal
faseInicial 2  = Just Final
faseInicial _  = Nothing

-- | Indica se um número é uma potência de 2 (1, 2, 4, 8, 16, ...).
-- Num torneio eliminatório o número de equipas tem de ser uma potência de 2,
-- para que cada ronda reduza as equipas exatamente para metade.
potenciaDeDois :: Int -> Bool
potenciaDeDois n
  | n < 1     = False
  | n == 1    = True
  | odd n     = False
  | otherwise = potenciaDeDois (n `div` 2)

-- | Número de rondas de um torneio com @n@ equipas (8 equipas -> 3 rondas).
numeroDeRondas :: Int -> Int
numeroDeRondas n
  | n <= 1    = 0
  | otherwise = 1 + numeroDeRondas (n `div` 2)

-- | Uma configuração é válida se o número de equipas for uma potência de 2
-- entre 2 e 16.
configuracaoValida :: Configuracao -> Bool
configuracaoValida c =
  potenciaDeDois (numeroEquipas c)
    && numeroEquipas c >= 2
    && numeroEquipas c <= 16

-- ---------------------------------------------------------------------------
-- Um jogo
-- ---------------------------------------------------------------------------

-- | Indica se uma equipa participa num jogo.
participa :: IdEquipa -> Jogo -> Bool
participa e jogo = e == equipaA jogo || e == equipaB jogo

-- | Golos marcados por uma equipa num jogo (0 se não participou).
golosMarcadosNoJogo :: IdEquipa -> Jogo -> Int
golosMarcadosNoJogo e jogo
  | e == equipaA jogo = golosA jogo
  | e == equipaB jogo = golosB jogo
  | otherwise         = 0

-- | Golos sofridos por uma equipa num jogo (0 se não participou).
golosSofridosNoJogo :: IdEquipa -> Jogo -> Int
golosSofridosNoJogo e jogo
  | e == equipaA jogo = golosB jogo
  | e == equipaB jogo = golosA jogo
  | otherwise         = 0

-- | A equipa que passa à ronda seguinte. Se houver empate, a decisão depende
-- da regra escolhida pelo administrador. Devolve 'Nothing' quando não é
-- possível decidir (por exemplo, empate com a regra 'Penaltis' mas sem
-- penalidades registadas, ou penalidades empatadas).
vencedor :: RegraEmpate -> Jogo -> Maybe IdEquipa
vencedor regra jogo
  | golosA jogo > golosB jogo = Just (equipaA jogo)
  | golosA jogo < golosB jogo = Just (equipaB jogo)
  | otherwise                 = desempatar regra jogo

-- | Auxiliar de 'vencedor': decide um jogo empatado.
desempatar :: RegraEmpate -> Jogo -> Maybe IdEquipa
desempatar Penaltis jogo =
  case penaltis jogo of
    Nothing -> Nothing
    Just (pa, pb)
      | pa > pb   -> Just (equipaA jogo)
      | pb > pa   -> Just (equipaB jogo)
      | otherwise -> Nothing
desempatar AvancaEquipaA jogo    = Just (equipaA jogo)
desempatar AvancaMelhorSeed jogo = Just (min (equipaA jogo) (equipaB jogo))

-- | A equipa que fica eliminada num jogo.
perdedor :: RegraEmpate -> Jogo -> Maybe IdEquipa
perdedor regra jogo =
  case vencedor regra jogo of
    Nothing -> Nothing
    Just v
      | v == equipaA jogo -> Just (equipaB jogo)
      | otherwise         -> Just (equipaA jogo)

-- | Um jogo é válido se tiver golos não negativos, duas equipas diferentes
-- e, caso tenha penalidades, se estas forem não negativas e o jogo tiver
-- acabado empatado.
jogoValido :: Jogo -> Bool
jogoValido jogo =
  golosA jogo >= 0
    && golosB jogo >= 0
    && equipaA jogo /= equipaB jogo
    && penaltisValidos jogo

-- | Auxiliar de 'jogoValido'.
penaltisValidos :: Jogo -> Bool
penaltisValidos jogo =
  case penaltis jogo of
    Nothing       -> True
    Just (pa, pb) -> pa >= 0 && pb >= 0 && golosA jogo == golosB jogo

-- ---------------------------------------------------------------------------
-- Listas de jogos (recursão sobre listas)
-- ---------------------------------------------------------------------------

-- | Jogos de uma determinada fase.
jogosDaFase :: Fase -> [Jogo] -> [Jogo]
jogosDaFase _ [] = []
jogosDaFase f (j : js)
  | fase j == f = j : jogosDaFase f js
  | otherwise   = jogosDaFase f js

-- | Jogos em que uma equipa participou.
jogosDaEquipa :: IdEquipa -> [Jogo] -> [Jogo]
jogosDaEquipa _ [] = []
jogosDaEquipa e (j : js)
  | participa e j = j : jogosDaEquipa e js
  | otherwise     = jogosDaEquipa e js

-- | Mantém apenas os jogos válidos.
jogosValidos :: [Jogo] -> [Jogo]
jogosValidos [] = []
jogosValidos (j : js)
  | jogoValido j = j : jogosValidos js
  | otherwise    = jogosValidos js

-- | Número de jogos em que uma equipa participou.
contarJogos :: IdEquipa -> [Jogo] -> Int
contarJogos _ [] = 0
contarJogos e (j : js)
  | participa e j = 1 + contarJogos e js
  | otherwise     = contarJogos e js

-- | Total de golos marcados por uma equipa.
golosMarcadosEquipa :: IdEquipa -> [Jogo] -> Int
golosMarcadosEquipa _ []       = 0
golosMarcadosEquipa e (j : js) = golosMarcadosNoJogo e j + golosMarcadosEquipa e js

-- | Total de golos sofridos por uma equipa.
golosSofridosEquipa :: IdEquipa -> [Jogo] -> Int
golosSofridosEquipa _ []       = 0
golosSofridosEquipa e (j : js) = golosSofridosNoJogo e j + golosSofridosEquipa e js

-- | Número de jogos que uma equipa ganhou.
contarVitorias :: RegraEmpate -> IdEquipa -> [Jogo] -> Int
contarVitorias _ _ [] = 0
contarVitorias r e (j : js)
  | vencedor r j == Just e = 1 + contarVitorias r e js
  | otherwise              = contarVitorias r e js

-- | Número de jogos que uma equipa perdeu.
contarDerrotas :: RegraEmpate -> IdEquipa -> [Jogo] -> Int
contarDerrotas _ _ [] = 0
contarDerrotas r e (j : js)
  | perdedor r j == Just e = 1 + contarDerrotas r e js
  | otherwise              = contarDerrotas r e js

-- | Num torneio eliminatório, uma equipa fica eliminada quando perde um jogo.
foiEliminada :: RegraEmpate -> IdEquipa -> [Jogo] -> Bool
foiEliminada _ _ [] = False
foiEliminada r e (j : js)
  | perdedor r j == Just e = True
  | otherwise              = foiEliminada r e js

-- | Equipas que venceram os jogos de uma fase (por ordem dos jogos).
-- São elas que jogam a fase seguinte.
vencedoresDaFase :: RegraEmpate -> Fase -> [Jogo] -> [IdEquipa]
vencedoresDaFase _ _ [] = []
vencedoresDaFase r f (j : js)
  | fase j == f =
      case vencedor r j of
        Just v  -> v : vencedoresDaFase r f js
        Nothing -> vencedoresDaFase r f js
  | otherwise = vencedoresDaFase r f js

-- | O campeão é o vencedor da final. 'Nothing' se a final ainda não foi
-- jogada (ou não se consegue decidir).
campeao :: RegraEmpate -> [Jogo] -> Maybe IdEquipa
campeao _ [] = Nothing
campeao r (j : js)
  | fase j == Final = vencedor r j
  | otherwise       = campeao r js

-- ---------------------------------------------------------------------------
-- Estatísticas de equipa
-- ---------------------------------------------------------------------------

-- | Estatísticas de uma equipa, calculadas a partir dos jogos.
estatisticasEquipa :: RegraEmpate -> IdEquipa -> [Jogo] -> EstatisticasEquipa
estatisticasEquipa r e js = EstatisticasEquipa
  { estEquipa        = e
  , estJogos         = contarJogos e js
  , estVitorias      = contarVitorias r e js
  , estDerrotas      = contarDerrotas r e js
  , estGolosMarcados = golosMarcadosEquipa e js
  , estGolosSofridos = golosSofridosEquipa e js
  }

-- | Estatísticas de todas as equipas (uma linha por equipa).
tabelaEstatisticas :: RegraEmpate -> [Equipa] -> [Jogo] -> [EstatisticasEquipa]
tabelaEstatisticas _ [] _        = []
tabelaEstatisticas r (e : es) js =
  estatisticasEquipa r (idEquipa e) js : tabelaEstatisticas r es js

-- ---------------------------------------------------------------------------
-- Emparelhamentos (chaveamento)
-- ---------------------------------------------------------------------------

-- | Junta os elementos de uma lista dois a dois, pela ordem em que estão.
-- Se sobrar um elemento, é ignorado.
--
-- >>> emparelhar [1, 2, 3, 4 :: Int]
-- [(1,2),(3,4)]
emparelhar :: [a] -> [(a, a)]
emparelhar (x : y : resto) = (x, y) : emparelhar resto
emparelhar _               = []

-- | Emparelha por seeds: o primeiro com o último, o segundo com o penúltimo,
-- e assim sucessivamente. É assim que se faz a primeira ronda, para que as
-- melhores equipas só se encontrem nas rondas finais.
--
-- >>> emparelharSeeds [1 .. 8 :: Int]
-- [(1,8),(2,7),(3,6),(4,5)]
emparelharSeeds :: [a] -> [(a, a)]
emparelharSeeds []       = []
emparelharSeeds [_]      = []
emparelharSeeds (x : xs) = (x, last xs) : emparelharSeeds (init xs)

-- | Ids de uma lista de equipas, pela mesma ordem.
idsDasEquipas :: [Equipa] -> [IdEquipa]
idsDasEquipas []       = []
idsDasEquipas (e : es) = idEquipa e : idsDasEquipas es

-- | Jogos da primeira ronda. As equipas têm de estar ordenadas por seed
-- (o id mais baixo primeiro).
primeiraRonda :: [Equipa] -> [(IdEquipa, IdEquipa)]
primeiraRonda es = emparelharSeeds (idsDasEquipas es)

-- | Jogos da ronda seguinte: os vencedores de uma fase, emparelhados dois a
-- dois pela ordem em que os jogos foram feitos.
proximaRonda :: RegraEmpate -> Fase -> [Jogo] -> [(IdEquipa, IdEquipa)]
proximaRonda r f js = emparelhar (vencedoresDaFase r f js)

-- ---------------------------------------------------------------------------
-- Pesquisa
-- ---------------------------------------------------------------------------

-- | Procura uma equipa pelo seu id.
procurarEquipaPorId :: IdEquipa -> [Equipa] -> Maybe Equipa
procurarEquipaPorId _ [] = Nothing
procurarEquipaPorId i (e : es)
  | idEquipa e == i = Just e
  | otherwise       = procurarEquipaPorId i es

-- | Procura uma equipa pelo seu nome (comparação exata).
procurarEquipaPorNome :: String -> [Equipa] -> Maybe Equipa
procurarEquipaPorNome _ [] = Nothing
procurarEquipaPorNome nome (e : es)
  | nomeEquipa e == nome = Just e
  | otherwise            = procurarEquipaPorNome nome es

-- | Nome de uma equipa a partir do seu id.
nomeDaEquipa :: IdEquipa -> [Equipa] -> String
nomeDaEquipa i es =
  case procurarEquipaPorId i es of
    Just equipa -> nomeEquipa equipa
    Nothing     -> "Equipa desconhecida"

-- | Procura um jogador pelo nome, em todas as equipas.
procurarJogador :: String -> [Equipa] -> Maybe Jogador
procurarJogador _ [] = Nothing
procurarJogador nome (e : es) =
  case procurarNoPlantel nome (plantel e) of
    Just jogador -> Just jogador
    Nothing      -> procurarJogador nome es

-- | Auxiliar de 'procurarJogador': procura num plantel.
procurarNoPlantel :: String -> [Jogador] -> Maybe Jogador
procurarNoPlantel _ [] = Nothing
procurarNoPlantel nome (j : js)
  | nomeJogador j == nome = Just j
  | otherwise             = procurarNoPlantel nome js

-- ---------------------------------------------------------------------------
-- Estatísticas individuais
-- ---------------------------------------------------------------------------

-- | Soma dos golos dos jogadores de um plantel.
golosPlantel :: [Jogador] -> Int
golosPlantel []       = 0
golosPlantel (j : js) = golosJogador j + golosPlantel js

-- | Soma das assistências dos jogadores de um plantel.
assistenciasPlantel :: [Jogador] -> Int
assistenciasPlantel []       = 0
assistenciasPlantel (j : js) = assistenciasJogador j + assistenciasPlantel js

-- | Soma dos cartões (amarelos e vermelhos) dos jogadores de um plantel.
cartoesPlantel :: [Jogador] -> Int
cartoesPlantel [] = 0
cartoesPlantel (j : js) =
  amarelosJogador j + vermelhosJogador j + cartoesPlantel js

-- | Golos marcados pelos jogadores de uma equipa.
golosEquipa :: Equipa -> Int
golosEquipa equipa = golosPlantel (plantel equipa)

-- | Número de jogadores de um plantel que jogam numa dada posição.
contarPorPosicao :: Posicao -> [Jogador] -> Int
contarPorPosicao _ [] = 0
contarPorPosicao p (j : js)
  | posicaoJogador j == p = 1 + contarPorPosicao p js
  | otherwise             = contarPorPosicao p js

-- | Escolhe o jogador com mais golos entre dois (ou o que existir).
-- Em caso de empate fica o primeiro.
melhorDe :: Maybe Jogador -> Maybe Jogador -> Maybe Jogador
melhorDe Nothing b = b
melhorDe a Nothing = a
melhorDe (Just a) (Just b)
  | golosJogador b > golosJogador a = Just b
  | otherwise                       = Just a

-- | Melhor marcador de um plantel ('Nothing' se estiver vazio).
melhorMarcador :: [Jogador] -> Maybe Jogador
melhorMarcador []       = Nothing
melhorMarcador (j : js) = melhorDe (Just j) (melhorMarcador js)

-- | Melhor marcador de todo o torneio.
melhorMarcadorTorneio :: [Equipa] -> Maybe Jogador
melhorMarcadorTorneio []       = Nothing
melhorMarcadorTorneio (e : es) =
  melhorDe (melhorMarcador (plantel e)) (melhorMarcadorTorneio es)
