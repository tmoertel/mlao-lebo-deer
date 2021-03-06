library(ggplot2)
library(lubridate)
library(scales)
library(dplyr)  # Load last to shadow earlier-defined functions.
library(tidyr)
library(ggthemes)

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

ggsave("img/car-and-deer-crashes.png")
ggsave("img/car-and-deer-crashes.pdf")

summarize(car_accidents, vehicles = sum(vehicles))

### In which months are deer-related car accidents most common?

qplot(as.factor(substr(date, 6, 7)), data = deer_accidents,
      weight = vehicles,
      main = "Deer-related car accidents in Mt. Lebanon",
      xlab = "Month", ylab = "Count") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5))


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

### Compute some yearly and monthly summary statistics.
group_by(deer_accidents, year(date)) %>%
  summarise(accidents = n())

group_by(deer_accidents, floor_date(date, "month")) %>%
  summarise(accidents = n()) %>%
  View

group_by(deer_accidents, year = year(date)) %>%
  summarise(accidents = n())

group_by(deer_accidents,
         year = year(date),
         last = month(date) > 8) %>%
  summarise(accidents = n())


### Pedestrian/bicyclist accidents.

pedcyc_incidents <-
  read.csv("data/pedestrian-and-bicyclist-accidents.csv",
           colClasses=c(
             "factor", rep("character", 3), rep("numeric", 3),
             rep("character", 7), "numeric"))
pedcyc_incidents <- transform(pedcyc_incidents, when=ymd_hm(paste(DATE, TIME)))
## select(subset(pedcyc_incidents, UCR.DESCRIPTION == "DEATH"), REPORT)
pedcyc_incidents <-
  pedcyc_incidents %>%
  subset(UCR.DESCRIPTION != "DEATH")

summary(pedcyc_incidents)

pedcyc_incidents %>%
  group_by(UCR.DESCRIPTION) %>%
  summarize(n = n(), injury_frequency = frequency(INJ > 0))

deer_accidents_by_year <-
  group_by(deer_accidents, year=year(date)) %>%
  summarise(accidents = n(), injury_accidents = sum(Person.Injured == "X"))

pedcyc_accidents_by_year <-
  pedcyc_incidents %>%
  group_by(year=year(when)) %>%
  summarise(accidents = n(), injury_accidents = sum(INJ > 0))

full_join(deer_accidents_by_year, pedcyc_accidents_by_year, by="year") %>%
  arrange(year)

full_join(deer_accidents_by_year, pedcyc_accidents_by_year, by="year") %>%
  arrange(year) %>%
  subset(year >= 2011 & year <= 2014) %>%
  summarize(deer_crash_injuries = sum(injury_accidents.x),
            pedcyc_crash_injuries = sum(injury_accidents.y))


deer_accidents_monthly <- transform(deer_accidents, year=year(date), month=month(date))

deer_accidents_monthly %>%
  count(year, month) %>%
  spread(month, n)

deer_accidents_monthly %>%
  count(year)

deer_accidents_monthly %>%
  filter(month > 8) %>%
  count(year)

transform(deer_incidents, year=year(date), month=month(date)) %>%
  count(year, month) %>%
  spread(month, n)


### Deer management report.

deer_management_report <-
  data.frame(Year=2000:2013,
             Animal_control=c(34,40,39,59,49,61,62,64,48,50,79,71,99,90),
             Police=c(rep(NA,11), 45,49,43))

(deer_management_report_m <- deer_management_report %>% gather(Kind, Reports, 2:3))

p <-
qplot(Year, Reports, data=deer_management_report_m,
      geom=c("line"), color=Kind,
      main="Reports of probable deer accidents in Mt. Lebanon (2000–2013)") +
  geom_vline(xintercept=2006.25, color="gray") +
  geom_vline(xintercept=2007.25, color="gray") +
  annotate("text", x=2006.5, y=65, label="Cull 69 deer", hjust=0, angle=90, size=4) +
  annotate("text", x=2007.5, y=65, label="Cull 146 deer", hjust=0, angle=90, size=4) +
  scale_color_discrete(name="Source",
                       breaks=c("Animal_control", "Police"),
                       labels=c("Animal control", "Police"))
p

p + scale_y_continuous(trans=log10_trans())

dev.new()

p + coord_fixed(ratio = with(deer_management_report, bank_slopes(Year, Animal_control)))

ggsave(file="/tmp/probable_deer_accidents_mt_lebanon_2000_thru_2013.pdf",
       device=cairo_pdf)

summary(m1 <- lm(I(log(Animal_control)) ~ Year, data=deer_management_report))

summary(m_lo <- lm(I(log(Animal_control)) ~ Year,
                   data=subset(deer_management_report, Year <= 2005)))

summary(m_lo_linear <- lm(Animal_control ~ Year,
                          data=subset(deer_management_report, Year <= 2005)))

summary(m_hi <- lm(I(log(Animal_control)) ~ Year,
                   data=subset(deer_management_report, Year >= 2010)))

summary(m_cull <- lm(I(log(Animal_control)) ~ Year,
                   data=subset(deer_management_report, Year > 2008)))
