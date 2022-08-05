rule = {
  matches = {
    {
      { "node.nick", "equals", "USB Audio #1" },
    },
  },
  apply_properties = {
    ["node.description"] = "Front Jack",
    ["priority.session"] = 9000
  },
}

table.insert(alsa_monitor.rules,rule)
