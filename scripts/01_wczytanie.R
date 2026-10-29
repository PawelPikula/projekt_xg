library(jsonlite)
library(tools)

# --- Ustawienia ---
zmienne <- c(
  "match_id", "period", "minute", "second", "related_events",
  "team.name", "player.name", "position.name", "location",
  "play_pattern.name", "under_pressure",
  "shot.body_part.name", "shot.type.name", "shot.technique.name",
  "shot.first_time", "shot.aerial_won", "shot.one_on_one",
  "shot.open_goal", "shot.deflected",
  "shot.outcome.name", "shot.statsbomb_xg"
)

flagi <- c("under_pressure", "shot.first_time", "shot.aerial_won",
           "shot.one_on_one", "shot.open_goal", "shot.deflected")

# --- Funkcja: jeden plik JSON -> strzały z jednego meczu ---
wczytaj_strzaly <- function(plik) {
  ev <- fromJSON(plik, flatten = TRUE)
  strzaly <- ev[ev$type.name == "Shot", ]
  
  # match_id z nazwy pliku
  strzaly$match_id <- as.integer(file_path_sans_ext(basename(plik)))
  
  # brakujące kolumny -> NA
  brakujace <- setdiff(zmienne, names(strzaly))
  for (z in brakujace) {
    strzaly[[z]] <- NA
  }
  
  # location -> x i y
  strzaly$location.x <- sapply(strzaly$location, `[`, 1)
  strzaly$location.y <- sapply(strzaly$location, `[`, 2)
  
  # flagi: NA -> 0, TRUE -> 1
  for (z in flagi) {
    strzaly[[z]] <- as.integer(!is.na(strzaly[[z]]))
  }
  
  # tylko potrzebne kolumny, bez kolumn-list
  kolumny <- c(setdiff(zmienne, c("location", "related_events")),
               "location.x", "location.y")
  return(strzaly[, kolumny])
}

# --- Wszystkie mecze ---
pliki <- list.files("data/raw", pattern = "^[0-9]+\\.json$", full.names = TRUE)
tabele <- lapply(pliki, wczytaj_strzaly)
dane <- do.call(rbind, tabele)
dim(dane)


table(dane$period)
table(dane$shot.type.name)




