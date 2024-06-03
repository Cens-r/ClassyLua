local MESSAGES = {
	neglectedIndex = "Attempting to use a class before its been implemented! <index: %s>",
	
	invalidType = "Passed an unhandled type: %s",
	excessiveConfigure = "Configuring a class that has already been implemented! Use the 'bypass' parameter to silence this warning.",
	linearizeFailure = "Failed to linearize the class!",
	
	superInvalidClass = "The class provided to 'Class.super()' was not found within the object's inheritance path!",
	superOutOfBound = "The offset calculated for 'Class.super()' was out of the bounds of the class's mro!",
	
	destroyedUse = "The object you're attempting to use has already been destroyed!",
	alreadyDestroyed = "Attempting to destroy an object that has already been destroyed!",
	
	invalidClassName = "The class name (%s) you provided is not a valid Instance class!",
	classInstanceDestroy = "Attempting to destroy a class's reference instance. This instance is used for method reference and thus destroying it isn't allowed.",
	
	missingID = "There is no error message assigned to id: %s"
}
type MessageTable = typeof(MESSAGES)

local ids = {}
for key in MESSAGES do
	ids[key] = key
end
ids.__messages = MESSAGES

return (ids :: any) :: MessageTable & { __messages: MessageTable }