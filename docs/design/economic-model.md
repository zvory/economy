# Economic model

- The current implementation target is the
  [fully planned physical-economy MVP](economic-model-mvp.md).
- The game needs an economic model, including support for economic crashes. The details are still
  undecided.
- The economy is a cyclic network of inputs and outputs, not a directed acyclic graph. Producers
  may depend directly or indirectly on one another's outputs.
- End users, such as consumers and the military, create demand for products. Producers seeking to
  satisfy that demand request the intermediate products they require, propagating orders through
  the production network over time rather than resolving the entire chain instantaneously.
- Raw-resource extraction is part of the production network rather than a terminal source with no
  requirements. Activities such as mining require inputs including labor.
- Players can inspect the production network and its demand, input, and output relationships in
  multiple forms.
- Changes in sector funding should take time to work through the economy. If rail funding suddenly
  stops, rail workers should not all become factory workers the next year.
- A sector cannot use unlimited new funding efficiently. Quadrupling its funding at once should
  cause waste rather than quadrupling its output.
