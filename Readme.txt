This readme file provides a description of the models of the fuel cell ship optimization project. 

More information about the details of the system can be found in the paper (format PDF) in the same folder. Please read the paper before going through the Readme file

The structure of an OSMOSE project can be described as follows:
- A frontend file (subfolder "projects") that acts as a "main" codefile
- A number of "ET files" (subfolder "ET"), each of them describing a specific technology. In particular, in the ship systems used in this work we have models for:
	- Diesel engines (5 of them)
	- Rankine cycle for waste heat recovery
	- Boiler
	- Exhaust gas boiler	
- A number of .csv files (subfolder "projects") that contain information about certain specific inputs to the problem. In particular:
	- typicalDaysDemand.csv includes the values of the energy demand for the ship
	- typicalDaysGeneral.csv provides some general information about the problem for each time step (time step duration, etc)
- A postcompute file (subfolder "projects"), where we can process the problem output. In this specific case, in the postcompute file I load a number of useful figures from the problem and write them all in a .csv output file ("osmose_output.csv")

OSMOSE does the following:
- Loads all fhe files containing information about the problem (ET files describing a technology, csv files with the data, etc)
- Processes all the data in a structured data format (Lua tables)
- Based on templates, writes an optimization problem using the AMPL language
- Tells the solver (CPLEX, GLPK) to solve the problem
- Loads the results 
- Prepares coffee

Note the following: 
- The current version of the frontend file has no locations (as the name suggests): this means that all components can exchange everything with each other. This is not fully realistic, and part of the work should also include the investigation of "more realistic" scenarios where the heat from the engines has to be extracted using a heat-transfer fluid
- In order to avoid making the problem nonlinear, I included a number of assumptions related to the WHR system. In particular:
	- Since we expect it to recover energy from the exhaust gas, the maximum temperature of the cycle corresponds to the exhaust gas maximum temperature 
	- The pressure of the water in the WHR is calculated so to avoid condensation in the turbine. You can see this in the ET definition, where the P_EVA is calculated using a veeeeeeeeery long function that calculates the appropriate pressure iteratively. 
	- The condensation pressure of the WHR cycle is assumed to be the minimum allowed by the temperature of the seawater temperature for the condenser. This is a rather poor assumption: in some time steps it would be better to have a "cogeneration" system, where the condensation temperature is higher and it can be used as the heat source for the heat demand. I don't know if it is ALWAYS better though, so this should also be looked into!


