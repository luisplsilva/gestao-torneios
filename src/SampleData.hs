-- |
-- Módulo      : SampleData
-- Descrição   : Dados de teste (fictícios) para demonstrar as funções.
--
-- Um torneio eliminatório com 8 equipas: 4 jogos nos quartos de final,
-- 2 nas meias-finais e 1 na final (7 jogos). Há dois jogos empatados no tempo
-- regulamentar, decididos por penalidades, para mostrar como a regra de
-- empate muda o resultado.
--
-- Os golos dos jogadores de cada equipa somam exatamente os golos que a
-- equipa marcou nos jogos, o que permite verificar a consistência dos dados
-- nos testes.
module SampleData
  ( equipasExemplo
  , jogosExemplo
  , jogoInvalidoExemplo
  , configuracaoExemplo
  , torneioExemplo
  ) where

import Model

-- | As oito equipas (o id é o seed: a equipa 1 é a melhor cabeça de série).
equipasExemplo :: [Equipa]
equipasExemplo =
  [ Equipa 1 "Aguias FC" "Lisboa"
      [ Jogador "Miguel Santos" 1  GuardaRedes 0 0 0 0 3
      , Jogador "Joao Pereira"  8  MedioCampo  2 4 1 0 3
      , Jogador "Tiago Ramos"   9  Avancado    6 1 1 0 3
      ]
  , Equipa 2 "Dragoes FC" "Porto"
      [ Jogador "Carlos Faria"  1  GuardaRedes 0 0 0 0 2
      , Jogador "Nuno Pinto"    6  MedioCampo  0 1 2 0 2
      , Jogador "Diogo Matos"   10 Avancado    1 0 1 1 2
      ]
  , Equipa 3 "Leoes FC" "Braga"
      [ Jogador "Ricardo Sousa" 1  GuardaRedes 0 0 0 0 2
      , Jogador "Hugo Barros"   5  MedioCampo  1 2 1 0 2
      , Jogador "Daniel Moreira" 9 Avancado    2 0 0 0 2
      ]
  , Equipa 4 "Falcoes FC" "Coimbra"
      [ Jogador "Filipe Rocha"  1  GuardaRedes 0 0 0 0 1
      , Jogador "Paulo Vieira"  3  Defesa      0 0 1 0 1
      , Jogador "Sergio Cunha"  7  Avancado    0 0 0 0 1
      ]
  , Equipa 5 "Lobos FC" "Faro"
      [ Jogador "Andre Lopes"     1  GuardaRedes 0 0 0 0 3
      , Jogador "Bruno Teixeira"  4  Defesa      1 0 2 0 3
      , Jogador "Ruben Costa"     11 Avancado    3 1 1 0 3
      ]
  , Equipa 6 "Tubaroes FC" "Setubal"
      [ Jogador "Rui Alves"     1  GuardaRedes 0 0 0 0 1
      , Jogador "Luis Neves"    6  MedioCampo  0 0 0 0 1
      , Jogador "Pedro Gomes"   9  Avancado    1 0 0 0 1
      ]
  , Equipa 7 "Touros FC" "Evora"
      [ Jogador "Hugo Dias"     1  GuardaRedes 0 0 0 0 1
      , Jogador "Vasco Rocha"   2  Defesa      0 0 1 0 1
      , Jogador "Ivo Marques"   10 Avancado    1 0 0 0 1
      ]
  , Equipa 8 "Corvos FC" "Viseu"
      [ Jogador "Jose Ferreira" 1  GuardaRedes 0 0 0 0 1
      , Jogador "Joel Santos"   4  Defesa      0 0 0 1 1
      , Jogador "Marco Pires"   9  Avancado    0 0 1 0 1
      ]
  ]

-- | Os 7 jogos do torneio
-- (Jogo fase equipaA equipaB golosA golosB penaltis).
jogosExemplo :: [Jogo]
jogosExemplo =
  [ Jogo QuartosFinal 1 8 3 0 Nothing
  , Jogo QuartosFinal 2 7 1 1 (Just (4, 3))
  , Jogo QuartosFinal 3 6 2 1 Nothing
  , Jogo QuartosFinal 4 5 0 2 Nothing
  , Jogo MeiaFinal    1 2 2 0 Nothing
  , Jogo MeiaFinal    3 5 1 1 (Just (3, 4))
  , Jogo Final        1 5 3 1 Nothing
  ]

-- | Um jogo inválido (golos negativos e uma equipa a jogar contra si
-- própria), usado para demonstrar a validação.
jogoInvalidoExemplo :: Jogo
jogoInvalidoExemplo = Jogo QuartosFinal 1 1 (-1) 0 Nothing

-- | Configuração de exemplo: 8 equipas e empates decididos por penalidades.
configuracaoExemplo :: Configuracao
configuracaoExemplo = Configuracao
  { regraEmpate   = Penaltis
  , numeroEquipas = 8
  }

-- | O torneio de exemplo completo.
torneioExemplo :: Torneio
torneioExemplo = Torneio
  { nomeTorneio    = "Taca Exemplo"
  , configuracao   = configuracaoExemplo
  , equipasTorneio = equipasExemplo
  , jogosTorneio   = jogosExemplo
  }
