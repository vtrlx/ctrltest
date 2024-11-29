--[[
ctrltest.lua — App to test game controllers
]]--

local lib = require "ctrltestlib"

-- Simple class implementation without inheritance.
local function newclass(init)
	local c = {}
	local mt = {}
	c.__index = c

	function mt:__call(...)
		local obj = setmetatable({}, c)
		init(obj, ...)
		return obj
	end

	function c:isa(klass)
		return getmetatable(self) == klass
	end

	return setmetatable(c, mt)
end

--[[
SECTION: App initialization
]]--

package.cpath = "/app/lib/lua/5.4/?.so"
package.path = "/app/share/lua/5.4/?.lua"

local lgi = require "lgi"
local Adw = lgi.require "Adw"
local Gtk = lgi.require "Gtk"
local Manette = lgi.require "Manette"

local app = Adw.Application {
	application_id = "ca.vlacroix.ControlTester",
}

--[[
SECTION: Main view
This view holds the main screen of the application.
]]--

local navview = Adw.NavigationView()

local function newpage(child, title)
	local tbview = Adw.ToolbarView {
		content = child,
	}
	tbview:add_top_bar(Adw.HeaderBar())
	return Adw.NavigationPage.new(tbview, title)
end

--[[
SECTION: Controller class
This class takes a Manette controller, and creates a Gtk Widget displaying its state.
]]--

local controllers = {}
local controller = newclass(function(self, device)
	self.device = device
	self.buttons = {}
	self.axes = {}
	self.hats = {}
	function device.on_button_press_event(device, event)
		local button = event:get_button()
		if not button then error "bad event!" end
		self.buttons[button] = true
		self:refresh()
	end
	function device.on_button_release_event(device, event)
		local button = event:get_button()
		if not button then error "bad event!" end
		self.buttons[button] = false
		self:refresh()
	end
	function device.on_absolute_axis_event(device, event)
		local axis, value = event:get_absolute()
		if not axis or not value then error "bad event!" end
		self.axes[axis] = value
		self:refresh()
	end
	function device.on_hat_axis_event(device, event)
		local hat, value = event:get_hat()
		if not hat or not value then error "bad event!" end
		self.hats[hat] = value
		self:refresh()
	end
	self:initdisplay()
end)

function controller:initdisplay()
	if self.widget then return end
	local box = Gtk.Box {
		orientation = "VERTICAL",
		margin_start = 12,
		margin_end = 12,
		margin_top = 12,
		margin_bottom = 12,
		spacing = 12,
	}
	self.buttonslabel = Gtk.Label()
	self.axeslabel = Gtk.Label()
	self.hatslabel = Gtk.Label()
	box:append(self.buttonslabel)
	box:append(self.axeslabel)
	box:append(self.hatslabel)
	self.widget = newpage(box, self.device:get_name())
	self.row = Adw.ActionRow {
		title = self.device:get_name(),
		activatable = true,
	}
	function self.row.on_activated()
		navview:push(self.widget)
	end
end

function controller:refresh()
	self.buttonslabel.label = ""
	for i, v in pairs(self.buttons) do
		self.buttonslabel.label = self.buttonslabel.label .. ("%d: %q, "):format(i, v)
	end
	self.axeslabel.label = ""
	for i, v in pairs(self.axes) do
		self.axeslabel.label = self.axeslabel.label .. ("%d: %q, "):format(i, v)
	end
	self.hatslabel.label = ""
	for i, v in pairs(self.hats) do
		self.hatslabel.label = self.hatslabel.label .. ("%d: %q, "):format(i, v)
	end
end

--[[
SECTION: Manette device monitoring
]]--

local controllerbox = Gtk.ListBox {
	selection_mode = "NONE",
}
local controllerclamp = Adw.Clamp {
	child = controllerbox,
	maximum_size = 600,
	margin_top = 24,
	margin_bottom = 24,
	margin_start = 48,
	margin_end = 48,
}
local scrolled = Gtk.ScrolledWindow { child = controllerclamp }
local controllerlistpage = newpage(scrolled, "Control Tester")
do
	controllerbox:add_css_class "boxed-list"
	navview:add(controllerlistpage)
end

local monitor = Manette.Monitor()
local function add_device(device)
	print "boop"
	print("connected", device:get_name())
	local c = controller(device)
	controllers[device:get_guid()] = c
	controllerbox:append(c.row)
end
do
	local iter = monitor:iterate()
	repeat
		local device = iter:next()
		if not device then break end
		add_device(device)
	until false
end
function monitor:on_device_connected(device)
	add_device(device)
end
function monitor:on_device_disconnected(device)
	print("disconnected", device:get_name())
	local c = controllers[device:get_guid()]
	if not c then return end
	controllerbox:remove(c.row)
	if c.widget.visible then
		-- Naïve as all get out, but it seems to be the only way to hide the controller test screen on disconnect.
		navview:pop_to_page(controllerlistpage)
	end
	navview:remove(c.widget)
	controllers[device:get_guid()] = nil
end

local function newwin()
	if app.active_window then return app.active_window end
	local window = Adw.ApplicationWindow {
		application = app,
		content = navview,
	}
	return window
end

function app:on_activate()
	app.active_window:present()
end

function app:on_startup()
	newwin():present()
end

return app:run()
