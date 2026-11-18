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
dane <- dane[dane$shot.type.name != "Penalty", ]
nrow(dane)
dim(dane)


table(dane$period)
table(dane$shot.type.name)
table(dane$shot.outcome.name)

dane$goal <- as.integer(dane$shot.outcome.name == "Goal")
table(dane$goal)
mean(dane$goal)

dx <- 120 - dane$location.x
dy <- dane$location.y - 40
dane$distance <- sqrt(dx^2 + dy^2)
dane$angle <- atan2(8 * dx, dx^2 + dy^2 - 16)

write.csv(dane, "data/processed/strzaly.csv", row.names = FALSE)

summary(dane$distance)

dim(read.csv("data/processed/strzaly.csv"))

przedzial <- cut(dane$distance, breaks = c(0, 6, 12, 18, 25, 35, 90))
tapply(dane$goal, przedzial, mean)

table(przedzial)

table(dane$shot.body_part.name, dane$goal)

tab <- table(dane$shot.body_part.name, dane$goal)
chisq.test(tab)

bliskie <- dane[dane$distance <= 12, ]
tab_bliskie <- table(bliskie$shot.body_part.name, bliskie$goal)
tab_bliskie
chisq.test(tab_bliskie)

model_test <- glm(goal ~ distance + shot.body_part.name,
                  family = binomial, data = dane)
summary(model_test)

exp(cbind(OR = coef(model_test), confint.default(model_test)))

model_kwadrat <- glm(goal ~ distance + I(distance^2) + shot.body_part.name,
                     family = binomial, data = dane)
summary(model_kwadrat)

nowe <- data.frame(distance = c(5, 10, 20, 40, 60, 80),
                   shot.body_part.name = "Right Foot")
predict(model_kwadrat, nowe, type = "response")

dane$distance_ogr <- pmin(dane$distance, 40)
model_ogr <- glm(goal ~ distance_ogr + I(distance_ogr^2) + shot.body_part.name,
                 family = binomial, data = dane)
nowe2 <- data.frame(distance_ogr = c(5, 10, 20, 40),
                    shot.body_part.name = "Right Foot")
predict(model_ogr, nowe2, type = "response")


model_kat <- glm(goal ~ distance_ogr + I(distance_ogr^2) + angle + shot.body_part.name,
                 family = binomial, data = dane)
summary(model_kat)
AIC(model_ogr, model_kat)


set.seed(123)
mecze <- unique(dane$match_id)
mecze_test <- sample(mecze, size = round(0.2 * length(mecze)))

trening <- dane[!dane$match_id %in% mecze_test, ]
test    <- dane[dane$match_id %in% mecze_test, ]

c(nrow(trening), nrow(test))

model_tr <- glm(goal ~ distance_ogr + I(distance_ogr^2) + angle + shot.body_part.name,
                family = binomial, data = trening)

p_test <- predict(model_tr, test, type = "response")
y <- test$goal

# Brier score: średni kwadrat błędu prawdopodobieństwa (im mniej, tym lepiej)
brier_model <- mean((y - p_test)^2)

# Dla porównania: model „zawsze średnia" i xG ze StatsBomb
p0 <- mean(trening$goal)
brier_srednia <- mean((y - p0)^2)
brier_statsbomb <- mean((y - test$shot.statsbomb_xg)^2, na.rm = TRUE)

c(model = brier_model, srednia = brier_srednia, statsbomb = brier_statsbomb)

sum(is.na(test$shot.statsbomb_xg))

logloss_model <- -mean(y * log(p_test) + (1 - y) * log(1 - p_test))
logloss_model

ll <- function(p) -mean(y * log(p) + (1 - y) * log(1 - p))

c(model = ll(p_test),
  srednia = ll(rep(p0, length(y))),
  statsbomb = ll(test$shot.statsbomb_xg))


dane$xg_model <- predict(model_kat, dane, type = "response")
dane$jeden <- 1

zawodnicy <- aggregate(cbind(strzaly = jeden, goal, xg_model) ~ player.name,
                       data = dane, FUN = sum)
zawodnicy$roznica <- zawodnicy$goal - zawodnicy$xg_model

# tylko zawodnicy z co najmniej 30 strzałami, żeby wynik nie był przypadkowy
zawodnicy <- zawodnicy[zawodnicy$strzaly >= 30, ]
zawodnicy <- zawodnicy[order(-zawodnicy$roznica), ]
head(zawodnicy, 10)


dane$wariancja <- dane$xg_model * (1 - dane$xg_model)
wariancja <- aggregate(wariancja ~ player.name, data = dane, FUN = sum)
zawodnicy <- merge(zawodnicy, wariancja, by = "player.name")
zawodnicy$z <- zawodnicy$roznica / sqrt(zawodnicy$wariancja)

head(zawodnicy[order(-zawodnicy$z),
               c("player.name", "strzaly", "goal", "xg_model", "z")], 10)


n <- nrow(zawodnicy)
n
qnorm(1 - 0.05 / (2 * n))   # z-score potrzebny do istotności po korekcji


