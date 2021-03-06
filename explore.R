library(stringr)
library(lubridate)
library(plotly)
library(fmsb)

df = read.csv("ATP.csv", stringsAsFactors = FALSE)

Sys.setenv("plotly_username"="shubh24")
Sys.setenv("plotly_api_key"="Jcgrh6kwxqOMZ3PerBKb")

font <- list(
  family = "Roboto",
  size = 18,
  color = "#7f7f7f"
)

df$date = as.Date(df$tourney_date, "%Y%m%d")
df$year = lubridate::year(df$date)

fedal = df[(df$winner_name == "Roger Federer" & df$loser_name == "Rafael Nadal") | (df$winner_name == "Rafael Nadal" & df$loser_name == "Roger Federer"),]

rafa = df[df$winner_name == "Rafael Nadal" | df$loser_name == "Rafael Nadal" ,]
rafa$win = as.numeric(rafa$winner_id == 104745)

roger = df[df$winner_name == "Roger Federer" | df$loser_name == "Roger Federer" ,]
roger$win = as.numeric(roger$winner_id == 103819)

yoy_win_ratio = function(athlete){
  athlete_yoy = aggregate(win ~ year, data = athlete, FUN = sum)
  athlete_yoy = merge(athlete_yoy, as.data.frame(table(athlete$year)), by.x = "year", by.y = "Var1")
  athlete_yoy$win_ratio = round(100*as.numeric(athlete_yoy$win/athlete_yoy$Freq), 2)
  
  return(athlete_yoy)
}
plot_yoy_win_ratio = function(athlete_win_ratio){
  xaxis <- list(
    title = "Year",
    titlefont = font
  )
  
  yaxis <- list(
    title = "Win Percentage",
    titlefont = font
  )
  
  p = plot_ly(athlete_win_ratio, x = ~year, y = ~win_ratio, type = "scatter", mode = "lines", color = ~athlete, colors = c("maroon", "green")) %>%
    layout(yaxis = yaxis, xaxis = xaxis, title = "Win percentage over the years")
  
  return (p)
  
}

roger_win_ratio = yoy_win_ratio(roger)
roger_win_ratio$athlete = "Roger Federer"
rafa_win_ratio = yoy_win_ratio(rafa)
rafa_win_ratio$athlete = "Rafael Nadal"

athlete_win_ratio = rbind(roger_win_ratio, rafa_win_ratio)
p = plot_yoy_win_ratio(athlete_win_ratio)
plotly_IMAGE(p, format = "png", out_file = "./viz/win_ratio_yoy")

plot_yoy_seed = function(athlete_seed){
  xaxis <- list(
    title = "Year",
    titlefont = font
  )
  
  yaxis <- list(
    title = "Seed",
    titlefont = font
  )
  
  p = plot_ly(athlete_seed, x = ~date, y = ~seed, type = "scatter", mode = "lines", color = ~athlete, colors = c("maroon", "green")) %>%
    layout(yaxis = yaxis, xaxis = xaxis, title = "Athletes' seeds over the years")
  
  return (p)
  
}

roger$seed = ifelse(roger$win == 1, as.numeric(roger$winner_seed), as.numeric(roger$loser_seed))
year_end_date = aggregate(date ~ year, data = roger[!is.na(roger$seed),], FUN = max)
roger_seed = unique(merge(year_end_date, roger[, c("date", "seed")], by = "date"))
roger_seed$athlete = "Roger Federer"

rafa$seed = ifelse(rafa$win == 1, as.numeric(rafa$winner_seed), as.numeric(rafa$loser_seed))
year_end_date = aggregate(date ~ year, data = rafa[!is.na(rafa$seed)], FUN = max)
rafa_seed = unique(merge(year_end_date, rafa[, c("date", "seed")], by = "date"))
rafa_seed$athlete = "Rafael Nadal"

athlete_seed = rbind(roger_seed, rafa_seed)
p = plot_yoy_seed(athlete_seed)
plotly_IMAGE(p, format = "png", out_file = "./viz/seeds_yoy")

surface_sensitivity = function(athlete){
  
  athlete_surface_wins = aggregate(win ~ year + surface, data = athlete, FUN = sum)
  
  athlete$dummy = 1
  athlete_surface_total = aggregate(dummy ~ year + surface, data = athlete, FUN = sum)
  athlete_surface_yoy = merge(athlete_surface_wins, athlete_surface_total, by = c("year", "surface"))
  
  athlete_surface_yoy$sensitivity = round(100*as.numeric(athlete_surface_yoy$win/athlete_surface_yoy$dummy), 2)
  
  return(athlete_surface_yoy)
}
plot_surface_sensitivity = function(athlete_surface_sensitivity){
  xaxis <- list(
    title = "Year",
    titlefont = font
  )
  
  yaxis <- list(
    title = "% Wins on Surface",
    titlefont = font
  )
  
  p = plot_ly(athlete_surface_sensitivity, x = ~year, y = ~sensitivity, type = "scatter", mode = "lines", colors = c("brown", "green", "blue"), color = ~surface) %>%
    layout(yaxis = yaxis, xaxis = xaxis, title = "Nadal - Win percentage over the years")
  
  return (p)
  
}

roger_surface_sensitivity = surface_sensitivity(roger)
roger_surface_sensitivity = roger_surface_sensitivity[!(as.character(roger_surface_sensitivity$surface) %in% c("", "Carpet")),]
roger_surface_sensitivity$surface = as.character(roger_surface_sensitivity$surface)
p = plot_surface_sensitivity(roger_surface_sensitivity)
plotly_IMAGE(p, format = "png", out_file = "./viz/roger_surface_sensitivity")

rafa_surface_sensitivity = surface_sensitivity(rafa)
rafa_surface_sensitivity = rafa_surface_sensitivity[!(as.character(rafa_surface_sensitivity$surface) %in% c("", "Carpet")),]
rafa_surface_sensitivity$surface = as.character(rafa_surface_sensitivity$surface)
p = plot_surface_sensitivity(rafa_surface_sensitivity)
plotly_IMAGE(p, format = "png", out_file = "./viz/rafa_surface_sensitivity")

tourney_fav = function(athlete){
  tourney_df = aggregate(win ~ tourney_name, data = athlete, FUN = sum)
  tourney_df = merge(tourney_df, as.data.frame(table(athlete$tourney_name)), by.x = "tourney_name", by.y = "Var1")
  tourney_df$win_ratio = round(100*as.numeric(tourney_df$win/tourney_df$Freq), 2)
  
  return(tourney_df[tourney_df$Freq > 10, c("tourney_name", "win_ratio")])
}
roger_tourney = tourney_fav(roger)
rafa_tourney = tourney_fav(rafa)

opponent_fav = function(athlete){
  
  athlete$opponent = ifelse(athlete$win == 1, as.character(athlete$loser_name), as.character(athlete$winner_name))
  
  athlete_df = aggregate(win ~ opponent, data = athlete, FUN = sum)
  athlete_df = merge(athlete_df, as.data.frame(table(athlete$opponent)), by.x = "opponent", by.y = "Var1")
  athlete_df$win_ratio = round(100*as.numeric(athlete_df$win/athlete_df$Freq), 2)
  
  return(athlete_df[athlete_df$Freq > 10, c("opponent", "win_ratio")])
}
roger_opponent = opponent_fav(roger)
rafa_opponent = opponent_fav(rafa)

#Dominance(% straight sets)
straight_sets = function(athlete){
  
  athlete_straight_sets = aggregate(straight_sets_win ~ surface, data = athlete, FUN = sum)
  
  athlete$dummy = 1
  athlete_wins_total = aggregate(dummy ~ surface, data = athlete[athlete$win == 1,], FUN = sum)
  athlete_straight_sets = merge(athlete_straight_sets, athlete_wins_total, by = c("surface"))
  
  athlete_straight_sets$dominance = round(100*as.numeric(athlete_straight_sets$straight_sets_win/athlete_straight_sets$dummy), 2)
  
  return(athlete_straight_sets)
}

plot_fed_rafa_dominance = function(fed_rafa_dominance){
  xaxis <- list(
    title = "Surface",
    titlefont = font
  )
  
  yaxis <- list(
    title = "Straight Set Win Percentage",
    titlefont = font
  )
  
  p = plot_ly(fed_rafa_dominance, x = ~surface, y = ~dominance.y, type = "bar", color = I("brown"), name = "Rafael Nadal") %>%
    add_trace(y = ~dominance.x, name = 'Roger Federer', color = I("light green") ) %>%
    layout(yaxis = yaxis, xaxis = xaxis, title = "Straight Set Win % -- Dominance",  barmode = 'grouped')
  
  return (p)
  
}

roger$sets = sapply(gregexpr("-", roger$score), length)
roger$straight_sets_win = as.numeric(((roger$sets <= 2 & as.numeric(roger$best_of == 3)) | (roger$sets <= 3  & as.numeric(roger$best_of == 5))) & roger$win == 1)
roger_straight_sets = straight_sets(roger)[, c("surface", "dominance")]

rafa$sets = sapply(gregexpr("-", rafa$score), length)
rafa$straight_sets_win = as.numeric(((rafa$sets <= 2 & as.numeric(rafa$best_of == 3)) | (rafa$sets <= 3  & as.numeric(rafa$best_of == 5))) & rafa$win == 1)
rafa_straight_sets = straight_sets(rafa)[, c("surface", "dominance")]

fed_rafa_dominance = merge(roger_straight_sets, rafa_straight_sets, by = "surface")
p = plot_fed_rafa_dominance(fed_rafa_dominance)
plotly_IMAGE(p, format = "png", out_file = "./viz/fed_rafa_dominance")

#fedal
fedal$winner_name = droplevels(fedal$winner_name)
table(fedal$winner_name)

plot_fedal_surface = function(fedal_yoy_surface){
  xaxis <- list(
    title = "Year",
    titlefont = font
  )
  
  yaxis <- list(
    title = "Number of Fedals",
    titlefont = font
  )
  
  p = plot_ly(fedal_yoy_surface, x = ~year, y = ~clay, type = "bar", color = I("maroon"), name = "clay") %>%
    add_trace(y = ~grass, name = 'grass', color = I("light green") ) %>%
    add_trace(y = ~hard, name = 'hard', color = I("sky blue")) %>%
    layout(yaxis = yaxis, xaxis = xaxis, title = "Fedal clashes over the years",  barmode = 'stack')
  
  return (p)
  
}

fedal_yoy_surface = as.matrix(table(fedal$year, fedal$surface))
fedal_yoy_surface = data.frame(cbind(rownames(fedal_yoy_surface), fedal_yoy_surface[,1], fedal_yoy_surface[,2], fedal_yoy_surface[,3]))
colnames(fedal_yoy_surface) = c("year", "clay", "grass", "hard")
p = plot_fedal_surface(fedal_yoy_surface)
plotly_IMAGE(p, format = "png", out_file = "./viz/fedal_surface_yoy")

table(fedal$winner_name, fedal$surface)

#outlier wins
fedal[as.character(fedal$surface) == "Clay" & as.character(fedal$winner_name) == "Roger Federer", c("tourney_name", "year", "winner_name", "score")]
fedal[as.character(fedal$surface) == "Grass" & as.character(fedal$winner_name) == "Rafael Nadal", c("tourney_name", "year", "winner_name", "score")]

serve_analysis = function(athlete){

  athlete$aces = ifelse(athlete$win == 1, as.numeric(athlete$w_ace), as.numeric(athlete$l_ace))
  athlete$df = ifelse(athlete$win == 1, as.numeric(athlete$w_df), as.numeric(athlete$l_df))
  
  athlete$first_serve_in = ifelse(athlete$win == 1, 100*as.numeric(athlete$w_1stIn)/as.numeric(athlete$w_svpt), 100*as.numeric(athlete$l_1stIn)/as.numeric(athlete$l_svpt))
  athlete$second_serve_in = ifelse(athlete$win == 1, as.numeric(athlete$w_svpt) - as.numeric(athlete$w_1stIn) - as.numeric(athlete$w_df),  as.numeric(athlete$l_svpt) - as.numeric(athlete$l_1stIn) - as.numeric(athlete$l_df))
  
  athlete$first_serve_won = ifelse(athlete$win == 1, 100*as.numeric(athlete$w_1stWon)/as.numeric(athlete$w_1stIn), 100*as.numeric(athlete$l_1stWon)/as.numeric(athlete$l_1stIn))
  athlete$second_serve_won = ifelse(athlete$win == 1, 100*as.numeric(athlete$w_2ndWon)/as.numeric(athlete$second_serve_in), 100*as.numeric(athlete$l_2ndWon)/as.numeric(athlete$second_serve_in))

  # athlete$second_serve_in = ifelse(athlete$win == 1, 100*as.numeric(athlete$second_serve_in)/as.numeric(athlete$w_svpt), 100*as.numeric(athlete$second_serve_in)/as.numeric(athlete$l_svpt))
  
  athlete$break_points_saved = ifelse(athlete$win == 1, 100*as.numeric(athlete$w_bpSaved)/as.numeric(athlete$w_bpFaced), 100*as.numeric(athlete$l_bpSaved)/as.numeric(athlete$l_bpFaced))
  
  return(athlete)
  
}

par(mfrow=c(3, 1))
par(mar=c(1,1,1,1))

max_radar = c(10, 3, rep(100, 4))
min_radar = rep(0, 6)
colors_border=c( rgb(0,0,0,0.9), rgb(1,0,0,0.9))
colors_in=c( rgb(0,0,0,0.2), rgb(1,0,0,0.3))

for (i in c("Clay", "Grass", "Hard")){
  roger_serve = serve_analysis(roger[as.character(roger$surface) == i,])
  rafa_serve = serve_analysis(rafa[as.character(rafa$surface) == i,])
  
  athlete = roger_serve
  roger_radar = as.data.frame(cbind(mean(athlete$aces, na.rm = TRUE), mean(athlete$df, na.rm = TRUE), mean(athlete$first_serve_in, na.rm = TRUE), mean(athlete$first_serve_won, na.rm = TRUE), mean(athlete$second_serve_won, na.rm = TRUE), mean(athlete$break_points_saved, na.rm = TRUE)))
  colnames(roger_radar) = c("aces", "double faults", "first serve %", "first serve points won %", "second serve points won %", "break points won %" )
  
  athlete = rafa_serve
  rafa_radar = as.data.frame(cbind(mean(athlete$aces, na.rm = TRUE), mean(athlete$df, na.rm = TRUE), mean(athlete$first_serve_in, na.rm = TRUE), mean(athlete$first_serve_won, na.rm = TRUE), mean(athlete$second_serve_won, na.rm = TRUE), mean(athlete$break_points_saved, na.rm = TRUE)))
  colnames(rafa_radar) = c("aces", "double faults", "first serve %", "first serve points won %", "second serve points won %", "break points won %" )
  
  athlete_radar = rbind(roger_radar, rafa_radar)

  radarchart(rbind(max_radar, min_radar, athlete_radar), axistype=2 , pcol=colors_border , 
             pfcol=colors_in , plwd=4 , cglcol="grey", cglty=1,
             axislabcol="grey", caxislabels=seq(0,2000,5), cglwd=0.8, vlcex=0.6, title = i)
  
}

table(fedal$tourney_name[fedal$winner_name == "Rafael Nadal"]) #5 times in finals RG, 3 times in finals Monte Carlo