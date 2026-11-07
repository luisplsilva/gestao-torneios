-- |
-- Módulo      : Display
-- Descrição   : Funções puras que transformam os dados em texto.
--
-- Estas funções só constroem 'String's; quem as imprime é o @Main@. Assim,
-- o IO fica separado do núcleo funcional.
module Display
  ( repetir
  , alinharEsquerda
  , alinharDireita
  , nomeDaFase
  , mostrarJogo
  , mostrarEstatisticas
  ) where

import Domain (nomeDaEquipa)
import Model

-- | Repete um carácter @n@ vezes (lista vazia se @n <= 0@).
repetir :: Int -> Char -> String
repetir n c
  | n <= 0    = []
  | otherwise = c : repetir (n - 1) c

-- | Preenche com espaços à direita até ter largura @n@.
alinharEsquerda :: Int -> String -> String
alinharEsquerda n s = s ++ repetir (n - length s) ' '

-- | Preenche com espaços à esquerda até ter largura @n@.
alinharDireita :: Int -> String -> String
alinharDireita n s = repetir (n - length s) ' ' ++ s

-- | Nome de uma fase, em texto.
nomeDaFase :: Fase -> String
nomeDaFase OitavosFinal = "Oitavos de final"
nomeDaFase QuartosFinal = "Quartos de final"
nomeDaFase MeiaFinal    = "Meias-finais"
nomeDaFase Final        = "Final"

-- | Texto de um jogo, por exemplo
-- @Quartos de final: Aguias FC 3 - 0 Corvos FC@.
mostrarJogo :: [Equipa] -> Jogo -> String
mostrarJogo es jogo =
  nomeDaFase (fase jogo) ++ ": "
    ++ nomeDaEquipa (equipaA jogo) es ++ " "
    ++ show (golosA jogo) ++ " - " ++ show (golosB jogo) ++ " "
    ++ nomeDaEquipa (equipaB jogo) es
    ++ textoPenaltis (penaltis jogo)

-- | Auxiliar de 'mostrarJogo': texto das penalidades (vazio se não houve).
textoPenaltis :: Maybe (Int, Int) -> String
textoPenaltis Nothing         = ""
textoPenaltis (Just (pa, pb)) = " (penaltis " ++ show pa ++ "-" ++ show pb ++ ")"

-- | Junta as colunas numéricas de uma linha, cada uma com largura 3.
colunas :: [String] -> String
colunas []       = ""
colunas (c : cs) = " " ++ alinharDireita 3 c ++ colunas cs

-- | Constrói uma linha da tabela: nome e colunas numéricas.
formatarLinha :: String -> [String] -> String
formatarLinha nome nums = alinharEsquerda 12 nome ++ colunas nums

-- | Texto de uma linha de estatísticas de equipa.
mostrarLinha :: [Equipa] -> EstatisticasEquipa -> String
mostrarLinha es e =
  formatarLinha (nomeDaEquipa (estEquipa e) es)
    [ show (estJogos e)
    , show (estVitorias e)
    , show (estDerrotas e)
    , show (estGolosMarcados e)
    , show (estGolosSofridos e)
    ]

-- | Estatísticas das equipas como lista de linhas de texto (cabeçalho incluído).
mostrarEstatisticas :: [Equipa] -> [EstatisticasEquipa] -> [String]
mostrarEstatisticas es ests = cabecalho : linhas ests
  where
    cabecalho = formatarLinha "Equipa" ["J", "V", "D", "GM", "GS"]

    linhas :: [EstatisticasEquipa] -> [String]
    linhas []       = []
    linhas (e : xs) = mostrarLinha es e : linhas xs
