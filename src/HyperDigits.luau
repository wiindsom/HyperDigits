--!optimize 2
--!native
--!nocheck
-- selene: allow(shadowing)

--[[

██╗░░██╗██╗░░░██╗██████╗░███████╗██████╗░██████╗░██╗░██████╗░██╗████████╗░██████╗
██║░░██║╚██╗░██╔╝██╔══██╗██╔════╝██╔══██╗██╔══██╗██║██╔════╝░██║╚══██╔══╝██╔════╝
███████║░╚████╔╝░██████╔╝█████╗░░██████╔╝██║░░██║██║██║░░██╗░██║░░░██║░░░╚█████╗░
██╔══██║░░╚██╔╝░░██╔═══╝░██╔══╝░░██╔══██╗██║░░██║██║██║░░╚██╗██║░░░██║░░░░╚═══██╗
██║░░██║░░░██║░░░██║░░░░░███████╗██║░░██║██████╔╝██║╚██████╔╝██║░░░██║░░░██████╔╝
╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═════╝░╚═╝░╚═════╝░╚═╝░░░╚═╝░░░╚═════╝░

Original is AlyaNum. Fork named to HyperDigits as an extension using the original as a base.
Implements a number system with support for hyperoperations (tetration, pentation, etc.) and extremely large values.
Current Limit is 10^^^^^10 aka heptation. Current normal operation(add/sub/mul/div) limit is 1e1e308 or 10^(10^308).

AlyaNum Creator: evilbocchi | https://github.com/evilbocchi
HyperDigits Maintainer: Arc(windsom) | https://github.com/wiindsom

What this version extends from the original:
> Support for percentages via fromPercentage + toPercent
> Custom Short-Suffix Support(Mirror copy from Saber Simulator)
> Customizable Number Cap + Cap Message
> Smooth Automatic Abbreviation Conversions(Only if they hit their own limit)
]]

local HttpService = game:GetService("HttpService")

local DECIMAL_POINTS = 2
local PERCENT_DECIMAL_POINTS = 3

local MAX_CAP = "1e44292"
local CAP_MESSAGE = "Incomprehensible"
local ENABLE_CAP = false

local DEFAULT_ABBREVIATION: "suffix" | "scientific" | "saber" = "suffix"

local FLOAT64_LIMIT = 1.797693015e308
local LOG10_FLOAT64_LIMIT = math.log10(FLOAT64_LIMIT)

local FLOAT64_SAFE_LIMIT = math.pow(2, 53) - 1
local LOG10_FLOAT64_SAFE_LIMIT = math.log10(FLOAT64_SAFE_LIMIT)

local HUGE = math.huge

local suffixes = {
	beginning = { "K", "M", "B" },
	first = { "U", "D", "T", "Qd", "Qn", "Sx", "Sp", "Oc", "No" },
	second = { "De", "Vt", "Tg", "Qdg", "Qng", "Sxg", "Spg", "Ocg", "Nog" },
	third = { "Ce", "Dce", "Tce", "Qdce", "Qnce", "Sxce", "Spce", "Occe", "Noce" },
	mult = {
		"Mi","Mc","Na","Pi","Fm","At","Zp","Yc","Xo","Ve","Me",
		"Due","Tre","Te","Pt","He","Hp","Oct","En","Ic","Mei",
		"Dui","Tri","Teti","Pti","Hei","Hp","Oci","Eni","Tra","TeC",
		"MTc","DTc","TrTc","TeTc","PeTc","HTc","HpT","OcT","EnT","TetC","MTetc",
		"DTetc","TrTetc","TeTetc","PeTetc","HTetc","HpTetc","OcTetc","EnTetc","PcT",
		"MPcT","DPcT","TPCt","TePCt","PePCt","HePCt","HpPct","OcPct","EnPct","HCt",
		"MHcT","DHcT","THCt","TeHCt","PeHCt","HeHCt","HpHct","OcHct","EnHct","HpCt",
		"MHpcT","DHpcT","THpCt","TeHpCt","PeHpCt","HeHpCt","HpHpct","OcHpct","EnHpct",
		"OCt","MOcT","DOcT","TOCt","TeOCt","PeOCt","HeOCt","HpOct","OcOct","EnOct","Ent","MEnT",
		"DEnT","TEnt","TeEnt","PeEnt","HeEnt","HpEnt","OcEnt","EnEnt","Hect","MeHect"
	}
}

local DP_OFFSET = math.pow(10, DECIMAL_POINTS)

export type BaseHyperDigits = {
	sign: number,
	multiplicand: number,
	exponent: number,
	tetrate: number,
	pentate: number,
	hexate: number,
	heptate: number
}

export type Number = BaseHyperDigits | number | HyperDigits

local HyperDigits = {}
HyperDigits["__index"] = HyperDigits

function fix(number: BaseHyperDigits): HyperDigits
	if number.sign == 0 then
		number.multiplicand = 0
		number.exponent = 0
		number.tetrate = 0
		number.pentate = 0
		number.hexate = 0
		number.heptate = 0
		return setmetatable(number, HyperDigits)
	elseif math.sign(number.multiplicand) == -1 then
		number.multiplicand = math.abs(number.multiplicand)
		number.sign = -number.sign
	end
	if number.multiplicand >= FLOAT64_SAFE_LIMIT then
		number.multiplicand = math.log10(number.multiplicand)
		number.exponent += 1
	end

	if number.exponent == 0 then
		local total = number.tetrate + number.pentate + number.hexate + number.heptate
		if number.multiplicand == 0 and total == 0 then
			number.sign = 0
			return setmetatable(number, HyperDigits)
		elseif number.multiplicand == 1 and total == 1 then
			number.multiplicand = 10
			number.tetrate = 0
			number.pentate = 0
			number.hexate = 0
			number.heptate = 0
		end
	end

	if number.multiplicand < LOG10_FLOAT64_SAFE_LIMIT and number.exponent > 0 then
		number.multiplicand = math.pow(10, number.multiplicand)
		number.exponent -= 1
		if number.multiplicand < LOG10_FLOAT64_SAFE_LIMIT and number.exponent > 0 then
			number.multiplicand = math.pow(10, number.multiplicand)
			number.exponent -= 1
		end
	end

	if number.hexate >= FLOAT64_SAFE_LIMIT then
		number.multiplicand = math.log10(number.hexate)
		number.heptate += 1
		number.exponent = 1
		number.tetrate = 0
		number.pentate = 0
		number.hexate = 0
	elseif number.pentate >= FLOAT64_SAFE_LIMIT then
		number.multiplicand = math.log10(number.pentate)
		number.hexate += 1
		number.exponent = 1
		number.tetrate = 0
		number.pentate = 0
	elseif number.tetrate >= FLOAT64_SAFE_LIMIT then
		number.multiplicand = math.log10(number.tetrate)
		number.pentate += 1
		number.exponent = 1
		number.tetrate = 0
	elseif number.exponent >= FLOAT64_SAFE_LIMIT then
		number.multiplicand = math.log10(number.exponent)
		number.tetrate += 1
		number.exponent = 1
	end

	return setmetatable(number, HyperDigits)
end

function HyperDigits.new(number: number | BaseHyperDigits): HyperDigits
	if type(number) == "number" then
		if number == HUGE then
			return fix({ sign = 0, multiplicand = 0, exponent = 0, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
		end
		return fix({ sign = math.sign(number), multiplicand = math.abs(number), exponent = 0, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
	end
	return setmetatable(number :: BaseHyperDigits, HyperDigits)
end

local ZERO = HyperDigits.new(0)
local ONE = HyperDigits.new(1)
local TWO = HyperDigits.new(2)
local THREE = HyperDigits.new(3)
local NEG_ONE = HyperDigits.new(-1)
local NEG_TWO = HyperDigits.new(-2)
local TEN = HyperDigits.new(10)
local E = HyperDigits.new(math.exp(1))
local ERECIPE = HyperDigits.new(math.exp(1 / math.exp(1)))

local E308 = HyperDigits.new(1e308)
local LAMBERTW_TOL = 1e-10
local H_LAMBERTW_TOL = HyperDigits.new(LAMBERTW_TOL)
local MAX_SAFE = HyperDigits.new(FLOAT64_SAFE_LIMIT)
local MAX_ALLOWED = HyperDigits.new(FLOAT64_LIMIT)
local MAX_ADD = HyperDigits.new({ sign = 1, multiplicand = FLOAT64_SAFE_LIMIT, exponent = 1, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
local MAX_MUL = HyperDigits.new({ sign = 1, multiplicand = FLOAT64_SAFE_LIMIT, exponent = 2, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
local MAX_POW = HyperDigits.new({ sign = 1, multiplicand = 1, exponent = FLOAT64_SAFE_LIMIT, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
local MAX_TETRATE = HyperDigits.new({ sign = 1, multiplicand = 10000000000, exponent = 8, tetrate = FLOAT64_SAFE_LIMIT, pentate = 0, hexate = 0, heptate = 0 })
local MAX_PENTATE = HyperDigits.new({ sign = 1, multiplicand = 10000000000, exponent = 8, tetrate = 8, pentate = FLOAT64_SAFE_LIMIT, hexate = 0, heptate = 0 })
local MAX_HEXATE = HyperDigits.new({ sign = 1, multiplicand = 10000000000, exponent = 8, tetrate = 8, pentate = 8, hexate = FLOAT64_SAFE_LIMIT, heptate = 0 })
local MAX_FRACTIONAL = HyperDigits.new(0.000000001)
local MAX_SUFFIX = HyperDigits.new({ sign = 1, multiplicand = 3000000, exponent = 1, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
local MAX_SCIENTIFIC = HyperDigits.new({ sign = 1, multiplicand = 300008, exponent = 4, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
local MAX_E_CHAIN = HyperDigits.new({ sign = 1, multiplicand = 10000000000, exponent = 8, tetrate = 1, pentate = 0, hexate = 0, heptate = 0 })
local MAX_ENT = HyperDigits.new({ sign = 1, multiplicand = 306, exponent = 1, tetrate = 2, pentate = 0, hexate = 0, heptate = 0 })

local SCI_CHAIN_SWITCH = HyperDigits.new({ sign = 1, multiplicand = 308, exponent = 2, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })

function compare(self: HyperDigits, number: HyperDigits): number
	if self.sign ~= number.sign then
		return self.sign > number.sign and 1 or -1
	elseif self.heptate ~= number.heptate then
		return self.heptate > number.heptate and 1 or -1
	elseif self.hexate ~= number.hexate then
		return self.hexate > number.hexate and 1 or -1
	elseif self.pentate ~= number.pentate then
		return self.pentate > number.pentate and 1 or -1
	elseif self.tetrate ~= number.tetrate then
		return self.tetrate > number.tetrate and 1 or -1
	elseif self.exponent ~= number.exponent then
		return self.exponent > number.exponent and 1 or -1
	elseif self.multiplicand ~= number.multiplicand then
		return self.multiplicand > number.multiplicand and 1 or -1
	else
		return 0
	end
end

function absCompare(self: HyperDigits, number: HyperDigits): number
	if self.heptate ~= number.heptate then
		return self.heptate > number.heptate and 1 or -1
	elseif self.hexate ~= number.hexate then
		return self.hexate > number.hexate and 1 or -1
	elseif self.pentate ~= number.pentate then
		return self.pentate > number.pentate and 1 or -1
	elseif self.tetrate ~= number.tetrate then
		return self.tetrate > number.tetrate and 1 or -1
	elseif self.exponent ~= number.exponent then
		return self.exponent > number.exponent and 1 or -1
	elseif self.multiplicand ~= number.multiplicand then
		return self.multiplicand > number.multiplicand and 1 or -1
	else
		return 0
	end
end

function equals(self: HyperDigits, number: HyperDigits): boolean
	return self.sign == number.sign
		and self.multiplicand == number.multiplicand
		and self.exponent == number.exponent
		and self.tetrate == number.tetrate
		and self.pentate == number.pentate
		and self.hexate == number.hexate
		and self.heptate == number.heptate
end

function moreThan(self: HyperDigits, number: HyperDigits): boolean
	return compare(self, number) == 1
end

function lessThan(self: HyperDigits, number: HyperDigits): boolean
	return compare(self, number) == -1
end

function moreEquals(self: HyperDigits, number: HyperDigits): boolean
	return compare(self, number) >= 0
end

function lessEquals(self: HyperDigits, number: HyperDigits): boolean
	return compare(self, number) <= 0
end

function absMoreThan(self: HyperDigits, number: HyperDigits): boolean
	return absCompare(self, number) == 1
end

function absLessThan(self: HyperDigits, number: HyperDigits): boolean
	return absCompare(self, number) == -1
end

function absMoreEquals(self: HyperDigits, number: HyperDigits): boolean
	return absCompare(self, number) >= 0
end

function equalsOne(self: HyperDigits): boolean
	return self.sign == 1 and self.multiplicand == 1 and self.exponent == 0 and self.tetrate == 0 and self.pentate == 0 and self.hexate == 0 and self.heptate == 0
end

function max(self: HyperDigits, number: HyperDigits): HyperDigits
	if moreThan(self, number) then
		return self
	else
		return number
	end
end

function min(self: HyperDigits, number: HyperDigits): HyperDigits
	if moreThan(self, number) then
		return number
	else
		return self
	end
end

function minmax(self: HyperDigits, number: HyperDigits): (HyperDigits, HyperDigits)
	if lessThan(self, number) then
		return self, number
	else
		return number, self
	end
end

function absMax(self: HyperDigits, number: HyperDigits): HyperDigits
	if absMoreThan(self, number) then
		return self
	else
		return number
	end
end

function absMinmax(self: HyperDigits, number: HyperDigits): (HyperDigits, HyperDigits)
	if absLessThan(self, number) then
		return self, number
	else
		return number, self
	end
end

function mutableUnary(self: HyperDigits): HyperDigits
	self.sign = -self.sign
	return self
end

function unary(self: HyperDigits): HyperDigits
	return setmetatable({
		sign = -self.sign,
		multiplicand = self.multiplicand,
		exponent = self.exponent,
		tetrate = self.tetrate,
		pentate = self.pentate,
		hexate = self.hexate,
		heptate = self.heptate
	}, HyperDigits)
end

function abs(self: HyperDigits): HyperDigits
	return setmetatable({
		sign = 1,
		multiplicand = self.multiplicand,
		exponent = self.exponent,
		tetrate = self.tetrate,
		pentate = self.pentate,
		hexate = self.hexate,
		heptate = self.heptate
	}, HyperDigits)
end

function HyperDigits.fromOnoe(onoeNum: { mantissa: number, exponent: number } & BaseHyperDigits): HyperDigits
	local number: BaseHyperDigits
	if onoeNum.sign ~= nil then
		number = onoeNum :: BaseHyperDigits
	else
		number = { sign = math.sign(onoeNum.mantissa), multiplicand = math.log10(onoeNum.mantissa) + onoeNum.exponent, exponent = 1, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 }
	end
	return fix(number)
end

function HyperDigits.fromOmega(onum: unknown): HyperDigits
	local number: BaseHyperDigits
	if onum.sign ~= nil then
		number = onum :: BaseHyperDigits
	else
		number = {
			sign = onum[1] or 0,
			multiplicand = onum[2][1] or 0,
			exponent = onum[2][2] or 0,
			tetrate = onum[2][3] or 0,
			pentate = onum[2][4] or 0,
			hexate = onum[2][5] or 0,
			heptate = onum[2][6] or 0
		}
	end
	return fix(number)
end

function toNumber(self: HyperDigits): number
	if self.exponent >= 2 or (self.exponent == 1 and self.multiplicand > LOG10_FLOAT64_LIMIT) then
		return HUGE * self.sign
	end
	return self.exponent == 1 and math.pow(10, self.multiplicand) * self.sign or self.multiplicand * self.sign
end

function toSerika(self: HyperDigits): (number, number)
	local mantissa: number
	local exponent: number
	if self.exponent == 0 then
		mantissa = (self.multiplicand / math.pow(10, math.floor(math.log10(self.multiplicand)))) * self.sign
		exponent = math.floor(math.log10(self.multiplicand))
	elseif self.exponent == 1 then
		mantissa = math.pow(10, self.multiplicand - math.floor(self.multiplicand)) * self.sign
		exponent = math.floor(self.multiplicand)
	elseif self.exponent == 2 and self.multiplicand <= 308 then
		local exp = math.pow(10, self.multiplicand)
		mantissa = math.pow(10, (exp - math.floor(exp))) * self.sign
		exponent = math.floor(exp)
	else
		return 10, HUGE
	end
	return mantissa, exponent
end

local function serikaNumEnforceDP(mantissa: number, exponent: number): string
	if DECIMAL_POINTS <= 0 then
		return tostring(math.floor(mantissa * math.pow(10, exponent)))
	end
	local scaled = mantissa * math.pow(10, exponent)
	local roundedInt = math.round(scaled)
	if math.abs(scaled - roundedInt) < 1e-9 then
		return string.format("%d", roundedInt)
	end
	local s = string.format("%."..DECIMAL_POINTS.."f", scaled)
	s = string.gsub(s, "0+$", "")
	s = string.gsub(s, "%.$", "")
	return s
end

function getTier1Suffix(exponent: number, hasBeginning: boolean?): string?
	if exponent < 3 then
		return nil
	else
		local suffix = ""
		if exponent < HUGE then
			exponent = math.floor(exponent / 3) - 1
			if hasBeginning == true and exponent < 3 then
				suffix = suffixes.beginning[exponent + 1]
			else
				local firstDivisee = exponent
				local secondDivisee: number
				local thirdDivisee: number
				if exponent > 99 then
					thirdDivisee = math.floor(exponent / 100)
					suffix = suffixes.third[thirdDivisee]
					if suffix == nil then
						return nil
					end
				end
				if exponent > 9 then
					secondDivisee = math.floor(exponent / 10)
					if thirdDivisee ~= nil then
						secondDivisee -= thirdDivisee * 10
						firstDivisee -= thirdDivisee * 100
					end
					firstDivisee -= secondDivisee * 10
					local second = suffixes.second[secondDivisee]
					if second ~= nil then
						suffix = second..suffix
					end
					local first = suffixes.first[firstDivisee]
					if first ~= nil then
						suffix = first..suffix
					end
				else
					suffix = suffixes.first[firstDivisee]
				end
			end
		end
		return suffix
	end
end

function getTier2Suffix(exponent: number): string?
	if exponent == HUGE then
		return
	end
	exponent = math.floor(exponent / 3) - 1
	local suffix = ""
	for i = math.floor(math.log10(exponent) / 3), 0, -1 do
		local powed = math.pow(10, i * 3)
		if exponent >= powed then
			local part1Exponent = math.floor(exponent / powed)
			if part1Exponent > 1000 then
				part1Exponent = math.fmod(part1Exponent, 1000)
			end
			local part1 = getTier1Suffix((part1Exponent + 1) * 3, false)
			if part1 ~= nil and part1 ~= "U" then
				suffix ..= part1
			end
			if i ~= 0 then
				local part2 = suffixes.mult[i]
				if part2 ~= nil then
					suffix ..= part2
				end
			end
			exponent = math.fmod(exponent, powed)
		end
	end
	return suffix
end

function serikaNumToSuffix(mantissa: number, exponent: number): string?
	if exponent < 3 then
		return serikaNumEnforceDP(mantissa, exponent)
	end
	local suffix = exponent > 3002 and getTier2Suffix(exponent) or getTier1Suffix(exponent, true)
	local formattedMantissa = serikaNumEnforceDP(mantissa, exponent % 3)
	return suffix and formattedMantissa..suffix
end

function numberToSuffix(number: number): string?
	local exponent = math.floor(math.log10(math.abs(number)))
	return serikaNumToSuffix(number / (math.pow(10, exponent)), exponent)
end

function serikaNumToScientific(mantissa: number, exponent: number): string
	local e: string
	if exponent == 0 then
		e = "0"
	else
		e = numberToSuffix(exponent)
	end
	return tostring(math.floor(mantissa * DP_OFFSET) / DP_OFFSET)
		.. "e"
		.. (e == nil and tostring(math.floor(exponent * DP_OFFSET) / DP_OFFSET) or e)
end

local function isHugeForm(n: HyperDigits): boolean
	return n.heptate ~= 0 or n.hexate ~= 0 or n.pentate ~= 0 or n.tetrate ~= 0 or n.exponent >= 2
end

local MAX_PLAIN_EXP = 1e6

local function isSimpleInt(n: HyperDigits): boolean
	return n.sign ~= 0 and not isHugeForm(n) and n.exponent == 0
end

local function trimDecimals(s: string): string
	if not string.find(s, "%.") then
		return s
	end
	s = string.gsub(s, "0+$", "")
	s = string.gsub(s, "%.$", "")
	return s
end

function mutableLog10(self: HyperDigits): HyperDigits
	if self.sign <= 0 then
		return ZERO
	end
	if self.exponent == 0 then
		self.multiplicand = math.log10(self.multiplicand)
	else
		self.exponent -= 1
	end
	return self
end

function log10(self: HyperDigits): HyperDigits
	if self.sign <= 0 then
		return ZERO
	end
	return setmetatable(self.exponent == 0 and {
		sign = self.sign,
		multiplicand = math.log10(self.multiplicand),
		exponent = self.exponent,
		tetrate = self.tetrate,
		pentate = self.pentate,
		hexate = self.hexate,
		heptate = self.heptate
	} or {
		sign = self.sign,
		multiplicand = self.multiplicand,
		exponent = self.exponent - 1,
		tetrate = self.tetrate,
		pentate = self.pentate,
		hexate = self.hexate,
		heptate = self.heptate
	}, HyperDigits)
end

function add(self: HyperDigits, number: HyperDigits): HyperDigits
	if self.sign == 0 then
		return number
	elseif number.sign == 0 then
		return self
	end

	local minAbsNum, maxAbsNum = absMinmax(self, number)

	if maxAbsNum.heptate ~= 0 or maxAbsNum.hexate ~= 0 or maxAbsNum.pentate ~= 0 or maxAbsNum.tetrate ~= 0 or maxAbsNum.exponent > 1 then
		return maxAbsNum
	end

	if maxAbsNum.exponent == 0 then
		return fix({
			sign = 1,
			multiplicand = (minAbsNum.sign * minAbsNum.multiplicand) + (maxAbsNum.sign * maxAbsNum.multiplicand),
			exponent = 0,
			tetrate = 0,
			pentate = 0,
			hexate = 0,
			heptate = 0
		})
	end

	local adjMinMult = minAbsNum.exponent == 0 and math.log10(minAbsNum.multiplicand) or minAbsNum.multiplicand

	if maxAbsNum.multiplicand - adjMinMult >= LOG10_FLOAT64_LIMIT then
		return maxAbsNum
	end

	local minSign, maxSign, maxMult = minAbsNum.sign, maxAbsNum.sign, maxAbsNum.multiplicand

	if maxSign == minSign then
		return fix({
			sign = maxSign,
			multiplicand = adjMinMult + math.log10(math.pow(10, maxMult - adjMinMult) + 1),
			exponent = 1,
			tetrate = 0,
			pentate = 0,
			hexate = 0,
			heptate = 0
		})
	end

	if adjMinMult == maxMult then
		return ZERO
	end

	return fix({
		sign = maxSign,
		multiplicand = adjMinMult + math.log10(math.pow(10, maxMult - adjMinMult) - 1),
		exponent = 1,
		tetrate = 0,
		pentate = 0,
		hexate = 0,
		heptate = 0
	})
end

function mutablePow10(number: HyperDigits): HyperDigits
	if number.sign == 1 then
		number.exponent += 1
		return number
	else
		return HyperDigits.new(math.pow(10, toNumber(number)))
	end
end

function pow10(number: HyperDigits): HyperDigits
	if number.sign == 1 then
		return fix({
			sign = number.sign,
			multiplicand = number.multiplicand,
			exponent = number.exponent + 1,
			tetrate = number.tetrate,
			pentate = number.pentate,
			hexate = number.hexate,
			heptate = number.heptate
		})
	else
		return HyperDigits.new(math.pow(10, toNumber(number)))
	end
end

function mul(self: HyperDigits, number: HyperDigits): HyperDigits
	if self.sign == 0 or number.sign == 0 then
		return ZERO
	elseif equalsOne(number) then
		return self
	end

	local maxNum = absMax(self, number)
	if absMoreThan(maxNum, MAX_MUL) then
		return maxNum
	end

	if self.exponent < 2 and number.exponent < 2 then
		local reverted = (self.exponent == 1 and math.pow(10, self.multiplicand) or self.multiplicand)
			* (number.exponent == 1 and math.pow(10, number.multiplicand) or number.multiplicand)
		if reverted < FLOAT64_LIMIT then
			return HyperDigits.new(self.sign * number.sign * reverted)
		end
	end

	local result = mutablePow10(add(mutableLog10(abs(self)), mutableLog10(abs(number))))
	result.sign *= self.sign * number.sign
	return result
end

function div(self: HyperDigits, number: HyperDigits): HyperDigits
	if self.sign == 0 or number.sign == 0 then
		return ZERO
	elseif equalsOne(number) then
		return self
	end

	local maxNum = absMax(self, number)
	if absMoreThan(maxNum, MAX_MUL) then
		return maxNum
	end

	if self.exponent < 2 and number.exponent < 2 then
		local reverted = (self.exponent == 1 and math.pow(10, self.multiplicand) or self.multiplicand)
			/ (number.exponent == 1 and math.pow(10, number.multiplicand) or number.multiplicand)
		if reverted < FLOAT64_LIMIT then
			return HyperDigits.new(self.sign * number.sign * reverted)
		end
	end

	local result = mutablePow10(add(mutableLog10(abs(self)), mutableUnary(mutableLog10(abs(number)))))
	result.sign *= self.sign * number.sign
	return result
end

function floor(self: HyperDigits): HyperDigits
	if (self.sign == -1 and lessThan(self, -MAX_SAFE)) or moreThan(self, MAX_SAFE) then
		return self
	end
	return HyperDigits.new(math.floor(toNumber(self)))
end

function isInteger(self: HyperDigits): boolean
	if absMoreThan(self, MAX_SAFE) then
		return true
	end
	return math.fmod(toNumber(self), 1) == 0
end

function reciprocal(self: HyperDigits): HyperDigits
	if (self.sign == -1 and lessThan(self, -MAX_ALLOWED)) or moreThan(self, MAX_ALLOWED) then
		return ZERO
	end
	return div(ONE, self)
end

function pow(self: HyperDigits, number: HyperDigits): HyperDigits
	if number.sign == 0 or equalsOne(self) then
		return ONE
	elseif equalsOne(number) then
		return self
	elseif number.sign == -1 then
		return reciprocal(pow(self, unary(number)))
	elseif self.sign == -1 and isInteger(number) then
		if lessThan(mod(number, TWO), ONE) then
			return pow(abs(self), number)
		end
		return mutableUnary(pow(abs(self), number))
	elseif self.sign <= 0 then
		return ZERO
	elseif moreEquals(max(self, number), MAX_POW) then
		return max(self, number)
	elseif equals(self, TEN) then
		return pow10(number)
	elseif lessThan(number, ONE) then
		return root(self, reciprocal(number))
	end
	return mutablePow10(mul(log10(self), number))
end

function root(self: HyperDigits, number: HyperDigits): HyperDigits
	if equalsOne(number) then
		return self
	elseif number.sign == -1 or self.sign == -1 then
		return reciprocal(root(self, unary(number)))
	elseif lessThan(number, ONE) then
		return pow(self, reciprocal(number))
	elseif number.sign == -1 and isInteger(number) and equals(mod(number, TWO), ONE) then
		return mutableUnary(root(unary(self), number))
	elseif equalsOne(self) then
		return ONE
	elseif self.sign == 0 then
		return ZERO
	elseif moreThan(max(self, number), MAX_POW) then
		if moreThan(self, number) then
			return self
		else
			return ZERO
		end
	end
	return mutablePow10(div(log10(self), number))
end

function mod(self: HyperDigits, number: HyperDigits): HyperDigits
	if self.sign == 0 then
		return ZERO
	end
	if self.sign * number.sign == -1 then
		return mutableUnary(mod(abs(self), abs(number)))
	end
	if self.sign == -1 then
		return mod(abs(self), abs(number))
	end
	return add(self, mutableUnary(mul(floor(div(self, number)), number)))
end

function log(self: HyperDigits, number: HyperDigits): HyperDigits
	if equals(number, TEN) then
		return log10(self)
	end
	return div(log10(self), log10(number))
end

function round(self: HyperDigits): HyperDigits
	if (self.sign == -1 and lessThan(self, -MAX_SAFE)) or moreThan(self, MAX_SAFE) then
		return self
	end
	return HyperDigits.new(math.floor(toNumber(self) + 0.5))
end

function ceil(self: HyperDigits): HyperDigits
	if (self.sign == -1 and lessThan(self, -MAX_SAFE)) or moreThan(self, MAX_SAFE) then
		return self
	end
	return HyperDigits.new(math.ceil(toNumber(self)))
end

function f_lambertw(z: number): number
	local w: number
	local wn: number
	if z > 1.79e308 then
		return z
	elseif z == 0 then
		return z
	elseif z == 1 then
		return 0.56714329040978387299997
	elseif z < 10 then
		w = 0
	else
		w = math.log(z) - math.log(math.log(z))
	end
	for _ = 1, 20 do
		wn = (z * math.exp(-w) + w * w) / (w + 1)
		if math.abs(wn - w) < LAMBERTW_TOL * math.abs(wn) then
			return wn
		else
			w = wn
		end
	end
	return w
end

function Hlambertw(self: HyperDigits): HyperDigits
	local wn: HyperDigits
	local w = log(self, E)
	for _ = 1, 20 do
		wn = div(add(mul(self, pow(E, unary(w))), mul(w, w)), add(w, ONE))
		if lessThan(abs(add(wn, unary(w))), mul(H_LAMBERTW_TOL, abs(wn))) then
			return wn
		end
		w = wn
	end
	return w
end

function lambertw(self: HyperDigits): HyperDigits
	if lessEquals(self, E308) then
		return HyperDigits.new(f_lambertw(toNumber(self)))
	elseif moreThan(self, MAX_POW) then
		return self
	elseif moreThan(self, MAX_MUL) then
		return log10(self)
	end
	return Hlambertw(self)
end

function slog(self: HyperDigits, base: Number): HyperDigits?
	local self = {
		sign = self.sign,
		multiplicand = self.multiplicand,
		exponent = self.exponent,
		tetrate = self.tetrate,
		pentate = self.pentate,
		hexate = self.hexate,
		heptate = self.heptate
	}
	local base = HyperDigits.new(base)

	if self.sign == -1 then
		return NEG_ONE
	elseif equalsOne(self) then
		return ZERO
	elseif equals(self, base) then
		return ONE
	elseif lessThan(base, ERECIPE) then
		return self
	elseif moreThan(max(self, base), MAX_TETRATE) then
		if moreThan(self, base) then
			return self
		end
		return ZERO
	elseif moreThan(max(self, base), MAX_POW) then
		if moreThan(self, base) then
			self.tetrate -= 1
			return fix(add(self, HyperDigits.new(-self.exponent)))
		end
		return ZERO
	end

	local q = 0
	local t = (self.exponent or 0) - (base.exponent or 0)
	if t > 3 then
		local p = t - 3
		q += p
		self.exponent -= p
	end
	for _ = 1, 99 do
		if self.sign == -1 then
			self = pow(base, self)
			q -= 1
		else
			if lessEquals(self, ONE) then
				return HyperDigits.new(q + toNumber(self) - 1)
			else
				q += 1
				self = log(self, base)
			end
		end
	end
	if moreThan(self, TEN) then
		return HyperDigits.new(q)
	end
	return nil
end

function pentlog(self: HyperDigits, base: Number): HyperDigits?
	local self = {
		sign = self.sign,
		multiplicand = self.multiplicand,
		exponent = self.exponent,
		tetrate = self.tetrate,
		pentate = self.pentate,
		hexate = self.hexate,
		heptate = self.heptate
	}
	local base = HyperDigits.new(base)

	if self.sign == -1 then
		return NEG_ONE
	elseif equalsOne(self) then
		return ZERO
	elseif equals(self, base) then
		return ONE
	elseif lessThan(base, ERECIPE) then
		return self
	elseif moreThan(max(self, base), MAX_PENTATE) then
		if moreThan(self, base) then
			return self
		end
		return ZERO
	elseif moreThan(max(self, base), MAX_TETRATE) then
		if moreThan(self, base) then
			self.pentate -= 1
			return fix(add(self, HyperDigits.new(-self.tetrate)))
		end
		return ZERO
	end

	local q = 0
	local t = (self.tetrate or 0) - (base.tetrate or 0)
	if t > 3 then
		local p = t - 3
		q += p
		self.tetrate -= p
	end
	for _ = 1, 99 do
		if self.sign == -1 then
			self = tetrate(base, self)
			q -= 1
		else
			if lessEquals(self, ONE) then
				return HyperDigits.new(q + toNumber(self) - 1)
			else
				q += 1
				self = slog(self, base)
			end
		end
	end
	if moreThan(self, TEN) then
		return HyperDigits.new(q)
	end
	return nil
end

function hextlog(self: HyperDigits, base: Number): HyperDigits?
	local self = {
		sign = self.sign,
		multiplicand = self.multiplicand,
		exponent = self.exponent,
		tetrate = self.tetrate,
		pentate = self.pentate,
		hexate = self.hexate,
		heptate = self.heptate
	}
	local base = HyperDigits.new(base)

	if self.sign == -1 then
		return NEG_ONE
	elseif equalsOne(self) then
		return ZERO
	elseif equals(self, base) then
		return ONE
	elseif lessThan(base, ERECIPE) then
		return self
	elseif moreThan(max(self, base), MAX_HEXATE) then
		if moreThan(self, base) then
			return self
		end
		return ZERO
	elseif moreThan(max(self, base), MAX_PENTATE) then
		if moreThan(self, base) then
			self.hexate -= 1
			return fix(add(self, HyperDigits.new(-self.pentate)))
		end
		return ZERO
	end

	local q = 0
	local t = (self.pentate or 0) - (base.pentate or 0)
	if t > 3 then
		local p = t - 3
		q += p
		self.pentate -= p
	end
	for _ = 1, 99 do
		if self.sign == -1 then
			self = pentate(base, self)
			q -= 1
		else
			if lessEquals(self, ONE) then
				return HyperDigits.new(q + toNumber(self) - 1)
			else
				q += 1
				self = pentlog(self, base)
			end
		end
	end
	if moreThan(self, TEN) then
		return HyperDigits.new(q)
	end
	return nil
end

function tetrate(self: HyperDigits, number: HyperDigits): HyperDigits
	if lessThan(number, NEG_TWO) or equals(number, NEG_ONE) then
		return ZERO
	elseif self.sign == 0 then
		if number.sign == 0 or equals(mod(number, TWO), ZERO) then
			return ZERO
		end
		return ONE
	elseif equalsOne(self) or number.sign == 0 then
		return ONE
	elseif equalsOne(number) then
		return self
	elseif equals(number, TWO) then
		return pow(self, self)
	end

	local maxNum = max(self, number)
	if moreThan(maxNum, MAX_TETRATE) then
		return maxNum
	elseif moreThan(self, MAX_POW) or moreThan(number, MAX_SAFE) then
		if lessThan(self, ERECIPE) then
			local nel = mutableUnary(log(self, E))
			return div(lambertw(nel), nel)
		end
		local q = add(slog(self, TEN), number)
		q.tetrate += 1
		return fix(q)
	end

	local revertedTetrate = toNumber(number)
	local floored = math.floor(revertedTetrate)
	local result = pow(self, HyperDigits.new(revertedTetrate - floored))
	local check = ZERO
	local count = 0
	for _ = 1, 100 do
		if not (floored ~= 0 and lessThan(result, MAX_ADD)) then
			break
		end
		count += 1
		if floored > 0 then
			result = pow(self, result)
			if equals(check, result) then
				floored = 0
				break
			end
			check = result
			floored -= 1
		else
			result = log(result, self)
			if equals(check, result) then
				floored = 0
				break
			end
			check = result
			floored += 1
		end
	end
	if count == 100 or lessThan(self, ERECIPE) then
		floored = 0
	end
	result.exponent += floored
	return fix(result)
end

function pentate(self: HyperDigits, number: HyperDigits): HyperDigits
	if lessThan(number, NEG_TWO) or equals(number, NEG_ONE) then
		return ZERO
	elseif self.sign == 0 then
		if number.sign == 0 or equals(mod(number, TWO), ZERO) then
			return ZERO
		end
		return ONE
	elseif equalsOne(self) or number.sign == 0 then
		return ONE
	elseif equalsOne(number) then
		return self
	elseif equals(number, TWO) then
		return tetrate(self, self)
	elseif equals(self, TWO) then
		if equals(number, THREE) then
			return HyperDigits.new(65536)
		end
	end

	local maxNum = max(self, number)
	if moreThan(maxNum, MAX_PENTATE) then
		return maxNum
	elseif moreThan(self, MAX_POW) or moreThan(number, MAX_SAFE) then
		if lessThan(self, ERECIPE) then
			local nel = mutableUnary(log(self, E))
			return div(lambertw(nel), nel)
		end
		local q = add(slog(self, TEN), number)
		q.tetrate = number.tetrate
		q.pentate = number.pentate + 1
		return fix(q)
	end

	local revertedPentate = toNumber(number)
	local floored = math.floor(revertedPentate)
	local result = pow(self, HyperDigits.new(revertedPentate - floored))
	local check = ZERO
	local count = 0
	for _ = 1, 100 do
		if not (floored ~= 0 and lessThan(result, MAX_ADD)) then
			break
		end
		count += 1
		if floored > 0 then
			result = tetrate(self, result)
			if equals(check, result) then
				floored = 0
				break
			end
			check = result
			floored -= 1
		else
			result = slog(result, self)
			if equals(check, result) then
				floored = 0
				break
			end
			check = result
			floored += 1
		end
	end
	if count == 100 or lessThan(self, ERECIPE) then
		floored = 0
	end
	result.tetrate += floored
	return fix(result)
end

function hexate(self: HyperDigits, number: HyperDigits): HyperDigits
	if lessThan(number, NEG_TWO) or equals(number, NEG_ONE) then
		return ZERO
	elseif self.sign == 0 then
		if number.sign == 0 or equals(mod(number, TWO), ZERO) then
			return ZERO
		end
		return ONE
	elseif equalsOne(self) or number.sign == 0 then
		return ONE
	elseif equalsOne(number) then
		return self
	elseif equals(number, TWO) then
		return pentate(self, self)
	end

	local maxNum = max(self, number)
	if moreThan(maxNum, MAX_HEXATE) then
		return maxNum
	elseif moreThan(self, MAX_POW) or moreThan(number, MAX_SAFE) then
		if lessThan(self, ERECIPE) then
			local nel = mutableUnary(log(self, E))
			return div(lambertw(nel), nel)
		end
		local q = add(slog(self, TEN), number)
		q.tetrate = number.tetrate
		q.pentate = number.pentate
		q.hexate = number.hexate + 1
		return fix(q)
	end

	local revertedHexate = toNumber(number)
	local floored = math.floor(revertedHexate)
	local result = pow(self, HyperDigits.new(revertedHexate - floored))
	local check = ZERO
	local count = 0
	for _ = 1, 100 do
		if not (floored ~= 0 and lessThan(result, MAX_ADD)) then
			break
		end
		count += 1
		if floored > 0 then
			result = pentate(self, result)
			if equals(check, result) then
				floored = 0
				break
			end
			check = result
			floored -= 1
		else
			result = pentlog(result, self)
			if equals(check, result) then
				floored = 0
				break
			end
			check = result
			floored += 1
		end
	end
	if count == 100 or lessThan(self, ERECIPE) then
		floored = 0
	end
	result.pentate += floored
	return fix(result)
end

local _MAX_CAP_HYPER: HyperDigits? = nil
local function getMaxCap(): HyperDigits
	if _MAX_CAP_HYPER == nil then
		_MAX_CAP_HYPER = HyperDigits.fromString(MAX_CAP)
	end
	return _MAX_CAP_HYPER
end
local function capStringIfNeeded(n: HyperDigits): string?
	if ENABLE_CAP and moreEquals(n, getMaxCap()) then
		return CAP_MESSAGE
	end
	return nil
end

function toEChain(self: HyperDigits): string
	if self.sign == 0 then
		return "0"
	end
	local capped = capStringIfNeeded(self)
	if capped ~= nil then
		return capped
	end
	if self.tetrate > 0 or self.exponent > 10 then
		return toEnt(self)
	end
	return string.rep("e", self.exponent)..tostring(math.floor(self.multiplicand * DP_OFFSET) / DP_OFFSET)
end

function toEnt(self: HyperDigits): string
	if self.sign == 0 then
		return "0"
	end
	local capped = capStringIfNeeded(self)
	if capped ~= nil then
		return capped
	end
	local cap = capStringIfNeeded(self)
	if cap then
		return cap
	end
	local multiplicand = self.multiplicand
	if self.tetrate > 0 then
		if self.tetrate > 1 or multiplicand > 308 or self.exponent > 1 then
			return toHyperE(self)
		end
		multiplicand = math.pow(10, multiplicand)
	end
	local part = "E("..(numberToSuffix(self.exponent) or tostring(self.exponent))..")"
	if self.sign == -1 then
		part = "-"..part
	end
	return part..(numberToSuffix(multiplicand) or tostring(multiplicand))
end

function toHyperE(self: HyperDigits): string
	if self.sign == 0 then
		return "0"
	end
	local capped = capStringIfNeeded(self)
	if capped ~= nil then
		return capped
	end
	if self.sign == -1 then
		return "-"..toHyperE(abs(self))
	end
	if lessThan(self, MAX_SAFE) then
		return toSuffix(self)
	end
	local parts = {}
	local suffixed = numberToSuffix(self.multiplicand)
	table.insert(
		parts,
		"E"..(suffixed == nil
			and tostring(math.floor(self.multiplicand * DP_OFFSET) / DP_OFFSET)
			or suffixed)
	)
	if self.exponent > 0 then
		table.insert(parts, "#"..(numberToSuffix(self.exponent) or tostring(self.exponent)))
	end
	if self.tetrate > 0 then
		table.insert(parts, "#"..(numberToSuffix(self.tetrate + 1) or tostring(self.tetrate + 1)))
	end
	if self.pentate > 0 then
		table.insert(parts, "#"..(numberToSuffix(self.pentate + 1) or tostring(self.pentate + 1)))
	end
	if self.hexate > 0 then
		table.insert(parts, "#"..(numberToSuffix(self.hexate + 1) or tostring(self.hexate + 1)))
	end
	if self.heptate > 0 then
		table.insert(parts, "#"..(numberToSuffix(self.heptate + 1) or tostring(self.heptate + 1)))
	end
	return table.concat(parts)
end

local function exponentString(exp: HyperDigits): string
	if exp.sign == 0 then
		return "0"
	end
	if exp.sign < 0 then
		return "-"..exponentString(HyperDigits.new({
			sign = 1,
			multiplicand = exp.multiplicand,
			exponent = exp.exponent,
			tetrate = exp.tetrate,
			pentate = exp.pentate,
			hexate = exp.hexate,
			heptate = exp.heptate,
		}))
	end
	if isSimpleInt(exp) then
		local v = math.floor(exp.multiplicand)
		if v <= MAX_PLAIN_EXP then
			return tostring(v)
		end
	end
	if exp.heptate > 0 or exp.hexate > 0 or exp.pentate > 0 or exp.tetrate > 0 or exp.exponent > 6 then
		return toEnt(exp)
	end
	local e = toEChain(exp)
	if #e < #toScientific(exp) then
		return e
	end
	return toScientific(exp)
end

function toScientificChain(value: HyperDigits | number): string
	local x = HyperDigits.new(value)
	local capped = capStringIfNeeded(x)
	if capped ~= nil then
		return capped
	end

	local cap = capStringIfNeeded(x)
	if cap then
		return cap
	end

	if x.sign == 0 then
		return "0"
	end
	if x.sign < 0 then
		return "-"..toScientificChain(abs(x))
	end

	if x.exponent == 0 and x.tetrate == 0 and x.pentate == 0 and x.hexate == 0 and x.heptate == 0 then
		local m, e = toSerika(x)
		if e == HUGE or e ~= e then
			return "1e"..exponentString(floor(log10(x)))
		end
		return trimDecimals(serikaNumToScientific(m, e))
	end

	local e = floor(log10(x))
	return "1e"..exponentString(e)
end

function toScientific(self: HyperDigits): string
	local capped = capStringIfNeeded(self)
	if capped ~= nil then
		return capped
	end
	local cap = capStringIfNeeded(self)
	if cap then
		return cap
	end
	if self.sign == 0 then
		return "0"
	end
	if absMoreEquals(abs(self), SCI_CHAIN_SWITCH) then
		return toScientificChain(self)
	end
	if self.exponent > 2 then
		return toEChain(self)
	end
	local mantissa, exponent = toSerika(self)
	if exponent == HUGE or exponent ~= exponent then
		return toScientificChain(self)
	end
	return serikaNumToScientific(mantissa, exponent)
end

function toSuffix(self: HyperDigits): string
	if self.sign == 0 then
		return "0"
	end
	local capped = capStringIfNeeded(self)
	if capped ~= nil then
		return capped
	end
	local cap = capStringIfNeeded(self)
	if cap then
		return cap
	end
	if absMoreEquals(abs(self), SCI_CHAIN_SWITCH) then
		return toScientificChain(self)
	end
	if self.exponent > 1 then
		return toScientific(self)
	end
	local mantissa, exponent = toSerika(self)
	if exponent == HUGE or exponent ~= exponent then
		return toScientificChain(self)
	end
	return serikaNumToSuffix(mantissa, exponent) or serikaNumToScientific(mantissa, exponent)
end

local SABER_BASE_SUFFIXES = {
	"K","M","B","T","q","Q","s","S","o","n","d","U","T","Qt","Qd","Sd","St","O","N","v","c",
}
local SABER_FAMILY_SPAN = 26 + 26 * 26

local function getBigLeagueSuffix(offset: number): string?
	local familyIndex = math.floor(offset / SABER_FAMILY_SPAN) + 1
	if familyIndex > #SABER_BASE_SUFFIXES then
		return nil
	end
	local base = SABER_BASE_SUFFIXES[familyIndex]
	local pos = offset % SABER_FAMILY_SPAN
	if pos < 26 then
		local second = string.char(65 + pos)
		return base..second
	end
	local pos2 = pos - 26
	local secondIndex = math.floor(pos2 / 26)
	local thirdIndex = pos2 % 26
	local second = string.char(65 + secondIndex)
	local third = string.char(65 + thirdIndex)
	return base..second..third
end

local function serikaNumToSaberSuffix(mantissa: number, exponent: number): string
	if exponent < 3 then
		return serikaNumEnforceDP(mantissa, exponent)
	end
	local tier = math.floor(exponent / 3) - 1
	local suffix: string
	if tier < #SABER_BASE_SUFFIXES then
		suffix = SABER_BASE_SUFFIXES[tier + 1]
	else
		local offset = tier - #SABER_BASE_SUFFIXES
		local bigSuffix = getBigLeagueSuffix(offset)
		if not bigSuffix then
			return serikaNumToScientific(mantissa, exponent)
		end
		suffix = bigSuffix
	end
	local formattedMantissa = serikaNumEnforceDP(mantissa, exponent % 3)
	return formattedMantissa..suffix
end

local function toSaberSuffix(self: HyperDigits): string
	local capped = capStringIfNeeded(self)
	if capped ~= nil then
		return capped
	end
	local cap = capStringIfNeeded(self)
	if cap then
		return cap
	end
	if self.sign == 0 then
		return "0"
	end
	if absMoreEquals(abs(self), SCI_CHAIN_SWITCH) then
		return toScientificChain(self)
	end
	if self.exponent > 1 then
		return toScientific(self)
	end
	local mantissa, exponent = toSerika(self)
	if exponent == HUGE or exponent ~= exponent then
		return toScientificChain(self)
	end
	return serikaNumToSaberSuffix(mantissa, exponent)
end

function toString(self: HyperDigits): string
	local cap = capStringIfNeeded(self)
	if cap then
		return cap
	end

	local out
	if self.sign == 0 then
		out = "0"
	elseif self.sign == -1 then
		out = "-"..toString(abs(self))
	elseif lessThan(abs(self), MAX_FRACTIONAL) then
		out = "1 / "..toSuffix(div(ONE, self))
	elseif absMoreEquals(abs(self), SCI_CHAIN_SWITCH) then
		out = toScientificChain(self)
	elseif lessThan(self, MAX_SUFFIX) then
		if DEFAULT_ABBREVIATION == "suffix" then
			out = toSuffix(self)
		elseif DEFAULT_ABBREVIATION == "saber" then
			out = toSaberSuffix(self)
		else
			out = toScientific(self)
		end
	elseif lessThan(self, MAX_SCIENTIFIC) then
		out = toScientific(self)
	elseif lessThan(self, MAX_E_CHAIN) then
		out = toEChain(self)
	elseif lessThan(self, MAX_ENT) then
		out = toEnt(self)
	else
		out = toHyperE(self)
	end
	return trimDecimals(out)
end

function getSuffixExponent(suffix: string): number?
	local exponent = 0
	for i, v in suffixes.third do
		local startIndex = string.find(suffix, v)
		if startIndex ~= nil then
			exponent += i * 300
			suffix = string.sub(suffix, 1, startIndex - 1)
			break
		end
	end
	for i, v in suffixes.second do
		local startIndex = string.find(suffix, v)
		if startIndex ~= nil then
			exponent += i * 30
			suffix = string.sub(suffix, 1, startIndex - 1)
			break
		end
	end
	for i, v in suffixes.first do
		local startIndex = string.find(suffix, v)
		if startIndex ~= nil then
			exponent += i * 3
			suffix = string.sub(suffix, 1, startIndex - 1)
			break
		end
	end
	for i, v in suffixes.beginning do
		local startIndex = string.find(suffix, v)
		if startIndex ~= nil then
			exponent += i * 3 - 3
			suffix = string.sub(suffix, 1, startIndex - 1)
			break
		end
	end
	return exponent + 3
end

function fromSuffix(str: string): HyperDigits?
	local suffix = str:match("%a+")
	if suffix == nil then
		return nil
	end
	local mantissa = tonumber(string.sub(str, 1, (string.find(str, suffix) :: number) - 1))
	local exponent = getSuffixExponent(suffix)
	if mantissa ~= nil and exponent ~= nil and exponent > 0 then
		return HyperDigits.fromOnoe({ mantissa = mantissa, exponent = exponent })
	end
	return nil
end

local function parseBigIntStringToHyper(s: string): HyperDigits
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	local sign = 1
	if s:sub(1, 1) == "-" then
		sign = -1
		s = s:sub(2)
	elseif s:sub(1, 1) == "+" then
		s = s:sub(2)
	end
	s = s:gsub("^0+", "")
	if s == "" then
		return ZERO
	end
	if #s <= 15 then
		return HyperDigits.new(sign * (tonumber(s) :: number))
	end
	local leadLen = 15
	local lead = tonumber(s:sub(1, leadLen)) :: number
	local log10N = (#s - 1) + math.log10(lead) - (leadLen - 1)
	return fix({
		sign = sign,
		multiplicand = log10N,
		exponent = 1,
		tetrate = 0,
		pentate = 0,
		hexate = 0,
		heptate = 0,
	})
end

function HyperDigits.fromString(str: string): HyperDigits
	if str == "[0]" then
		return ZERO
	end
	str = str:gsub("^%s+", ""):gsub("%s+$", "")
	if str == "" then
		return ZERO
	end
	if string.find(str, ",") or string.find(str, "%[") then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(str)
		end)
		if not ok then
			local fromSuff = fromSuffix(str)
			if fromSuff ~= nil then
				return fromSuff
			end
			return HyperDigits.new(tonumber(str) or 0)
		end

		local omega = decoded
		omega = { math.sign(omega[1] or 1), omega }
		omega[2][1] = math.abs(omega[2][1] or 0)
		return fix(HyperDigits.fromOmega(omega))
	end

	local lower = string.gsub(str, "E", "e")
	if string.find(lower, "e", 1, true) then
		local subs = string.split(lower, "e")
		if subs[1] == "" then
			subs[1] = "1"
		end
		if #subs == 1 or subs[2] == "" then
			local n = tonumber(subs[1])
			if n == nil then
				return ZERO
			end
			return HyperDigits.new(n)
		end
		if #subs == 2 then
			local sign = 1
			local mantissa = tonumber(subs[1])

			if mantissa == nil or mantissa == 0 then
				return ZERO
			end
			if mantissa < 0 then
				mantissa = -mantissa
				sign = -1
			end

			local expStr = (subs[2] :: string):gsub("^%s+", ""):gsub("%s+$", "")
			if expStr == "" then
				return HyperDigits.new(sign * mantissa)
			end

			local exponentNum = tonumber(expStr)

			if exponentNum == nil or exponentNum == HUGE or exponentNum ~= exponentNum then
				if expStr:sub(1, 1) == "-" then
					return ZERO
				end
				local bigExp = parseBigIntStringToHyper(expStr)
				local result = mul(HyperDigits.new(mantissa), pow10(bigExp))
				result.sign *= sign
				return fix(result:toBase())
			end
			local exponent = exponentNum
			if exponent < 0 then
				local small = mantissa * math.pow(10, exponent)
				return fix({
					sign = sign,
					multiplicand = math.abs(small),
					exponent = 0,
					tetrate = 0,
					pentate = 0,
					hexate = 0,
					heptate = 0
				})
			end
			local first = exponent + math.log10(mantissa)
			local second = 1
			if first == 0 then
				first = 1
				second = 0
			elseif first < 0 then
				first = -first
				sign = -sign
			end
			return fix({
				sign = sign,
				multiplicand = first,
				exponent = second,
				tetrate = 0,
				pentate = 0,
				hexate = 0,
				heptate = 0
			})
		end
		local sign = 1
		if subs[1] == "-" then
			sign = -1
		end
		local last = subs[#subs]
		local lastNum = tonumber(last)
		if lastNum == nil then
			return ZERO
		end
		return fix({
			sign = sign,
			multiplicand = lastNum,
			exponent = #subs - 1,
			tetrate = 0,
			pentate = 0,
			hexate = 0,
			heptate = 0
		})
	end
	local fromSuff = fromSuffix(str)
	if fromSuff ~= nil then
		return fromSuff
	end
	return HyperDigits.new(tonumber(str) or 0)
end

function HyperDigits.toBase(self: HyperDigits): BaseHyperDigits
	return setmetatable(self, nil) :: BaseHyperDigits
end

function HyperDigits.getPercentage(numerator: HyperDigits, denominator: HyperDigits)
	if denominator.sign == 0 or denominator.exponent == HUGE then
		return HyperDigits.new(0)
	end

	local percentage = numerator / denominator
	percentage = HyperDigits.min(HyperDigits.max(percentage, HyperDigits.new(0)), HyperDigits.new(1))

	local scaled = percentage:mul(HyperDigits.new(1000))
	local rounded = scaled:add(HyperDigits.new(0.5)):floor():div(HyperDigits.new(1000))
	return rounded
end

function HyperDigits.fromPercent(percent: string | number): HyperDigits
	if type(percent) == "number" then
		local num = HyperDigits.new(percent):div(HyperDigits.new(100))
		num.isPercent = true
		return num
	elseif type(percent) == "string" then
		if not percent:match("^[-+]?[%d%.eE]+%%?$") then
			return HyperDigits.new(0)
		end

		local numStr = percent:gsub("%%", "")
		local num = HyperDigits.fromString(numStr):div(HyperDigits.new(100))
		num.isPercent = true
		return num
	end
	return HyperDigits.new(0)
end

function HyperDigits.toPercent(number: HyperDigits): string
	local percentValue = number:mul(HyperDigits.new(100))
	local numValue = percentValue:toNumber()

	if numValue % 1 == 0 then
		return string.format("%d%%", numValue)
	else
		return string.format("%."..PERCENT_DECIMAL_POINTS.."f%%", numValue)
	end
end

function HyperDigits.fromScientific(str: string): HyperDigits
	return HyperDigits.fromString(str)
end

function HyperDigits.changeSuffixes(newSuffixes: typeof(suffixes))
	suffixes = newSuffixes
end

function HyperDigits.changeDecimalPoints(decimalPoints: number)
	DECIMAL_POINTS = decimalPoints
	DP_OFFSET = math.pow(10, DECIMAL_POINTS)
end

function HyperDigits.changeDefaultAbbreviation(mode: "suffix" | "scientific" | "saber")
	DEFAULT_ABBREVIATION = mode
end

function HyperDigits.lbencode(self: HyperDigits): number
	if self.sign == 0 then
		return 0
	end
	local sign = self.sign
	local function safelog10(x: number): number
		if x <= 0 or x ~= x then
			return 0
		end
		return math.log10(x)
	end
	if self.heptate > 0 then
		local cnum = 1.2e17
		cnum += safelog10((self.heptate + (safelog10(self.hexate + 1) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif self.hexate > 0 then
		local cnum = 1.1e17
		cnum += safelog10((self.hexate + (safelog10(self.pentate + 1) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif self.pentate > 0 then
		local cnum = 1e17
		cnum += safelog10((self.pentate + (safelog10(self.tetrate + 1) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif self.tetrate > 0 then
		if self.tetrate == 2 then
			local cnum = 7e16
			cnum += safelog10((self.exponent + (safelog10(self.multiplicand) / 16) + 1)) * 6.26775e14
			return sign * cnum

		elseif self.tetrate == 1 then
			local cnum = 6e16
			cnum += safelog10((self.exponent + (safelog10(self.multiplicand) / 16) + 1)) * 6.26775e14
			return sign * cnum
		elseif self.tetrate < 9999 then
			local cnum = 8e16
			cnum += safelog10((self.exponent + (safelog10(self.multiplicand) / 16) + 1)) * 6.26775e8
			cnum += self.tetrate * 1e10
			return sign * cnum
		end
		local cnum = 9e16
		cnum += safelog10((self.tetrate + (safelog10(self.exponent + 1) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif self.exponent > 0 then
		if self.exponent <= 9999 then
			local cnum = 4e16
			cnum += safelog10((self.multiplicand + 1)) * 6.26775e8
			cnum += self.exponent * 1e10
			return sign * cnum
		elseif self.exponent < 4 then
			return sign * (math.floor(safelog10((self.multiplicand + 1)) * 6.26775e14) + self.exponent * 1e16)
		end
		local cnum = 5e16
		cnum += safelog10((self.exponent + (safelog10(self.multiplicand) / 16) + 1)) * 6.26775e14
		return sign * cnum
	elseif self.multiplicand > 0 then
		return sign * math.floor(safelog10((self.multiplicand + 1)) * 6.26775e14)
	end
	return 0
end

function HyperDigits.lbdecode(int: number): HyperDigits
	if int == 0 then
		return ZERO
	end

	local sign = math.sign(int)
	int = math.abs(int)

	local mode = math.floor(int / 1e16)
	if mode >= 3 then
		int -= 1
	end

	local function pow10(x: number): number
		return 10 ^ x
	end

	if mode == 0 then
		return fix({ sign = sign, multiplicand = pow10(int / 6.26775e14) - 1, exponent = 0, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
	elseif mode < 4 then
		return fix({ sign = sign, multiplicand = pow10(math.fmod(int, 1e16) / 6.26775e14) - 1, exponent = mode, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
	elseif mode == 4 then
		local remainder = math.fmod(int, 1e10)
		return fix({
			sign = sign,
			multiplicand = pow10(remainder / 6.26775e8) - 1,
			exponent = math.floor((int - 4e16) / 1e10),
			tetrate = 0, pentate = 0, hexate = 0, heptate = 0
		})
	elseif mode == 5 then
		local remainder = math.fmod(int, 1e16)
		local arrows = pow10(remainder / 6.26775e14) - 1
		local arg1 = pow10(math.fmod(arrows, 1) * 16)
		return fix({ sign = sign, multiplicand = arg1, exponent = math.floor(arrows), tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
	elseif mode == 6 then
		local remainder = math.fmod(int, 1e16)
		local arrows = pow10(remainder / 6.26775e14) - 1
		local arg1 = pow10(math.fmod(arrows, 1) * 16)
		return fix({ sign = sign, multiplicand = arg1, exponent = math.floor(arrows), tetrate = 1, pentate = 0, hexate = 0, heptate = 0 })
	elseif mode == 7 then
		local remainder = math.fmod(int, 1e16)
		local arrows = pow10(remainder / 6.26775e14) - 1
		local arg1 = pow10(math.fmod(arrows, 1) * 16)
		return fix({ sign = sign, multiplicand = arg1, exponent = math.floor(arrows), tetrate = 2, pentate = 0, hexate = 0, heptate = 0 })
	elseif mode == 8 then
		local arg3 = math.floor((int - 8e16) / 1e10)
		local remainder = math.fmod(int, 1e10) * 1e6
		local arrows = pow10(remainder / 6.26775e14) - 1
		local arg1 = pow10(math.fmod(arrows, 1) * 16)
		return fix({ sign = sign, multiplicand = arg1, exponent = math.floor(arrows), tetrate = math.floor(arg3), pentate = 0, hexate = 0, heptate = 0 })
	elseif mode == 9 then
		local remainder = math.fmod(int, 1e16)
		local arrows = pow10(remainder / 6.26775e14) - 1
		local arg1 = pow10(math.fmod(arrows, 1) * 16)
		return fix({ sign = sign, multiplicand = 1, exponent = math.floor(arg1), tetrate = math.floor(arrows), pentate = 0, hexate = 0, heptate = 0 })
	elseif mode == 10 then
		local remainder = math.fmod(int, 1e16)
		local arrows = pow10(remainder / 6.26775e14) - 1
		local arg1 = pow10(math.fmod(arrows, 1) * 16)
		return fix({ sign = sign, multiplicand = 1, exponent = 0, tetrate = math.floor(arg1), pentate = math.floor(arrows), hexate = 0, heptate = 0 })
	else
		local zeros = mode - 10
		local remainder = math.fmod(int, 1e16)
		local arrows = pow10(remainder / 6.26775e14) - 1

		local arg1 = FLOAT64_SAFE_LIMIT ^ (math.fmod(arrows, 1))

		local xd = { 1, 0 }
		for _ = 1, zeros do
			table.insert(xd, 0)
		end
		table.insert(xd, math.floor(arg1))
		table.insert(xd, math.floor(arrows))
		if xd[zeros + 4] == 0 then
			table.remove(xd)
		end
		return HyperDigits.fromOmega({ sign, xd })
	end
end

local function isPercent(num: HyperDigits)
	return num.isPercent == true
end

HyperDigits.fix = fix

HyperDigits.add = function(self: HyperDigits, number: Number)
	local num = HyperDigits.new(number)

	if ENABLE_CAP then
		local maxCapConverted = getMaxCap()
		if moreEquals(self, maxCapConverted) or moreThan(num, maxCapConverted) then
			return maxCapConverted
		end
	end

	if isPercent(num) then
		return add(self, mul(self, num))
	end
	return add(self, num)
end

HyperDigits.sub = function(self: HyperDigits, number: Number)
	local num = HyperDigits.new(number)

	if ENABLE_CAP then
		local maxCapConverted = getMaxCap()
		if moreEquals(self, maxCapConverted) or moreThan(num, maxCapConverted) then
			return maxCapConverted
		end
	end

	if isPercent(num) then
		return add(self, unary(mul(self, num)))
	end
	return add(self, unary(num))
end

HyperDigits.mul = function(self: HyperDigits, number: Number)
	local num = HyperDigits.new(number)

	if ENABLE_CAP then
		local maxCapConverted = getMaxCap()
		if moreEquals(self, maxCapConverted) or moreThan(num, maxCapConverted) then
			return maxCapConverted
		end
	end

	return mul(self, num)
end

HyperDigits.div = function(self: HyperDigits, number: Number)
	local num = HyperDigits.new(number)

	if ENABLE_CAP then
		local maxCapConverted = getMaxCap()
		if moreEquals(self, maxCapConverted) or moreThan(num, maxCapConverted) then
			return maxCapConverted
		end
	end

	return div(self, num)
end

HyperDigits.pow = function(self: HyperDigits, number: Number)
	local num = HyperDigits.new(number)

	if ENABLE_CAP then
		local maxCapConverted = getMaxCap()
		if moreEquals(self, maxCapConverted) or moreThan(num, maxCapConverted) then
			return maxCapConverted
		end
	end

	return pow(self, num)
end

HyperDigits.mod = function(self: HyperDigits, number: Number)
	local num = HyperDigits.new(number)

	if ENABLE_CAP then
		local maxCapConverted = getMaxCap()
		if moreEquals(self, maxCapConverted) or moreThan(num, maxCapConverted) then
			return maxCapConverted
		end
	end

	if isPercent(num) then
		return mod(self, mul(self, num))
	end
	return mod(self, num)
end

HyperDigits.root = function(self: HyperDigits, number: Number)
	return root(self, HyperDigits.new(number))
end

HyperDigits.equals = function(self: HyperDigits, number: Number)
	return equals(self, HyperDigits.new(number))
end

HyperDigits.lessThan = function(self: HyperDigits, number: Number)
	return lessThan(self, HyperDigits.new(number))
end

HyperDigits.lessEquals = function(self: HyperDigits, number: Number)
	return lessEquals(self, HyperDigits.new(number))
end

HyperDigits.moreThan = function(self: HyperDigits, number: Number)
	return moreThan(self, HyperDigits.new(number))
end

HyperDigits.moreEquals = function(self: HyperDigits, number: Number)
	return moreEquals(self, HyperDigits.new(number))
end

HyperDigits.compare = function(self: HyperDigits, number: Number)
	return compare(self, HyperDigits.new(number))
end

HyperDigits.abs = function(self: HyperDigits)
	return abs(HyperDigits.new(self))
end

HyperDigits.log10 = function(self: HyperDigits)
	return log10(HyperDigits.new(self))
end

HyperDigits.log = function(self: HyperDigits, number: Number)
	return log(self, HyperDigits.new(number))
end

HyperDigits.floor = function(self: HyperDigits)
	return floor(HyperDigits.new(self))
end

HyperDigits.round = function(self: HyperDigits)
	return round(HyperDigits.new(self))
end

HyperDigits.ceil = function(self: HyperDigits)
	return ceil(HyperDigits.new(self))
end

HyperDigits.isInteger = function(self: HyperDigits)
	return isInteger(HyperDigits.new(self))
end

HyperDigits.reciprocal = function(self: HyperDigits)
	return reciprocal(HyperDigits.new(self))
end

HyperDigits.lambertw = function(self: HyperDigits)
	return lambertw(HyperDigits.new(self))
end

HyperDigits.slog = function(self: HyperDigits, number: Number)
	return slog(self, HyperDigits.new(number))
end

HyperDigits.pentlog = function(self: HyperDigits, number: Number)
	return pentlog(self, HyperDigits.new(number))
end

HyperDigits.hextlog = function(self: HyperDigits, number: Number)
	return hextlog(self, HyperDigits.new(number))
end

HyperDigits.tet = function(self: HyperDigits, number: Number)
	return tetrate(self, HyperDigits.new(number))
end

HyperDigits.pent = function(self: HyperDigits, number: Number)
	return pentate(self, HyperDigits.new(number))
end

HyperDigits.hext = function(self: HyperDigits, number: Number)
	return hexate(self, HyperDigits.new(number))
end

HyperDigits.unary = function(self: HyperDigits)
	return unary(HyperDigits.new(self))
end

HyperDigits.min = function(self: HyperDigits, number: Number)
	return min(self, HyperDigits.new(number))
end

HyperDigits.max = function(self: HyperDigits, number: Number)
	return max(self, HyperDigits.new(number))
end

HyperDigits.minmax = function(self: HyperDigits, number: Number)
	return minmax(self, HyperDigits.new(number))
end

HyperDigits.toString = function(self: Number)
	return toString(HyperDigits.new(self))
end

HyperDigits.toSerika = function(self: Number)
	return toSerika(HyperDigits.new(self))
end

HyperDigits.toNumber = function(self: Number)
	return toNumber(HyperDigits.new(self))
end

HyperDigits.toSuffix = function(self: Number)
	return toSuffix(HyperDigits.new(self))
end

HyperDigits.toSaberSuffix = function(self: Number)
	return toSaberSuffix(HyperDigits.new(self))
end

HyperDigits.toScientificChain = function(self: Number)
	return toScientificChain(self)
end

HyperDigits.toScientific = function(self: Number)
	return toScientific(HyperDigits.new(self))
end

HyperDigits.toEChain = function(self: Number)
	return toEChain(HyperDigits.new(self))
end

HyperDigits.toEnt = function(self: Number)
	return toEnt(HyperDigits.new(self))
end

HyperDigits.toHyperE = function(self: Number)
	return toHyperE(HyperDigits.new(self))
end

HyperDigits.eq = HyperDigits.equals
HyperDigits.lt = HyperDigits.lessThan
HyperDigits.le = HyperDigits.lessEquals
HyperDigits.mt = HyperDigits.moreThan
HyperDigits.me = HyperDigits.moreEquals
HyperDigits.unm = HyperDigits.unary
HyperDigits.recip = HyperDigits.reciprocal
HyperDigits.revert = toNumber
HyperDigits.encode = HyperDigits.lbencode
HyperDigits.decode = HyperDigits.lbdecode

HyperDigits.__add = HyperDigits.add
HyperDigits.__sub = HyperDigits.sub
HyperDigits.__mul = HyperDigits.mul
HyperDigits.__div = HyperDigits.div
HyperDigits.__pow = HyperDigits.pow
HyperDigits.__mod = HyperDigits.mod
HyperDigits.__eq = HyperDigits.eq
HyperDigits.__lt = HyperDigits.lt
HyperDigits.__le = HyperDigits.le
HyperDigits.__unm = HyperDigits.unm
HyperDigits.__tostring = HyperDigits.toString
HyperDigits.__concat = function(self: HyperDigits, value: any): HyperDigits
	return HyperDigits.toString(self)..value
end

HyperDigits.GOOGOL = HyperDigits.new(10e100)
HyperDigits.GOOGOLPLEX = HyperDigits.new(10):pow(HyperDigits.GOOGOL)
HyperDigits.GOOGOLPLEXPLEX = HyperDigits.new(10):pow(HyperDigits.GOOGOLPLEX)
HyperDigits.TRITRI = HyperDigits.new({ sign = 1, multiplicand = 3638334640023.778, exponent = 7625597484984, tetrate = 0, pentate = 0, hexate = 0, heptate = 0 })
HyperDigits.TRITET = HyperDigits.new({ sign = 1, multiplicand = 153.906997547968, exponent = 2, tetrate = 2, pentate = 2, hexate = 0, heptate = 0 })
HyperDigits.GRAHAM1 = HyperDigits.new({ sign = 1, multiplicand = 3638334640023.778, exponent = 7625597484984, tetrate = 0, pentate = 1, hexate = 0, heptate = 0 })

export type HyperDigits = typeof(setmetatable({} :: BaseHyperDigits, HyperDigits))

return HyperDigits
