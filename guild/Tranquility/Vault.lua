-- Compatibility shim for older callers. Guild membership alone controls entry.
local A=_G.TranquilityAccess
function A:ShowVault()
 if self:Allowed()then if self.frame then self.frame:Hide()end;return true end
 return self:ShowDenied()
end
function A:SubmitVault()return false end
function A:UnlockVault()return self:Allowed()end