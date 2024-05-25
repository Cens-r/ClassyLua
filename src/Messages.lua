local MESSAGES = {
	neglectedIndex = "Attempting to use a class before its been implemented! <index: %s>",
	
	invalidType = "Passed an unhandled type: %s",
	excessiveConfigure = "Configuring a class that has already been implemented! Use the 'bypass' parameter to silence this warning.",
	linearizeFailure = "Failed to linearize the class!",
	
	superInvalidClass = "The class provided to 'Class.super()' was not found within the object's inheritance path!",
	superOutOfBound = "The offset calculated for 'Class.super()' was out of the bounds of the class's mro!",
	
	missingID = "There is no error message assigned to id: %s"
}
type MessageTable = typeof(MESSAGES)

local ids = {}
for key in MESSAGES do
	ids[key] = key
end
ids.__messages = MESSAGES

return (ids :: any) :: MessageTable & { __messages: MessageTable }