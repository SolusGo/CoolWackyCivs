-- Verify actual UI callbacks, popup queues and screen blockers without a renderer.
local function event()
 local e={handlers={}};e.Add=function(f)e.handlers[#e.handlers+1]=f end
 return setmetatable(e,{__call=function(self,...)for _,f in ipairs(self.handlers)do f(...)end end})
end
Events=setmetatable({},{__index=function(t,k)local e=event();rawset(t,k,e);return e end})
Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
InterfaceModeTypes={INTERFACEMODE_SELECTION=0}
Locale={ConvertTextKey=function(key)return key end}
include=function(name)assert(name=='IconSupport','UI must not include gameplay')end
IconHookup=function(index,size,atlas,control)
 assert(atlas=='CR7_ICON_ATLAS' or atlas=='CR7_OBJECT_ATLAS')
 control.icon=index
end
local function control()
 local c={callbacks={}}
 function c:SetHide(yes)self.hidden=yes end
 function c:SetText(value)self.text=value end
 function c:RegisterCallback(key,handler)self.callbacks[key]=handler end
 function c:CalculateSize()end;function c:ReprocessAnchoring()end
 function c:CalculateInternalSize()end
 return c
end
Controls=setmetatable({},{__index=function(t,k)local c=control();rawset(t,k,c);return c end})
ContextPtr={}
function ContextPtr:SetInputHandler(handler)self.input=handler end
function ContextPtr:SetUpdate()error('UI polling is forbidden')end
