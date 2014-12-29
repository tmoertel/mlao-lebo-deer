library(lubridate)
library(ggplot2)
library(plyr)
library(scales)

deer_incidents <- read.csv("data/mt-lebanon-deer-incidents.csv",
                           as.is=c(1,6))
deer_incidents <- transform(deer_incidents, date = mdy(Incident.Date))
deer_incidents <- transform(deer_incidents, Incident.Date = NULL)

qplot(date, data = deer_incidents, geom = "density",
      main = "All deer incidents (including trivial)")

### For context, compare deer-related car accidents with all car accidents.

deer_accidents <- subset(deer_incidents, Vehicle.Involved == "X")
deer_accidents <- transform(deer_accidents, vehicles=1, Vehicle.Involved=NULL)

qplot(date, data = deer_accidents, geom = "density",
      main = "Deer incidents involving automobiles")

car_accidents <- read.csv("data/police-blotter/accidents.csv")
car_accidents <- transform(car_accidents, date = ymd(date), time = hm(time))

## The car-accident data come from the accidents section of police
## blotters. The blotters are published weekly, but we can't take for
## granted that the blotters will each cover exactly 7 days worth of
## reporting, or that there won't be missing blotters. Therefore, to
## determine the years worth of data coverage we have, we add up the
## dates covered by the individual police blotters in our data set.
pbdates <- read.csv("data/police-blotter/police_blotter_date_ranges.csv")
pbdates <- mutate(pbdates,
                  from = mdy(from),
                  to = mdy(to),
                  years = (to - from) / dyears(1) + 1/365)  # Inclusive.
if (length(unique(pbdates$years)) > 1) {
  ## Right now, all of the blotters cover 7 days. If that ever changes,
  ## we ought to verify that there wasn't a data-entry error.
  stop("Check dates on police blotters for inconsistencies.")
}
police_blotter_data_coverage_in_years <- sum(pbdates$years)

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

qplot(as.factor(substr(month, 1, 7)), data = combined_accidents,
      weight = vehicles, fill = kind,
      main = "Car accidents in Mt. Lebanon",
      xlab = "Month", ylab = "Count") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5))

combined_accidents_by_month <-
  ddply(combined_accidents, .(month, kind), summarize, vehicles = sum(vehicles))

summarize(car_accidents, vehicles = sum(vehicles))


### In terms of injury risk, how do deer incidents compare to car accidents?

## First, deer-related incidents.
(deer_injury_incidents <- sum(deer_incidents$Person.Injured == "X"))
(deer_incident_years <- diff(range(deer_incidents$date)) / dyears(1))
(deer_injury_incidents_per_year <- deer_injury_incidents / deer_incident_years)

## Next, car-related incidents.
(car_injury_incidents <- sum(car_accidents$injuries > 0))
(car_incident_years <- police_blotter_data_coverage_in_years)
(car_injury_incidents_per_year <- car_injury_incidents / car_incident_years)

(relative_risk_of_injury_car_to_deer <-
 car_injury_incidents_per_year / deer_injury_incidents_per_year)


### If there's a car accident in Mt. Lebanon, how much more (or less) likely
### is it to injure someone, given that a deer was involved?
frequency <- function(bools) sum(bools) / length(bools)
(freq_of_injury_in_all_car_accidents <- frequency(car_accidents$injuries > 0))
(freq_of_injury_in_deer_car_accidents <- frequency(deer_accidents$Person.Injured == "X"))
(rel_freq_of_injury_in_accidents_if_deer_involved <-
     (freq_of_injury_in_deer_car_accidents /
          freq_of_injury_in_all_car_accidents))
