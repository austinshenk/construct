------------------------------------------
--Construct
--Adds a way for 3d recipes to be built
--and then when hit by a hammer on the
--it will convert to the the chosen construct
------------------------------------------
local Constructs = {}
local Reverting = {}
local nodeReg = minetest.register_node
local Alias = {}
local def = {}
local pipeworks = minetest.get_modpath("pipeworks")
--Hammer Metadata
--TL,TR,BL,BR,C,Recipe
------------------------------------------------------------
-- _    _ _______ _____ _      _____ _______ _____ ______  _____ 
--| |  | |__   __|_   _| |    |_   _|__   __|_   _|  ____|/ ____|
--| |  | |  | |    | | | |      | |    | |    | | | |__  | (___  
--| |  | |  | |    | | | |      | |    | |    | | |  __|  \___ \ 
--| |__| |  | |   _| |_| |____ _| |_   | |   _| |_| |____ ____) |
-- \____/   |_|  |_____|______|_____|  |_|  |_____|______|_____/ 
--
------------------------------------------------------------
function register_construct_alias(from, to)
	Alias[from] = to
end
local function register_construct(name, wear, r, b)
	Constructs[name] = {recipe=r, build=b, wear=wear}
end

local function parseMetadata(tool)
	local data = tool:get_metadata()
	if data == "" then data = "00100construct:furnace" end
	local m = {
		TL = data:sub(1,1),
		TR = data:sub(2,2),
		BL = data:sub(3,3),
		BR = data:sub(4,4),
		C = data:sub(5,5),
		Recipe = data:sub(6),
	}
	--print(m.TL..m.TR..m.BL..m.BR..m.C..m.Recipe)
	return m
end
local function hacky_swap_node(pos,name)
	local node = minetest.env:get_node(pos)
	local meta = minetest.env:get_meta(pos)
	local meta0 = meta:to_table()
	if node.name == name then
		return
	end
	node.name = name
	local meta0 = meta:to_table()
	minetest.env:set_node(pos,node)
	meta = minetest.env:get_meta(pos)
	meta:from_table(meta0)
end
local function setConstructFormspec(start, name, str)
	local env = minetest.env
	local recipe = Constructs[name]
	local l,w,h = #recipe.recipe,#recipe.recipe[1][1],#recipe.recipe[1]
	local meta
	for z=1,l do
	for y=1,h do
	for x=1,w do
		meta = env:get_meta({x=start.x+x-1,y=start.y+y-1,z=start.z+z-1})
		meta:set_string("formspec", str)
	end
	end
	end
end
------------------------------------------------------------
-- ______ ____  _____  __  __  _____ _____  ______ _____  _____ 
--|  ____/ __ \|  __ \|  \/  |/ ____|  __ \|  ____/ ____|/ ____|
--| |__ | |  | | |__) | \  / | (___ | |__) | |__ | |    | (___  
--|  __|| |  | |  _  /| |\/| |\___ \|  ___/|  __|| |     \___ \ 
--| |   | |__| | | \ \| |  | |____) | |    | |___| |____ ____) |
--|_|    \____/|_|  \_\_|  |_|_____/|_|    |______\_____|_____/ 
--
------------------------------------------------------------
local function showHammerFormspec(tool)
	local meta = parseMetadata(tool)
	return "size[3,4]button[0,0;1,1;topleft;"..meta.TL.."]button[2,0;1,1;topright;"..meta.TR.."]"..
			"button[1,1;1,1;center;"..meta.C.."]button[0,2;1,1;botleft;"..meta.BL.."]button[2,2;1,1;botright;"..meta.BR.."]"..
			"button[0,3;3,1;recipe;"..meta.Recipe.."]"
end
local function showRecipeList()
	local row = 6
	local width = 3
	local col = math.floor(#Constructs/row)+1
	local str = "size["..(width*col)..","..row.."]"
	local x,y = 0,0
	for recipe,_ in pairs(Constructs) do
		str = str.."button["..x..","..y..";"..width..",1;"..recipe..";"..recipe:sub(11).."]"
		y=y+1
		if y == row-1 then y=0 x=x+1 end
	end
	return str
end
------------------------------------------------------------
--          _      _____  ____  _____  _____ _______ _    _ __  __  _____ 
--    /\   | |    / ____|/ __ \|  __ \|_   _|__   __| |  | |  \/  |/ ____|
--   /  \  | |   | |  __| |  | | |__) | | |    | |  | |__| | \  / | (___  
--  / /\ \ | |   | | |_ | |  | |  _  /  | |    | |  |  __  | |\/| |\___ \ 
-- / ____ \| |___| |__| | |__| | | \ \ _| |_   | |  | |  | | |  | |____) |
--/_/    \_\______\_____|\____/|_|  \_\_____|  |_|  |_|  |_|_|  |_|_____/ 

------------------------------------------------------------
local function revertConstruct(start, destroyed, recipe)
	local r = Constructs[recipe]
	if r == nil then return end
	Reverting[minetest.pos_to_string(start)] = 1
	local env = minetest.env
	local l,w,h = #r.recipe,#r.recipe[1][1],#r.recipe[1]
	local pos
	for z=1,l do
	for y=1,h do
	for x=1,w do
		pos = {x=start.x+x-1,y=start.y+y-1,z=start.z+z-1}
		if pos ~= destroyed then
			env:set_node(pos, {name=r.recipe[z][y][x]})
		end
	end
	end
	end
	Reverting[minetest.pos_to_string(start)] = nil
end
local function createConstruct(player, start, recipe)
	local r = Constructs[recipe]
	if r == nil then return end
	local env = minetest.env
	local i=1
	local pos
	local l,w,h = #r.recipe,#r.recipe[1][1],#r.recipe[1]
	local meta
	for z=1,l do
	for y=1,h do
	for x=1,w do
		pos = {x=start.x+x-1,y=start.y+y-1,z=start.z+z-1}
		if r.build[i].name ~= "air" then
			meta = env:get_meta(pos)
			env:set_node(pos, r.build[i])
			meta:set_int("x", start.x)
			meta:set_int("y", start.y)
			meta:set_int("z", start.z)
		else
			env:set_node(pos, {name="air"})
		end
		i = i+1
	end
	end
	end
	local tool = player:get_wielded_item()
	tool:add_wear(r.wear)
	player:set_wielded_item(tool)
end
local function checkRecipe(tool,pos,player)
	if pos == nil then return end
	local env = minetest.env
	local node = env:get_node(pos)
	local meta = parseMetadata(tool)
	local recipe = Constructs[meta.Recipe]
	if recipe == "" or recipe == nil or recipe == {} then return end
	local l,w,h = #recipe.recipe,#recipe.recipe[1][1],#recipe.recipe[1]
	local dx,dy,dz = 0,0,0
	local px,py,pz = 1,1,1
	--Bottom Left is desired start position
	if meta.TR == "1" then dx = -(w-1) px = -1 dy = -(h-1) py = -1 end
	if meta.TL == "1" then dy = -(h-1) py = -1 end
	if meta.BR == "1" then dx = -(w-1) px = -1 end
	if meta.C == "1" then dz = -(l-1) pz = -1 end
	local zero = {x=0,y=0,z=0}
	minetest.add_particle({x=pos.x-(px*0.6),y=pos.y,z=pos.z}, zero, zero, 1, 2, false, "construct_trail.png", player:get_player_name())
	minetest.add_particle({x=pos.x,y=pos.y-(py*0.6),z=pos.z}, zero, zero, 1, 2, false, "construct_trail.png", player:get_player_name())
	minetest.add_particle({x=pos.x,y=pos.y,z=pos.z-(pz*0.6)}, zero, zero, 1, 2, false, "construct_trail.png", player:get_player_name())
	local start = {x=pos.x+dx,y=pos.y+dy,z=pos.z+dz}
	local name
	for z=1,l do
	for y=1,h do
	for x=1,w do
		node = env:get_node({x=start.x+x-1,y=start.y+y-1,z=start.z+z-1})
		name = recipe.recipe[z][y][x]
		if node.name ~= name and Alias[node.name] ~= name then return false end
	end
	end
	end
	return true
end
------------------------------------------------------------
-- 		_______ ____   ____  _       _____ 
--	   |__   __/ __ \ / __ \| |     / ____|
--		  | | | |  | | |  | | |    | (___  
-- 		  | | | |  | | |  | | |     \___ \ 
--		  | | | |__| | |__| | |____ ____) |
-- 		  |_|  \____/ \____/|______|_____/ 
--
------------------------------------------------------------
minetest.register_tool("construct:hammer", {
	description = "Construction Hammer",
	inventory_image = "construct_tool_hammer.png",
	on_place = function(itemstack, placer, pointed_thing)
		minetest.show_formspec(placer:get_player_name(), "construct:hammer", showHammerFormspec(itemstack))
	end,
	on_use = function(itemstack, user, pointed_thing)
		if checkRecipe(itemstack, pointed_thing.under, user) then
			local meta = parseMetadata(itemstack)
			local recipe = Constructs[meta.Recipe]
			local l,w,h = #recipe.recipe,#recipe.recipe[1][1],#recipe.recipe[1]
			local dx,dy,dz = 0,0,0
			local px,py,pz = 1,1,1
			--Bottom Left is desired start position
			if meta.TR == "1" then dx = -(w-1) px = -1 dy = -(h-1) py = -1 end
			if meta.TL == "1" then dy = -(h-1) py = -1 end
			if meta.BR == "1" then dx = -(w-1) px = -1 end
			if meta.C == "1" then dz = -(l-1) pz = -1 end
			local start = {x=pointed_thing.under.x+dx,y=pointed_thing.under.y+dy,z=pointed_thing.under.z+dz}
			createConstruct(user, start, meta.Recipe)
			itemstack:add_wear(Constructs[meta.Recipe].wear)
			return itemstack
		end
		return nil
	end,
})
minetest.register_craft({
	output = "construct:hammer",
	recipe = {
	{"","default:steel_ingot",""},
	{"default:steel_ingot","default:stick","default:steel_ingot"},
	{"","default:stick",""},
	},
})
------------------------------------------------------------
-- _____  ______ _____ _____  _____ _______ ______ _____   _____ 
--|  __ \|  ____/ ____|_   _|/ ____|__   __|  ____|  __ \ / ____|
--| |__) | |__ | |  __  | | | (___    | |  | |__  | |__) | (___  
--|  _  /|  __|| | |_ | | |  \___ \   | |  |  __| |  _  / \___ \ 
--| | \ \| |___| |__| |_| |_ ____) |  | |  | |____| | \ \ ____) |
--|_|  \_\______\_____|_____|_____/   |_|  |______|_|  \_\_____/ 
--                                                               
------------------------------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "construct:hammer" then return false end
	local tool = player:get_wielded_item()
	local meta = parseMetadata(tool)
	if fields.topleft then meta.TL,meta.TR,meta.BL,meta.BR = 1,0,0,0 end
	if fields.topright then meta.TL,meta.TR,meta.BL,meta.BR = 0,1,0,0 end
	if fields.botleft then meta.TL,meta.TR,meta.BL,meta.BR = 0,0,1,0 end
	if fields.botright then meta.TL,meta.TR,meta.BL,meta.BR = 0,0,0,1 end
	if fields.center then if meta.C == "0" then meta.C = "1" else meta.C = "0" end end
	if fields.recipe then minetest.show_formspec(player:get_player_name(), "construct:hammer", showRecipeList()) return end
	for recipe,_ in pairs(Constructs) do
		if fields[recipe] then meta.Recipe = recipe end
	end
	local ttool = tool:to_table()
	ttool.metadata = meta.TL..meta.TR..meta.BL..meta.BR..meta.C..meta.Recipe
	player:set_wielded_item(ttool)
	minetest.show_formspec(player:get_player_name(), "construct:hammer", showHammerFormspec(player:get_wielded_item()))
	return true
end)
------------------------------------------------------------
--  _____ _______ ____   _____ _  _______ _____ _      ______ 
-- / ____|__   __/ __ \ / ____| |/ /  __ \_   _| |    |  ____|
--| (___    | | | |  | | |    | ' /| |__) || | | |    | |__   
-- \___ \   | | | |  | | |    |  < |  ___/ | | | |    |  __|  
-- ____) |  | | | |__| | |____| . \| |    _| |_| |____| |____ 
--|_____/   |_|  \____/ \_____|_|\_\_|   |_____|______|______|
--                                                            
------------------------------------------------------------
local function getStockpileFormspec(meta, page)
	local str = "size[8,9]"..
				"list[current_player;main;0,5;8,4;]"..
				"button[3,4.125;.75,.75;previous;<]label[3.8,4.125;"..(math.floor(page/32)+1).."]button[4.25,4.125;.75,.75;next;>]"..
				"button[7.325,4.125;.6,.75;linear;=]button[6.75,4.125;.6,.75;vertical;||]"
	if meta == nil then
		str = str.."list[context;main;0,0;8,4;"..page.."]"
	else
		str = str.."list[nodemeta:"..meta:get_int("x")..","..meta:get_int("y")..","..meta:get_int("z")..";main;0,0;8,4;"..page.."]"
	end
	return str
end
local function GeneralSort(pos)
	local meta = minetest.env:get_meta(pos)
	local inv = meta:to_table().inventory.main
	table.sort(inv, function(a,b)
		if a:is_empty() then return false end
		if b:is_empty() then return true end
		if a:get_name()==b:get_name() then
			return a:get_count()>b:get_count()
		end
		return a:get_name()<b:get_name()
	end)
	return inv
end
local function LinearSort(meta, list)
	meta:get_inventory():set_list("main", list)
end
local function VerticalSort(meta, list)
	local inv = meta:get_inventory()
	local i,x,y,page = 1,0,1,0
	while page<2 do
	while x<8 do
		inv:set_stack("main", y+x+(page*32), list[i])
		i=i+1
		if y>=25 then
			y=1
			x=x+1
		else
			y=y+8
		end
	end
		page = page+1
		x = 0
		y = 1
	end
end
register_construct("construct:stockpile", 500,
										  {{{"default:wood","default:wood"},{"default:wood","default:wood"}},{{"default:wood","default:wood"},{"default:wood","default:wood"}}},
										  {{name="construct:stockpile_source", param2=0},{name="construct:stockpile_corner", param2=3},
										   {name="construct:stockpile_corner", param2=23},{name="construct:stockpile_corner", param2=20},
										   {name="construct:stockpile_corner", param2=1},{name="construct:stockpile_corner", param2=2},
										   {name="construct:stockpile_corner", param2=22},{name="construct:stockpile_corner", param2=21}})
	def = {description = "Stockpile",
		tiles = {"construct_stockpile_top.png","construct_stockpile_top.png","construct_stockpile_top.png","construct_stockpile_side2.png","construct_stockpile_top.png","construct_stockpile_side.png"},
		groups = {choppy=2,oddly_breakable_by_hand=2, not_in_creative_inventory=1},
		sounds = default.node_sound_wood_defaults(),
		drop = "default:wood",
		paramtype2 = "facedir",
		on_construct = function(pos)
			local meta = minetest.env:get_meta(pos)
			meta:set_string("formspec", getStockpileFormspec(nil, 0))
			meta:set_string("infotext", "Stockpile")
			local inv = meta:get_inventory()
			inv:set_size("main", 64)
		end,
		on_destruct = function(pos)
			if Reverting[minetest.pos_to_string(pos)] == 1 then return end
			revertConstruct(pos, pos, "construct:stockpile")
		end,
		can_dig = function(pos,player)
			return minetest.env:get_meta(pos):get_inventory():is_empty("main")
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			local meta = minetest.env:get_meta(pos)
			if fields.linear then
				LinearSort(meta, GeneralSort(pos))
			end
			if fields.vertical then
				VerticalSort(meta, GeneralSort(pos))
			end
			if fields.next then
				setConstructFormspec(pos, "construct:stockpile", getStockpileFormspec(nil, 32))
			end
			if fields.previous then
				setConstructFormspec(pos, "construct:stockpile", getStockpileFormspec(nil, 0))
			end
		end,
	}
	if pipeworks ~= nil then
		def.groups.tubedevice=1
		def.groups.tubedevice_receiver=1
		def.tube = {
			insert_object=function(pos,node,stack,direction)
				local meta=minetest.env:get_meta(pos)
				local inv=meta:get_inventory()
				return inv:add_item("main",stack)
			end,
			can_insert=function(pos,node,stack,direction)
				local meta=minetest.env:get_meta(pos)
				local inv=meta:get_inventory()
				return inv:room_for_item("main",stack)
			end,
			input_inventory="main"
		}
		def.after_place_node = function(pos)
			tube_scanforobjects(pos)
		end
		def.after_dig_node = function(pos)
			tube_scanforobjects(pos)
		end
	end
nodeReg("construct:stockpile_source", def)
	local function register_stockpile_meta(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec", getStockpileFormspec(meta, 0))
		meta:set_string("infotext", "Stockpile")
		meta:get_inventory():set_size("main", 64)
	end
	def.on_construct = function(pos)
		minetest.after(.5, register_stockpile_meta, pos)
	end
	def.on_destruct = function(pos)
		local meta = minetest.env:get_meta(pos)
		local start = {x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}
		if Reverting[minetest.pos_to_string(start)] == 1 then return end
		revertConstruct(start, pos, "construct:stockpile")
	end
	def.can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos)
		local inv = minetest.get_inventory({type="node", pos={x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}})
		return inv:is_empty("main")
	end
	def.on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.env:get_meta(pos)
		local spos = {x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}
		local inv = GeneralSort(spos)
		if fields.linear then
			LinearSort(minetest.env:get_meta(spos), inv)
		end
		if fields.vertical then
			VerticalSort(minetest.env:get_meta(spos), inv)
		end
		if fields.next then
			setConstructFormspec({x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}, "construct:stockpile", getStockpileFormspec(meta, 32))
		end
		if fields.previous then
			setConstructFormspec({x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}, "construct:stockpile", getStockpileFormspec(meta, 0))
		end
	end
	if pipeworks ~= nil then
		def.tube = {
			insert_object=function(pos,node,stack,direction)
				local meta = minetest.env:get_meta(pos)
				local metapos = {x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}
				local inv = minetest.env:get_meta(metapos):get_inventory()
				return inv:add_item("main",stack)
			end,
			can_insert=function(pos,node,stack,direction)
				local meta=minetest.env:get_meta(pos)
				local metapos = {x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}
				local inv = minetest.env:get_meta(metapos):get_inventory()
				return inv:room_for_item("main",stack)
			end,
			input_inventory="main"
		}
	end
nodeReg("construct:stockpile_corner", def)
------------------------------------------------------------
-- ______ _    _ _____  _   _          _____ ______ 
--|  ____| |  | |  __ \| \ | |   /\   / ____|  ____|
--| |__  | |  | | |__) |  \| |  /  \ | |    | |__   
--|  __| | |  | |  _  /| . ` | / /\ \| |    |  __|  
--| |    | |__| | | \ \| |\  |/ ____ \ |____| |____ 
--|_|     \____/|_|  \_\_| \_/_/    \_\_____|______|
--                                                 
------------------------------------------------------------
register_construct("construct:furnace", 5000, 
										{{{"default:cobble","default:cobble","default:cobble"},{"default:cobble","default:cobble","default:cobble"},{"default:cobble","default:cobble","default:cobble"}},
										{{"default:cobble","default:cobble","default:cobble"},{"default:cobble","default:torch","default:cobble"},{"default:cobble","default:cobble","default:cobble"}},
										{{"default:cobble","default:cobble","default:cobble"},{"default:cobble","default:cobble","default:cobble"},{"default:cobble","default:cobble","default:cobble"}}},
										{{name="construct:furnace_source", param2=0},{name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},
										 {name="construct:furnace_side", param2=0},{name="construct:furnace_idle", param2=0},{name="construct:furnace_side", param2=0},
										 {name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},
										 {name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},
										 {name="construct:furnace_idle", param2=0},{name="air", param2=0},{name="construct:furnace_idle", param2=0},
										 {name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},
										 {name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},
										 {name="construct:furnace_side", param2=0},{name="construct:furnace_idle", param2=0},{name="construct:furnace_side", param2=0},
										 {name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0},{name="construct:furnace_side", param2=0}})
	local furnace_formspec = function(pos, percent)
		local str = "size[8,9]list[current_player;main;0,5;8,4;]"
		if pos==nil then
			str = str.."list[context;fuel;2,3;1,1;]"..
				"list[context;src;2,1;1,1;]"..
				"list[context;dst;5,1;2,2;]"
		else
			str = str.."list[nodemeta:"..pos..";fuel;2,3;1,1;]"..
				"list[nodemeta:"..pos..";src;2,1;1,1;]"..
				"list[nodemeta:"..pos..";dst;5,1;2,2;]"
		end
		if percent > 0 then
			str = str.."image[2,2;1,1;default_furnace_fire_bg.png^[lowpart:"..(100-percent)..":default_furnace_fire_fg.png]"
		else
			str = str.."image[2,2;1,1;default_furnace_fire_bg.png]"
		end
		return str
	end
	def = {description = "Furnace",
	tiles = {"construct_furnace_top.png","construct_furnace_top.png","construct_furnace_side.png","construct_furnace_side.png","construct_furnace_side.png","construct_furnace_side.png"},
	groups = {choppy=2,oddly_breakable_by_hand=2, not_in_creative_inventory=1,tubedevice=1,tubedevice_receiver=1},
	paramtype = "none",
	light_source = 0,
	sounds = default.node_sound_wood_defaults(),
	drop = "default:cobble",
	on_construct = function(pos)
		local meta = minetest.env:get_meta(pos)
		meta:set_string("formspec", furnace_formspec(nil, 0))
		meta:set_string("infotext", "Furnace")
		local inv = meta:get_inventory()
		inv:set_size("fuel", 1)
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
		meta:set_float("fuel", 0.0)
	end,
	can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src") then
			local start = {x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}
			if Reverting[minetest.pos_to_string(start)] == 1 then return end
			revertConstruct(start, pos, "construct:furnace")
			return true
		else
			return false
		end
	end,
	on_dig = function(pos, node, digger)
		if digger == nil then return end
		minetest.node_dig(pos, node, digger)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		if listname == "fuel" then
			if minetest.get_craft_result({method="fuel",width=1,items={stack}}).time ~= 0 then
				if inv:is_empty("src") then
					meta:set_string("infotext","Furnace is empty")
				end
				return stack:get_count()
			else
				return 0
			end
		elseif listname == "src" then
			return stack:get_count()
		elseif listname == "dst" then
			return 0
		end
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.env:get_meta(pos)
		local inv = meta:get_inventory()
		local stack = inv:get_stack(from_list, from_index)
		if to_list == "fuel" then
			if minetest.get_craft_result({method="fuel",width=1,items={stack}}).time ~= 0 then
				if inv:is_empty("src") then
					meta:set_string("infotext","Furnace is empty")
				end
				return count
			else
				return 0
			end
		elseif to_list == "src" then
			return count
		elseif to_list == "dst" then
			return 0
		end
	end,
	}
	if pipeworks ~= nil then
		def.tube = {
			insert_object=function(pos,node,stack,direction)
				local meta=minetest.env:get_meta(pos)
				local inv=meta:get_inventory()
				if direction.y==1 then
					return inv:add_item("fuel",stack)
				else
					return inv:add_item("src",stack)
				end
			end,
			can_insert=function(pos,node,stack,direction)
				local meta=minetest.env:get_meta(pos)
				local inv=meta:get_inventory()
				if direction.y==1 then
					return inv:room_for_item("fuel",stack)
				elseif direction.y==-1 then
					return inv:room_for_item("src",stack)
				else
					return 0
				end
			end,
			input_inventory="dst"
		}
		def.after_place_node = function(pos)
			tube_scanforobjects(pos)
		end
		def.after_dig_node = function(pos)
			tube_scanforobjects(pos)
		end
	end
nodeReg("construct:furnace_source", def)
	local function register_furnace_meta(pos)
		local meta = minetest.env:get_meta(pos)
		local metapos = meta:get_int("x")..","..meta:get_int("y")..","..meta:get_int("z")
		meta:set_string("formspec", furnace_formspec(metapos, 0))
		meta:set_string("infotext", "Furnace is empty")
		local inv  = meta:get_inventory()
		inv:set_size("fuel", 1)
		inv:set_size("src", 1)
		inv:set_size("dst", 4)
	end
	def.on_construct = function(pos)
		minetest.after(.5, register_furnace_meta, pos)
	end
	def.can_dig = function(pos,player)
		local meta = minetest.env:get_meta(pos)
		local start = {x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}
		local inv = minetest.get_inventory({type="node", pos=start})
		if inv:is_empty("fuel")==true and inv:is_empty("dst")==true and inv:is_empty("src")==true then
			if Reverting[minetest.pos_to_string(start)] == 1 then return false end
			revertConstruct(start, pos, "construct:furnace")
			return true
		else
			return false
		end
	end
	if pipeworks ~= nil then
		def.tube = {
			insert_object=function(pos,node,stack,direction)
				local meta=minetest.env:get_meta(pos)
				local start = {x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}
				local inv = minetest.get_inventory({type="node", pos=start})
				if direction.y==1 then
					return inv:add_item("fuel",stack)
				else
					return inv:add_item("src",stack)
				end
			end,
			can_insert=function(pos,node,stack,direction)
				local meta=minetest.env:get_meta(pos)
				local start = {x=meta:get_int("x"),y=meta:get_int("y"),z=meta:get_int("z")}
				local inv = minetest.get_inventory({type="node", pos=start})
				if direction.y==1 then
					return inv:room_for_item("fuel",stack)
				elseif direction.y==-1 then
					return inv:room_for_item("src",stack)
				else
					return 0
				end
			end,
			input_inventory="dst"
		}
	end
nodeReg("construct:furnace_side", def)
	def.tiles = {"construct_furnace_top.png","construct_furnace_top.png","construct_furnace_front.png","construct_furnace_front.png","construct_furnace_front.png","construct_furnace_front.png"}
nodeReg("construct:furnace_idle", def)
	def.tiles = {"construct_furnace_top.png","construct_furnace_top.png","construct_furnace_front_active.png","construct_furnace_front_active.png","construct_furnace_front_active.png","construct_furnace_front_active.png"}
	def.paramtype = "light"
	def.light_source = 8
nodeReg("construct:furnace_active", def)
local function swap_furnace_nodes(pos, percent, infotext, active)
	local recipe = Constructs["construct:furnace"]
	local l,w,h = #recipe.recipe,#recipe.recipe[1][1],#recipe.recipe[1]
	local meta, metapos, currpos
	local i = 0
	for z=1,l do
	for y=1,h do
	for x=1,w do
		currpos = {x=pos.x+x-1,y=pos.y+y-1,z=pos.z+z-1}
		meta = minetest.env:get_meta(currpos)
		metapos = pos.x..","..pos.y..","..pos.z
		meta:set_string("infotext",infotext)
		if i==4 or i==12 or i==14 or i==22 then
			if active == 0 then
				hacky_swap_node(currpos,"construct:furnace_idle")
			else
				hacky_swap_node(currpos,"construct:furnace_active")
			end
		end
		if percent > 0 and active == 1 then
			meta:set_string("formspec", furnace_formspec(metapos, percent))
		else
			meta:set_string("formspec", furnace_formspec(metapos, 0))
		end
		i = i+1
	end
	end
	end
end
minetest.register_abm({
	nodenames = {"construct:furnace_source"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.env:get_meta(pos)
		for i, name in ipairs({
				"fuel_totaltime",
				"fuel_time",
				"src_totaltime",
				"src_time"
		}) do
			if meta:get_string(name) == "" then
				meta:set_float(name, 0.0)
			end
		end

		local inv = meta:get_inventory()

		local srclist = inv:get_list("src")
		local cooked = nil
		local aftercooked
		
		if srclist then
			cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
		end
		
		local was_active = false
		
		if meta:get_float("fuel_time") < meta:get_float("fuel_totaltime") then
			was_active = true
			meta:set_float("fuel_time", meta:get_float("fuel_time") + 1)
			meta:set_float("src_time", meta:get_float("src_time") + 1)
			if cooked and cooked.item and meta:get_float("src_time") >= cooked.time then
				-- check if there's room for output in "dst" list
				if inv:room_for_item("dst",cooked.item) then
					-- Put result in "dst" list
					inv:add_item("dst", cooked.item)
					-- take stuff from "src" list
					inv:set_stack("src", 1, aftercooked.items[1])
				else
					print("Could not insert '"..cooked.item:to_string().."'")
				end
				meta:set_string("src_time", 0)
			end
		end
		
		if meta:get_float("fuel_time") < meta:get_float("fuel_totaltime") then
			local percent = math.floor(meta:get_float("fuel_time") /
					meta:get_float("fuel_totaltime") * 100)
			meta:set_string("infotext","Furnace active: "..percent.."%")
			swap_furnace_nodes(pos, percent, "Furnace active: "..percent.."%", 1)
			meta:set_string("formspec", furnace_formspec(nil, percent))
			return
		end

		local fuel = nil
		local afterfuel
		local cooked = nil
		local fuellist = inv:get_list("fuel")
		local srclist = inv:get_list("src")
		
		if srclist then
			cooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
		end
		if fuellist then
			fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})
		end

		if fuel and fuel.time and fuel.time <= 0 then
			meta:set_string("infotext","Furnace out of fuel")
			swap_furnace_nodes(pos, 0, "Furnace out of fuel", 0)
			local metapos = pos.x..","..pos.y..","..pos.z
			meta:set_string("formspec", furnace_formspec(nil, 0))
			return
		end

		if cooked and cooked .item and cooked.item:is_empty() then
			if was_active then
				meta:set_string("infotext","Furnace is empty")
				swap_furnace_nodes(pos, 0, "Furnace is empty", 0)
				local metapos = pos.x..","..pos.y..","..pos.z
				meta:set_string("formspec", furnace_formspec(nil, 0))
			end
			return
		end

		if fuel and fuel.time then
			meta:set_string("fuel_totaltime", fuel.time*2)
		end
		meta:set_string("fuel_time", 0)
		
		if afterfuel and afterfuel.items and afterfuel.items[1] then
			inv:set_stack("fuel", 1, afterfuel.items[1])
		end
	end,
})
def = nil