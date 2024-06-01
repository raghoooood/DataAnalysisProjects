select * 
from PortfolioProject ..CovidDeth
Where continent is not null
order by 3, 4

--select * 
--from PortfolioProject ..CovidVacsine
--order by 3, 4

-- select data that we are going to be using 

--select location , date, total_cases, new_cases, total_deaths, population
--from PortfolioProject..CovidDeth
--order by 1,2 

select location , date, total_cases, total_deaths, 
    CASE
        WHEN TRY_CAST(total_cases AS DECIMAL(10, 2)) IS NULL OR TRY_CAST(total_deaths AS DECIMAL(10, 2)) IS NULL THEN NULL
        WHEN TRY_CAST(total_cases AS DECIMAL(10, 2)) = 0 THEN 0
        ELSE (TRY_CAST(total_deaths AS DECIMAL(10, 2)) / TRY_CAST(total_cases AS DECIMAL(10, 2))) * 100
    END AS DeathPercentage
from PortfolioProject..CovidDeth
where location like '%saudi%'
and continent is not null

order by 1,2 


-- Looking at total cases vs population
--  Show what percentage of population got Covid

select location , date, total_cases, population, 
    CASE
        WHEN TRY_CAST(total_cases AS DECIMAL(10, 2)) IS NULL OR TRY_CAST(population AS DECIMAL(10, 2)) IS NULL THEN NULL
        WHEN TRY_CAST(population AS DECIMAL(10, 2)) = 0 THEN 0
        ELSE (TRY_CAST(total_cases AS DECIMAL(10, 2)) / TRY_CAST( population AS DECIMAL(10, 2))) * 100
    END AS PercentPopulationInfected
from PortfolioProject..CovidDeth
where location like '%saudi%'
and continent is not null

order by 1,2 


-- looking at countries whith highest infection Rate compared to population 

select location , population, Max(total_cases) As HighestInfectedCount, 
MAX((total_cases/population))*100 as PercentPopulationInfected

from PortfolioProject..CovidDeth
where continent is not null

Group by location, population
order by PercentPopulationInfected desc 


-- showing Countries with highest deth count per population

select location , Max(cast(total_deaths as int)) As TotalDeathCount
from PortfolioProject..CovidDeth
where continent is not null
Group by location
order by TotalDeathCount desc 

-- Let's break thing down by continent

select continent , Max(cast(total_deaths as int)) As TotalDeathCount
from PortfolioProject..CovidDeth
where continent is not null
Group by continent
order by TotalDeathCount desc 


-- showing continetens with highest deth count per population

select continent , Max(cast(total_deaths as int)) As TotalDeathCount
from PortfolioProject..CovidDeth
where continent is not null
Group by continent
order by TotalDeathCount desc 

-- Breacking Global Numbers 

select  SUM(new_cases) as total_cases , SUM(CAST(new_deaths AS INT)) as total_deaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases) *100  as DeathPercentage
from PortfolioProject..CovidDeth
--where location like '%saudi%'
WHERE continent is not null
--GROUP BY date
order by 1,2 


--NOW FOR LOOKING FOR COVIDE VACCINATIONS TABLE 
select * 
FROM PortfolioProject..CovidDeth  death
JOIN PortfolioProject..CovidVacsine vac
		on death.location = vac.location
		and death.date = vac.date


-- looking at total population VS vaccination
select death.continent, death.location, death.date, death.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeth  death
JOIN PortfolioProject..CovidVacsine vac
		on death.location = vac.location
		and death.date = vac.date
	WHERE death.continent is not null
	ORDER BY 2,3


-- using Partition by , to stopping things, adding these toghether

-- use CTE, if the number of the coulmns in cte is diffrent from nunber in select statment , it will give error
	With PopVsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
	as (
	select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations )) OVER (Partition by death.location ORDER BY death.location, death.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeth  death
JOIN PortfolioProject..CovidVacsine vac
		on death.location = vac.location
		and death.date = vac.date
	WHERE death.continent is not null
	--ORDER BY 2,3
	)
	Select * , (RollingPeopleVaccinated/Population) *100
	from PopVsVac
	

	-- TEMP Table 
DROP TABLE IF EXISTS #PercentPopulationVaccinated;
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC, 
	--New_vaccinations varchar,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    death.continent, 
    death.location, 
    death.date, 
    death.population,
	--vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeth AS death
JOIN 
    PortfolioProject..CovidVacsine AS vac
    ON death.location = vac.location
    AND death.date = vac.date

SELECT *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM 
    #PercentPopulationVaccinated;


	-- creating view to store data for later visualization 
	IF OBJECT_ID('PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW PercentPopulationVaccinated;
GO
	create View PercentPopulationVaccinated as 
	Select 
	death.continent, 
    death.location, 
    death.date, 
    death.population,
	vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeth AS death
JOIN 
    PortfolioProject..CovidVacsine AS vac
    ON death.location = vac.location
    AND death.date = vac.date

where death.continent is not null
	--ORDER BY 2,3
	GO
	SELECT *
	FROM PercentPopulationVaccinated


