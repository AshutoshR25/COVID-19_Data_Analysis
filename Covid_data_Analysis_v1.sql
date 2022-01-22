
/*
Covid 19 Data Exploration and Analysis

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/



-- Observing the datasets
SELECT TOP(100) *
FROM covid_research..covid_deaths;

SELECT  *
FROM covid_research..covid_vaccinations;


-- Getting specific data and adding a column death percentage per million

-- Total cases vs Total deaths
-- This will give us the chances of a person dying based on the cases in their country.

SELECT TOP 1000
  continent, location, date, population, 
  new_cases, total_cases_per_million,  
  total_deaths_per_million, 
  (total_deaths_per_million/total_cases_per_million)* 100 AS death_percentage_per_million
FROM
  covid_research..covid_deaths
WHERE
  location = 'India';


-- Total cases vs population
-- Percentage of population infected

SELECT TOP 100
  continent, location, date, population, 
  new_cases, population,total_cases_per_million,  
  total_deaths_per_million, 
  (total_cases_per_million/population)* 100 AS person_infected_percentage_per_million
FROM
  covid_research..covid_deaths;


-- As data is in per_million i.e formula cases-per_million = (event/population)*1000000
-- Hence only dividing the cases_per_million by 10000 would be *100 i.e %

-- Percentage of population infected

SELECT 
  continent, location, population,  
  MAX(total_cases_per_million*population)/1000000 AS highly_infected,
  MAX(total_cases_per_million)/ 10000 AS person_infected_percentage
FROM
  covid_research..covid_deaths
GROUP BY
  continent,location, population
ORDER BY
  person_infected_percentage DESC;


SELECT
  date, population, 
  new_cases,
  location, total_cases_per_million
from
  covid_research..covid_deaths
where
  location = 'India';


-- Observing countries with highest death count
-- At first the cases were less hence the continents were entered into location 
-- To overcome it we will take continent not NULL

SELECT
  location, MAX(CAST(total_deaths as int)) AS total_death_count
from
  covid_research..covid_deaths
where
  continent is NOT NULL
group by
  location
order by
  total_death_count desc;


-- Observing the deaths based on Continents

SELECT
  continent, MAX(CAST(total_deaths as int)) AS total_death_count
from
  covid_research..covid_deaths
where
  continent is NOT NULL
group by
  continent
order by
  total_death_count desc;


-- On running this query we can see that North america shows the cases of USA itself

SELECT
  location, MAX(CAST(total_deaths as int)) AS total_death_count
from
  covid_research..covid_deaths
where
  continent is NULL
group by
  location
order by
  total_death_count desc;


-- GLobal Numbers cases and death percentage per day

select
  date, sum(new_cases) as total_cases_per_day,
  sum(cast(new_deaths as int)) as total_deaths_per_day,
  sum(new_cases)/sum(cast(new_deaths as int))/100 as death_percentage_per_day
from
  covid_research..covid_deaths
where 
  continent is NOT NULL
group by
  date
order by 
  date;





-- Overall cases across the world and death percentage
select
  sum(new_cases) as total_cases,
  sum(cast(new_deaths as int)) as total_deaths,
  sum(new_cases)/sum(cast(new_deaths as int))/100 as death_percentage
from
  covid_research..covid_deaths
where 
  continent is NOT NULL



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (Rolling_People_Vaccinated/population)*100
From covid_research..covid_deaths dea
Join covid_research..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3



-- Using CTE to perform Calculation on Partition By in previous query

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_People_Vaccinated
--, (Rolling_People_Vaccinated/population)*100
From covid_research..covid_deaths dea
Join covid_research..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
select *, (Rolling_People_Vaccinated/population)* 100
from pop_vs_vac;



-- Using temp tables to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #temp_pop_vs_vac
create table #temp_pop_vs_vac
(
continent varchar(50), 
location varchar(50), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
Rolling_People_Vaccinated numeric
)

Insert Into #temp_pop_vs_vac
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_People_Vaccinated
--, (Rolling_People_Vaccinated/population)*100
From covid_research..covid_deaths dea
Join covid_research..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null ;



-- Creating View to store data for later visualizations

Drop view if EXISTS Percent_Population_Vaccinated
Create View Percent_Population_Vaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (Rolling_People_Vaccinated/population)*100
From covid_research..covid_deaths dea
Join covid_research..covid_vaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
