-- |
-- Módulo      : Main
-- Descrição   : Demonstração da Fase 1 (único módulo com IO).
--
-- Mostra, com os dados de 'SampleData', as principais funções do domínio.
module Main (main) where

import Display
import Domain
import Model
import SampleData

main :: IO ()
main = do
  let torneio = torneioExemplo
      cfg     = configuracao torneio
      regra   = regraEmpate cfg
      es      = equipasTorneio torneio
      js      = jogosTorneio torneio

  putStrLn "=== Gestao de Torneios Eliminatorios - Fase 1 ==="
  putStrLn ("Torneio: " ++ nomeTorneio torneio)
  putStrLn ("Equipas: " ++ show (numeroEquipas cfg)
              ++ " | Regra de empate: " ++ show regra
              ++ " | Configuracao valida: " ++ show (configuracaoValida cfg))
  putStrLn ("Numero de rondas: " ++ show (numeroDeRondas (numeroEquipas cfg)))

  titulo "Equipas"
  mostrarEquipas es

  titulo "Primeira ronda (emparelhamento por seeds)"
  mostrarPares es (primeiraRonda es)

  titulo "Jogos"
  mostrarJogos es js

  titulo "Quem avancou em cada fase"
  mostrarAvancos es regra js (fasesDesde QuartosFinal)

  titulo "Campeao"
  case campeao regra js of
    Nothing -> putStrLn "A final ainda nao foi decidida."
    Just i  -> putStrLn (nomeDaEquipa i es)

  titulo "Estatisticas das equipas"
  mapM_ putStrLn (mostrarEstatisticas es (tabelaEstatisticas regra es js))

  titulo "Estatisticas individuais"
  case melhorMarcadorTorneio es of
    Nothing -> putStrLn "Sem jogadores."
    Just j  -> putStrLn ("Melhor marcador do torneio: " ++ nomeJogador j
                           ++ " (" ++ show (golosJogador j) ++ " golos, "
                           ++ show (assistenciasJogador j) ++ " assistencias)")
  case procurarEquipaPorNome "Lobos FC" es of
    Nothing -> putStrLn "Equipa nao encontrada."
    Just e  -> putStrLn ("Lobos FC: " ++ show (golosEquipa e) ++ " golos, "
                           ++ show (assistenciasPlantel (plantel e)) ++ " assistencias, "
                           ++ show (cartoesPlantel (plantel e)) ++ " cartoes")

  titulo "A regra de empate escolhida pelo administrador muda o resultado"
  putStrLn ("Meia-final empatada: " ++ mostrarJogo es meiaFinalEmpatada)
  mostrarRegra es Penaltis
  mostrarRegra es AvancaEquipaA
  mostrarRegra es AvancaMelhorSeed

  titulo "Validacao"
  putStrLn ("Jogo valido?   " ++ mostrarJogo es jogoNormal
              ++ " -> " ++ show (jogoValido jogoNormal))
  putStrLn ("Jogo invalido? (golos negativos, equipa contra si propria) -> "
              ++ show (jogoValido jogoInvalidoExemplo))

-- | Um jogo normal, usado para demonstrar a validação.
jogoNormal :: Jogo
jogoNormal = Jogo QuartosFinal 1 8 3 0 Nothing

-- | Uma meia-final empatada no tempo regulamentar (3 vs 5), decidida nas
-- penalidades a favor da equipa 5.
meiaFinalEmpatada :: Jogo
meiaFinalEmpatada = Jogo MeiaFinal 3 5 1 1 (Just (3, 4))

-- | Escreve o título de uma secção.
titulo :: String -> IO ()
titulo t = putStrLn ("\n--- " ++ t ++ " ---")

-- | Escreve as equipas, uma por linha.
mostrarEquipas :: [Equipa] -> IO ()
mostrarEquipas [] = return ()
mostrarEquipas (e : es) = do
  putStrLn (show (idEquipa e) ++ " - " ++ nomeEquipa e
              ++ " (" ++ cidadeEquipa e ++ "), "
              ++ show (length (plantel e)) ++ " jogadores")
  mostrarEquipas es

-- | Escreve pares de equipas (jogos ainda por realizar).
mostrarPares :: [Equipa] -> [(IdEquipa, IdEquipa)] -> IO ()
mostrarPares _ [] = return ()
mostrarPares es ((a, b) : ps) = do
  putStrLn (nomeDaEquipa a es ++ " vs " ++ nomeDaEquipa b es)
  mostrarPares es ps

-- | Escreve os jogos, um por linha.
mostrarJogos :: [Equipa] -> [Jogo] -> IO ()
mostrarJogos _ [] = return ()
mostrarJogos es (j : js) = do
  putStrLn (mostrarJogo es j)
  mostrarJogos es js

-- | Para cada fase, escreve as equipas que avançaram.
mostrarAvancos :: [Equipa] -> RegraEmpate -> [Jogo] -> [Fase] -> IO ()
mostrarAvancos _ _ _ [] = return ()
mostrarAvancos es r js (f : fs) = do
  putStrLn (nomeDaFase f ++ ": " ++ nomes (vencedoresDaFase r f js))
  mostrarAvancos es r js fs
  where
    nomes :: [IdEquipa] -> String
    nomes []       = "-"
    nomes [i]      = nomeDaEquipa i es
    nomes (i : is) = nomeDaEquipa i es ++ ", " ++ nomes is

-- | Mostra quem avança na meia-final empatada com uma dada regra.
mostrarRegra :: [Equipa] -> RegraEmpate -> IO ()
mostrarRegra es r =
  case vencedor r meiaFinalEmpatada of
    Nothing -> putStrLn ("  " ++ show r ++ " -> nao e possivel decidir")
    Just i  -> putStrLn ("  " ++ show r ++ " -> avanca " ++ nomeDaEquipa i es)
