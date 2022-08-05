rule = {
  matches = {
    {
      { "node.nick", "equals", "USB Audio" },
    },
  },
  apply_properties = {
    ["node.description"] = "Back Jack",
    ["priority.session"] = 8000
  },
}

table.insert(alsa_monitor.rules,rule)
