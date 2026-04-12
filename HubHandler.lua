local ms = game:GetService("MarketplaceService")
local http = game:GetService("HttpService")
local ts = game:GetService("TweenService")
local players = game.Players

local freeevent = Instance.new("RemoteEvent", game.ReplicatedStorage)
freeevent.Name = "GrantFreeProduct"

local config = require(game.ServerScriptService.Configuration)
local LoggerService = require(100480655648418)

local Logger = LoggerService.new()

function localLog(msg, scriptName, typ)
	local ev = game.ReplicatedStorage:FindFirstChild("LocalLogEvent")

	if ev then
		ev:FireAllClients(msg, scriptName, typ)
	end
end

local s, loadingErr = pcall(function()
	warn("Requesting UI...")
	local UILoader = require(129619868289742)

	if game.StarterGui:FindFirstChild("HubUI") then
		localLog("CUSTOM UI FOUND: no support will be provided for custom UIs!", script.Name, "Warn")
		warn("CUSTOM UI FOUND: no support will be provided for custom UIs!")
	else
		if config.Theme then
			if config.Theme == "round" then
				UILoader.load()
			elseif config.Theme == "flat" then
				UILoader.loadNoRound()
			else
				UILoader.load(config.Theme)
			end
		else
			UILoader.load()
		end
	end
end)

if loadingErr then
	warn("Failed to load UI: " .. loadingErr)
end

repeat
	task.wait()
until game.StarterGui:FindFirstChild("HubUI")

warn("UI has been insterted")

for _, v in pairs(game.Players:GetChildren()) do
	if v:IsA("Player") then
		repeat
			task.wait()
		until v.PlayerGui:FindFirstChild("HubUI")
	end
end

local functions = require(74574433329568)

function removeDuplicateUI()
	local _found = false

	for _, x in pairs(game.Players:GetChildren()) do
		if x:IsA("Player") then
			for _, v in pairs(x.PlayerGui:GetChildren()) do
				if v.Name == "HubUI" then
					if _found == true then
						v:Destroy()
					else
						_found = true
					end
				end
			end
		end
	end
end

removeDuplicateUI()

local ui = game.StarterGui.HubUI

local HomeTab = ui.Home_Tab
local ShopTab = ui.Shop_Tab
local AboutUsTab = ui.AboutUs_Tab
local LinkTab = ui.Link_Tab
local ProfileTab = ui.Profile_Tab
local CartTab = ui.ShoppingCart_Tab
local WishlistTab = ui.Wishlist_Tab

local GroupNameLabel = HomeTab.Main_Header.Market_Title
local ProductList = ShopTab.Sections_Holder.Section1_Holder.ScrollingFrame

local ProductFormat = ProductList.Slot_Frame
local ProductFormat1 = HomeTab.Section1_Holder.ScrollingFrame.Slot_Frame

local TopElements = ui.TopElements_Holder

local PlayerIcon = TopElements.UserProfile_Holder.UserProfile_Container.UserProfile_Button
local PlayerIcon_ProfileTab = ProfileTab.UserProfile_Holder.UserProfile_Container.UserProfile_Button

local Username_Text = ProfileTab.Username_Text
local ProfileText = ProfileTab.Profile_Text

local AboutText = AboutUsTab.AboutUsDescription_Text

local gridCopy = ShopTab.Sections_Holder.Section1_Holder.ScrollingFrame.UIListLayout:Clone()

local CodeLabel = LinkTab.CodeBar_Holder.CodeBar.Code

local url = config.URL

local valid_chars = {}

local groupService = game:GetService("GroupService")

local ReplicatedFirst = game:GetService("ReplicatedFirst")
ReplicatedFirst:RemoveDefaultLoadingScreen()

local ownedProducts = {}
local productCount = 0
local joinedTimestamp = nil

wait()

removeDuplicateUI()

local function checkApiKey()
	local success, response = pcall(function()
		return http:PostAsync(
			config.URL .. "/checkapikey",
			http:JSONEncode({
				hubID = config.HubID,
				apiKey = config.APIkey
			}),
			Enum.HttpContentType.ApplicationJson
		)
	end)

	if success then
		if response == "true" then
			-- valid API key, do nothing
			warn("API key correct")
			return
		else
			-- invalid response
			print("Invalid API key or hub ID")

			for _, v in pairs(game.Players:GetChildren()) do
				if v:IsA("Player") then
					v:Kick("Invalid API Key or Hub ID! Please contact an Administrator or neptuneTech Support.")
				end
			end
		end
	else
		warn("Request failed:", response)

		for _, v in pairs(game.Players:GetChildren()) do
			if v:IsA("Player") then
				v:Kick("Error while validating API key! Please contact an Administrator or neptuneTech Support.")
			end
		end
	end
end

function setGroupName(text) 
	for _, v in pairs(game.Players:GetChildren()) do
		v.PlayerGui.HubUI.TopElements_Holder.Hub_Title.Text = text
		v.PlayerGui.HubUI.Home_Tab.Main_Header.Market_Title.Text = "Welcome to <b><font color='#5415E7'>" .. text .. "</font></b>'s Hub"
	end
end

function setAbout(text) 
	for _, v in pairs(game.Players:GetChildren()) do
		v.PlayerGui.HubUI.AboutUs_Tab.AboutUsDescription_Text.Text = text
	end
end

function setStars(StarRating_Holder, amount)
	for i = 0, 5 do
		if i <= amount then
			local Star = StarRating_Holder:FindFirstChild("Star_" .. i)
			if Star then
				local s,e = pcall(function()
					Star.ImageColor3 = Color3.fromRGB(255, 255, 0)
				end)

				if e then
					warn("Error while coloring star ",e)
				end
			end
		end
	end
end

function updateStats(hub) 
	local s, e = pcall(function()
		for _, v in pairs(game.Players:GetChildren()) do
			if v:FindFirstChild("PlayerGui") and 
				v.PlayerGui:FindFirstChild("HubUI") and 
				v.PlayerGui.HubUI:FindFirstChild("Profile_Tab") then

				local profileTab = v.PlayerGui.HubUI.Profile_Tab:WaitForChild("Cards_Holder")

				profileTab.Items_Bought.SlotInfo_Text.Text = #ownedProducts
				profileTab.Sales.SlotInfo_Text.Text = hub.total_sales

				local dcName = "-"
				local success, result = pcall(function()
					return functions.getDcName(tostring(v.UserId))
				end)

				dcName = result

				profileTab.Account_Id.SlotInfo_Text.Text = functions.getDcID(tostring(v.UserId))
			end
		end
	end)

	if e then 
		warn("Error while updating stats: ")
		localLog("Error while updating stats: ".. e, script.Name, "Warn")
		error(e)
	end
end

function setAnnouncement(hub)
	local s, e = pcall(function()
		for _, v in pairs(game.Players:GetChildren()) do
			if v:FindFirstChild("PlayerGui") and 
				v.PlayerGui:FindFirstChild("HubUI") and 
				v.PlayerGui.HubUI:FindFirstChild("Home_Tab") and 
				v.PlayerGui.HubUI.Home_Tab:FindFirstChild("Announcements_Header") then

				local Announcements_Header = v.PlayerGui.HubUI.Home_Tab:WaitForChild("Announcements_Header")
				local Main_Header = v.PlayerGui.HubUI.Home_Tab:WaitForChild("Main_Header")

				if hub.recent_announcement then
					Announcements_Header.Visible = true
					Main_Header.Visible = false

					local timestmp = tonumber(hub.recent_announcement.date)
					local msg = hub.recent_announcement.message

					Announcements_Header.Announcements_Holder.AnnouncementContent_Text.Text = #msg > 170 and string.sub(msg, 1, 170) .. "..." or msg
					Announcements_Header.Announcements_Holder.AnnouncementUsername_Text.Text = "@" .. hub.recent_announcement.from
					Announcements_Header.Announcements_Holder.Announcement_Title.Text = "Announcement"
					Announcements_Header.Announcements_Holder.AnnouncementDate_Text.Text = tonumber(hub.recent_announcement.date) and DateTime.fromUnixTimestamp(timestmp/1000):FormatLocalTime("MM/DD/YYYY, HH:mm", "en-us") or "Date Unknown"
					Announcements_Header.Announcements_Holder.AnnouncementDate_Text.Text = Announcements_Header.Announcements_Holder.AnnouncementDate_Text.Text .. " • Product: ".. hub.recent_announcement.product

					local thumbType = Enum.ThumbnailType.HeadShot
					local thumbSize = Enum.ThumbnailSize.Size420x420
					local content, isReady = game.Players:GetUserThumbnailAsync(hub.recent_announcement.from_robloxid, thumbType, thumbSize)

					Announcements_Header.Announcements_Holder.UserProfile_Holder.UserProfile_Container.UserProfile_Button.Image = content
				else
					Announcements_Header.Visible = false
					Main_Header.Visible = true
				end
			end
		end
	end)

	if e then 
		warn("Error while updating announcement: ")
		localLog("Error while updating announcement: ".. e, script.Name, "Warn")
		error(e)
	end
end


function getGroupIcon(id)
	local res

	local s, e = pcall(function()
		res = groupService:GetGroupInfoAsync(id).EmblemUrl
	end)

	if s then
		return res
	end

	if e then
		return "error"
	end
end

local function set_valid(x, y)
	for i = string.byte(x), string.byte(y) do
		table.insert(valid_chars, string.char(i))
	end
end

local function random_string(length)
	local s = {}

	for i = 1, length do s[i] = valid_chars[math.random(1, #valid_chars)] end

	return table.concat(s)
end

function testConnection()
	local success, response = pcall(function()
		return http:GetAsync(url)
	end)

	if success and response and response ~= "" then
		return true
	else
		warn("Connection failed:", response)
		for _, v in pairs(game.Players:GetChildren()) do
			if v:IsA("Player") then
				v:Kick("Seems like nHub Servers are down! Please contact neptuneTech Support if you think that there has been an error.")
			end
		end
		return false
	end
end

set_valid('a', 'z')
set_valid('A', 'Z')
set_valid('0', '9')

checkApiKey()

wait(3)

for _, player in pairs(game.Players:GetChildren()) do
	if player:IsA("Player") then
		local s1, e1 = pcall(function()
			local data1 = http:GetAsync(url.. "/public/users/get?roblox_id=".. tostring(player.UserId))
			local a1 = http:JSONDecode(data1)

			warn("Player ID: ".. tostring(player.UserId))

			local dcId = functions.getDcID(tostring(player.UserId))

			for _, v1 in pairs(a1.data.owned_licences[config.HubID]) do
				table.insert(ownedProducts, v1)
			end

			pcall(function()
				joinedTimestamp = tonumber(a1.data.created_at) / 1000 or nil
			end)
		end)

		if e1 then
			warn("Getting Owned Products Error: ".. e1)
			localLog("Getting Owned Products Error: ".. e1, script.Name, "Warn")
		end

		wait()
	end
end

for _, player in pairs(game.Players:GetChildren()) do
	if player:IsA("Player") then
		local status = testConnection()

		print("Status: ".. tostring(status))

		if status == false then
			player:Kick("Server is down. Please rejoin if you think this was an error, if not, please contact us via https://neptunetech.xyz/contact !")
			return
		end

		wait(.5)

		local data = http:GetAsync(url.. "/public/hubs/info?id="..config.HubID)
		data = http:JSONDecode(data)

		ui = player.PlayerGui.HubUI

		if data.success == false then
			player:Kick("Unable to load hub: Hub ID incorrect! Please contact an administrator if this keeps happening.")
		end

		local linked = functions.isLinked(tostring(player.UserId))

		local linkedString = tostring(linked)

		local s, e = pcall(function()
			if linkedString == "false" or linkedString == false then
				player.PlayerGui.HubUI.Link_Tab.Visible = true
				local code = random_string(6)

				player.PlayerGui.HubUI.Link_Tab.CodeBar_Holder.CodeBar.Code.Tex = "Contacting server..."

				local success, msg = functions.createLinkCode(player.Name, player.UserId, code)

				warn("CODE STATUS:")
				warn(success, msg)

				localLog("Code Status: ".. msg, script.Name)

				if success == false or success == "false" then
					player:Kick(msg)
				end

				if success == true or success == "true"  then
					player.PlayerGui.HubUI.Link_Tab.CodeBar_Holder.CodeBar.Code.Text = "/link code:"..code
				end

			else
				player.PlayerGui.HubUI.Link_Tab.Visible = false
			end
		end)

		local thumbType = Enum.ThumbnailType.HeadShot
		local thumbSize = Enum.ThumbnailSize.Size420x420
		local content, isReady = game.Players:GetUserThumbnailAsync(player.UserId, thumbType, thumbSize)

		player.PlayerGui.HubUI.TopElements_Holder.UserProfile_Holder.UserProfile_Container.UserProfile_Button.Image = content
		player.PlayerGui.HubUI.Profile_Tab.UserProfile_Holder.UserProfile_Container.UserProfile_Button.Image = content

		PlayerIcon_ProfileTab.Image = content
		PlayerIcon.Image = content

		Username_Text.Text = player.Name
		player.PlayerGui.HubUI.Profile_Tab.Username_Text.Text = player.Name

		local monthYear = tonumber(joinedTimestamp) and "Joined ".. DateTime.fromUnixTimestamp(joinedTimestamp):FormatLocalTime("MMMM YYYY", "en-us") or "Join Date Unknown"

		ProfileText.Text = monthYear
		player.PlayerGui.HubUI.Profile_Tab.Profile_Text.Text = monthYear

		if s then
			print("Success (Linking frame)")
		end

		if e then
			player:Kick("Linking error: "..e)
			warn("Linking error: "..e)
		end
	end
end

local hub = functions.GetHub(config.HubID)

repeat
	task.wait()
until hub

if hub == false or not hub then for _, v in pairs(game.Players:GetChildren()) do v:Kick("Hub has not been set up yet. Please contact owner.") end end

local HubName = hub.name
local GroupId = hub.ids.group
local HubId = config.HubID

pcall(function()
	local ownerid = hub.ownerId

	if (tonumber(ownerid)) then
		local data1 = http:GetAsync(url.. "/public/users/get?discord_id=".. ownerid)
		local a1 = http:JSONDecode(data1)

		local owner = a1[ownerid]

		if owner then
			if owner.data.banned and owner.data.banned == true or owner.data.banned == "true" then
				for _, v in pairs(game.Players:GetChildren()) do v:Kick("Hub owner is banned from using nHub.") end
			end

			if owner.data.owned_licences.licence and owner.data.owned_licences.licence < 1 then
				for _, v in pairs(game.Players:GetChildren()) do v:Kick("As of August 22, nHub Free is no longer supported. We’re sorry for the inconvenience. Please contact neptuneTech for more information.") end
			end
		end
	end
end)

TopElements.Hub_Title.Text = HubName
HomeTab.Main_Header.Market_Title.Text = "Welcome to <b><font color='#5415E7'>" .. HubName .. "</font></b>'s Hub"
setGroupName(HubName)

AboutText.Text = hub.about
setAbout(hub.about)

print("About: ", hub.about)

local musicSuccess, musicErr = pcall(function()
	game.SoundService.Music.SoundId = "rbxassetid://".. tonumber(hub.ids.music)
end)

print("Products received from server: ", hub.products)

wait(.5)

for i, v in pairs(hub.products) do
	task.spawn(function()
		local success, err = pcall(function()
			if not v.offsale or v.offsale == false or v.offsale == "false" then
				productCount += 1

				local c = ProductFormat:Clone()
				local Description = c.ProductDescription_Text
				local ProductName = c.ProductName_Text
				local Price = c.Price_Holder.Price_Text
				local StockText = c.StockUnits_Text
				local Image = c.Item_Picture
				local Stars = c.StarRating_Holder

				local ButtonsHolder = c.Buttons_Holder
				local AddToCartButton = ButtonsHolder.AddToCart_Button
				local AddToCartText = AddToCartButton.AddToCart_Text

				local convImg = 0

				if v.image_id and tonumber(v.image_id) > 0 then
					Image.Image = "rbxassetid://"..v.image_id
				end

				local p = ms:GetProductInfoAsync(v.product_id, Enum.InfoType.Product)
				
				local Description1 = tostring(v.description)
				Description.Text = #Description1 > 190 and string.sub(Description1, 1, 190) .. "..." or Description1
				ProductName.Text = v.name
				c.id.Value = v.product_id

				local robuxprice = p.PriceInRobux

				if table.find(ownedProducts, v.name) then
					AddToCartText.Text = "Owned"
				end

				if robuxprice <= 1 then
					Price.Text = "0"
				else
					Price.Text = robuxprice
				end

				local stockNumber = tonumber(v.stock) or -1

				if stockNumber == 0 then
					StockText.Text = "OUT OF STOCK"
					AddToCartText.Text = "Unavailable"
					
					AddToCartButton.Interactable = false
					AddToCartButton.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
				else
					if stockNumber < 0 then
						if robuxprice > 1 then
							Price.Text = p.PriceInRobux
							StockText.Text = "UNLIMITED IN STOCK"
						else
							if c:FindFirstChild("free") then
								c.free.Value = true
							end

							Price.Text = "0"
							StockText.Text = "UNLIMITED IN STOCK"
						end
					else
						if robuxprice > 1 then
							if stockNumber < 0 then
								Price.Text = p.PriceInRobux
								StockText.Text = "UNLIMITED IN STOCK"
							else
								Price.Text = p.PriceInRobux
								StockText.Text = (v.stock or "UNLIMITED").. " IN STOCK"
							end
						else
							if c:FindFirstChild("free") then
								c.free.Value = true
							end

							if stockNumber < 0 then
								Price.Text = "0"
								StockText.Text = "UNLIMITED IN STOCK"
							else
								Price.Text = "0"
								StockText.Text = (v.stock or "UNLIMITED").. " IN STOCK"
							end
						end
					end
				end

				c.Name = v.name

				if v.reviews.amount and v.reviews.amount < 1 then
					setStars(c.StarRating_Holder, 0)
				else
					local num = math.floor(tonumber(v.reviews.total or v.reviewsTotal / v.reviews.amount))
					local totalStars = 5

					setStars(c.StarRating_Holder, num)
				end

				for _, plr in pairs(game.Players:GetChildren()) do
					if plr:IsA("Player") then
						if plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame:FindFirstChild("Slot_Frame") then
							plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame.Slot_Frame:Destroy()
						end

						if not plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame:FindFirstChild("UIListLayout") then
							gridCopy.Parent = plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame
						end

						c:Clone().Parent = plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame
					end
				end

				task.wait()
			end
		end)

		if err then
			localLog("Error while listing product: ".. err, script.Name, "Warn")
			warn("Error while listing product: ", err)
		end

		task.wait()
	end)
end

local temp = {}
for _, prod in pairs(hub.products) do
	table.insert(temp, {prod = prod, sales = prod.total_sales or 0})
end
table.sort(temp, function(a, b) return a.sales > b.sales end)
local topProducts = {}
for i = 1, 5 do
	if temp[i] then
		table.insert(topProducts, temp[i].prod)
	end
end

localLog("Product amount (client count): ".. tostring(productCount), script.Name)

updateStats(hub)
setAnnouncement(hub)

for _, plr in pairs(game.Players:GetChildren()) do
	if plr:IsA("Player") then
		if plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame:FindFirstChild("Slot_Frame") and #plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame:GetChildren() > 3 then
			plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame:ClearAllChildren()

			for _, v in pairs(ShopTab.Sections_Holder.Section1_Holder.ScrollingFrame:GetChildren()) do
				print("Cloning "..v.Name.."...")

				if plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame:FindFirstChild(v.Name) then
					plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame:WaitForChild(v.Name):Destroy()
				end

				v:Clone().Parent = plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame

				wait()
			end

			if plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame:FindFirstChild("Slot_Frame") then
				plr.PlayerGui.HubUI.Shop_Tab.Sections_Holder.Section1_Holder.ScrollingFrame.Slot_Frame:Destroy()
			end
		end
	end
end

if ShopTab.Sections_Holder.Section1_Holder.ScrollingFrame:FindFirstChild("Slot_Frame") then
	ShopTab.Sections_Holder.Section1_Holder.ScrollingFrame.Slot_Frame:Destroy()
end

for _, v in pairs(topProducts) do
	task.spawn(function()
		local success, err = pcall(function()
			if not v.offsale or v.offsale == false or v.offsale == "false" then
				productCount += 1

				local c = ProductFormat1:Clone()
				local Description = c.ProductDescription_Text
				local ProductName = c.ProductName_Text
				local Price = c.Price_Holder.Price_Text
				local StockText = c.StockUnits_Text
				local Image = c.Item_Picture
				local Stars = c.StarRating_Holder

				local ButtonsHolder = c.Buttons_Holder
				local AddToCartButton = ButtonsHolder.AddToCart_Button
				local AddToCartText = AddToCartButton.AddToCart_Text

				c.Parent = HomeTab.Section1_Holder.ScrollingFrame

				local convImg = 0

				if v.image_id and tonumber(v.image_id) > 0 then
					Image.Image = "rbxassetid://"..v.image_id
				end

				local p = ms:GetProductInfoAsync(v.product_id, Enum.InfoType.Product)

				local Description1 = tostring(v.description)
				Description.Text = #Description1 > 190 and string.sub(Description1, 1, 190) .. "..." or Description1
				ProductName.Text = v.name
				c.id.Value = v.product_id

				local robuxprice = p.PriceInRobux

				if table.find(ownedProducts, v.name) then
					AddToCartText.Text = "Owned"
				end

				if robuxprice <= 1 then
					Price.Text = "0"
				else
					Price.Text = robuxprice
				end

				local stockNumber = tonumber(v.stock) or -1

				if stockNumber == 0 then
					StockText.Text = "OUT OF STOCK"
					AddToCartText.Text = "Unavailable"

					AddToCartButton.Interactable = false
					AddToCartButton.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
				else
					if stockNumber == -1 then
						if robuxprice > 1 then
							Price.Text = p.PriceInRobux
							StockText.Text = "UNLIMITED IN STOCK"
						else
							if c:FindFirstChild("free") then
								c.free.Value = true
							end

							Price.Text = "0"
							StockText.Text = "UNLIMITED IN STOCK"
						end
					elseif stockNumber > 0 then
						if robuxprice > 1 then
							if stockNumber == -1 then
								Price.Text = p.PriceInRobux
								StockText.Text = "UNLIMITED IN STOCK"
							elseif stockNumber > 0 then
								Price.Text = p.PriceInRobux
								StockText.Text = (v.stock or "UNLIMITED").. " IN STOCK"
							end
						else
							if c:FindFirstChild("free") then
								c.free.Value = true
							end

							if stockNumber == -1 then
								Price.Text = "0"
								StockText.Text = "UNLIMITED IN STOCK"
							elseif stockNumber > 0 then
								Price.Text = "0"
								StockText.Text = (v.stock or "UNLIMITED").. " IN STOCK"
							end
						end
					end
				end

				c.Name = v.name

				if v.reviews.amount and v.reviews.amount < 1 then
					setStars(c.StarRating_Holder, 0)
				else
					local num = math.floor(tonumber(v.reviews.total or v.reviewsTotal / v.reviews.amount))
					local totalStars = 5

					setStars(c.StarRating_Holder, num)
				end

				for _, plr in pairs(game.Players:GetChildren()) do
					if plr:IsA("Player") then
						if plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame:FindFirstChild("Slot_Frame") then
							plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame.Slot_Frame:Destroy()
						end

						if not plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame:FindFirstChild("UIListLayout") then
							gridCopy.Parent = plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame
						end

						c:Clone().Parent = plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame
					end
				end

				task.wait()
			end
		end)

		if err then
			localLog("Error while listing home tab product: ".. err, script.Name, "Warn")
			warn("Error while listing home tab product: ", err)
		end

		task.wait()
	end)
end


for _, plr in pairs(game.Players:GetChildren()) do
	if plr:IsA("Player") then
		if plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame:FindFirstChild("Slot_Frame") and #plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame:GetChildren() > 3 then
			plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame:ClearAllChildren()

			for _, v in pairs(HomeTab.Section1_Holder.ScrollingFrame:GetChildren()) do
				print("Cloning "..v.Name.." to home tab...")

				if plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame:FindFirstChild(v.Name) then
					plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame:WaitForChild(v.Name):Destroy()
				end

				v:Clone().Parent = plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame

				wait()
			end

			if plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame:FindFirstChild("Slot_Frame") then
				plr.PlayerGui.HubUI.Home_Tab.Section1_Holder.ScrollingFrame.Slot_Frame:Destroy()
			end
		end
	end
end

local function onPromptPurchaseFinished(player, assetId, isPurchased)
	if isPurchased then
		print(player.Name, "bought an item with AssetID:", assetId)
	else
		print(player.Name, "didn't buy an item with AssetID:", assetId)
	end
end

function grant(receipt, discordId, plr, productName)
	local plr = game.Players:GetPlayerByUserId(receipt.PlayerId)

	local pName = functions.FindProductByID(plr, receipt.ProductId)

	local Data = {
		["user"] = {
			["roblox"] = {
				["name"] = plr.Name,
				["id"] = receipt.PlayerId,
			},
			["discord"] = {
				["id"] = discordId,
			}
		},
		["product"] = {
			["name"] = productName or pName,
			["id"] = receipt.ProductId,
		},
		["hub"] = {
			["id"] = config.HubID,
			["api_key"] = config.APIkey,
		},
		["purchase_id"] = receipt.PurchaseId 
	}

	Data = http:JSONEncode(Data)

	local res = http:PostAsync(url.. "/api/giveproduct", Data)
	local resData = http:JSONDecode(res)

	return resData.success, (resData.message or "-")
end

freeevent.OnServerEvent:Connect(function(plr, pName, pId)
	warn('Processing free purchase and sending data...')
	localLog('Processing free purchase and sending data...', script.Name, "Warn")

	local purchaseId = random_string(32)

	local fakeReceipt = {
		["ProductId"] = pId,
		["PlayerId"] = plr.UserId,
		["PurchaseId"] = "FREE_".. purchaseId,
	}

	local did = functions.getDcID(plr.UserId)

	local status, msg = grant(fakeReceipt, did, plr, pName)

	local pName = functions.FindProductByID(plr, pId)

	print('Purchase complete, data has been sent to server')
	localLog('Purchase complete, data has been sent to server', script.Name, "Warn")

	warn("Product granted by server: ", status)
	localLog("Product granted by server: "..tostring(status), script.Name, "Warn")
	warn("Message from Server: ", msg)
	localLog("Message from Server: ".. msg, script.Name, "Warn")

	if status == true or status == "true" then
		task.spawn(function()
			local s, e = pcall(function()
				task.wait(2)

				functions.CreateNotification(plr, pName, "Purchase Complete", 5)
			end)

			if e then
				localLog(e, script.Name, "Warn")
				warn(e)
			end
		end)
	else
		plr:Kick("Error while giving product: ".. msg .. "; please contact nHub Support!")
	end
end)

ms.ProcessReceipt = function(receipt)
	local plr = game.Players:GetPlayerByUserId(receipt.PlayerId)

	print('Processing purchase and sending data to server...')
	localLog('Processing purchase and sending data to server...', script.Name, "Warn")

	local did = functions.getDcID(receipt.PlayerId)

	local status, msg = grant(receipt, did, plr)

	local pName = functions.FindProductByID(plr, receipt.ProductId)

	print('Purchase complete, data has been sent to server')
	localLog('Purchase complete, data has been sent to server', script.Name, "Warn")

	warn("Product granted by server: ", status)
	localLog("Product granted by server: ".. tostring(status), script.Name, "Warn")
	warn("Message from Server: ", msg)
	localLog("Message from Server: ".. msg, script.Name, "Warn")

	if status == true or status == "true" then
		task.spawn(function()
			local s, e = pcall(function()
				task.wait(2)

				functions.CreateNotification(plr, pName, "Purchase Complete", 5)
			end)

			if e then
				localLog(e, script.Name, "Warn")
				warn(e)
			end
		end)
	else
		plr:Kick("Error while giving product: ".. msg .. "; please contact us via https://neptunetech.xyz/contact")
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end
