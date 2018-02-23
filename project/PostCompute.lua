function PostCompute(project)
    print('POST COMPUTE:\n')
    
    local cp = require 'coolprop'
    
    -- To get the result optimization parameter of a unit:
    -- 1. Load the unit results:
    --    unit = project:getUnit('projectName_clusterName_locationName_unitId_unitName')
    -- 2. Get the required variable (for instance, the Mult_t)
    --    x = unit.Units_Mult_t[1]
    
    -- To get an input parameter
    -- parameter = project.getTag('locationName.unitName.parameterName')
    
    
    
    ---

    -- Get results of a unit
    local aaa = project.getTag('exhaust_boiler.orc.PMAX_TURBINE')
    local Fuel_Supply = project:getUnit('CruiseShip_02_Operational_OtherComp_other_components_fuel_supply_Fuel_Supply')
    local FuelConsumption1 = Fuel_Supply.Units_Mult_t[1] * project.operatingparam[1][2]["timesValues"][1]["value"]
    --local FuelConsumption2 = NG_Supply.Units_Mult_t[2] * project.operatingparam[1][2]["timesValues"][2]["value"]
    --local FuelConsumption3 = NG_Supply.Units_Mult_t[3] * project.operatingparam[1][2]["timesValues"][3]["value"]
    --local FuelConsumption4 = NG_Supply.Units_Mult_t[4] * project.operatingparam[1][2]["timesValues"][4]["value"]
    --local FuelConsumption5 = NG_Supply.Units_Mult_t[5] * project.operatingparam[1][2]["timesValues"][5]["value"]
    --local FuelConsumption6 = NG_Supply.Units_Mult_t[6] * project.operatingparam[1][2]["timesValues"][6]["value"]
    local FuelConsumptionMax = project:getTag('Loc.fuel_supply.MAX_INTAKE')
    local FuelLHV = project:getTag('Loc.fuel_supply.FUEL_LHV')
    --local FuelConsumptionTot = (FuelConsumption1 + FuelConsumption2 + FuelConsumption3 + FuelConsumption4 + FuelConsumption5 + FuelConsumption6) * FuelConsumptionMax / FuelLHV / 1000 * 3600 
    --print('Total fuel consumption equal to '..FuelConsumptionTot..' ton')

    local investmentCosts = project.results.Costs_Cost["DefaultInvCost"][1]
    local operationalCosts = project.results.Costs_Cost["DefaultOpCost"][1]
  -- Output to CSV file
    local results = 'OpCosts,'..operationalCosts
    local fid = io.open('C:\\Users\\FrancescoBaldi\\switchdrive\\Software\\OsmoseSuite\\Osmose\\projects\\CruiseShip_02\\Operational\\osmose_output.txt','w')
    fid:write(results)
    fid:close()
    

  
  
end

--
--