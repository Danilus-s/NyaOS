local componen = {}

componen["gpu"] = component.proxy(component.list("gpu")())
componen["filesystem"] = component.proxy(computer.getBootAddress())

return componen
