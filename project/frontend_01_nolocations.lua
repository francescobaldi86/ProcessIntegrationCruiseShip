local osmose = require 'lib.osmose'
local frontend = osmose.Project ('CruiseShip_03_nolocations','OperatingCost')

frontend.operationalCosts = 'input_general_full.csv'
frontend:scenario(1):period(1):time(1)

frontend.options.graph = {}
--frontend.options.graph.spaghetti = {}
frontend.options.unitconversion = false
frontend.options.autodTmin = {activate = true, C = 2, alpha= {gas = 0.06, liquid = 0.5, evap = 3.6, cond = 1.6}}

-- General inputs
frontend.T_TC_OUT = {default=300, unit='C'}
frontend.T_SW_OUT = {default=25, unit='C'}
frontend.C = {default=2, unit='K*m'} 
frontend.alpha_gas = {default=0.06, unit='m^2'} 
frontend.alpha_liquid = {default=0.5, unit='m^2'} 
frontend.alpha_evap = {default=3.6, unit='m^2'} 
frontend.alpha_cond = {default=1.6, unit='m^2'} 

--frontend.clusters = {EngineRoom={'engine_room'},Users={'users'},OtherComp={'other_components'},ExhaustBoiler={'exhaust_boiler'}}


frontend:load(
    -- Processes
    {prop = 'ShipComponents.PropellerMech', with = 'demand_electrical_full.csv'}, 
    --{aux_el = 'ShipComponents.AuxiliaryPowerDemand', with='input_demands_1ts.csv'}, 
    {ht_heat = 'ShipComponents.HeatDemandGen', with='demand_HTheat_full.csv'},
    {lt_heat = 'ShipComponents.HeatDemandGen', with='demand_LTheat_full.csv'},
               
     --Connections World <-> Cluster
    {fuel_supply = 'ShipComponents.FuelInput'},  
    {environment = 'ShipComponents.Environment'},
    
    -- Engines
    {diesel_engine1 = 'ET.DieselEngines.DieselEngine_v11', with='ME1.csv'},
    {diesel_engine2 = 'ET.DieselEngines.DieselEngine_v11', with='ME2.csv'},
    {diesel_engine3 = 'ET.DieselEngines.DieselEngine_v11', with='ME3.csv'},
    {diesel_engine4 = 'ET.DieselEngines.DieselEngine_v11', with='ME4.csv'},
    {diesel_engine5 = 'ET.DieselEngines.DieselEngine_v11', with='ME4.csv'},
    
    -- Hot Utilities
    {burner = 'ShipComponents.DieselBurner'},
    {engine_exhust = 'ShipComponents.ChimneyDesLoad'},
    
    -- Cold Utilities
    {free_cooling = 'ShipComponents.SeaWaterCooling'},
    
    -- Converters
    {el_mot = 'ET.Converters.ElectricMotor'},
    {el_gen = 'ET.Converters.ElectricGenerator'},
    
    -- WHR
    {orc = 'Et.WHR.RankineSteamLin', with='optivar.csv'}
    
    -- Heat transfer
    --{hpsteam_generator = 'ET.Heaters.HPSteamGenerator', with='optivar_reference.csv'},
    --{hpsteam_heater = 'ET.Heaters.HPSteamHeater', with='optivar_reference.csv'},
    --{lpsteam_generator = 'ET.Heaters.LPSteamGenerator', with='optivar_reference.csv', locations={'engine_room','exhaust_boiler'}},
    --{lpsteam_heater = 'ET.Heaters.LPSteamHeater', with='optivar_reference.csv', locations={'users'}},
    --{hw_generator = 'ET.Heaters.HWGenerator', with='optivar_reference.csv'},
    --{hw_heater = 'ET.Heaters.HWHeater', with='optivar_reference.csv'}
  )  




--frontend.options.mathProg = {}
frontend.options.mathProg.language = 'ampl'
-- frontend.options.mathProg.solver = 'cplex'
--frontend.options.mathProg.options  = {'--mipgap 0.001','--tmlim 200'}  --https://en.wikibooks.org/wiki/GLPK/Using_GLPSOL

--frontend.options.graph.format = 'jpg'               -- 'eps', 'jpg', 'svg'
--frontend.options.graph.force_enthalpy = true
--frontend.options.graph.spaghetti = true --             true OR false( or not defined)

--frontend.options.return_solver
--frontend.options.doLCA = true
--frontend.options.postprint                   true OR false

frontend:solve()

frontend:compute('PostCompute.lua')