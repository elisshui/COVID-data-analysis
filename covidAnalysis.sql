--CASES & DEATHS
SELECT *
	FROM COVIDAnalysis..covidDeaths
	ORDER BY 3,4

--Selecting data to be used
SELECT Location, Date, total_cases, new_cases, total_deaths, population
	FROM COVIDAnalysis..covidDeaths
	ORDER BY 1,2

-- total cases vs total deaths
SELECT Location, Date, total_cases, total_deaths, (total_deaths/total_cases)*100 as "percentage_deaths" 
	FROM COVIDAnalysis..covidDeaths
	--WHERE location like '%Canada'
	ORDER BY 1,2

--total cases vs population (%population)
SELECT Location, Date, population, total_cases, (total_cases/population)*100 as "percentage_pop_infected" 
	FROM COVIDAnalysis..covidDeaths
	WHERE location like '%Kingdom'
	and continent is not NULL
	ORDER BY 1,2

--**highest infection rate compaired to population per country
SELECT Location, population, MAX(total_cases) as "highestInfectCount", MAX((total_cases/population)*100) as "PercentPopInfected" 
	FROM COVIDAnalysis..covidDeaths
	WHERE continent is not NULL --remove this to incl. world, EU, continents
	GROUP BY Location, population
	ORDER BY PercentPopInfected desc

--**highest infection rate per day, incl. global regions
SELECT Location, population, date, MAX(total_cases) as "highestInfectCount", MAX((total_cases/population)*100) as "PercentPopInfected" 
	FROM COVIDAnalysis..covidDeaths
	--WHERE continent is not NULL --remove this to incl. world, EU, continents
	GROUP BY Location, population, date
	ORDER BY PercentPopInfected desc

--highest death count per population
SELECT Location, MAX(cast(Total_deaths as int)) as "totalDeathCount"
	FROM COVIDAnalysis..covidDeaths
	WHERE continent is not NULL
	GROUP BY Location
	ORDER BY "totalDeathCount" desc	


--CONTINENT DATA
--**highest death count per continent, incl class division
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
	From COVIDAnalysis..CovidDeaths
	Where continent is null 
	and location not in ('World', 'European Union', 'International')
	Group by location
	order by TotalDeathCount desc

--looking at highest death count per population by continent
SELECT continent, MAX(cast(Total_deaths as int)) as "totalDeathCount"
	FROM COVIDAnalysis..covidDeaths
	WHERE continent is not NULL
	GROUP BY continent
	ORDER BY "totalDeathCount" desc	

--GLOBAL DATA
--**sum of new cases = total cases, sum of new deaths = total deaths --> b/c can't do aggregate func in aggregate func
SELECT date, SUM(new_cases) as "totalCases", SUM(cast(new_deaths as int)) as "totalDeaths", (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as "deathPercentage" 
	FROM COVIDAnalysis..covidDeaths
	WHERE continent is not NULL
	GROUP BY date
	ORDER BY 1,2

--remove date column and group by from prev query to see global total cases + otherdata
SELECT SUM(new_cases) as "totalCases", SUM(cast(new_deaths as int)) as "totalDeaths", (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as "deathPercentage" 
	FROM COVIDAnalysis..covidDeaths
	WHERE continent is not NULL
	ORDER BY 1,2

--VACCINATIONS (joined tables)
SELECT *
	FROM COVIDAnalysis..covidDeaths Dth
	JOIN COVIDAnalysis..covidVaccinations Vac
		ON Dth.location = Vac.location
		and Dth.date = Vac.date

--Total population vs vaccinations
SELECT Dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
	FROM COVIDAnalysis..covidDeaths Dth
	JOIN COVIDAnalysis..covidVaccinations Vac
		ON Dth.location = Vac.location
		and Dth.date = Vac.date 
	WHERE Dth.continent is not NULL
	ORDER BY 1, 2, 3

--Vaccination rolling count using CTE
WITH popVsVac(continent, location, date, population, new_vaccinations, vacRollingCount)
as
(
SELECT Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations
, SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER (Partition by Dth.location ORDER BY Dth.location, Dth.date) as "vacRollingCount"
	FROM COVIDAnalysis..covidDeaths Dth
	JOIN COVIDAnalysis..covidVaccinations Vac
		ON Dth.location = Vac.location
		and Dth.date = Vac.date 
	WHERE Dth.continent is not NULL
)
SELECT *, (vacRollingCount/population)*100 as "percentVaccinated"
	FROM popVsVac

--TEMP TABLE
DROP Table if exists #PercentPopuVaccinated
CREATE TABLE #PercentPopuVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
vacRollingCount numeric
)
INSERT INTO #PercentPopuVaccinated
SELECT Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations
, SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER (Partition by Dth.location ORDER BY Dth.location, Dth.date) as "vacRollingCount"
	FROM COVIDAnalysis..covidDeaths Dth
	JOIN COVIDAnalysis..covidVaccinations Vac
		ON Dth.location = Vac.location
		and Dth.date = Vac.date 
	WHERE Dth.continent is not NULL

SELECT *, (vacRollingCount/population)*100 as "percentVaccinated"
	FROM #PercentPopuVaccinated

--Creating views --> for visualizations
Create View PercentPopuVaccinated as 
SELECT Dth.continent, Dth.location, Dth.date, Dth.population, Vac.new_vaccinations
, SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER (Partition by Dth.location ORDER BY Dth.location, Dth.date) as "vacRollingCount"
	FROM COVIDAnalysis..covidDeaths Dth
	JOIN COVIDAnalysis..covidVaccinations Vac
		ON Dth.location = Vac.location
		and Dth.date = Vac.date 
	WHERE Dth.continent is not NULL

SELECT *
FROM PercentPopuVaccinated
