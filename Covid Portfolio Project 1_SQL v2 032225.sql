
Select *
from PortfolioProject..CovidDeaths
order by 3, 4

--Select *
--from PortfolioProject..CovidVaccinations
--order by 3, 4

--Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1, 2

--Looking at Total Cases vs Total Deaths (Error Message, Operand data type nvarchar)
Select Location, date, SUM(cast(total_cases as int)), SUM(cast(total_deaths as int)) --(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
Where continent is null
Group by location
order by 1, 2

--Shows likelihood of dying if you contract covid in your country (Error Message, Operand data type nvarchar)
Select Location, date, SUM(total_cases), SUM(cast(total_deaths as int)) --(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1, 2

--Looking at Total Cases vs Population 
--Shows what percentage of population got Covid
Select Location, date, total_cases, population, (total_cases/population)*100 as PercentofPopulationInfected
from PortfolioProject..CovidDeaths
Where location like '%states%'
order by 1, 2

--Countries with highest infection rate compared to population (Error Message, had to add group by Location and Population for this to work)
--Percentage Infected seems wrong for me because San Marino shows as 75% which seems wrong.  
--Alex shows % for Andorra as 17% my results show Andorra as 60% 
Select Location, Population, Max(total_cases) as HighestInfectionCount, population, Max((total_cases/population))*100 as PercentofPopulationInfected
from PortfolioProject..CovidDeaths
--Where location like '%Andorra%'
Group by Location, Population
order by PercentofPopulationInfected desc

--Breaking things down by Continent
Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc

--Countries with the highest Death Count Rate per population
--When we run, the TotalDeathCount was incorrect because of data type for total_death.
--Had to Cast total_deaths for the correct count to show up
--Also some locations that showed up should not be there, was grouping entire continent.
--To fix contient grouping issue, 
Select Location, Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount desc

--Below numbers seem more accurate when we use where continent is null for location
--High Income, Upper middle income and Lower middle income showing up in my data but not for Alex
--Alex plans to use the continent is null for this exercise going forward
Select location, Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
Where continent is null
Group by location
order by TotalDeathCount desc

--Global Numbers
--Alex was able to run below but did not look right, but did not run for me
Select date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
Where continent is not null
--Group by date
order by 1, 2

--Global Numbers
--Alex finally got below to work but does not look correct for me
--I am seeing alot more NULL than expected
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--Where continent is not null
Group by date
order by 1, 2

--JOIN DEATHS AND VACCINATION TABLES
--my amounts are different from Alex
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2, 3

--Looking at Total Population vs Vaccinations
--getting Arithmetic overflow error converting expression to a data type int
--It is "Warning: Null value is eliminated by an aggregate or other SET operations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2, 3


--USE CTE
--Getting Arithmetic overflow error converting expression to data type int
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2, 3
)

Select *, (RollingPeopleVaccinated/Population)* 100 
From PopvsVAC


--TEMP TABLE
--Getting Arithmetic overflow error converting expression to data type int
DROP Table if exists #PercentPopulationVaccinated
Create Table  #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date Datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

Select *, (RollingPeopleVaccinated/Population)* 100 
From #PercentPopulationVaccinated


--Creating View to store data for later visualization
--Had to take the d off the end of View name since I created this same view before.
--Was telling me the view exist already

Create View PercentPopulationVaccinate as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int, new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) 
as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2, 3

--To query the View
Select *
From PercentPopulationVaccinate