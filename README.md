# Własny model xG (expected goals) na danych StatsBomb Open Data

Projekt z przedmiotu *Projekt z zakresu analizy danych* (Politechnika Lubelska, Inżynieria i Analiza Danych).

Autorzy: Paweł Pikula, Sebastian Soleme, Olaf Niedziela

## Cel

Zbudować własny model **expected goals (xG)**, czyli prawdopodobieństwa, że dany strzał zakończy się golem, na podstawie cech strzału (położenie, część ciała, presja obrońców, typ akcji itd.). Model porównamy z xG publikowanym przez StatsBomb, a następnie użyjemy go do analizy zawodników i drużyn (gole − xG).

## Dane

Dane pochodzą z [StatsBomb Open Data](https://github.com/statsbomb/open-data). Wybrane rozgrywki:

- Premier League 2015/16
- Mundial 2018
- Mundial 2022
- Euro 2020
- Euro 2024

Łącznie 610 meczów. Surowe pliki JSON (po jednym na mecz) nie są częścią repozytorium, bo zajmują setki MB. Odtwarza je skrypt `scripts/00_pobierz_surowe.R`.

Data provided by StatsBomb. Dane są udostępnione na warunkach opisanych w repozytorium StatsBomb Open Data.

## Struktura projektu

    scripts/
      00_pobierz_surowe.R   pobiera surowe pliki JSON do data/raw
      01_wczytanie.R        wyciąga strzały ze wszystkich meczów do jednej tabeli
    data/
      raw/                  surowe JSON (poza repozytorium, tworzone przez skrypt 00)
      processed/            tabele po przetworzeniu

## Jak uruchomić

1. Otwórz `projekt_xg.Rproj` w RStudio (wtedy katalog roboczy to folder projektu).
2. Zainstaluj pakiet: `install.packages("jsonlite")`.
3. Uruchom `scripts/00_pobierz_surowe.R` (pobieranie trwa kilkanaście minut; skrypt można przerwać i uruchomić ponownie, pobrane pliki są pomijane).
4. Uruchom `scripts/01_wczytanie.R`.

## Status

- [x] Pobranie danych (610 meczów)
- [x] Wczytanie strzałów do jednej tabeli (ok. 15,7 tys. strzałów)
- [ ] Filtrowanie (bez rzutów karnych i serii karnych) i zapis do CSV
- [ ] Cechy: odległość i kąt strzału
- [ ] Analiza eksploracyjna i testy statystyczne
- [ ] Modele i porównanie ze StatsBomb xG
- [ ] Analiza zawodników i drużyn