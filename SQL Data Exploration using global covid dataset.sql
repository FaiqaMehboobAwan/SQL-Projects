SELECT *
FROM [Portfolio Project].[dbo].[covid death]
ORDER BY 3,4
SELECT *
FROM [Portfolio Project].[dbo].[covid vaccinations]
ORDER BY 3,4

--select the date to start analysis from
Select Location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project].[dbo].[covid death]
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Portfolio Project].[dbo].[covid death]
Where location like '%Pak%' AND continent is not NULL
order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as InfectedPopulationPercent
From [Portfolio Project].[dbo].[covid death]
order by 1,2

--Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [Portfolio Project].[dbo].[covid death]
Group by Location, Population
order by PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project].[dbo].[covid death]
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project].[dbo].[covid death]
Where continent is not null 
Group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

Select continent, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [Portfolio Project].[dbo].[covid death]
where continent is not null 
Group By continent
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT  death.continent, death.location, death.date, death.population, vaccinations.new_vaccinations,
SUM(CONVERT(int,vaccinations.new_vaccinations))
OVER (Partition by death.location Order BY death.location, death.Date) as RollingPeopleVaccinated
FROM [Portfolio Project].[dbo].[covid death] death
join [Portfolio Project].[dbo].[covid vaccinations] vaccinations
ON death.location = vaccinations.location
AND death.date = vaccinations.date
WHERE death.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select death.continent, death.location, death.date, death.population, vaccinations.new_vaccinations
, SUM(CONVERT(int,vaccinations.new_vaccinations))
OVER (Partition by death.location Order BY death.location, death.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM [Portfolio Project].[dbo].[covid death] death
join [Portfolio Project].[dbo].[covid vaccinations] vaccinations
ON death.location = vaccinations.location
AND death.date = vaccinations.date
WHERE death.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as populationVSvaccination
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
	Create Table #PercentPopulationVaccinated
	(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVaccinated numeric
	)
	Insert into #PercentPopulationVaccinated
	Select death.continent, death.location, death.date, death.population, vaccinations.new_vaccinations
	, SUM(CAST(vaccinations.new_vaccinations AS bigint)) OVER (Partition by death.Location Order by death.location,death.Date) as RollingPeopleVaccinated
	FROM [Portfolio Project].[dbo].[covid death] death
join [Portfolio Project].[dbo].[covid vaccinations] vaccinations
		On death.location = vaccinations.location
		and death.date = vaccinations.date
	Select *, (RollingPeopleVaccinated/Population)*100 AS PercentPopulationVaccinated 
	From #PercentPopulationVaccinated 


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated  AS

Select death.continent, death.location, death.date, death.population, vaccinations.new_vaccinations
, SUM(CAST(vaccinations.new_vaccinations AS bigint)) OVER (Partition by death.Location Order by death.location,death.Date) as RollingPeopleVaccinated
FROM [Portfolio Project].[dbo].[covid death] death
join [Portfolio Project].[dbo].[covid vaccinations] vaccinations
On death.location = vaccinations.location
		and death.date = vaccinations.date
where death.continent is not null 

