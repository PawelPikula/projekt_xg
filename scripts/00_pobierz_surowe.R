# ============================================================
#  00_pobierz_surowe.R
#  Pobiera surowe pliki JSON meczów ze StatsBomb Open Data
#  do folderu data/raw. NIC nie przetwarza, tylko ściąga.
#  Można przerwać i uruchomić ponownie: pobrane pliki są pomijane.
# ============================================================

library(jsonlite)

BAZA <- "https://raw.githubusercontent.com/statsbomb/open-data/master/data"

# Rozgrywki do pobrania: competition_id, season_id, nazwa.
# Usuń lub dopisz wiersze według swojego wyboru.
rozgrywki <- data.frame(
  comp   = c(2,  43, 43,  55, 55),
  season = c(27, 3,  106, 43, 282),
  nazwa  = c("Premier League 2015/16", "Mundial 2018", "Mundial 2022",
             "Euro 2020", "Euro 2024")
)
# Inne dostępne (comp, season): Serie A 2015/16 (12, 27), Ligue 1 2015/16 (7, 27),
# Copa America 2024 (223, 282), Puchar Narodow Afryki 2023 (1267, 107)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
options(timeout = 600)   # duże pliki: do 10 minut na plik zamiast domyślnych 60 s

# 1. Lista meczów: zapisujemy też informacje o meczach (przydadzą się później)
lista <- list()
for (r in seq_len(nrow(rozgrywki))) {
  m <- fromJSON(sprintf("%s/matches/%d/%d.json", BAZA, rozgrywki$comp[r], rozgrywki$season[r]),
                flatten = TRUE)
  lista[[r]] <- data.frame(
    match_id    = m$match_id,
    competition = rozgrywki$nazwa[r],
    match_date  = m$match_date,
    home_team   = m$home_team.home_team_name,
    away_team   = m$away_team.away_team_name,
    home_score  = m$home_score,
    away_score  = m$away_score
  )
}
mecze <- do.call(rbind, lista)
write.csv(mecze, "data/raw/mecze.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("Meczow do pobrania:", nrow(mecze), "\n")

# 2. Pobieranie plików zdarzeń
for (i in seq_len(nrow(mecze))) {
  plik <- sprintf("data/raw/%d.json", mecze$match_id[i])
  if (file.exists(plik)) next                      # już pobrany -> pomijamy
  ok <- tryCatch({
    download.file(sprintf("%s/events/%d.json", BAZA, mecze$match_id[i]),
                  plik, quiet = TRUE, mode = "wb")
    TRUE
  }, error   = function(e) { unlink(plik); FALSE },   # błąd -> usuwamy niepełny plik
  warning = function(w) { unlink(plik); FALSE })   # ostrzeżenie (np. ucięty plik) -> też usuwamy
  if (!ok) cat("\nNie udalo sie:", mecze$match_id[i], "(uruchom skrypt ponownie)\n")
  cat("Pobrano", i, "/", nrow(mecze), "\r")
}

# 3. Kontrola: każdy plik musi dać się wczytać jako JSON; uszkodzone usuwamy
pliki <- list.files("data/raw", pattern = "^[0-9]+\\.json$", full.names = TRUE)
zle <- pliki[!sapply(pliki, function(p) isTRUE(tryCatch(validate(readChar(p, file.size(p), useBytes = TRUE)),
                                                        error = function(e) FALSE)))]
if (length(zle) > 0) {
  cat("\nUszkodzone pliki (usuniete, uruchom skrypt ponownie):", basename(zle), "\n")
  unlink(zle)
}

cat("\nGotowe. Plikow JSON w data/raw:",
    length(list.files("data/raw", pattern = "^[0-9]+\\.json$")), "\n")