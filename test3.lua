local json = require("json")
local math = require("math")

-- Options Trading App v5

-- Global Variables and Setup
Trades = {}
Winners = {}

_0RBIT = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ"

local json = require("json")
 
_0RBIT = "BaMK1dfayo75s3q1ow6AO64UDpD9SEFbeE8xYrY2fyQ"


BASE_URL = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/new%20york?unitGroup=us&include=current%2Chours&key=EUEQ4LDRZAS7HY2ZSJTVV76JD&contentType=json"

CurrentData = CurrentData or {}


BASE_URL_OUTCOME = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/New%20York,%20NY,%20United%20States/last2days?key=EUEQ4LDRZAS7HY2ZSJTVV76JD&include=hours&elements=datetimeEpoch,temp,datetime"

 
OutcomeData = OutcomeData or {}



NOW = NOW or nil

-- Function to initialize the app
function initializeApp()
    Trades = {}
    Winners = {}

    -- Initialize with a dummy trade to prevent Trades list from returning zero
    local dummyTrade = {
        tradeId = tostring(math.random(100000, 500000)),
        timeCreated = math.floor(CurrentData.currentConditions.datetimeEpoch / 3600) * 3600,
        location = CurrentData.resolvedAddress,
        amount = 0,
        contractExpiry = math.floor(CurrentData.currentConditions.datetimeEpoch / 3600) * 3600 + 86400, -- expires in one day
        contractType = "Call",
        assetPrice = CurrentData.currentConditions.temp,
        status = "open"
    }
    Trades["dummy"] = dummyTrade

    print("Options Trading App initialized.")
end

-- Function to create a new trade
function createTrade(amount, contractType)
    if amount <= -1 then
        print("Trade amount must be higher than 0.")
        return
    end

    -- Ensure CurrentData is updated before creating trade
    Send({
        Target = _0RBIT,
        Action = "Get-Real-Data",
        Url = BASE_URL
    })

    local tradeId = tostring(math.random(100000, 500000))
    local timeCreated = math.floor(CurrentData.currentConditions.datetimeEpoch / 3600) * 3600
    local location = CurrentData.resolvedAddress
    local currentAssetPrice = CurrentData.currentConditions.temp
    local contractExpiry = timeCreated + 86400  -- Set contract expiry exactly one day from timeCreated

    local newTrade = {
        tradeId = tradeId,
        timeCreated = timeCreated,
        location = location,
        amount = amount,
        contractExpiry = contractExpiry,
        contractType = contractType,
        assetPrice = currentAssetPrice,
        status = "open"
    }
    Trades[tradeId] = newTrade
    print("New trade created: " .. tradeId)
end

-- Function to check contract expiry and close positions
function checkContractExpiry()
    for tradeId, trade in pairs(Trades) do
        if os.time() >= trade.contractExpiry then
            print("Contract expired for trade: " .. tradeId)
            trade.status = "closed"
            local currentAssetPrice = getAssetPriceAtExpiry(trade.contractExpiry)
            if isWinner(trade, currentAssetPrice) then
                table.insert(Winners, trade)
            end
        end
    end
end

-- Function to get the asset price at contract expiry
function getAssetPriceAtExpiry(expiryTime)
    for _, hourData in ipairs(OutcomeData.hours) do
        if hourData.datetimeEpoch == expiryTime then
            return hourData.temp
        end
    end
    return nil -- Return nil if no matching time is found
end

-- Function to determine if a trade is a winner
function isWinner(trade, currentAssetPrice)
    if trade.contractType == "Call" and currentAssetPrice > trade.assetPrice then
        return true
    elseif trade.contractType == "Put" and currentAssetPrice < trade.assetPrice then
        return true
    else
        return false
    end
end

-- Function to send rewards to winners
function sendRewards()
    for _, winner in ipairs(Winners) do
        local payout = winner.amount * 1.7
        print("Sending reward: " .. payout .. " to trade: " .. winner.tradeId)
        -- Placeholder for reward sending logic
    end
    -- Clear winners list after sending rewards
    Winners = {}
end

-- Handler to process trade requests
function handleTradeRequest(msg)
    local amount = msg.Amount
    local contractType = msg.ContractType

    createTrade(amount, contractType)
end

-- Initialization
initializeApp()

-- Handlers
Handlers.add(
    "TradeRequest",
     Handlers.utils.hasMatchingTag("Action", "TradeRequest"),
    handleTradeRequest)

-- Periodic check for contract expiry and sending rewards
function onTick()
    -- Ensure OutcomeData is updated before checking contract expiry
    Send({
        Target = _0RBIT,
        Action = "Get-Real-Data",
        Url = BASE_URL_OUTCOME
    })

    -- Use current time and asset price from OutcomeData for checking contract expiry
    checkContractExpiry()
    sendRewards()
end


Handlers.add(
    "Get-Request",
    Handlers.utils.hasMatchingTag("Action", "Sponsored-Get-Request-Outcome"),
    function(msg)
        Send({
            Target = _0RBIT,
            Action = "Get-Real-Data",
            Url = BASE_URL_OUTCOME
        })
        print(Colors.green .. "You have sent a GET Request to the 0rbit process.")
    end
)

Handlers.add(
    "Receive-Data",
    Handlers.utils.hasMatchingTag("Action", "Receive-Response"),
    function(msg)
        local res = json.decode(msg.Data)
        OutcomeData = res
        print(Colors.green .. "You have received the data from the 0rbit process.")
    end
)


Handlers.add(
    "Get-Request",
    Handlers.utils.hasMatchingTag("Action", "Sponsored-Get-Request-Current"),
    function(msg)
        Send({
            Target = _0RBIT,
            Action = "Get-Real-Data",
            Url = BASE_URL
        })
        print(Colors.green .. "You have sent a GET Request to the 0rbit process.")
    end
)

Handlers.add(
    "Receive-Data",
    Handlers.utils.hasMatchingTag("Action", "Receive-Response"),
    function(msg)
        local res = json.decode(msg.Data)
        CurrentData = res
        print(Colors.green .. "You have received the data from the 0rbit process.")
    end
)

