library(lubridate)
library(ggplot2)
library(plyr)
library(scales)

deer_incidents <- read.csv("data/mt-lebanon-deer-incidents-2014-10.csv", as.is=c(1,6))
deer_incidents <- transform(deer_incidents, Incident.Date = mdy(Incident.Date))
deer_incidents <- transform(deer_incidents, date = Incident.Date,
                            Incident.Date = NULL)

qplot(date, data = deer_incidents, geom = "density")

### For context, compare deer-related car accidents with all car accidents.

deer_accidents <- subset(deer_incidents, Vehicle.Involved == "X")
deer_accidents <- transform(deer_accidents, vehicles=1, Vehicle.Involved=NULL)

car_accidents <- read.csv("data/police-blotter/accidents.csv")
car_accidents <- transform(car_accidents, date = ymd(date))

deer_accidents_in_car_accidents_date_range <-
  subset(deer_accidents, (date >= min(car_accidents$date) &
                          date <= max(car_accidents$date)))

deer_accidents_included_in_car_accidents <-
  subset(deer_accidents_in_car_accidents_date_range,
         date %in% car_accidents$date)

deer_accidents_missing_in_car_accidents <-
  subset(deer_accidents_in_car_accidents_date_range,
         ! date %in% car_accidents$date)

combined_accidents <-
  rbind(data.frame(date = deer_accidents$date, kind = "deer", vehicles = 1),
        data.frame(date = car_accidents$date,  kind = "car",
                   vehicles = car_accidents$vehicles))

combined_accidents <-
  transform(combined_accidents, month = floor_date(date, "month"))

qplot(as.factor(month), data = combined_accidents,
      weight = vehicles, fill = kind)

combined_accidents_by_month <-
  ddply(combined_accidents, .(month, kind), summarize, vehicles = sum(vehicles))

summarize(car_accidents, vehicles = sum(vehicles))


### In terms of injury risk, how do deer incidents compare to car accidents?

(deer_injury_incidents <- sum(deer_incidents$Person.Injured == "X"))
(deer_incident_years <- diff(range(deer_incidents$date)) / dyears(1))
(deer_injury_incidents_per_year <- deer_injury_incidents / deer_incident_years)

(car_injury_incidents <- sum(car_accidents$injuries > 0))
(car_incident_years <- diff(range(car_accidents$date)) / dyears(1))
(car_injury_incidents_per_year <- car_injury_incidents / car_incident_years)

(relative_risk_of_injury_car_to_deer <-
 car_injury_incidents_per_year / deer_injury_incidents_per_year)
