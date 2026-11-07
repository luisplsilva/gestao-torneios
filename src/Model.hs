-- |
-- Módulo      : Model
-- Descrição   : Modelo de domínio do Sistema de Gestão de Torneios Eliminatórios.
--
-- Este módulo só tem a definição dos tipos de dados (sem lógica).
-- As relações entre entidades fazem-se com identificadores: um 'Jogo' guarda
-- os ids das duas equipas ('IdEquipa'), e não as equipas inteiras.
-- O id de uma equipa serve também de "seed" (cabeça de série): a equipa 1 é
-- a melhor cabeça de série.
module Model
  ( IdEquipa
  , Posicao (..)
  , Jogador (..)
  , Equipa (..)
  , Fase (..)
  , RegraEmpate (..)
  , Configuracao (..)
  , Jogo (..)
  , EstatisticasEquipa (..)
  , Torneio (..)
  ) where

-- | Identificador único de uma equipa (também é o seu seed).
type IdEquipa = Int

-- | Posição em que um jogador atua.
data Posicao
  = GuardaRedes
  | Defesa
  | MedioCampo
  | Avancado
  deriving (Show, Eq)

-- | Um jogador, com as suas estatísticas individuais no torneio.
data Jogador = Jogador
  { nomeJogador        :: String
  , numeroCamisola     :: Int
  , posicaoJogador     :: Posicao
  , golosJogador       :: Int
  , assistenciasJogador :: Int
  , amarelosJogador    :: Int
  , vermelhosJogador   :: Int
  , jogosJogador       :: Int
  } deriving (Show, Eq)

-- | Uma equipa, com o respetivo plantel.
data Equipa = Equipa
  { idEquipa     :: IdEquipa
  , nomeEquipa   :: String
  , cidadeEquipa :: String
  , plantel      :: [Jogador]
  } deriving (Show, Eq)

-- | Fases de um torneio eliminatório (de uma ronda para a seguinte
-- o número de equipas reduz-se para metade).
data Fase
  = OitavosFinal   -- ^ 16 equipas
  | QuartosFinal   -- ^ 8 equipas
  | MeiaFinal      -- ^ 4 equipas
  | Final          -- ^ 2 equipas
  deriving (Show, Eq)

-- | O que fazer quando um jogo acaba empatado. É o administrador do
-- torneio que escolhe a regra.
data RegraEmpate
  = Penaltis         -- ^ decide o desempate por grandes penalidades
  | AvancaEquipaA    -- ^ avança a primeira equipa do jogo (a "da casa")
  | AvancaMelhorSeed -- ^ avança a equipa com menor id (melhor seed)
  deriving (Show, Eq)

-- | Opções do torneio, definidas pelo administrador.
data Configuracao = Configuracao
  { regraEmpate   :: RegraEmpate
  , numeroEquipas :: Int          -- ^ 2, 4, 8 ou 16
  } deriving (Show, Eq)

-- | Um jogo entre duas equipas (referidas pelo seu id). Os golos são os do
-- tempo regulamentar; as grandes penalidades (se existirem) vão à parte.
data Jogo = Jogo
  { fase      :: Fase
  , equipaA   :: IdEquipa
  , equipaB   :: IdEquipa
  , golosA    :: Int
  , golosB    :: Int
  , penaltis  :: Maybe (Int, Int)  -- ^ golos nas penalidades (A, B)
  } deriving (Show, Eq)

-- | Estatísticas de uma equipa no torneio.
data EstatisticasEquipa = EstatisticasEquipa
  { estEquipa        :: IdEquipa
  , estJogos         :: Int
  , estVitorias      :: Int
  , estDerrotas      :: Int
  , estGolosMarcados :: Int
  , estGolosSofridos :: Int
  } deriving (Show, Eq)

-- | Um torneio: nome, configuração, equipas inscritas e jogos realizados.
data Torneio = Torneio
  { nomeTorneio      :: String
  , configuracao     :: Configuracao
  , equipasTorneio   :: [Equipa]
  , jogosTorneio     :: [Jogo]
  } deriving (Show, Eq)
