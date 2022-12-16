--create database covid_project
--use covid_project

-- We'll be looking at the data from two different excel sheet - CovidDeaths and CovidVaccinations
select * 
from CovidDeaths 
order by 3, 4

select * 
from CovidVaccincations
order by 3,4

-- Looking at total cases vs total deaths

select Location, date, total_deaths, total_cases, (cast(total_deaths as float)/cast(total_cases as float))*100 as Deathpercentage 
from CovidDeaths 
where Location like '%states%' 
order by 1,2

-- looking at total cases vs population for united states
select Location, date, total_cases, Population, (cast(total_cases as float)/cast(population as float))*100 as InfectionPercentage
from CovidDeaths 
where Location like '%states%' and ((cast(total_cases as float)/cast(population as float))*100)>0.01
order by (cast(total_cases as float)/cast(population as float))*100 asc

-- Country with the highest infection rate
select Location, Population, max(total_cases) as Highestinfectioncount,
Max(cast(total_cases as float)/cast(population as float))*100 as 
Percentinfected
from CovidDeaths 
group by location, Population
order by Percentinfected desc

-- Showing the countries highest death count
select Location, max(total_deaths) as max_deaths
from CovidDeaths 
where continent is not null
group by Location
order by max_deaths desc

-- Showing the death count by continent 
select Location, max(total_deaths) as TotalDeathsCount
from CovidDeaths
where continent is NULL
group by LOCATION
order by TotalDeathsCount desc

-- GLOBAL NUMBERS
select date, Sum(new_cases), sum(new_deaths) as total_deaths,
(sum(cast(new_deaths as float))/sum(cast(new_cases as float)))*100 as deathpercentage
from CovidDeaths
where continent is not NULL 
group by DATE 
order by deathpercentage desc

-- total population vs vaccinations
-- shows percentage of population that has recieved at least one covid vaccine

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as float)) over (partition by dea.location order by
dea.location, dea.date) as RollingPeopleVaccinated 
from CovidDeaths dea 
join Covidvaccincations vac 
    on dea.location = vac.location 
    and dea.date = vac.date 
where dea.continent is not null 
order by 2,3

-- using cte to perform calculation on partition by from previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccincations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- temp table
drop table if exists #PercentVaccinated 
create table #PercentVaccinated 
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric

)
insert into #PercentVaccinated 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccincations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

-- creating view to store data for later visualisations

create view VaccinationPercent as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccincations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 