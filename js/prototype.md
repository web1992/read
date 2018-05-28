# prototype

Person.prototype is an object shared by all instances of Person. It forms part of a lookup chain (that has a special name, "prototype chain"): any time you attempt to access a property of Person that isn't set, JavaScript will check Person.prototype to see if that property exists there instead. As a result, anything assigned to Person.prototype becomes available to all instances of that constructor via the this object.
