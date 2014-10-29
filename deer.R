library(lubridate)
library(ggplot2)
library(scales)

deer <- read.csv("data/mt-lebanon-deer-incidents-2014-10.csv")
deer <- transform(deer, Incident.Date = mdy(Incident.Date))
deer <- transform(deer, Month = floor_date(Incident.Date, "month"))

qplot(Month, data = deer)

qplot(Incident.Date, data = deer, geom = "density")

