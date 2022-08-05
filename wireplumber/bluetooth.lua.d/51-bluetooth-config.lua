rule = {
  matches = {
    {
      { "node.name", "matches", "bluez_output.*" },
    },
  },
  apply_properties = {
    ["priority.session"] = 9500
  },
}

table.insert(bluez_monitor.rules,rule)
