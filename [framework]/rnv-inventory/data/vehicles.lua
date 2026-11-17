return {
	-- 0	vehicle has no storage
	-- 1	vehicle has no trunk storage
	-- 2	vehicle has no glovebox storage
	-- 3	vehicle has trunk in the hood
	Storage = {
		[joaat('jester')] = 3,
		[joaat('adder')] = 3,
		[joaat('osiris')] = 1,
		[joaat('pfister811')] = 1,
		[joaat('penetrator')] = 1,
		[joaat('autarch')] = 1,
		[joaat('bullet')] = 1,
		[joaat('cheetah')] = 1,
		[joaat('cyclone')] = 1,
		[joaat('voltic')] = 1,
		[joaat('reaper')] = 3,
		[joaat('entityxf')] = 1,
		[joaat('t20')] = 1,
		[joaat('taipan')] = 1,
		[joaat('tezeract')] = 1,
		[joaat('torero')] = 3,
		[joaat('turismor')] = 1,
		[joaat('fmj')] = 1,
		[joaat('infernus')] = 1,
		[joaat('italigtb')] = 3,
		[joaat('italigtb2')] = 3,
		[joaat('nero2')] = 1,
		[joaat('vacca')] = 3,
		[joaat('vagner')] = 1,
		[joaat('visione')] = 1,
		[joaat('prototipo')] = 1,
		[joaat('zentorno')] = 1,
		[joaat('trophytruck')] = 0,
		[joaat('trophytruck2')] = 0,
	},

	-- slots, maxWeight; default weight is 8000 per slot
	glovebox = {
		[0] = {11, 88000},		-- Compact
		[1] = {11, 88000},		-- Sedan
		[2] = {11, 88000},		-- SUV
		[3] = {11, 88000},		-- Coupe
		[4] = {11, 88000},		-- Muscle
		[5] = {11, 88000},		-- Sports Classic
		[6] = {11, 88000},		-- Sports
		[7] = {11, 88000},		-- Super
		[8] = {5, 40000},		-- Motorcycle
		[9] = {11, 88000},		-- Offroad
		[10] = {11, 88000},		-- Industrial
		[11] = {11, 88000},		-- Utility
		[12] = {11, 88000},		-- Van
		[14] = {31, 248000},	-- Boat
		[15] = {31, 248000},	-- Helicopter
		[16] = {51, 408000},	-- Plane
		[17] = {11, 88000},		-- Service
		[18] = {11, 88000},		-- Emergency
		[19] = {11, 88000},		-- Military
		[20] = {11, 88000},		-- Commercial (trucks)
		models = {
			[joaat('xa21')] = {11, 88000}
		}
	},

	trunk = {
		[0] = {21, 168000},		-- Compact
		[1] = {41, 328000},		-- Sedan
		[2] = {51, 408000},		-- SUV
		[3] = {31, 248000},		-- Coupe
		[4] = {41, 328000},		-- Muscle
		[5] = {31, 248000},		-- Sports Classic
		[6] = {31, 248000},		-- Sports
		[7] = {21, 168000},		-- Super
		[8] = {5, 40000},		-- Motorcycle
		[9] = {51, 408000},		-- Offroad
		[10] = {51, 408000},	-- Industrial
		[11] = {41, 328000},	-- Utility
		[12] = {61, 488000},	-- Van
		-- [14] -- Boat
		-- [15] -- Helicopter
		-- [16] -- Plane
		[17] = {41, 328000},	-- Service
		[18] = {41, 328000},	-- Emergency
		[19] = {41, 328000},	-- Military
		[20] = {61, 488000},	-- Commercial
		models = {
			[joaat('xa21')] = {11, 10000}
		},
	}
}
