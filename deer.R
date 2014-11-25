library(lubridate)
library(ggplot2)
library(plyr)
library(scales)

deer <- read.csv("data/mt-lebanon-deer-incidents-2014-10.csv")
deer <- transform(deer, Incident.Date = mdy(Incident.Date))
deer <- transform(deer, Month = floor_date(Incident.Date, "month"))

qplot(Month, data = deer)

qplot(Incident.Date, data = deer, geom = "density")

### For context, compare deer-related car accidents with all car accidents.

all_accidents <- read.csv("data/police-blotter/accidents.csv")
all_accidents <- transform(all_accidents, date = mdy(date))

summarize(all_accidents, vehicles = sum(vehicles))
